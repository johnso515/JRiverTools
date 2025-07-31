

<# Runner script to copy files for CA Trip #>
using module 'C:\Users\johns\Projects\CommonTools\Release\0.1.0\CommonTools.psm1'
# Debug
. 'C:\Users\johns\Projects\JRiverTools\Source\Classes\ItemLocation.ps1'
<# Note that this enum should be moved out into the tools project #>
. 'C:\Users\johns\Projects\JRiverTools\Source\Enums\CopyLocationType.ps1'


. 'C:\Users\johns\Projects\JRiverTools\Source\Enums\MusicSources.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Enums\MusicEncodings.ps1'

. 'C:\Users\johns\Projects\JRiverTools\Source\Classes\MusicAlbum.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Classes\AlbumTrack.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Classes\AlbumCopyRequest.ps1'

. 'C:\Users\johns\Projects\JRiverTools\Source\Classes\AlbumCopyRequest.ps1'


. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Get-AlbumDtlForArtistList.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Get-LocationDtlForPassthrough.ps1'

. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Get-LocalAblumDtlFromArtistPath.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Get-MetaDataFromSourceFolder.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Get-MusicPathsFromHTPCForMusicSource.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Get-RemoteAblumDtlFromArtistPath.ps1'


<# Copy Working script #>
. 'C:\Users\johns\Projects\JRiverTools\Scripts\Copy-RemotePlayListFilesToLocal.ps1'
. 'C:\Users\johns\Projects\JRiverTools\Source\Public\Get-RemoteTrackDetailsForAlbum.ps1'

. 'C:\Users\johns\Projects\VAASystemUtils\VAASystemUtils\Source\Public\Build-PathFromArray.ps1'

. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Get-EscapedPathString.ps1'





Import-Module VistaAlAguaSecurityDetails -Force
Import-Module PowerShellHumanizer



$QualifiedMasterPlayList = 'Y:\Passthrough\Nov CA Trip.m3u'
<# Debug and Display.  Set to 10000johnso5150 to pull all available #>
$SampleRows = 100000

try {


    # -----------------------------------------
    $startDateTime = Get-Date
    Write-Host ""
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host "    Starting the the process to copy $($QualifiedMasterPlayList) from HTPC"
    Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss'))"
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host ""

    <#
        To Do: Test this.

        Example 6: Resolve a path containing brackets

        This example uses the LiteralPath parameter to resolve the path of the Test[xml] subfolder. Using LiteralPath causes the brackets to be treated as normal characters rather than a regular expression.
        PowerShell

        PS C:\> Resolve-Path -LiteralPath 'test[xml]'

    #>

    if (Test-Path $QualifiedMasterPlayList) {
        Write-Host "$($spacer*1)$($spaceTwo*2) Copying files from $QualifiedMasterPlayList"
        Write-Host "$($spacer*1)$('-'*30)"

        Copy-RemotePlayListFilesToLocal -QualifiedPlaylist $QualifiedMasterPlayList -TargetPath 'C:\Users\johns\Music' -SampleRows 500 
        <# To Do 
                True up target path 
                e.g. Remove anything in target that isnt in the Playlist file
        #>
    }


    $timeStr = Get-FormattedTimeString -startTimestamp $startDateTime 
    $endDateTime = Get-Date
    Write-Host ""
    Write-Host ""
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host "    Completed copying Music from HTPC."
    Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss')) Finished: $($endDateTime.ToString('MM/dd/yy HH:mm:ss')) Elapsed: $timeStr "
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host ""
    Write-Host ""

}
finally {
    [System.GC]::Collect()
}

