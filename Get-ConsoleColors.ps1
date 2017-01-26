#requires -Version 3.0

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

         .EXAMPLE
         'yellow', 'red' | Get-ConsoleColors
   #>

   [CmdletBinding(PositionalBinding = $false)]
   param
   (
      [Parameter(ValueFromPipeline)]
      [String]$Color = 'white'
   )

   begin
   {
      # do some error handling
      $ErrorActionPreferenceInit = $ErrorActionPreference
      $ErrorActionPreference     = 'Stop'

      # get all possible colors
      try   {$ConsoleColors = [ConsoleColor].GetEnumNames()}
      catch {"[ERROR@$($_.InvocationInfo.ScriptLineNumber)] $_"}
   }
   process
   {
      try
      {
         foreach ($ConsoleColor in $ConsoleColors)
         {
            # design two columns with names of colors
            $Object = ' ' + ([ConsoleColor]::$ConsoleColor).ToString().PadRight(($ConsoleColors | Measure-Object -Maximum -Property Length).Maximum) + ' '

            if ($Color)
            {
               Write-Host -BackgroundColor ([ConsoleColor]::$Color) -ForegroundColor ([ConsoleColor]::$ConsoleColor) -NoNewline -Object $Object
               Write-Host -Object ' ' -NoNewline
               Write-Host -ForegroundColor ([ConsoleColor]::$Color) -BackgroundColor ([ConsoleColor]::$ConsoleColor) -Object $Object
            }
            else
            {
               Write-Host -ForegroundColor ([ConsoleColor]::$ConsoleColor) -Object $Object -NoNewline
               Write-Host -Object ' ' -NoNewline
               Write-Host -BackgroundColor ([ConsoleColor]::$ConsoleColor) -Object $Object
            }
         }
      }
      catch {"[ERROR@$($_.InvocationInfo.ScriptLineNumber)] $_"}
   }
   end {$ErrorActionPreference = $ErrorActionPreferenceInit}
}
