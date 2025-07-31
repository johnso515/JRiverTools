# ============================================================================================
# <Start> Get-EscapedPathString
# ============================================================================================
<#
     Enter a comment or description
#>

function Get-EscapedPathString {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        [Parameter(mandatory=$true, ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the Path to escape.'
        )]
        [string] $SourcePath
        
    )
    
    begin {
        <# Passed preference variables from caller #>
        [bool]$private:ShowVerbose = $false
        [bool]$private:ShowDebug = $false
        [bool]$private:ShowWhatIf = $false
         
        <# Capture the passed -Verbose setting #>
        if ($PSBoundParameters.ContainsKey('Verbose')) {
            [bool]$ShowVerbose = $($PSBoundParameters['Verbose'])
        }
        <# Capture the passed -Debug setting #>
        if ($PSBoundParameters.ContainsKey('Debug')) {
            [bool]$ShowDebug = $($PSBoundParameters['Debug'])
        }
        <# Capture the passed -WhatIf setting #>
        if ($PSBoundParameters.ContainsKey('WhatIf')) {
            [bool]$ShowWhatIf = $($PSBoundParameters['WhatIf'])
        }
         
        [string]$private:EscapedPath = $null
    }
    
    process {

        # K:\Media4\Music\Flac\Various Artists\Richard Blade's Flashback Favorites, Vol. 1\10 Time Zone - World Destruction [Extended 12'' Mix].flac
        
        if ($SourcePath.Contains('[')) {
            $EscapedPath = $SourcePath.Replace('[','`[').Replace(']','`]')
        }
        else {
            $EscapedPath = $SourcePath
        }

        $EscapedPath = $EscapedPath.Replace("''","`'`'")

        if ($SourcePath.Contains("'")) {
            $EscapedPath = $EscapedPath.Replace("'","`'")
        }

        if ($SourcePath.Contains('.')) {
            $EscapedPath = $EscapedPath.Replace('.','`.')
        }

        if ($SourcePath.Contains(',')) {
            $EscapedPath = $EscapedPath.Replace(',','`,')
        }
        # '
        $EscapedPath = $EscapedPath.Replace("'","`'")

        Write-Output $EscapedPath
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Get-EscapedPathString
# ============================================================================================