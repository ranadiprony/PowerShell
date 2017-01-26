#requires -Version 2.0

function Update-ConsoleWindow
{
   <#
         .Synopsis
         Hide or show PowerShell console window

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .DESCRIPTION
         Called with the responding parameter the console gets hidden or shown.
         Only useful if called within a different runspace or process.
         Keep in mind: If called in current console the window is hidden with the process remaining in memory.

         .PARAMETER Handle
         0  HIDE
         1  NORMAL
         2  SHOWMINIMIZED
         3  SHOWMAXIMIZED
         4  SHOWNOACTIVATE
         5  SHOW
         6  MINIMIZE
         7  SHOWMINNOACTIVE
         8  SHOWNA
         9  RESTORE
         10 SHOWDEFAULT
         11 FORCEMINIMIZE
   #>

   [CmdletBinding()]
   param
   (
      [Parameter(
            Mandatory,
            ValueFromPipeline
      )]
      [Int]$Handle = 1
   )

   begin
   {
      # do some error handling
      $ErrorActionPreferenceInit = $ErrorActionPreference
      $ErrorActionPreference     = 'Stop'
   }
   process
   {
      try
      {
         # initialize function
         Add-Type -Name 'Window' -Namespace 'Console' -MemberDefinition '
            [DllImport("Kernel32.dll")]
            public static extern IntPtr GetConsoleWindow();

            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
         '

         $null = [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(),$Handle)
      }
      catch {"[ERROR@$($_.InvocationInfo.ScriptLineNumber)] $_"}
   }
   end {$ErrorActionPreference = $ErrorActionPreferenceInit}
}
