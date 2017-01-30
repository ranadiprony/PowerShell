#requires -Version 3.0

function Convert-NumbersToWords
{
   <#
         .Synopsis
         Convert numbers to words

         .NOTES
         Tobias Haase
         tohaase@online.de
         https://github.com/tohaase

         .DESCRIPTION
         To resolve a riddle for geocaching I required a tool to change whole numbers to german words. Here we are.

         .PARAMETER Number
         Any whole number up to 1000000000000000000

         .PARAMETER Divider
         Put a char between the blocks to aim readability

         .PARAMETER Table
         Format output as hashtable

         .EXAMPLE
         1..10 | Convert-NumbersToWords
         eins
         zwei
         drei
         vier
         fünf
         sechs
         sieben
         acht
         neun
         zehn

         .EXAMPLE
         1..10 | Convert-NumbersToWords -Table

         Name                           Value                                                                                                                                                    
         ----                           -----                                                                                                                                                    
         1                              eins                                                                                                                                                     
         2                              zwei                                                                                                                                                     
         3                              drei                                                                                                                                                     
         4                              vier                                                                                                                                                     
         5                              fünf                                                                                                                                                     
         6                              sechs                                                                                                                                                    
         7                              sieben                                                                                                                                                   
         8                              acht                                                                                                                                                     
         9                              neun                                                                                                                                                     
         10                             zehn   

         .EXAMPLE
         100..110 | Convert-NumbersToWords -Table -Divider '-'

         Name                           Value                                                                                                                                                    
         ----                           -----                                                                                                                                                    
         100                            ein-hundert                                                                                                                                              
         101                            ein-hundert-eins                                                                                                                                         
         102                            ein-hundert-zwei                                                                                                                                         
         103                            ein-hundert-drei                                                                                                                                         
         104                            ein-hundert-vier                                                                                                                                         
         105                            ein-hundert-fünf                                                                                                                                         
         106                            ein-hundert-sechs                                                                                                                                        
         107                            ein-hundert-sieben                                                                                                                                       
         108                            ein-hundert-acht                                                                                                                                         
         109                            ein-hundert-neun                                                                                                                                         
         110                            ein-hundert-zehn   
   #>

   [CmdletBinding()]
   param
   (
      [Parameter(
            Mandatory,
            ValueFromPipeline
      )]
      [Array]$Number,

      [Parameter()]
      [String]$Divider,

      [Parameter()]
      [Switch]$Table
   )

   begin
   {
      # do some error handling
      $ErrorActionPreferenceInit = $ErrorActionPreference
      $ErrorActionPreference     = 'Stop'

      # collect pipe input
      if ($Input) {$Number = $Input}

      # define words
      $Words = [ordered]@{
         'and'    = 'und'
         'one'    = 'ein'
         '0'      = 'null'
         '1'      = 'eins'
         '2'      = 'zwei'
         '3'      = 'drei'
         '4'      = 'vier'
         '5'      = 'fünf'
         '6'      = 'sechs'
         '7'      = 'sieben'
         '8'      = 'acht'
         '9'      = 'neun'
         '10'     = 'zehn'
         '11'     = 'elf'
         '12'     = 'zwölf'
         '13'     = 'dreizehn'
         '14'     = 'vierzehn'
         '15'     = 'fünfzehn'
         '16'     = 'sechszehn'
         '17'     = 'siebzehn'
         '18'     = 'achtzehn'
         '19'     = 'neunzehn'
         '20'     = 'zwanzig'
         '30'     = 'dreißig'
         '40'     = 'vierzig'
         '50'     = 'fünfzig'
         '60'     = 'sechzig'
         '70'     = 'siebzig'
         '80'     = 'achtzig'
         '90'     = 'neunzig'
         '100'    = 'hundert'
         '10^3'   = 'tausend'
         '10^3s'  = 'ein tausend'
         '10^6'   = 'millionen'
         '10^6s'  = 'eine million'
         '10^9'   = 'milliarden'
         '10^9s'  = 'eine milliarde'
         '10^12'  = 'billionen'
         '10^12s' = 'eine billion'
         '10^15'  = 'billiarden'
         '10^15s' = 'eine billiarde'
      }
   }
   process
   {
      try
      {
         $Number | ForEach-Object -Process {

            if ($_ -ge 1000000000000000000)
            {
               Write-Warning -Message 'Number not supported'
            }
            else
            {
               ############################################################# INITIALIZE VARIABLES #############################################################

               [Long]$ThisNum  = $_
               [String]$Left   = $ThisNum
               [String]$Group  = ''
               [String]$Slice  = ''
               [String]$Word   = ''
               [Array]$PowName = ($Words.GetEnumerator() | Where-Object -Property Name -Match -Value '^10\^[0-9]{1,2}$').Name
               [Bool]$Ready    = $false

               # loop while not resolved the whole number
               while ($Ready -eq $false)
               {
                  ############################################################# SET POWER RELATION ############################################################
                  
                  $PowName | ForEach-Object -Process {if ($Left.Length -gt ($_ -replace '^10\^')) {$Group = $Words.$_}}

                  ######################################################### SET SLICE OF LEFT NUMBER ##########################################################
                  
                  if ($Slice.Length -eq 0)
                  {
                     $PowValue = $(($Words.GetEnumerator() | Where-Object -Property Value -EQ -Value $Group).Name -replace '^10\^')
               
                     if ($PowValue) {$Slice = $Left.Substring(0, $Left.Length - $PowValue)}
                     else           {$Slice = $Left}
                  }
      
                  ############################################################### PROCESS SLICE ###############################################################
                  
                  switch ($Slice.Length)
                  {
                     #========================================================== SLICE WITH 1 DIGIT ===========================================================
                     1
                     {
                        #.............................................................. DIGIT 0 ...............................................................
                        if (($Slice -eq 0) -and ($Left.Length -eq 1)) {$Word += $Words.'0'}
                        
                        #............................................................. DIGIT 1-9 ..............................................................
                        if ($Slice -ne 0)
                        {
                           #........................................................... DIGIT 1 ...............................................................
                           if ($Group -and $Slice -eq '1') {$Word += $Words.$(($Words.GetEnumerator() | Where-Object -Property Value -EQ -Value $Group).Name + 's')}
                           else                            {$Word += $Words.$Slice}

                           # set divider
                           if ($Divider) {$Word += $Divider}

                           #............................................................ DIGIT 2 - 9 .............................................................
                           if (($Group) -and ($Slice -match '([2-9])'))
                           {
                              # add group to word
                              $Word += $Group
                           
                              # set divider
                              if ($Divider) {$Word += $Divider}
                           }
                        }

                        # reduce slice
                        $Slice = $Slice.Substring(1)
                     }
                     #========================================================= SLICE WITH 2 DIGITS ===========================================================
                     2
                     {
                        #............................................................ DIGIT 01-09 .............................................................
                        if ($Slice -match '(^[0][1-9]$)')
                        {
                           if ($Group -and ($Slice.Substring(1,1) -eq '1')) {$Word += $Words.$(($Words.GetEnumerator() | Where-Object -Property Value -EQ -Value $Group).Name + 's')}
                           else {$Word += $Words.($Slice.Substring(1,1))}
                           
                           # set divider
                           if ($Divider) {$Word += $Divider}
                        }
                        #............................................................ DIGIT 10-19 .............................................................
                        elseif ($Slice -match '(^[1][0-9]$)')
                        {
                           $Word += $Words.('1' + $Slice.Substring(1,1))
                           
                           # set divider
                           if ($Divider) {$Word += $Divider}
                        }
                        #............................................................ DIGIT 20-99 .............................................................
                        elseif ($Slice -match '(^[2-9][0-9]$)')
                        {
                           #..................................................... DIGITS W/O LEADING '0' ......................................................
                           if ($Slice.Substring(1,1) -ne 0)
                           {
                              if ($Slice.Substring(1,1) -eq '1') {$Word += $Words.'one'}
                              else {$Word += $Words.($Slice.Substring(1,1))}

                              # set divider
                              if ($Divider) {$Word += $Divider}

                              # add 'and' to word
                              $Word += $Words.'and'

                              # set divider
                              if ($Divider) {$Word += $Divider}
                           }

                           #...................................................... NAME OF LEADING '0' ........................................................
                           $Word += $Words.($Slice.Substring(0,1) + 0)

                           # set divider
                           if ($Divider) {$Word += $Divider}
                        }

                        #........................................................... DIGIT NOT 00 .............................................................
                        if (($Group) -and ($Slice -notmatch '(^[0][1]$)'))
                        {
                           # set divider
                           if ($Divider) {$Word += $Divider}

                           # add group to word
                           $Word += $Group

                           # set divider
                           if ($Divider) {$Word += $Divider}
                        }
                     
                        # reduce slice
                        $Slice = $Slice.Substring(1)
                        
                        #............................................................. DIGIT 00 ...............................................................
                        if ($Group -and ($Slice -match '(^[0][0]$)'))
                        {
                           # set divider
                           if ($Divider) {$Word += $Divider}

                           # add group to word
                           $Word += $Group

                           # set divider
                           if ($Divider) {$Word += $Divider}
                        }

                        # reduce slice
                        $Slice = $Slice.Substring(1)
                     }
                     #========================================================= SLICE WITH 3 DIGITS ===========================================================
                     3
                     {
                        if ($Slice -match '(^[0][0][0]$)')
                        {
                           # reduce slice
                           $Slice = $Slice.Substring(1)
                           $Slice = $Slice.Substring(1)
                        }
                        elseif ($Slice.Substring(0,1) -ne 0)
                        {
                           if ($Slice.Substring(0,1) -eq 1) {$Word += $Words.'one'}
                           else                             {$Word += $($Words.($Slice.Substring(0,1)))}

                           # set divider
                           if ($Divider) {$Word += $Divider}

                           # add word for '100'
                           $Word += $Words.'100'
               
                           # set divider
                           if ($Divider) {$Word += $Divider}
                        }

                        # reduce slice
                        $Slice = $Slice.Substring(1)
                     }
                  }
            
                  # finish conversation
                  if (($Slice.Length -eq 0) -and ($Left.Length -le 3)) {$Ready = $true}

                  # prepare for another loop
                  if (($Slice.Length -eq 0) -and ($Left.Length -gt 3))
                  {
                     $PowValue = $(($Words.GetEnumerator() | Where-Object -Property Value -EQ -Value $Group).Name -replace '^10\^')
               
                     if ($PowValue) {$Left = $Left.Substring($Left.Length - $PowValue)}
                     else           {$Left = $Left.Substring($Left.Length - 3)}

                     # remove group
                     $Group = ''
                  }
               }
               
               #################################################################### OUTPUT ####################################################################

               # prepare output
               if ($Divider) {$Result = ($Word -replace $('{0}{1}' -f $Divider, $Divider), $Divider).TrimStart($Divider).TrimEnd($Divider)}
               else          {$Result = $Word -replace ' '}
               
               # format output to hashtable
               if ($Table)
               {
                  $Output = @{}
                  $Output.Add($ThisNum, $Result)
                  $Output | Write-Output
               }
               else {$Result | Write-Output}               
            }
         }
      }
      catch {"[ERROR@$($_.InvocationInfo.ScriptLineNumber)] $_"}
   }
   end {$ErrorActionPreference = $ErrorActionPreferenceInit}
}
