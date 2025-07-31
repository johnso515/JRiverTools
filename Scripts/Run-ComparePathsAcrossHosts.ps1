# Compare paths across local and remote hosts

using module 'C:\Users\johns\Projects\JRiverTools\Release\0.2.0\JRiverTools.psm1'
using module 'C:\Users\johns\Projects\CommonTextTools\Release\0.1.4\CommonTextTools.psm1'

<# Debug #>
. 'C:\Users\johns\Projects\VAASystemUtils\VAASystemUtils\Source\Public\Compare-SrcHostPathToTrgHost.ps1'
. 'C:\Users\johns\Projects\VAASystemUtils\VAASystemUtils\Source\Public\Build-PathFromArray.ps1'

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
# \\Syn414jNas\Media\Pictures 
$LocalPathToCheck = '\\Syn414jNas\Backup\Debbie-Main\DebbieDDocs\WSHS82\Photos\Reunion Photos'
$RemotePathToCheck = 'J:\Media3\Music\Flac'
Compare-SrcHostPathToTrgHost -RemoteComputer HTPC -LocalPath $LocalPathToCheck `
                        -RemotePath $RemotePathToCheck `
                        -Verbose:$ShowVerbose -WhatIf:$ShowWhatIf -Debug:$ShowDebug



<# Done #>
[System.GC]::Collect()
return