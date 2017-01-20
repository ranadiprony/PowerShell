#requires -Version 2.0

function Update-ConsoleWindow
{
   <#
         .Synopsis
         Hide or show powershell console window

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .DESCRIPTION
         Called with the responding parameter the console gets hidden or shown.
         Only useful if called within a different runspace or process.
         Keep in mind: If called in current console the window is hidden with the process remaining in memory.

         .PARAMETER Hide
         Hide console

         .PARAMETER Show
         Show console

         .EXAMPLE
         Update-ConsoleWindow -Hide

         .EXAMPLE
         Update-ConsoleWindow -Show
   #>

   [CmdletBinding()]
   param
   (
      [Parameter()]
      [switch]$Hide,

      [Parameter()]
      [switch]$Show
   )

   # initialize function

   try
   {
      Add-Type -Name 'Window' -Namespace 'Console' -MemberDefinition '
         [DllImport("Kernel32.dll")]
         public static extern IntPtr GetConsoleWindow();

         [DllImport("user32.dll")]
         public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
      '
   }

   catch
   {
   }

   if ($Hide)
   {
      $consolePtr = [Console.Window]::GetConsoleWindow()
      $null       = [Console.Window]::ShowWindow($consolePtr,0)
   }

   elseif ($Show)
   {
      $consolePtr = [Console.Window]::GetConsoleWindow()
      $null       = [Console.Window]::ShowWindow($consolePtr,5)
   }

   else
   {
      Write-Warning -Message "Use parameter 'Hide' or 'Show' to make some action"
   }
}
