class MusicAlbum {
    <# Define the class. Try constructors, properties, or methods. #>

    [string]$ArtistName
    [string]$AlbumName
    [string] $Genre
    # [string]$Drive
    # [string]$TargetAlbumPath
    # [string]$SourceAlbumPath
    [ItemLocation] $Location = $null
    [MusicEncodings]$Encoding = 'flac'
    [MusicSources]$PurchaseSource = 'cd'
    [int64]$AlbumSizeBytes = 0

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

