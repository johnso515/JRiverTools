# Compare paths across local and remote hosts

using module 'C:\Users\johns\Projects\JRiverTools\Release\0.2.0\JRiverTools.psm1'
using module 'C:\Users\johns\Projects\CommonTextTools\Release\0.1.4\CommonTextTools.psm1'

<# Debug #>
. 'C:\Users\johns\Projects\VAASystemUtils\VAASystemUtils\Source\Public\Compare-PathsAcrossHosts.ps1'
. 'C:\Users\johns\Projects\VAASystemUtils\VAASystemUtils\Source\Public\Build-PathFromParts.ps1'

. 'C:\Users\johns\Projects\VAASystemUtils\VAASystemUtils\Source\Private\Test-RemotePath.ps1'


<# Display and debug vars #>
[string]$private:spaceTwo = $(' '*2)
[string]$private:spacer = $(' '*4)

$VerbosePreference = 'SilentlyContinue'  # $oldVerbose

<# Working variables #>
[bool]$private:ShowVerbose = $true
[bool]$private:ShowDebug = $false
[bool]$private:ShowWhatIf = $false

<# Run the job #>
$LocalPathToCheck = '\\Syn414JNas\Media3\Music\Flac'
$RemotePathToCheck = 'J:\Media3\Music\Flac'
Compare-PathsAcrossHosts -RemoteComputer HTPC -LocalPath $LocalPathToCheck `
                        -RemotePath $RemotePathToCheck `
                        -Verbose:$ShowVerbose -WhatIf:$ShowWhatIf -Debug:$ShowDebug



<# Done #>
[System.GC]::Collect()
return