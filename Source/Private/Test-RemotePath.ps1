# ============================================================================================
# <Start> Test-RemotePath
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


function Test-RemotePath {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the path to check on the passed remote session.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $TargetPathToCheck,

        [Parameter(Mandatory=$true
                    , ValueFromPipelineByPropertyName=$true
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
        [string]$private:PatchedPath = $null
        
        [bool]$private:targetPathExists = $false
    }
    
    process {
        try {
            

            <# Check for spaces in the path #>
            <#
            if ($TargetPathToCheck.Contains(' ') ) {
                $PatchedPath = '"'
                $PatchedPath += $TargetPathToCheck
                $PatchedPath += '"'
                $TargetPathToCheck = $PatchedPath
            }
            #>
            Write-Verbose "$($spacer*$DisplayOffset) Checking for $TargetPathToCheck"

            # Write-Host "$spacer Debug: Testing $baseDriveTargetPath"
            $targetPathExists = Invoke-Command -Session $session `
                    -ScriptBlock { ($true -eq (Test-Path $using:TargetPathToCheck) ) }

            if ($targetPathExists) {
                Write-Verbose "$($spacer*$DisplayOffset) $TargetPathToCheck exists..."
            }
            else {
                Write-Verbose "$($spacer*$DisplayOffset) $TargetPathToCheck does not exist..."
            }
                    
            Write-Output $targetPathExists
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
# <End> Test-RemotePath
# ============================================================================================