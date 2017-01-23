#requires -Version 3.0

function Get-ComputerHardware
{
   <#
         .Synopsis
         Get basic information about computers

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .DESCRIPTION
         Give in one or more computernames to request states of RAM, CPU and disk sizes.
         For remote servers in a different domain you can transmit your credentials.

         .PARAMETER ComputerName
         One or more servers, you can also pipe a list.

         .PARAMETER Credential
         Open window to hand over credentials including domain, username and password.
   #>

   [CmdletBinding()]
   Param
   (
      [Parameter(Mandatory, ValueFromPipeline)]
      [array]$ComputerName,

      [Parameter()]
      [switch]$Credential
   )

   begin
   {
      # do some error handling
      $ErrorActionPreference = 'Stop'

      # ask for credentials if necessary
      if ($Credential)
      {
         $Cred = Get-Credential -Message 'Waiting for your credentials'
      }

      # define array for result
      [Collections.ArrayList]$Output = @()
   }

   process
   {
      foreach ($Computer in $ComputerName)
      {
         try
         {
            # credentials set
            if ($Cred)
            {
               $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer -Credential $Cred
               $LogicalDisk    = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer -Credential $Cred | Where-Object -Property MediaType -EQ -Value '12'
            }

            # no credentials set
            else
            {
               $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer
               $LogicalDisk    = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer | Where-Object -Property MediaType -EQ -Value '12'
            }

            # get processor and memory
            $CPU = '{0}' -f [int]$ComputerSystem.NumberOfLogicalProcessors
            $RAM = '{0:#} GB' -f [int]($ComputerSystem.TotalPhysicalMemory/1GB)

            # get disks
            foreach ($Drive in ($LogicalDisk.DeviceID -replace ':'))
            {
               $Size      = $('{0} GB' -f [math]::Round(($LogicalDisk | Where-Object -FilterScript {$_.DeviceID -eq $($Drive + ':')}).Size/1GB))
               $FreeSpace = $('{0} GB' -f [math]::Round(($LogicalDisk | Where-Object -FilterScript {$_.DeviceID -eq $($Drive + ':')}).FreeSpace/1GB))
               
               Set-Variable -Name $('Disk{0}_s' -f $Drive) -Value $Size -Force
               Set-Variable -Name $('Disk{0}_f' -f $Drive) -Value $FreeSpace -Force
            }

            # set data for output
            $Data        = [ordered]@{}
            $Data.Server = $Computer.ToUpper()
            $Data.RAM    = $RAM
            $Data.CPU    = $CPU

            foreach ($Drive in ($LogicalDisk.DeviceID -replace ':'))
            {
               $Data.$('{0}s' -f $Drive) = $(Get-Variable -Name $('Disk{0}_s' -f $Drive)).Value
               $Data.$('{0}f' -f $Drive) = $(Get-Variable -Name $('Disk{0}_f' -f $Drive)).Value
            }

            $Output += New-Object -TypeName PSObject -Property $Data
         }

         catch
         {
            # set data for output
            $Data             = [ordered]@{}
            $Data.Server      = $Computer.ToUpper()
            $Data.Information = 'error'
            $Output += New-Object -TypeName PSObject -Property $Data
         }
      }
   }

   end
   {
      $Output
   }
}
