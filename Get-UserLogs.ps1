#requires -Version 4.0

function Get-UserLogs
{
   <#
         .Synopsis
         Get users and their server log times

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .DESCRIPTION
         Give in one or more computernames to request times for logon and logoff.
         For reaching remote servers in a different domain you can transmit your credentials.

         .PARAMETER Computername
         One or more computernames

         .PARAMETER LogonType
         Define the type of logon that should be processed. Number or name could be used both.

         2 Interactive (logon at keyboard and screen of system)
         3 Network (i.e. connection to shared folder on this computer from elsewhere on network)
         4 Batch (i.e. scheduled task)
         5 Service (Service startup)
         7 Unlock (i.e. unnattended workstation with password protected screen saver)
         8 NetworkCleartext (Logon with credentials sent in the clear text. Often indicates a logon to IIS with "basic authentication")
         9 NewCredentials (such as with RunAs or mapping a network drive with alternate credentials)
         10 RemoteInteractive (Terminal Services, Remote Desktop or Remote Assistance)
         11 CachedInteractive (logon with cached domain credentials such as when logging on to a laptop when away from the network)

         Default is to show all types.

         .PARAMETER StartTime
         Timeset of the earlist log entries. Should work in your local format, e.g. dd.MM.yyyy hh:mm:ss or MM/dd/yyyy hh:mm:ss

         Default is 24 hours before.

         .PARAMETER EndTime
         Timeset of the latest log entries. Should work in your local format, e.g. dd.MM.yyyy hh:mm:ss or MM/dd/yyyy hh:mm:ss

         Default is current time.

         .PARAMETER Credential
         Open window to hand over credentials including domain, username and password.

         .PARAMETER OnlyLogin
         Only show log with logins.

         .PARAMETER OnlyLogoff
         Only show log with logoffs.
   #>

   [CmdletBinding()]
   Param
   (
      [Parameter(Mandatory, ValueFromPipeline)]
      [array]$ComputerName,

      [Parameter()]
      [ValidateSet('Interactive', 'Network', 'Batch', 'Service', 'Unlock', 'Networkcleartext', 'NewCredentials', 'RemoteInteractive', 'CachedInteractive')]
      [string]$LogonType = $null,

      [Parameter()]
      [string]$UserName = $null,

      [Parameter()]
      [string]$StartTime,

      [Parameter()]
      [string]$EndTime,

      [Parameter()]
      [switch]$Credential,

      [Parameter()]
      [switch]$OnlyLogin,

      [Parameter()]
      [switch]$OnlyLogoff
   )

   begin
   {
      # do some error handling
      $ErrorActionPreference = 'Stop'

      # define logon types
      $LogonTypes = @{
         '2' = 'Interactive'
         '3' = 'Network'
         '4' = 'Batch'
         '5' = 'Service'
         '7' = 'Unlock'
         '8' = 'Networkcleartext'
         '9' = 'NewCredentials'
         '10' = 'RemoteInteractive'
         '11' = 'CachedInteractive'
      }

      # ask for credentials if necessary
      switch ($Credential)
      {
         $true
         {
            $Cred    = Get-Credential -Message 'Waiting for your credentials'
            $Command = 'Get-WinEvent -ComputerName $Computer -FilterHashtable $Filter -Credential $Cred'
         }

         default {$Command = 'Get-WinEvent -ComputerName $Computer -FilterHashtable $Filter'}
      }

      # collect pipe input
      if ($Input) {$ComputerName = $Input}

      # give attention when logontype or username are set
      Write-Host -Object ''

      if ($LogonType) {Write-Host -ForegroundColor DarkYellow -Object ("`Logontype set to '$LogonType'")}
      if ($UserName)  {Write-Host -ForegroundColor DarkYellow -Object ("Username set to '$UserName'") }

      # set culture for correct time format
      try
      {
         $Culture = New-Object -TypeName System.Globalization.CultureInfo -ArgumentList ([Globalization.CultureInfo]::CurrentCulture.Name)

         switch ($StartTime.Length)
         {
            {$_ -gt 0} {$StartTime = ($StartTime | Get-Date -Format $Culture.DateTimeFormat.ShortDatePattern) + ' ' + ($StartTime | Get-Date -Format $Culture.DateTimeFormat.LongTimePattern)}
            default    {[datetime]$StartTime = (Get-Date).AddDays(-1)}
         }

         switch ($EndTime.Length)
         {
            {$_ -gt 0} {$EndTime = ($EndTime | Get-Date -Format $Culture.DateTimeFormat.ShortDatePattern) + ' ' + ($EndTime | Get-Date -Format $Culture.DateTimeFormat.LongTimePattern)}
            default    {[datetime]$EndTime = (Get-Date)}
         }
      }

      catch
      {
         Write-Warning -Message 'Please check starttime/endtime'
         $Error[0]
         Break
      }

      function Output
      {
         param
         (
            [switch]$Login,
            [switch]$Logoff,
            [string]$Output
         )

         if ($Login)
         {
            Write-Host -BackgroundColor DarkGreen -NoNewline -Object "[login]"
            Write-Host -Object "  $Date $Time " -NoNewline
         }

         if ($Logoff)
         {
            Write-Host -BackgroundColor DarkRed -NoNewline -Object "[logoff]"
            Write-Host -Object " $Date $Time " -NoNewline
         }

         Write-Host -Object $Output
      }
   }

   process
   {
      foreach ($Computer in $ComputerName)
      {
         Write-Host -ForegroundColor Yellow -Object "`n$($Computer.ToUpper())"

         # set filter
         if     ($OnlyLogin)  {$ID = 4624}
         elseif ($OnlyLogoff) {$ID = 4634}
         else                 {$ID = 4624, 4634}

         $Filter = @{
            LogName   = 'Security'
            ID        = $ID
            StartTime = $StartTime
            EndTime   = $EndTime
         }

         try
         {
            Invoke-Expression -Command $Command | ForEach-Object -Process {

               [array]$Event = $_
               [array]$XML = ([XML]$Event.ToXml()).Event.EventData.Data

               $Date         = $Event.TimeCreated.ToShortDateString()
               $Time         = $Event.TimeCreated.ToShortTimeString()
               $UserNameXML  = $XML.Where{$_.Name -eq 'TargetUserName'}.'#text'
               $LogonTypeXML = $XML.Where{$_.Name -eq 'LogonType'}.'#text'

               if ($UserName -and ($UserNameXML -match $UserName))
               {
                  if ($LogonType)
                  {
                     if ($LogonTypeXML -eq $LogonTypes.GetEnumerator().Where{$_.Value -eq $LogonType}.Name)
                     {
                        switch ($Event.ID)
                        {
                           4624 {Output -Login}
                           4634 {Output -Logoff}
                        }
                     }
                  }

                  else
                  {
                     switch ($Event.ID)
                     {
                        4624 {Output -Login -Output $($LogonTypes.$LogonTypeXML)}
                        4634 {Output -Logoff}
                     }
                  }
               }

               elseif (-not $UserName)
               {
                  if ($LogonType)
                  {
                     if ($LogonTypeXML -eq $LogonTypes.GetEnumerator().Where{$_.Value -eq $LogonType}.Name)
                     {
                        switch ($Event.ID)
                        {
                           4624 {Output -Login -Output $UserNameXML}
                           4634 {Output -Logoff -Output $UserNameXML}
                        }
                     }
                  }

                  else
                  {
                     switch ($Event.ID)
                     {
                        4624 {Output -Login -Output "$UserNameXML $($LogonTypes.$LogonTypeXML)"}
                        4634 {Output -Logoff -Output $UserNameXML}
                     }
                  }
               }
            }
         }

         catch
         {
            Write-Host -Object 'Error while reading data' -ForegroundColor Red
            Write-Host -Object $Error[0]
            Continue
         }
      }
   }
}
