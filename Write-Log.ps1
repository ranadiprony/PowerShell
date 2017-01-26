#requires -Version 3.0
function Write-Log
{
   <#
         .Synopsis
         Send a message to a logfile

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .DESCRIPTION
         Takes a message to send it to a logfile. If used in a catch-block you can read the scriptlinenumber.

         .PARAMETER Message
         Own text or error variable

         .PARAMETER Break
         Breaks workflow after saving the logfile

         .EXAMPLE
         Write-Log -Message 'This is my text'

         .EXAMPLE
         try {Get-ChildItem -Path $non_existing_path}
         catch {$_ | Write-Log -Break}
   #>

   [CmdletBinding()]
   param (
      [Parameter(
            Mandatory,
            ValueFromPipeline
      )]
      $Message,

      [Parameter()]
      [Switch]$Break
   )

   try
   {
      if ($Message.InvocationInfo.ScriptLineNumber) {$InputObject = (Get-Date).ToString() + " [ERROR@$($Message.InvocationInfo.ScriptLineNumber)] " + $Message}
      else                                          {$InputObject = (Get-Date).ToString() + " $Message"}

      Out-File -InputObject $InputObject -FilePath "$PSScriptRoot\WriteLog.log" -Encoding utf8 -Append -Force
   
      if ($Break) {Break}
   }
   catch
   {
      Write-Warning -Message $_
   }
}
