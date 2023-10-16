
class AlbumTrack {
    <# Define the class. Try constructors, properties, or methods. #>
}

class Location {
    <# Define the class. Try constructors, properties, or methods. #>
    [string]$Drive
    [string]$Path
}

# Debug

. 'C:\Users\johns\Projects\JRiverTools\enums\MusicSources.ps1'
. 'C:\Users\johns\Projects\JRiverTools\enums\MusicEncodings.ps1'

class MusicAlbum {
    <# Define the class. Try constructors, properties, or methods. #>

    [string]$ArtistName
    [string]$AlbumName
    # [string]$Drive
    # [string]$TargetAlbumPath
    # [string]$SourceAlbumPath
    [Location] $Location = $null
    [MusicEncodings]$Encoding = 'flac'
    [MusicSources]$PurchaseSource = 'cd'
    [int64]$FreeSpaceBytes = 0
    [int64]$UsedSpaceBytes = 0
    [bool]$TargetFileFound = $false
    [hashtable]$AlbumTracks = [ordered]@{}
    [int]$TracksFound = $this.AlbumTrackHashes.Count

    [void] MethodName($OptionalParameters) {
        <# Action to perform. You can use $ to reference the current instance of this class #>
    }

    MusicAlbum() {
        $this.ArtistName = 'Tbd'
        $this.AlbumName = 'Tbd'
    }

    MusicAlbum($Album, $Artist) {
        $this.ArtistName = $Album
        $this.AlbumName = $Artist
    }

}

