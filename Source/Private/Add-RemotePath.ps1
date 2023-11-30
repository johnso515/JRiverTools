# ============================================================================================
# <Start> Add-RemotePath
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


function Add-RemotePath {
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

        [string]$private:MsgString = $null

        <# Working variables #>
        [string]$private:baseDrivePath = $null

        [string]$private:PatchedLeafPath = $null
        [string]$private:TargetPath = $null
        [string]$private:RawTargetPath = $null
        [string]$private:RawTargetLeafPath = $null

    }
    
    process {
        try {

            
            
            $RawTargetLeafPath = $TargetLeafPath
            $RawTargetPath = Build-PathFromParts -PathParts @($TargetBasePath, $TargetLeafPath) -Verbose:$false

            <# Check for spaces in the path #>
            if ($TargetLeafPath.Contains(' ') ) {
                $PatchedLeafPath = "'"
                $PatchedLeafPath += $TargetLeafPath
                $PatchedLeafPath += "'"
                $TargetLeafPath = $PatchedLeafPath
            }

            <# Check for spaces in the path #>
            if ($RawTargetPath.Contains(' ') ) {
                $PatchedLeafPath = "'"
                $PatchedLeafPath += $RawTargetPath
                $PatchedLeafPath += "'"
                $TargetPath = $PatchedLeafPath
            }
            else {
                <# Action when all if and elseif conditions are false #>
                $TargetPath = $RawTargetPath
            }

            $MsgString = 'Creating <' + $TargetLeafPath + "> in $TargetBasePath" + '<' + $TargetPath + '>' + '<' + $RawTargetPath + '>'
            Write-Verbose "$($spacer*$DisplayOffset)$($spaceTwo*1) $MsgString"

            $baseDrivePath = Invoke-Command -Session $session `
                -ScriptBlock { Param ($FullPath, $Root, $Child, $WhatIfFlag) 
                ## $PSCmdlet.ShouldProcess('TARGET','OPERATION')
                # if ($PSCmdlet.ShouldProcess($Child,"Creating path on $Root ")){
                Push-Location $BaseProjectPath -StackName AddPathStack
                Set-Location $Root

                New-Item -Path . -Name $Child -ItemType Directory -Force -WhatIf:$WhatIfFlag
                # New-Item -Path $FullPath -ItemType Directory -Force 

                <# Return to invoke location #>
                Pop-Location -StackName AddPathStack

                if (-not $WhatIfFlag ) {
                        (Join-Path $Root $Child)
                }
            } -ArgumentList $TargetPath, $TargetBasePath, $RawTargetLeafPath, $ShowWhatIf 

            <# 
            if (-not $ShowWhatIf ) {
                $baseDrivePath = Invoke-Command -Session $session `
                    -ScriptBlock { 
                        if ($PSCmdlet.ShouldProcess($TargetLeafPath,"Building path string from  path on $TargetBasePath ")){
                            (Join-Path $using:TargetBasePath $using:TargetLeafPath) }
                        }
            }
            #>
            <# Return the unmodified path if valid#>
            if ($baseDrivePath.Length -gt 0) {
                Write-Output $RawTargetPath
            }
            else {
                Write-Output $null
            }
            
                    
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
# <End> Add-RemotePath
# ============================================================================================