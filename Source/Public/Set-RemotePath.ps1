# ============================================================================================
# <Start> Set-RemotePath
# ============================================================================================
<#
     Enter a comment or description
#>
<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


function Set-RemotePath {
    [CmdletBinding(
        PositionalBinding,
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the base path of the path to create. It is assumed that this path aleady exists.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $TargetBasePath,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the leaf of the path to create. It is assumed that the base path aleady exists.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $TargetLeafPath,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true
            , HelpMessage = 'Specify the session object for the remote server to check.'
        )]
        [ValidateNotNullOrEmpty()]
        $session,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true
            , HelpMessage = 'Specify the offset level for verbose and debug messages.'
        )]
        [int]$DisplayOffset = 1
        
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

        if ($DisplayOffset -lt 1 -or $DisplayOffset -gt 5) {
            $DisplayOffset = 1
        }
         
        <# Display and debug vars #>
        [string]$private:spaceTwo = $(' ' * 2)
        [string]$private:spacer = $(' ' * 4)

        <# Working variables #>
        [bool]$private:targetPathExists = $false
        [string]$private:TargetPath = $null

    }
    
    process {
        try {

            Write-Verbose "$($spacer*$DisplayOffset)$($spaceTwo*1) Checking for $TargetBasePath, $TargetLeafPath"

            $TargetPath = Build-PathFromParts -PathParts @($TargetBasePath, $TargetLeafPath) -Verbose:$false

            Write-Verbose "$($spacer*$DisplayOffset) Checking for $TargetPath"

            # Write-Host "$spacer Debug: Testing $baseDriveTargetPath"
            $targetPathExists = Test-RemotePath -TargetPathToCheck $TargetPath `
                -DisplayOffset $($DisplayOffset+1) `
                -session $session -Verbose:$showVerbose

                
            if (-not $targetPathExists) {
                <# Here we would create the base path #>
                Write-Verbose "$($spacer*$DisplayOffset) $TargetPath does not exist. Creating now."

                $TargetPath = Add-RemotePath -TargetBasePath $TargetBasePath `
                    -TargetLeafPath $TargetLeafPath `
                    -DisplayOffset $($DisplayOffset+1) `
                    -session $session -Verbose:$showVerbose -WhatIf:$ShowWhatIf
                    
            }
            Write-Verbose "$($spacer*$DisplayOffset) Returning $TargetPath."
            Write-Output $TargetPath

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
# <End> Set-RemotePath
# ============================================================================================