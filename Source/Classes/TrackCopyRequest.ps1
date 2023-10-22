class TrackCopyRequest : ItemCopyRequest {
    <# ItemCopyRequest
        [datetime] $RequestCreated
        [System.IO.FileSystemInfo] $TargetPath
        [System.IO.FileSystemInfo] $SourcePath
        [string] $ItemName
    #>
    [AlbumTrack] $Track
    [bool] $Overwrite
}