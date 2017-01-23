#requires -Version 1.0

function Get-ConsoleColors 
{
   <#
         .Synopsis
         Show a bunch of colors in console window

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .PARAMETER Color
         Set foreground and background to compare against a fixed color

         .EXAMPLE
         Get-ConsoleColors

         .EXAMPLE
         Get-ConsoleColors -Color Yellow
   #>

   [CmdletBinding()]
   Param
   (
      [Parameter()]
      [ConsoleColor]$Color = 'white'
   )

   begin
   {
      # do some error handling
      $ErrorActionPreference = 'Stop'

      # get all possible colors
      $ConsoleColors = [ConsoleColor].GetEnumNames()
   }

   process
   {
      foreach ($ConsoleColor in $ConsoleColors)
      {
         if ($Color)
         {
            Write-Host -BackgroundColor $Color -ForegroundColor ([ConsoleColor]::$ConsoleColor) -Object (' ' + ([ConsoleColor]::$ConsoleColor).ToString().PadRight(($ConsoleColors | Measure-Object -Maximum -Property Length).Maximum) + ' ') -NoNewline
            Write-Host -Object ' ' -NoNewline
            Write-Host -ForegroundColor $Color -BackgroundColor ([ConsoleColor]::$ConsoleColor) -Object (' ' + ([ConsoleColor]::$ConsoleColor).ToString().PadRight(($ConsoleColors | Measure-Object -Maximum -Property Length).Maximum) + ' ')
         }

         else
         {
            Write-Host -ForegroundColor ([ConsoleColor]::$ConsoleColor) -Object (' ' + ([ConsoleColor]::$ConsoleColor).ToString().PadRight(($ConsoleColors | Measure-Object -Maximum -Property Length).Maximum) + ' ') -NoNewline
            Write-Host -Object ' ' -NoNewline
            Write-Host -BackgroundColor ([ConsoleColor]::$ConsoleColor) -Object (' ' + ([ConsoleColor]::$ConsoleColor).ToString().PadRight(($ConsoleColors | Measure-Object -Maximum -Property Length).Maximum) + ' ')
         }
      }
   }
}
