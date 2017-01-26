#requires -Version 3.0

function Enter-RemoteRegistry
{
   <#
         .Synopsis
         Read, delete or write subkeys and values of a registry on a remote computer

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .PARAMETER ComputerName
         One or more computernames. Piping is also permittet.

         .PARAMETER Path
         Path to Registry, e.g. 'HKLM:\Software'.

         .PARAMETER Read
         Read data from registry.

         .PARAMETER Delete
         Delete data from registry.

         .PARAMETER Write
         Write data to registry.

         .PARAMETER ValueName
         Name of value. Must be unique.
         Using -Read you can get all existing values by using '*' (asterisk/joker).

         .PARAMETER ValueData
         Data of value. Datatype will be checked against ValueKind,
         e.g. the word 'example' could not be used with 'DWord'.

         .PARAMETER ValueKind
         Kind of Data. Standard is 'String'.
         Possible values are String, ExpandString, Binary, DWord, MultiString, QWord

         .PARAMETER Force
         Delete or write data without warning.

         .PARAMETER Verbose
         Did a lot for verbose output. Use it if you need more information.

         .EXAMPLE
         Enter-RemoteRegistry -Read -ComputerName 'mycomputer' -Path 'HKLM:\SOFTWARE'

         .EXAMPLE
         Enter-RemoteRegistry -Read -ComputerName 'mycomputer' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion' -ValueName '*'

         .EXAMPLE
         Enter-RemoteRegistry -Read -ComputerName 'mycomputer' -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion' -ValueName 'CommonFilesDir'

         .EXAMPLE
         Enter-RemoteRegistry -Delete -ComputerName 'mycomputer' -Path 'HKLM:\SOFTWARE\TestFolder' -Force

         .EXAMPLE
         Enter-RemoteRegistry -Delete -ComputerName 'mycomputer' -Path 'HKLM:\SOFTWARE\TestFolder' -ValueName 'TestValue' -Force
   #>

   [CmdletBinding(DefaultParameterSetName = 'Read')]
   param
   (
      [Parameter(ParameterSetName = 'Read')]
      [Switch]$Read,

      [Parameter(ParameterSetName = 'Delete')]
      [Switch]$Delete,

      [Parameter(ParameterSetName = 'Write')]
      [Switch]$Write,

      [Parameter(
            Mandatory,
            ValueFromPipeline
      )]
      [Array]$Computername,

      [Parameter(Mandatory)]
      [String]$Path,

      [Parameter()]
      [String]$ValueName,

      [Parameter()]
      [String]$ValueData,

      [Parameter()]
      [Microsoft.Win32.RegistryValueKind]$ValueKind,

      [Parameter()]
      [Switch]$Force
   )

   begin
   {
      # do some error handling
      $ErrorActionPreferenceInit = $ErrorActionPreference
      $ErrorActionPreference     = 'Stop'

      # collect pipe input
      if ($Input) {$Computername = $Input}

      # verify valuedata
      try
      {
         $OldValueData = $ValueData
         Remove-Variable -Name 'ValueData' -Force

         switch ($ValueKind)
         {
            {$_ -eq 'Binary'}       {[Byte]$ValueData = $OldValueData}
            {$_ -eq 'DWord'}        {[Int32]$ValueData = $OldValueData}
            {$_ -eq 'ExpandString'} {[String]$ValueData = $OldValueData}
            {$_ -eq 'MultiString'}  {[String]$ValueData = $OldValueData}
            {$_ -eq 'QWord'}        {[Int64]$ValueData = $OldValueData}
            {$_ -eq 'String'}       {[String]$ValueData = $OldValueData}
            default
            {
               $ValueKind         = 'String'
               [String]$ValueData = $OldValueData
            }
         }

         Remove-Variable -Name 'OldValueData' -Force
      }
      catch
      {
         Write-Warning -Message 'Wrong format of ValueData'
         break
      }
   }
   process
   {
      foreach ($Computer in $Computername)
      {
         #================================================================= OPEN BASEKEY ======================================================================

         Write-Verbose -Message $Computer

         # set basekey depending on registry root
         if     ($Path -match '^HKLM:\\(.*)') {$BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)}
         elseif ($Path -match '^HKCU:\\(.*)') {$BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('CurrentUser', $Computer)}
         else
         {
            Write-Warning -Message 'Only HKLM and HKCU are supported'
            break
         }

         # check for valid basekey
         if ($BaseKey.Handle.IsInvalid -ne $false)
         {
            Write-Warning -Message 'Error opening basekey'
            break
         }

         Write-Verbose -Message "BaseKey '$($BaseKey.Name)' opened"

         #================================================================== OPEN SUBKEY ======================================================================

         # define path name
         $SubKeyPath = ($Matches[1] -replace '^\\', '' -replace '\\$', '')

         # open subkey
         $SubKey = $BaseKey.OpenSubKey($SubKeyPath, $true)

         # subkey not found
         if ($SubKey.Handle.IsInvalid -ne $false)
         {
            if ($PsCmdlet.ParameterSetName -ne 'Write')
            {
               Write-Warning -Message "SubKey '$($BaseKey.Name)\$SubKeyPath' not found"
               Write-Verbose -Message "BaseKey '$($BaseKey.Name)' closed"
               $BaseKey.Close()
               return
            }
         }

         #=================================================================== SUBKEY FOUND ====================================================================

         if ($SubKey.Handle.IsInvalid -eq $false)
         {
            Write-Verbose -Message "SubKey '$($SubKey.Name)' opened"

            #__________________________________________________________________ R E A D _______________________________________________________________________

            if ($PsCmdlet.ParameterSetName -eq 'Read')
            {
               #--------------------------------------------------------------- SUBKEYS -----------------------------------------------------------------------
               if (-not $ValueName)
               {
                  Write-Verbose -Message "Found $($SubKey.SubKeyCount) subkeys"
                  $SubKey.GetSubKeyNames()
               }
               #---------------------------------------------------------------- VALUES -----------------------------------------------------------------------
               elseif ($ValueName)
               {
                  [Collections.ArrayList]$ValueNames = @()

                  Write-Verbose -Message "Found $($SubKey.ValueCount) values"

                  foreach ($GetValueName in $SubKey.GetValueNames())
                  {
                     if ($GetValueName.Length -ne 0)
                     {
                        $ValueNames += [PSCustomObject]@{
                           'ValueName' = $GetValueName
                           'ValueData' = $SubKey.GetValue($GetValueName)
                           'ValueKind' = $SubKey.GetValueKind($GetValueName)
                        }
                     }
                  }

                  Write-Verbose -Message "Filter set to value '$ValueName'"

                  # output all values
                  if ($ValueName -eq '*') {$ValueNames}
                  # output matching values
                  else {$ValueNames | Where-Object -FilterScript {$_.ValueName -eq $ValueName}}
               }
            }
            #_________________________________________________________ D E L E T E  |  W R I T E ______________________________________________________________

            elseif ($PsCmdlet.ParameterSetName -match '(Delete|Write)')
            {
               #---------------------------------------------------------------- SUBKEYS ----------------------------------------------------------------------
               if (-not $ValueName)
               {
                  if ($Force)
                  {
                     # set lower name and path
                     $SubKeyName = $SubKeyPath.Substring($SubKeyPath.LastIndexOf('\') + 1)
                     $SubKeyPath = $SubKeyPath -replace "\\$SubKeyName$"

                     Write-Verbose -Message "SubKey '$($SubKey.Name)' closed"
                     $SubKey.Close()

                     # open subkey
                     $SubKey = $BaseKey.OpenSubKey($SubKeyPath, $true)

                     # check for valid subkey
                     if ($SubKey.Handle.IsInvalid -ne $false)
                     {
                        Write-Warning -Message "Error opening subkey '$($BaseKey.Name)\$SubKeyPath'"
                        $BaseKey.Close()
                        return
                     }
                     else {Write-Verbose -Message "SubKey '$($SubKey.Name)' opened"}

                     # delete subkey
                     $null = $SubKey.DeleteSubKeyTree($SubKeyName)
                     Write-Verbose -Message "SubKey '$SubKeyName' deleted"

                     # close subkey
                     Write-Verbose -Message "SubKey '$($SubKey.Name)' closed"
                     $SubKey.Close()

                     # set upper name and path
                     $SubKeyPath = "$SubKeyPath\$SubKeyName"
                     $SubKey     = $BaseKey.OpenSubKey($SubKeyPath, $true)
                  }

                  if (-not $Force) {Write-Warning -Message "SubKey '$($SubKey.Name)' exists, use parameter -Force"}
               }

               #---------------------------------------------------------------- VALUES -----------------------------------------------------------------------

               if ($ValueName)
               {
                  if ($Force)
                  {
                     if ($SubKey.GetValue($ValueName) -ne $null)
                     {
                        Write-Verbose -Message "Value '$ValueName' exists"
                        Write-Verbose -Message "Old ValueData: $($SubKey.GetValue($ValueName))"
                        Write-Verbose -Message "Old ValueKind: $($SubKey.GetValueKind($ValueName))"

                        $SubKey.DeleteValue($ValueName)
                        Write-Verbose -Message "Value '$ValueName' deleted"
                     }
                  }

                  # check for existing valuenames
                  if (-not $Force)
                  {
                     if ($SubKey.GetValue($ValueName) -ne $null)
                     {
                        Write-Warning -Message "Value '$ValueName' exists, use parameter -Force"
                        Write-Verbose -Message "Current ValueData: $($SubKey.GetValue($ValueName))"
                        Write-Verbose -Message "Current ValueKind: $($SubKey.GetValueKind($ValueName))"
                     }
                  }

                  if ($SubKey.GetValue($ValueName) -eq $null)
                  {
                     if ($PsCmdlet.ParameterSetName -eq 'Delete') {Write-Verbose -Message "ValueName '$ValueName' not found"}

                     if ($PsCmdlet.ParameterSetName -eq 'Write')
                     {
                        if ($ValueData -eq $null) {Write-Warning -Message 'ValueData missing'}

                        if ($ValueData -ne $null)
                        {
                           $SubKey.SetValue($ValueName, $ValueData, [Microsoft.Win32.RegistryValueKind]::$ValueKind)

                           # check for set value
                           if ($SubKey.GetValueNames() -contains $ValueName)
                           {
                              Write-Verbose -Message "New ValueName: $ValueName"
                              Write-Verbose -Message "New ValueData: $ValueData"
                              Write-Verbose -Message "New ValueKind: $ValueKind"
                           }
                           else {Write-Warning -Message "Error setting value '$ValueName'"}
                        }
                     }
                  }
               }
            }
         }

         #================================================================= SUBKEY NOT FOUND ==================================================================

         if ($SubKey.Handle.IsInvalid -ne $false)
         {
            # create subkey
            if ($PsCmdlet.ParameterSetName -eq 'Write')
            {
               # set lower name and path
               $SubKeyName = $SubKeyPath.Substring($SubKeyPath.LastIndexOf('\') + 1)
               $SubKeyPath = $SubKeyPath -replace "\\$SubKeyName$"

               # open subkey
               $SubKey = $BaseKey.OpenSubKey($SubKeyPath, $true)

               # check for valid subkey
               if ($SubKey.Handle.IsInvalid -ne $false)
               {
                  Write-Warning -Message "Error opening subkey '$($BaseKey.Name)\$SubKeyPath'"
                  $BaseKey.Close()
                  return
               }
               else {Write-Verbose -Message "SubKey '$($SubKey.Name)' opened"}

               # create subkey
               $null = $SubKey.CreateSubKey($SubKeyName)
               Write-Verbose -Message "SubKey '$SubKeyName' created"

               # close subkey
               Write-Verbose -Message "SubKey '$($SubKey.Name)' closed"
               $SubKey.Close()

               # set upper name and path
               $SubKeyPath = "$SubKeyPath\$SubKeyName"
               $SubKey     = $BaseKey.OpenSubKey($SubKeyPath, $true)
               Write-Verbose -Message "SubKey '$($SubKey.Name)' opened"
            }
         }

         #=================================================================== CLOSE SUBKEY ====================================================================

         if ($SubKey.Name -ne $null)
         {
            Write-Verbose -Message "SubKey '$($SubKey.Name)' closed"
            $SubKey.Close()
         }

         #================================================================== CLOSE BASEKEY ====================================================================

         Write-Verbose -Message "BaseKey '$($BaseKey.Name)' closed"
         $BaseKey.Close()
      }
   }
   end {$ErrorActionPreference = $ErrorActionPreferenceInit}
}
