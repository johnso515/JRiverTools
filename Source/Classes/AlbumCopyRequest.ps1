# AlbumCopyRequest.ps1
class AlbumCopyRequest : ItemCopyRequest {
    <# ItemCopyRequest
        [datetime] $RequestCreated
        [System.IO.FileSystemInfo] $TargetPath
        [System.IO.FileSystemInfo] $SourcePath
        [string] $ItemName
    #>
    [CopyLocationType] $SourceLocType
    [CopyLocationType] $TargetLocType
    [MusicAlbum] $Album
    [bool] $Overwrite
}