# ============================================================================================
# <Start> Get-LocationDtlForPassthrough
# ============================================================================================
<#
     Get the Location Object (Class Instance) for the Local Passthrough folder
#>

function Get-LocationDtlForPassthrough {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory=$false
        , ValueFromPipelineByPropertyName
        , HelpMessage = "Specify the passthrough sub-path to search. This defaults to Music."
                    )]
        [string[]] $SubPath = 'Music'
        
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

        [string]$private:NASUNCPath = '\\syn414jnas\Backup'
        [string]$private:TransferRoot = 'Passthrough'

        <# Working varibales #>
        $private:DriveObject = $null

        <# Return object #>
        $private:LocationToSearch = $null
        $private:Drive = $null
        $private:Path = $null

        <# Display and debug #>
        $private:spacer = $(" "*4)
        $private:spaceTwo = $(" "*2)
         
    }
    
    process {
        try {

            <# Find the Drive for the Passthrough path #>
            $DriveObject = Get-CimInstance -Class Win32_LogicalDisk | Where-Object { $_.ProviderName -eq $NASUNCPath }
            <#
                DeviceID     : Y:
                DriveType    : 4
                ProviderName : \\syn414jnas\Backup
                FreeSpace    : 4615502127104
                Size         : 8336697995264
                VolumeName   : Backup
            #>
            
            # $LocationToSearch = [ItemLocation]::New()
            # $DriveObject.GetType()  --> CimInstance
            if (-not $null -eq $DriveObject ) {

                $Drive = $DriveObject.DeviceID

                $PassthroughPathToTest = $NASUNCPath + $([IO.Path]::DirectorySeparatorChar) + $TransferRoot + $([IO.Path]::DirectorySeparatorChar) + $SubPath
                
                Write-Verbose "$($spacer*2) Checking path for $PassthroughPathToTest "

                $PathToSearch = Resolve-Path $PassthroughPathToTest 
                # $PathToSearch.ProviderPath
                
                if (-not $null -eq $PathToSearch ) {
                    $Path = (Get-Item $PathToSearch.ProviderPath)
                    Write-Verbose "$($spacer*2) Found $($PathToSearch.ProviderPath) path for $($Path.GetType()) "
                    
                }
                else {
                    Write-Verbose "$($spacer*2) Cound not resolve the path for $PassthroughPathToTest"
                }

            }
            
            $LocationToSearch = [PSCustomObject]@{
                Drive = $Drive
                Path = $Path
            }

            Write-Output $LocationToSearch
            
        
        }
        catch {
            Write-Host " Hit some error!"
            $ScriptName = $PSItem.InvocationInfo.ScriptName
            $Line  = $PSItem.InvocationInfo.Line 
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
# <End> Get-LocationDtlForPassthrough
# ============================================================================================