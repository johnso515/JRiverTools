using module 'C:\Users\johns\Projects\JRiverTools\Release\0.2.0\JRiverTools.psm1'

using module 'C:\Users\johns\Projects\CommonTextTools\Release\0.1.4\CommonTextTools.psm1'

<# Debug #>
. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Set-MusicFoldersForRoot.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Build-PathFromParts.ps1'

. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Test-RemotePath.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Add-RemotePath.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Set-RemotePath.ps1'

<# Display and debug vars #>
[string]$private:spaceTwo = $(' '*2)
[string]$private:spacer = $(' '*4)

$VerbosePreference = 'SilentlyContinue'  # $oldVerbose

[bool]$private:ShowVerbose = $true
[bool]$private:ShowDebug = $false
[bool]$private:ShowWhatIf = $false

#                         # -FoldersToCreate @{'Music'    = @('Amazon MP3')} `
<#
                        -FoldersToCreate @{'Music'    = @('Amazon MP3')} `
#>
Set-MusicFoldersForRoot -TargetServer HTPC -TargetDriveLetter 'J' `
                        -TargetBasePath 'Media5' `
                        -Verbose:$ShowVerbose -WhatIf:$ShowWhatIf -Debug:$ShowDebug