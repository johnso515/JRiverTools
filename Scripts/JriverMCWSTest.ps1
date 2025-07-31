
<#

Find the Ips for the server
    http://webplay.jriver.com/libraryserver/lookup?id=ekebOo

ekebOo 
    98.97.176.43 52199 
    192.168.4.73
    ,100.105.28.97 52200 adf6a8c810ee3a508ce41d183a4ff517cb5a453b 18-c0-4d-88-c6-30
    ,84-1b-77-29-dc-da,00-ff-dd-57-07-0b
    ,,,84-1b-77-29-dc-d6,84-1b-77-29-dc-d7
    ,86-1b-77-29-dc-d6

    http://192.168.4.73:52199/MCWS/v1/Alive
        {569F8AB8-01A8-4118-B409-D48120955AA5} 24 JRiver Media Center 31.0.84 Htpc ekebOo 31 Windows Windows

    http://100.105.28.97:52200/MCWS/v1/Alive
    No response
#>
<#

http://100.105.28.97/MCWS/v1/doc 


$EventDtlResponse = Invoke-RestMethod -Uri $fullUriAggregate `
                                            -Method Post -Headers $header -Body $bodyAggregate 
#>

$ServerIP = '100.105.28.97'
$ServerPort = '52199'
$ServerAddress = $ServerIP + ':' + $ServerPort

$ServerAliveSuffix = '/MCWS/v1/Alive'
$Uri = 'http://' + $ServerAddress + $ServerAliveSuffix

$EventDtlResponse = Invoke-RestMethod -Uri $Uri -Method Post
# $EventDtlResponse.Response

# http://localhost:52199/MCWS/v1/Authenticate
# Call the web service function: MCWS/v1/Authenticate 
# -Headers $header
$EventDtlResponse = $null
[System.Collections.IDictionary]$header = @{}
# $uid = "Riley"

$jriverServerUserName = Get-SecretForPassedName -SecretToFetch 'JR_HTPC_USERID' -FetchPlainText $true
$jriverServerPswd = Get-SecretForPassedName -SecretToFetch 'JR_HTPC_PSWRD' -FetchPlainText $false

$baseAuthString = $jriverServerUserName + ':' + $jriverServerPswd
$encodedAuthString = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($baseAuthString))
# Authorization: Basic 
$fullAuthString = 'Basic ' + $encodedAuthString
$header.Add('Authorization', $fullAuthString)
# -Authentication Basic
# -Credential $PSCredential
# $Secure_String_Pwd = ConvertTo-SecureString $pswd -AsPlainText -Force
$htpcJRiverCreds = New-Object System.Management.Automation.PSCredential ($jriverServerUserName, $jriverServerPswd)

$ServerAuthenticateSuffix = '/MCWS/v1/Authenticate'
$Uri = 'http://' + $ServerAddress + $ServerAuthenticateSuffix

# $Uri = 'http://192.168.4.73:52199/MCWS/v1/Authenticate'
# Invoke-RestMethod -Uri $Uri  -Method Get -Headers $header

# $EventDtlResponse = Invoke-RestMethod -Uri $Uri  -Method Get -Headers $header

# $EventDtlResponse = Invoke-WebRequest -Uri $Uri -Headers $header

$EventDtlResponse = Invoke-WebRequest -Uri $Uri -Authentication Basic -Credential $htpcJRiverCreds -AllowUnencryptedAuthentication

if ($EventDtlResponse.StatusCode -eq 200) {
    $Xml = $EventDtlResponse.Content

    $ItemCount = 0
    # 

    <#
        <?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
        <Response Status="OK">
            <Item Name="Token">2Kb7FzP5</Item>
            <Item Name="ReadOnly">0</Item>
            <Item Name="PreLicensed">0</Item>
        </Response>
    
    #>


    [xml]$Doc = $($EventDtlResponse.Content)

    $Token = $Doc.Response.Item | Where-Object { $_.Name -eq 'Token' } | Select-Object -Property '#text' -ExpandProperty '#text'
    Write-Host "  This is the login Token: $Token"
    # $Doc.ChildNodes('Response').ChildNodes('Item')
}
else {
    Write-Host '  Bad Response...'
    $EventDtlResponse
}



<#
-Headers $header
+ "&Token=" + $Token
http://localhost:52199/MCWS/v1/Playback/Info?Zone=-1

#>

<# Get the Zones Info 
    http://localhost:52199/MCWS/v1/Playback/Zones
#>
$EventDtlResponse = $null

$ServerGetZonesSuffix = '/MCWS/v1/Playback/Zones'
$Uri = 'http://' + $ServerAddress + $ServerGetZonesSuffix


# $Uri = 'http://192.168.4.73:52199/MCWS/v1/Playback/Zones'
# Write-Host "  This is the URI: $Uri"
$EventDtlResponse = $null
$EventDtlResponse = Invoke-WebRequest -Uri $Uri -Authentication Basic -Credential $htpcJRiverCreds -AllowUnencryptedAuthentication

if ($EventDtlResponse.StatusCode -eq 200) {

    [xml]$Doc = $($EventDtlResponse.Content)

    $NumberOfZones = $Doc.Response.Item | Where-Object { $_.Name -eq 'NumberZones' } | Select-Object -Property '#text' -ExpandProperty '#text'

    $CurrentZoneIndex = $Doc.Response.Item | Where-Object { $_.Name -eq 'CurrentZoneIndex' } | Select-Object -Property '#text' -ExpandProperty '#text'
    
    $ZoneNameToken = 'ZoneName' + $($CurrentZoneIndex.ToString())

    $CurrentZoneName = $Doc.Response.Item | Where-Object { $_.Name -eq $ZoneNameToken } | Select-Object -Property '#text' -ExpandProperty '#text'


    $CurrentZoneId = $Doc.Response.Item | Where-Object { $_.Name -eq 'CurrentZoneID' } | Select-Object -Property '#text' -ExpandProperty '#text'
    Write-Host "  This is the Current Zone Id: $CurrentZoneId"

}
else {
    Write-Host '  Bad Response...'
    $EventDtlResponse
}

<#
    Zone: The zone the command is targetted for. (default: -1)
    ZoneType: The type of value provided in 'Zone' (ID: zone id; Index: zone index; Name: zone name). (default: ID)
    + '&ZoneType=ID'
#>


$EventDtlResponse = $null
# http://localhost:52199/MCWS/v1/Playback/Info?Zone=-1
$ServerGetInfoForZoneSuffix = '/MCWS/v1/Playback/Info'
$Uri = $null
$Uri = 'http://' + $ServerAddress + $ServerGetInfoForZoneSuffix


$Uri += '?Zone=' 
$Uri += $($CurrentZoneId.ToString())


# Write-Host "  This is the URI: $Uri"
$EventDtlResponse = $null
$EventDtlResponse = Invoke-WebRequest -Uri $Uri -Authentication Basic -Credential $htpcJRiverCreds -AllowUnencryptedAuthentication

if ($EventDtlResponse.StatusCode -eq 200) {
    Write-Host ''
    # Write-Host '  Valid Response...Zone Playback Info...'
    Write-Host ''
    # $EventDtlResponse.Content

    [xml]$Doc = $($EventDtlResponse.Content)

    $ImageSuffix = $Doc.Response.Item | Where-Object { $_.Name -eq 'ImageURL' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $Artist = $Doc.Response.Item | Where-Object { $_.Name -eq 'Artist' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $Album = $Doc.Response.Item | Where-Object { $_.Name -eq 'Album' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $TrackName = $Doc.Response.Item | Where-Object { $_.Name -eq 'Name' } | Select-Object -Property '#text' -ExpandProperty '#text'

    $CurFileKey = $Doc.Response.Item | Where-Object { $_.Name -eq 'FileKey' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $NextFileKey = $Doc.Response.Item | Where-Object { $_.Name -eq 'NextFileKey' } | Select-Object -Property '#text' -ExpandProperty '#text'
    

    $CurrentZoneName = $Doc.Response.Item | Where-Object { $_.Name -eq 'ZoneName' } | Select-Object -Property '#text' -ExpandProperty '#text'

    Write-Host "  Currently playing $TrackName by $Artist from $Album on Zone $CurrentZoneName"

}
else {
    Write-Host '  Bad Response...'
    $EventDtlResponse
}

<#
$ServerGetFileInfoSuffix = '/MCWS/v1/Files/GetInfo'
$Uri = 'http://' + $ServerAddress + $ServerGetFileInfoSuffix

$Uri += '?Action=JSON' 
$Uri += '&Keys'

$Uri += $($NextFileKey.ToString())

http://localhost:52199/MCWS/v1/Files/GetInfo?Action=mpl&ActiveFile=-1&Formatted=0&Zone=-1&ZoneType=ID
#>

$ServerGetFileInfoSuffix = '/MCWS/v1/Files/GetInfo'
$Uri = 'http://' + $ServerAddress + $ServerGetFileInfoSuffix

$Uri += '?Action=JSON' 

$Uri += '&Keys='
$Uri += $($NextFileKey.ToString())

$Uri += '&Fields='
$Uri += 'Name,Artist,Album,Genre'

# Write-Host "  This is the URI: $Uri"

$EventDtlResponse = $null

$EventDtlResponse = Invoke-WebRequest -Uri $Uri -Authentication Basic -Credential $htpcJRiverCreds -AllowUnencryptedAuthentication

if ($EventDtlResponse.StatusCode -eq 200) {
    # Write-Host ''
    # Write-Host '  Valid Response...File Info ....'
    # Write-Host ''
    # $EventDtlResponse.Content

    $NextAlbumDetails = $($EventDtlResponse.Content) | ConvertFrom-Json

    $NextAlbum = $NextAlbumDetails[0].Album
    $NextArtist = $NextAlbumDetails[0].Artist
    $NextTrackName = $NextAlbumDetails[0].Name
    $NextGenre = $NextAlbumDetails[0].Genre

    Write-Host "  Playing Next $NextTrackName by $NextArtist from $NextAlbum ($NextGenre) on Zone $CurrentZoneName"
    Write-Host ''
    Write-Host ''
    <#
    [xml]$Doc = $($EventDtlResponse.Content)

    $Doc.Response.Item | Where-Object { $_.Name -eq 'ImageURL' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $Artist = $Doc.Response.Item | Where-Object { $_.Name -eq 'Artist' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $Album = $Doc.Response.Item | Where-Object { $_.Name -eq 'Album' } | Select-Object -Property '#text' -ExpandProperty '#text'
    $TrackName = $Doc.Response.Item | Where-Object { $_.Name -eq 'Name' } | Select-Object -Property '#text' -ExpandProperty '#text'

    $NextFileKey = $Doc.Response.Item | Where-Object { $_.Name -eq 'NextFileKey' } | Select-Object -Property '#text' -ExpandProperty '#text'
    
    $CurrentZoneName = $Doc.Response.Item | Where-Object { $_.Name -eq 'ZoneName' } | Select-Object -Property '#text' -ExpandProperty '#text'

    Write-Host "  Next playing $TrackName by $Artist from $Album on Zone $CurrentZoneName"
    #>
}
else {
    Write-Host '  Bad Response...'
    $EventDtlResponse
}  
<#
    More Actions
    
    Name Artist Album Genre
      GetInfo
         Get information or play a list of files.
         Parameters:
            Keys: A comma seperated list of file keys (default: )
            Action: The action to perform with the files (MPL: return MPL playlist; JSON: Return files as JSON array; Play: plays files; Save: saves the files (as a playlist in the library, etc.); Serialize: return serialized file array (basically a list of file keys); M3U: saves the list as an m3u). (default: mpl)
            Shuffle: Set to 1 to shuffle the files. (default: )
            ActiveFile: A file key to set as active (used as the file that playback starts with, etc.). (default: -1)
            ActiveFileOnly: Set to 1 to trim the returned files to only contain the active file. (default: )
            PlayMode: Play mode flags delimited by commas (Add: adds to end of playlist; NextToPlay: adds files in the next to play position). (default: )
            Fields: The fields to include in an MPL (use empty to include all fields) (set to Calculated to include calculated fields). (default: )
            NoLocalFilenames: Set to 1 to filter out local filenames from MPL output (since they might be meaningless to a server). (default: )
            PlayDoctor: Set to 1 to change the files to a Play Doctor generated playlist using these files as a seed. (default: )
            SaveMode: Playlist: playlist (overwrites existing; returns ID) (default: )
            SaveName: A backslash delimited path used with the action 'Save'. (default: )
            NoUI: Set to one to put the player in no UI mode. (default: )
            Formatted: Set to 1 if you want a formatted value (like a formatted date). (default: 0)
            Zone: The zone the command is targetted for. (default: -1)
            ZoneType: The type of value provided in 'Zone' (ID: zone id; Index: zone index; Name: zone name). (default: ID)
         Response:

    http://localhost:52199/MCWS/v1/Files/GetInfo?Action=mpl&ActiveFile=-1&Formatted=0&Zone=-1&ZoneType=ID

    GetImage
        Get an image for a file in the database.
        Parameters:
        File: The key of the file. (default: -1)
        FileType: The type of value provided in 'File' (Key: file key; Filename: filename of file). (default: Key)
        Type: The type of image to get: Thumbnail (default), Full, ThumbnailsBinary (default: Thumbnail)
        ThumbnailSize: The size of the thumbnail (if type is thumbnail): Small, Medium, Large (default) (default: )
        Rebuild: Whether the thumbnail should be rebuilt (default: )
        Width: The width for the returned image. (default: )
        Height: The height for the returned image. (default: )
        FillTransparency: A color to fill image transparency with (hex number). (default: )
        Square: Set to 1 to crop the image to a square aspect ratio. (default: )
        Pad: Set to 1 to pad around the image with transparency to fullfill the requested size. (default: )
        Format: The preferred image format (jpg or png). (default: jpg)
        Response:
        Examples:
            http://localhost:52199/MCWS/v1/File/GetImage?File=-1&FileType=Key&Type=Thumbnail&Format=jpg

#>

<#
http://localhost:52199/MCWS/v1/Authenticate
Status
------
OK
#>