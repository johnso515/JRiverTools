# ============================================================================================
# <Start> Build-PathFromParts
# ============================================================================================
<#
     Enter a comment or description
#>

function Build-PathFromParts {
    [CmdletBinding(
        PositionalBinding,
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the array of tokens to use to create the path string.'
        )]
        [array] $PathParts
        
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

        <# Output vars #>
        [string]$private:ConstructedPath = $null
         
    }
    
    process {
        try {
            $ConstructedPath = ''
            0..($($PathParts.Count) - 1) | ForEach-Object {
                Write-Verbose "$($spacer*2)$($spaceTwo) Adding <$_> $($PathParts[$_])"
                $ConstructedPath += $($PathParts[$_])
                if ($_ -le ($($PathParts.Count) - 2)) {
                    $ConstructedPath += $([IO.Path]::DirectorySeparatorChar)
                }
            }
            Write-Verbose "$($spacer*2)$($spaceTwo) Source Path <$ConstructedPath>"

            Write-Output $ConstructedPath

        }
        catch {
            Write-Host ' Hit some error!'
            $ScriptName = $PSItem.InvocationInfo.ScriptName
            $Line = $PSItem.InvocationInfo.Line 
            $ScriptLineNumber = $PSItem.InvocationInfo.ScriptLineNumber
            Write-Host "Error...Name: $ScriptName Line: $Line Script Line Nbr: $ScriptLineNumber"
            $err = $_.Exception
            $err | Select-Object -Property *
            "Response: $err.Response"
            $err.Response
        }
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Build-PathFromParts
# ============================================================================================