

<#
    Build Playlists with Unique songs for each day specified
#>


<#
    Example

    path = 'M:\Musikk\awesome_song.mp3'
$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $path
$file = Split-Path $path -Leaf
$shellfolder = $shell.Namespace($folder)
$shellfile = $shellfolder.ParseName($file)

write-host $shellfolder.GetDetailsOf($shellfile, 27); 

#>
<#
    From https://www.powershellgallery.com/packages/FC_SysAdmin/5.0.0/Content/public%5CGet-FileMetaData.ps1
    and https://gist.githubusercontent.com/woehrl01/5f50cb311f3ec711f6c776b2cb09c34e/raw/c87fee680c47139ab840f001d820a6ace794ce14/Get-FileMetaData.psm1
#>

# ---------------
$OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding
# [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Set-Content:Encoding'] = 'UTF8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'UTF8'
$PSDefaultParameterValues['Get-Content:Encoding'] = 'UTF8'

# UTF8Encoding
$FileEncoding = 'Default'

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding =
New-Object System.Text.UTF8Encoding


. 'C:\Users\johns\Projects\JRiverTools\Source\Private\Get-HashFromStringStream.ps1'

#region HelperFunctions
# ============================================================================================
# <Start> Get-CandidateItemsForStep
# ============================================================================================
<#
     Enter a comment or description
#>

function Get-CandidateItemsForStep {
    [CmdletBinding(
        PositionalBinding,
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the number of items in the set.'
        )]
        [ValidateRange(0)]
        [int] $ItemCount, 

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]] $ItemList
        
    )
    
    begin {
        [System.Collections.ArrayList]$private:ItemsToChooseFrom = @()
    }
    
    process {
        if ($ItemCount -gt 1) {
            # $ItemsToChooseFrom = 
            $ItemsToChooseFrom = $ItemList | Sort-Object | Get-Random -Shuffle
        }
        elseif ($ItemCount -eq 1) {
            [void]$ItemsToChooseFrom.Add($ItemList)
        }
        else {
            $ItemsToChooseFrom = @()
        }

        Write-Output $ItemsToChooseFrom
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Get-CandidateItemsForStep
# ============================================================================================
#endregion
<#


Authors                        Question Mark; ? & The Mysterians
Rating                         4 Stars
Album artist                   ? & The Mysterians
Item type                      Media Center file
Attributes                     A
Album                          Best of ? & The Mysterians: Cameo Parkway 1966-1967, The
Part of set                    1
Title                          Midnight Hour
Year                           2005
Space free                     78.1 GB
Date modified                  10/26/2023 6:42 AM
Type                           Media Center file
#                              11
Date accessed                  10/26/2023 6:42 AM
Folder                         Best of _ & The Mysterians_ Cameo Parkway 1966-1967, The (D:\Music\_ … 
Owner                          Everyone
Composers                      Robert Balderrama
Name                           11 Question Mark - Midnight Hour.mp3
Folder path                    D:\Music\_ & The Mysterians\Best of _ & The Mysterians_ Cameo Parkway… 
Length                         00:02:38
Kind                           Music
Space used                     ‎67%
Contributing artists           Question Mark; ? & The Mysterians
Protected                      No
Path                           D:\Music\_ & The Mysterians\Best of _ & The Mysterians_ Cameo Parkway… 
Beats-per-minute               120
Bit rate                       ‎88kbps
Folder name                    Best of _ & The Mysterians_ Cameo Parkway 1966-1967, The
Computer                       JOHNS-SPECTRE (this PC)
Total size                     238 GB
Shared                         No
Genre                          Rock
HashVal                        4F0374060F8296704BCC254673011980
Filename                       11 Question Mark - Midnight Hour.mp3
Link status                    Unresolved
File extension                 .mp3
Perceived type                 Audio
Date created                   10/25/2023 11:16 PM
Size                           1.71 MB
#>
# C:\Users\johns\Music
# D:\Music
# \01 - Sisters Coming Home (2003 Remaster).flac
# C:\Users\johns\Music\HDtracks\Emmylou Harris
# Get-ChildItem -Path "" -Recurse -File

<# Display and debug vars #>
[string]$private:spaceTwo = $(' ' * 2)
[string]$private:spacer = $(' ' * 4)
[int]$private:TitlePadLen = 23
[int]$private:MetricPadLen = 9

[string]$private:outputSeparaterString = "`t"


<# Working Variables #>
#region WorkingVariables

[int]$private:TotalListMinutes = 0

[datetime]$private:CurrentDate = '2023-11-05'

[System.Collections.ArrayList]$local:ValidGenresToChooseFrom = @()

[System.Collections.ArrayList]$local:GenresToChooseFrom = @()
[System.Collections.ArrayList]$local:ArtistsToChooseFrom = @()
[System.Collections.ArrayList]$local:AlbumsToChooseFrom = @()
[System.Collections.ArrayList]$local:TitlesToChooseFrom = @()


[System.Collections.ArrayList]$local:GenresToSkip = @()

[System.Collections.ArrayList]$local:SkippedTracks = @()
[System.Collections.ArrayList]$local:HashBucketKeys = @()

<# Hash to value mappings #>
[hashtable]$private:HashToFullPath = @{}

[hashtable]$private:GenreToHash = @{}
[hashtable]$private:HashToGenre = @{}

[hashtable]$private:ArtistToHash = @{}
[hashtable]$private:HashToArtist = @{}

<# Unmapping hash tables #>

[hashtable]$private:HashToAlbum = @{}
[hashtable]$private:AlbumToHash = @{}

[hashtable]$private:HashToTitleTrack = @{}
[hashtable]$private:TitleTrackToHash = @{}


[hashtable]$private:HashGenreToArtist = @{}
[hashtable]$private:HashArtistToAlbum = @{}
[hashtable]$private:HashAlbumToTitle = @{}

<# Rolling Days for no-repeat #>
# $DaysToLookBackForNoRepeat = 0
[hashtable]$private:RollingIncludedTracks = @{}
<#
    Day -> TitleTrack
        -> Artist/Title  ( Note: Think on how to normalize title and title - live for example )
#>
<# Mapped set of hierarchical Itesm Genre->Artist->Album->Track #>
$MusicHash = @{}
<# Per Day PlayList Details#>
$OutPutHash = @{}

<# Input Filtering #>

[array]$private:ExtensionsToSkip = @('.jpg'
    , '.txt'
    , '.pdf'

)

<# Output File details #>

[string]$private:PlayListExt = 'm3u'
[string]$private:LogFileExt = 'tsv'

$StarRatingInclusionPtcs = @{
    '1' = 5      # 1 Star - 30% Included
    '2' = 25     # 2 Star - 40%
    '3' = 60     # 3 Star - 50%
    '4' = 70     # 4 Star - 60%
    '5' = 90     # 5 Star - 70%
    'X' = 10     # Unknown Star rating
}

$MusicInputCols = @('Rating'    # 4 Stars
    , 'Album artist'    # 4 ? & The Mysterians
    , 'Album'    # Best of ? & The Mysterians: Cameo Parkway 1966-1967, The
    , 'Title'    # Midnight Hour
    , 'Year'    # 2005
    , 'Date modified'    # 10/26/2023 6:42 AM
    , '#'    # 11
    , 'Folder'    # Best of _ & The Mysterians_ Cameo Parkway 1966-1967, The (D:\Music\_ … 
    , 'Name'    # 11 Question Mark - Midnight Hour.mp3
    , 'Folder path'    # D:\Music\_ & The Mysterians\Best of _ & The Mysterians_ Cameo Parkway… 
    , 'Length'    # 00:02:38
    , 'Path'    # D:\Music\_ & The Mysterians\Best of _ & The Mysterians_ Cameo Parkway… 
    , 'Folder name'    # Best of _ & The Mysterians_ Cameo Parkway 1966-1967, The
    , 'Computer'    # JOHNS-SPECTRE (this PC)
    , 'Genre'    # Rock
                        
    , 'Filename'    # 11 Question Mark - Midnight Hour.mp3
)
$MusicOutputCols = @('Rating'    # 4 Stars
    , 'Album artist'    # 4 ? & The Mysterians
    , 'Album'    # Best of ? & The Mysterians: Cameo Parkway 1966-1967, The
    , 'Title'    # Midnight Hour
    , 'Year'    # 2005
    , 'Date modified'    # 10/26/2023 6:42 AM
    , '#'    # 11
    , 'Folder'    # Best of _ & The Mysterians_ Cameo Parkway 1966-1967, The (D:\Music\_ … 
    , 'Name'    # 11 Question Mark - Midnight Hour.mp3
    , 'Folder path'    # D:\Music\_ & The Mysterians\Best of _ & The Mysterians_ Cameo Parkway… 
    , 'Length'    # 00:02:38
    , 'Path'    # D:\Music\_ & The Mysterians\Best of _ & The Mysterians_ Cameo Parkway… 
    , 'Folder name'    # Best of _ & The Mysterians_ Cameo Parkway 1966-1967, The
    , 'Computer'    # JOHNS-SPECTRE (this PC)
    , 'Genre'    # Rock
    , 'HashVal'    # 4F0374060F8296704BCC254673011980
    , 'Filename'    # 11 Question Mark - Midnight Hour.mp3
)
# Manually added
# HashVal' 

#endregion

$rx = [System.Text.RegularExpressions.Regex]::new('(\d{1}) Stars')

<# User Configuration #>
#region UserConfigurationSettings
$NumberOfPlayListsToBuild = 3

<# Debug and Display.  Set to 100000 to pull all available #>
$SampleRows = 100000

$PlayListHours = 14
$DaysToLookBackForNoRepeat = 2  # Can repeat every third day
$MaxSongLengthMinutes = 8

$LongSongsToInclude = @()

<# First date to create the playlist for #>
[datetime]$StartDate = '2023-11-05'

<# Where to look for music #>
$MusicSourcePath = 'D:\Music'


<# Block the genre altogether #>
$SkipTheseGenres = @('Soundtrack'
    , 'Sea Shanties'
    , 'Podcast'
    , 'Stage & Screen'
    # , 'Celtic'
    , 'Scottish Folk'
)

<# Limit the number of songs included for these genres #>
$GenreSongLimits = @{'Punk' = 10
    'New Wave'              = 50
    'Metal/Hard Rock'       = 50
    'Celtic'                = 10
    'Latin'                 = 10
}

<#
[string]$private:PlayListExt = "m3u"
[string]$private:LogFileExt = "tsv"

Nov2023-CA-Visit-Resources.tsv

Nov CA Trip.m3u
#>

<# Output details #>
# \TransferPlayLists
[string]$private:OutputPathSuffix = 'TransferPlayLists'
[string]$private:OutputFileSuffix = 'Nov2023-CA-Visit'
[string]$private:OutputPath = Resolve-Path "$env:USERPROFILE\*\$OutputPathSuffix" | Select-Object -ExpandProperty Path

[bool]$private:IsTest = $false

[bool]$private:ShowVerbose = $false
[bool]$private:ShowDebug = $false
[bool]$private:ShowWhatIf = $false

#endregion


#region CalculatedControlVariables
$TargetPlayListDuration = 60 * $PlayListHours

#endregion

$GenresToSkip = $SkipTheseGenres  | ForEach-Object { $($_.ToLower())}

<#
    [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference

    $DebugPreference 	SilentlyContinue

    $VerbosePreference 	SilentlyContinue
    $WarningPreference 	Continue
    $WhatIfPreference 	$False
#>

if ($ShowVerbose) {
    $VerbosePreference = Continue
}



$QualifiedMasterPlayList = 'Y:\Passthrough\JssSpectre\Nov CA Trip.m3u'


$startDateTime = Get-Date
Write-Host ''
Write-Host ' -------------------------------------------------------------------------------------'
Write-Host ' -------------------------------------------------------------------------------------'
Write-Host "$($spacer*1) Starting the to build $($NumberOfPlayListsToBuild.ToString()) unique playlists"
Write-Host "$($spacer*1) from the music found on $($env:COMPUTERNAME) from $MusicSourcePath."   
Write-Host "$($spacer*1) Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss'))"

Write-Host ' -------------------------------------------------------------------------------------'
Write-Host ''

$MasterPlayListSongs = Get-Content -Path $QualifiedMasterPlayList -Encoding UTF8

<#
    Calculate flat list of songs:
        TitleTrackHashKey -> Track details including hash keys for Genres etc
#>

try {
    
    $shellobj = New-Object -ComObject Shell.Application 

    $PctComplete = 0
    $RowsProcessed = 0
    $PriorProgressPctNbr = 0

    $OkToBuildMusic = $false
    $TotalListMinutes = 0
    
    $TotalCandidates = (Get-ChildItem -Path $MusicSourcePath -Recurse -File -Exclude *.txt,*.jpg,*.pdf | Measure-Object).Count
    
    # (Get-ChildItem -Path $MusicSourcePath -Recurse -File -Exclude *.txt,*.jpg,*.pdf | Measure-Object)

    if ($TotalCandidates -lt $SampleRows) {
        $SampleRows = $TotalCandidates
    }

    # $MasterPlayListSongs | Select-Object -First $SampleRows `

    $startBaseBuildDateTime = Get-Date
    Write-Host ''
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host "$($spacer*1) Starting the load of $($SampleRows.ToString('N0')) songs"
    Write-Host "$($spacer*1) from the music found on $($env:COMPUTERNAME) from $MusicSourcePath."   
    Write-Host "$($spacer*1) Started: $($startBaseBuildDateTime.ToString('MM/dd/yy HH:mm:ss'))"

    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host ''
    
    #region CalculateBaseMusicData

    <# Get the base data from the filesystem #>
    $TrackObjects = Get-ChildItem -Path $MusicSourcePath -Recurse -File -Exclude *.txt,*.jpg,*.pdf | Where-Object { $_.Length -gt 0 }

    <# Confirm that the type is correct #>

    $FirstSongItem = $TrackObjects | Select-Object -First 1
    
    <# Validate that the objects are of the correct type #>
    if ('System.IO.FileInfo' -eq $($FirstSongItem.GetType()) ) {
        $OkToBuildMusic = $true
        
    }
    else {
        <# No OP - do not have valid music to process #>
        $FirstSongItem.GetType()

    }

    if ($OkToBuildMusic) {

        :InitialTrackLoop foreach ($CurrentTrack in $TrackObjects) {

            $SkipRow = $false

            $Item = $CurrentTrack.FullName
            $tmp = $CurrentTrack
            <# 
                This has been pre-verified:

                if ($($CurrentTrack.GetType()) -eq 'System.IO.FileInfo') {
                    
                }
                else {

                    $Item = $CurrentTrack
                }
        
                if ('System.IO.FileInfo' -eq $($CurrentTrack.GetType()) ) {
                    $tmp = $CurrentTrack
                }
                else {
                    $tmp = Get-Item -LiteralPath $Item 
                }
            

            # Skip non-music extensions 
            if ($ExtensionsToSkip.Count -gt 0 -and $ExtensionsToSkip.Contains($tmp.Extension)) {
                continue InitialTrackLoop
            }
            #>

            Write-Verbose "<$($CurrentTrack.GetType())>"

            $pathname = $tmp.DirectoryName 
            $filename = $tmp.Name 
    
            <# Get the Hash value of the Path/Song #>
            # $SourceHashResults = Get-FileHash -LiteralPath $Item -Algorithm MD5                 
            # $SourceHashVal = $SourceHashResults.'Hash'
            $SourceHashVal = Get-HashFromStringStream -stringToHash $Item -hashAlgo MD5

            <# Build out the attributes for the track #>
            $hash = @{}

            $folderobj = $shellobj.namespace($pathname) 
            $fileobj = $folderobj.parsename($filename) 
        
            :AttributeLoop for ($i = 0; $i -le 294; $i++) { 
                $name = $folderobj.getDetailsOf($null, $i)
                if ($name) {

                    if (-not $MusicInputCols.Contains($name)) {
                        continue AttributeLoop
                    }

                    $value = $folderobj.getDetailsOf($fileobj, $i)
                    if ($value) {
                        $hash[$($name)] = $($value)
                    }
                }
            } 
            # Add the hash
            $hash['HashVal'] = $SourceHashVal

            <# Basic validation of the Song #>

            <# Calculate the time factors #>
            $TrackLenString = $hash['Length']    
            # 00:02:38
            # Size - estimate based on size;
            if ($TrackLenString.Length -gt 0) {
                ([Int16]$Hours, [Int16]$Minutes, [Int16]$Seconds) = $TrackLenString.Split(':')
            }
            else {
                <# Default to 3 minutes #>
                ([Int16]$Hours, [Int16]$Minutes, [Int16]$Seconds) = (0, 3, 0)
            }
        
                
            <# Calculate the progress towards a target list #>
            $SecondsFraction = $Seconds / 60
            $TotalMinutes = ($Hours * 60) + $Minutes + $SecondsFraction

            <#
                $MaxSongLengthMinutes = 8
                $LongSongsToInclude = @()
            #>
            if ($TotalMinutes -gt $MaxSongLengthMinutes `
                    -and ($LongSongsToInclude.Count -eq 0 -or -not $LongSongsToInclude.Contains($($hash['Title'])) ) ) {
                $SkipRow = $true
            }
            elseif ($TotalMinutes -eq 0 ) {
                $SkipRow = $true
                # Write-Host "$($spacer*1) $(($RowsProcessed+1).ToString().PadLeft(5))) $($hash['Name']) --> <$TrackLenString>"
                <# Show detaisl #>
                <#
                foreach ($name in $hash.Keys | Sort-Object) {
                    $value = $hash[$name]
                    Write-Host "$($spacer*2)$($spaceTwo) $($name.PadRight($TitlePadLen)) --> <$value>"
                }
                Write-Host ''
                #>
            }
            

            <# Check the Core Attributes #>
            if ($($hash['Genre']).Length -eq 0 `
                    -or $($hash['Album artist']).Length -eq 0 `
                    -or $($hash['Album']).Length -eq 0 `
                    -or $($hash['Title']).Length -eq 0) {
                $SkipRow = $true
            }

            <# Patch Genre if needed #>
            $RawGenre = $($hash['Genre'])

            if ($RawGenre.Contains(';')) {
                ($RawGenre, $remainder) = $RawGenre.Split(';')
                $hash['Genre'] = $RawGenre
            }

            <# Check the cleaned Genre against the list #>
            if ($RawGenre.Length -gt 0 -and $GenresToSkip.Count -gt 0 -and $GenresToSkip.Contains($($RawGenre.ToLower))) {
                $SkipRow = $true
            }

            <# Song is valid #>
            if (-not $SkipRow) {

                $TotalListMinutes += $TotalMinutes
                $RowsProcessed++

                <# Map the keys #>

                <# Full Track Path and Name #>
                # $SourceHashVal Is the ID hash (includes path/artist/album/track)

                if (-not $HashToFullPath.ContainsKey($SourceHashVal)) {
                    $HashToFullPath[$SourceHashVal] = $Item  # This is what is written out in the list
                }
                <# Genre #>
                #region SetGenreHash
                if ($($hash['Genre']).Length -gt 0) {

                    $Genre = $hash['Genre']

                    if ($GenreToHash.ContainsKey($Genre)) {
                        $GenreHash = $GenreToHash[$Genre]
                    }
                    else {
                        $GenreHash = Get-HashFromStringStream -stringToHash $Genre -hashAlgo MD5
                        $GenreToHash[$Genre] = $GenreHash
                        $HashToGenre[$GenreHash] = $Genre
                    }

                }
                else {
                    $GenreHash = $null
                }
                #endregion

                <# Artist #>
                #region SetArtistHash
                if ($($hash['Album artist']).Length -gt 0) {
                
                    $Artist = $hash['Album artist']
                    if ($ArtistToHash.ContainsKey($Artist)) {
                        $ArtistHash = $ArtistToHash[$Artist]
                    }
                    else {
                        $ArtistHash = Get-HashFromStringStream -stringToHash $Artist -hashAlgo MD5
                        $ArtistToHash[$Artist] = $ArtistHash
                        $HashToArtist[$ArtistHash] = $Artist
                    }

                }
                else {
                    $ArtistHash = $null
                }
                #endregion

                <# Album #>
                #region SetAlbumHash
                if ($($hash['Album']).Length -gt 0) {
                        
                    $Album = $hash['Album']

                    if ($AlbumToHash.ContainsKey($Album)) {
                        $AlbumHash = $AlbumToHash[$Album]
                    }
                    else {
                        $AlbumHash = Get-HashFromStringStream -stringToHash $Album -hashAlgo MD5
                        $AlbumToHash[$Album] = $AlbumHash
                        $HashToAlbum[$AlbumHash] = $Album
                    }

                }
                else {
                    $AlbumHash = $null
                }
                #endregion

                <# TitleTrack #>
                #region SetTitelTrackHash
                if ($($hash['Title']).Length -gt 0) {
                    $TitleTrack = $hash['Title']

                    if ($TitleTrackToHash.ContainsKey($TitleTrack)) {
                        $TitleTrackHash = $TitleTrackToHash[$TitleTrack]
                    }
                    else {
                        $TitleTrackHash = Get-HashFromStringStream -stringToHash $TitleTrack -hashAlgo MD5
                        $TitleTrackToHash[$TitleTrack] = $TitleTrackHash
                        $HashToTitleTrack[$TitleTrackHash] = $TitleTrack
                    }
                }
                else {
                    $TitleTrackHash = $null
                }
                #endregion

                <# Build the output hash #>

                if (-Not $MusicHash.ContainsKey($SourceHashVal)) {
                    $MusicHash[$SourceHashVal] = @{}
                    $MusicHash[$SourceHashVal]['TrackDetail'] = @{}
                    $MusicHash[$SourceHashVal]['TrackKeys'] = @{}
                }

                <# Add the track details#>
                foreach ($MusicAttribute in $MusicOutputCols) {
                    $MusicHash[$SourceHashVal]['TrackDetail'][$MusicAttribute] = $hash[$MusicAttribute]
                }
                $MusicHash[$SourceHashVal]['TrackDetail']['TotalMinutes'] = $TotalMinutes

                <# Parse and Save stars #>
                # 4 Stars
                $RawRating = $hash['Rating']
            
                $RatingStars = $rx.match($RawRating).Value[0]
                $MusicHash[$SourceHashVal]['TrackDetail']['RatingStars'] = $RatingStars

                Write-Debug "$($spacer*1) $($RowsProcessed.ToString().PadLeft(5))) $RawRating --> <$RatingStars>"

                <# Add the Keys#>
                $MusicHash[$SourceHashVal]['TrackKeys']['Genre'] = $GenreHash
                $MusicHash[$SourceHashVal]['TrackKeys']['Artist'] = $ArtistHash
                $MusicHash[$SourceHashVal]['TrackKeys']['Album'] = $AlbumHash
                $MusicHash[$SourceHashVal]['TrackKeys']['Title'] = $TitleTrackHash

            
                <# Update the counters #>
                #region UpdateTheTrackCounterByType
                <# Genre to Artist #>
                #region SetGenreToArtistMapping
                if (-Not $HashGenreToArtist.ContainsKey($GenreHash)) {
                    $HashGenreToArtist[$GenreHash] = @{}
                }
                if (-Not $($HashGenreToArtist[$GenreHash]).ContainsKey($ArtistHash)) {
                    $HashGenreToArtist[$GenreHash][$ArtistHash] = 0
                }
                $ArtistCount = $HashGenreToArtist[$GenreHash][$ArtistHash]
                $ArtistCount++
                $HashGenreToArtist[$GenreHash][$ArtistHash] = $ArtistCount
                #endregion

                <# Artist to Album #>
                #region SetArtistToAlbumMapping
                if (-Not $HashArtistToAlbum.ContainsKey($ArtistHash)) {
                    $HashArtistToAlbum[$ArtistHash] = @{}
                }
                if (-Not $($HashArtistToAlbum[$ArtistHash]).ContainsKey($AlbumHash)) {
                    $HashArtistToAlbum[$ArtistHash][$AlbumHash] = 0
                }
                $AlbumCount = $HashArtistToAlbum[$ArtistHash][$AlbumHash]
                $AlbumCount++
                $HashArtistToAlbum[$ArtistHash][$AlbumHash] = $AlbumCount
                #endregion

                <# Album to TrackTitle #>
                #region SetAlbumToTitleMapping
                if (-Not $HashAlbumToTitle.ContainsKey($AlbumHash)) {
                    $HashAlbumToTitle[$AlbumHash] = @{}
                }
                if (-Not $($HashAlbumToTitle[$AlbumHash]).ContainsKey($SourceHashVal)) {
                    $HashAlbumToTitle[$AlbumHash][$SourceHashVal] = 0
                }
                $TitleCount = $HashAlbumToTitle[$AlbumHash][$SourceHashVal]
                $TitleCount++
                $HashAlbumToTitle[$AlbumHash][$SourceHashVal] = $TitleCount
                #endregion
                #endregion

                $RawPctComplete = $($RowsProcessed / $SampleRows)
                $PctComplete = [math]::Floor(($RawPctComplete * 100))
                if ($PctComplete -gt 100) {
                    $PctComplete = 100
                }
                $PctCompleteString = $($RawPctComplete.ToString('P0'))

                # -CurrentOperation "Processing $($RowsProcessed.ToString().PadLeft(4)) of $($SampleRows.ToString().PadLeft(4))"
                # -Status "$PctCompleteString Complete:"

                if ($RowsProcessed -eq 1 -or $PctComplete -ne $PriorProgressPctNbr) {
                    Write-Progress -Activity "Parsing Base music files from $MusicSourcePath" `
                        -Status "$PctCompleteString Complete:" `
                        -PercentComplete $PctComplete
                    $PriorProgressPctNbr = $PctComplete
                }
                # Write-Output New-Object PSObject -Property $hash


                if ($RowsProcessed -gt $SampleRows) {
                    break InitialTrackLoop
                }
            }
        } 
    }
    #endregion
    



    $TotalArtists = $($HashToArtist.Count)
    $TotalGenres = $($HashToGenre.Count)

    if ($PctComplete -gt 100) {
        $PctComplete = 100
    }
    Write-Progress -Complete -Activity 'Parsing Base music files' -Status "$PctCompleteString Complete:" -PercentComplete $PctComplete

    <# Done - Report output #>
    $timeStr = Get-FormattedTimeString -startTimestamp $startBaseBuildDateTime
    $endDateTime = Get-Date
    Write-Host ''
    Write-Host ''
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host "$($spacer*1) Completed the initial music build. Found $($TotalGenres.ToString()) unique Genres and ($TotalArtists.ToString()) unique Artists."
    Write-Host "$($spacer*1) from the music found on $($env:COMPUTERNAME) from $MusicSourcePath." 
    Write-Host "$($spacer*1) Started: $($startBaseBuildDateTime.ToString('MM/dd/yy HH:mm:ss')) Finished: $($endDateTime.ToString('MM/dd/yy HH:mm:ss')) Elapsed: $timeStr "
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host ''
    Write-Host ''


    $startBuildDateTime = Get-Date
    Write-Host ''
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host "$($spacer*1) Starting the to playlist build of $($NumberOfPlayListsToBuild.ToString()) unique playlists"
    Write-Host "$($spacer*1) from the music found on $($env:COMPUTERNAME) from $MusicSourcePath."   
    Write-Host "$($spacer*1) Started: $($startBuildDateTime.ToString('MM/dd/yy HH:mm:ss'))"
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host ''

    #region BuildAllPlaylists
    if ($HashToFullPath.Count -gt 0) {

        <# Filter any genres that are on the blocked list #>
        :BaseGenreLoop foreach ($Genre in $GenreToHash.Keys | Sort-Object) {

            $GenreHash = $GenreToHash[$Genre]

            if ($GenresToSkip.Contains($Genre)) {
                continue BaseGenreLoop 
            }
            if ($($HashGenreToArtist[$GenreHash]).Count -eq 0) {
                continue BaseGenreLoop
            }
            [void]$ValidGenresToChooseFrom.Add($GenreHash)
        }

        <#
        [hashtable]$private:HashGenreToArtist = @{}
        [hashtable]$private:HashArtistToAlbum = @{}
        [hashtable]$private:HashAlbumToTitle = @{}
    #>
        # $DaysToLookBackForNoRepeat = 0

        <#
        RollingIncludedTracks = @{}
        Day -> TitleTrack
            -> Artist/Title  ( Note: Think on how to normalize title and title - live for example )

            $MusicHash[$SourceHashVal]['TrackDetail'] = @{}
                $MusicHash[$SourceHashVal]['TrackKeys'] = @{}

                [hashtable]$private:GenreToHash = @{}
        [hashtable]$private:HashToGenre = @{}
    #>
        $OutPutHash.Clear()
    
        if ($RowsProcessed -gt 0) {
            $AvgSongLength = [math]::Round($TotalListMinutes / $RowsProcessed, 2)
        }
        else {
            $AvgSongLength = 0
        }
    
        <# To Do:  Pull out the "Buffer" amount into a variable #>
        if ($AvgSongLength -gt 0) {
            $TargetIterations = [math]::Ceiling((1.1 * ($TargetPlayListDuration / $AvgSongLength)))
        }
        else {
            $TargetIterations = 0
        }
    
        :DayLoop for ($DayIdx = 0; $DayIdx -lt $NumberOfPlayListsToBuild; $DayIdx++) {
            <# This is used to build the output playlist name #>
            $CurrentDate = $StartDate.AddDays($DayIdx)

            Write-Verbose "$($spacer*1) $($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy'))"

            $DayKey = $($CurrentDate.ToString('yyyyMMdd'))
            $startBuildListDateTime = Get-Date

            if (-not $OutPutHash.ContainsKey($DayKey)) {
                $OutPutHash[$DayKey] = @{}
                $OutPutHash[$DayKey]['TitleList'] = @{}
                $OutPutHash[$DayKey]['TitleTrackList'] = [ordered]@{}
                $OutPutHash[$DayKey]['GenreDetails'] = [ordered]@{}
                $OutPutHash[$DayKey]['ArtistDetails'] = [ordered]@{}
                $OutPutHash[$DayKey]['AlbumDetails'] = [ordered]@{}
            }

            if (-not $RollingIncludedTracks.ContainsKey($DayKey)) {
                $RollingIncludedTracks[$DayKey] = @{}
                $RollingIncludedTracks[$DayKey]['TitleTrack'] = @{}
                $RollingIncludedTracks[$DayKey]['ArtistTitle'] = @{}
            }

            $TotalListMinutes = 0
            $PriorProgressPctNbr = 0

            $ArtistsToChooseFrom.Clear()
            $TitlesToChooseFrom.Clear()
            $PriorProgressPctNbr = 0

            <# Calculate Pct complete for progress display #>
            $RawPctComplete = 0
            $PctComplete = [math]::Floor(($RawPctComplete * 100))
            if ($PctComplete -gt 100) {
                $PctComplete = 100
            }
            $PctCompleteString = $($RawPctComplete.ToString('P'))
            $timeStr = Get-FormattedTimeString -startTimestamp $startBuildDateTime

            Write-Progress -Activity "Building the Playlist for $($CurrentDate.ToString('MM/dd/yy'))" `
                -Status "$PctCompleteString Complete (Elapsed $timeStr):" `
                -Id $DayIdx -PercentComplete $PctComplete

            # $TargetIterations

            :ListLoop while ($TotalListMinutes -lt $TargetPlayListDuration) {

                Write-Verbose "$($spacer*1) $($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) --> $($TotalListMinutes.ToString())"
            
                <# Re-set the Genre order for the current iteration #>
                $GenresToChooseFrom.Clear()
                $GenreCount = $ValidGenresToChooseFro.Count

                $GenresToChooseFrom = $ValidGenresToChooseFrom | Sort-Object | Get-Random -Shuffle
            
                :GenreLoop foreach ($GenreHashKey in $GenresToChooseFrom) {

                    $Genre = $HashToGenre[$GenreHashKey]
                    Write-Verbose "$($spacer*1) $($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) Genre --> $Genre"

                    <# Check the number of songs we have found for the current genre #>
                    if ($GenreSongLimits.ContainsKey($Genre)) {

                        if ($($OutPutHash[$DayKey]['GenreDetails']).Contains($GenreHashKey)) {

                            if ($($OutPutHash[$DayKey]['GenreDetails'][$GenreHashKey]).Count -ge $($GenreSongLimits[$Genre])) {
                                <# We have met the limit for the genre, continue #>
                                continue GenreLoop
                            }
                        }
                    }

                    <# Get the Artists for the Genre #>
                    $ArtistsToChooseFrom.Clear()
                
                    $ArtistCount = $($HashGenreToArtist[$GenreHashKey]).Count

                    # $ArtistsToChooseFrom = $($HashGenreToArtist[$GenreHashKey]).Keys | Sort-Object | Get-Random -Shuffle
                    $ArtistsToChooseFrom = Get-CandidateItemsForStep -ItemCount $ArtistCount `
                        -ItemList $($($HashGenreToArtist[$GenreHashKey]).Keys)

                    :ArtistLoop foreach ($ArtistHashKey in $ArtistsToChooseFrom) {

                        $Artist = $HashToArtist[$ArtistHashKey]
                        Write-Verbose "$($spacer*1)$($spaceTwo) $($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) Artist --> $Artist"


                        $AlbumsToChooseFrom.Clear()
                        $AlbumCount = $($HashArtistToAlbum[$ArtistHashKey]).Count
                
                        # $AlbumsToChooseFrom = $($HashArtistToAlbum[$ArtistHashKey]).Keys | Sort-Object | Get-Random -Shuffle
                        $AlbumsToChooseFrom = Get-CandidateItemsForStep -ItemCount $AlbumCount `
                            -ItemList $($($HashArtistToAlbum[$ArtistHashKey]).Keys)

                        :AlbumLoop foreach ($AlbumHashKey in $AlbumsToChooseFrom) {
                        
                            $Album = $HashToAlbum[$AlbumHashKey]
                            Write-Verbose "$($spacer*1)$($spaceTwo*2)$($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) Album --> $Album"


                            $TitlesToChooseFrom.Clear()
                            $CandidateTrackCount = $($HashAlbumToTitle[$AlbumHashKey]).Count
                            $TitlesToChooseFrom = Get-CandidateItemsForStep -ItemCount $CandidateTrackCount `
                                -ItemList $($($HashAlbumToTitle[$AlbumHashKey]).Keys)
                        
                            # $($HashAlbumToTitle[$AlbumHashKey]).Keys | Sort-Object | Get-Random -Shuffle

                            :TrackLoop foreach ($SourceHashVal in $TitlesToChooseFrom) {
                            
                                <# Hash of the Title only #>
                                $TitleHashKey = $MusicHash[$SourceHashVal]['TrackKeys']['Title']

                                $TitleTrack = $HashToTitleTrack[$TitleHashKey]
                                Write-Verbose "$($spacer*1)$($spaceTwo*3)$($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) Song --> $TitleTrack"


                                <# $SourceHashVal is the hash of the full path including the Album/Artist/Track #>

                                $ArtistSongKey = $ArtistHashKey + '|' + $TitleHashKey
                                $IncludeTrack = $true
                                $FoundTrack = $false
                                $DaysChecked = 0

                                :PriorDayLoop foreach ($PriorDayKey in $RollingIncludedTracks.Keys | Sort-Object -Descending ) {
                                    $DaysChecked++
                                
                                    if ($DaysChecked -gt $DaysToLookBackForNoRepeat) {
                                        break PriorDayLoop
                                    }

                                    if ($($RollingIncludedTracks[$PriorDayKey]['TitleTrack']).ContainsKey($SourceHashVal)) {
                                        $FoundTrack = $true
                                    }
                                    <# Check the Artist Song #>
                                
                                    if ($($RollingIncludedTracks[$PriorDayKey]['ArtistTitle']).ContainsKey($ArtistSongKey)) {
                                        $FoundTrack = $true
                                    }

                                    if ($FoundTrack) {
                                        break PriorDayLoop
                                    }

                                }

                                $IncludeTrack = -not $FoundTrack

                                <# Check the Probability of including #>
                                if ($IncludeTrack) {
                                    <#
                                    The Track is notionally valid.  Check probability of including based on stars
                                #>
                                    [string]$RatingStars = $MusicHash[$SourceHashVal]['TrackDetail']['RatingStars']
                                    if ($RatingStars.Length -eq 0) {
                                        $RatingStars = 'X'
                                    }
                                    <# Generate a random number 1-10 #>
                                    [int]$RatingStarFloor = $StarRatingInclusionPtcs[$RatingStars]
                                    $IncludeTrackIndex = Get-Random -Minimum 1 -Maximum 101
                                    if ($RatingStarFloor -gt $IncludeTrackIndex) {
                                        <# Outside of the range -Flip Include to false
                                        1 Star - 30% Included
                                        2 Star - 40%
                                        3 Star - 50%
                                        4 Star - 60%
                                        5 Star - 70%

                                        $StarRatingInclusionPtcs = @{
                                            '1'  = 5

                                    #>
                                        $IncludeTrack = $false
                                    }
                                }
                             

                                if ($IncludeTrack) {
                                    Write-Verbose "$($spacer*1)$($spaceTwo*3)$($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) --> $TitleTrack (Saved)"
                                    <# Update the output etc #>
                                    $TotalMinutes = $MusicHash[$SourceHashVal]['TrackDetail']['TotalMinutes']
                                    $TotalListMinutes += $TotalMinutes

                                    <# Update the Prior List details #>
                                    if (-not $($RollingIncludedTracks[$PriorDayKey]['TitleTrack']).ContainsKey($SourceHashVal)) {
                                        $RollingIncludedTracks[$DayKey]['TitleTrack'][$SourceHashVal] = 1
                                    }

                                    if (-not $($RollingIncludedTracks[$DayKey]['ArtistTitle']).ContainsKey($ArtistSongKey)) {
                                        $RollingIncludedTracks[$DayKey]['ArtistTitle'][$ArtistSongKey] = 1
                                    }

                                    <# Update the output hash #>
                                    if (-not $($OutPutHash[$DayKey]['TitleTrackList']).Contains($SourceHashVal)) {
                                        $OutPutHash[$DayKey]['TitleTrackList'][$SourceHashVal] = $TitleHashKey
                                    }

                                    if (-not $($OutPutHash[$DayKey]['GenreDetails']).Contains($GenreHashKey)) {
                                        $OutPutHash[$DayKey]['GenreDetails'][$GenreHashKey] = @{}
                                    }
                                    $OutPutHash[$DayKey]['GenreDetails'][$GenreHashKey][$SourceHashVal] = 1

                                    if (-not $($OutPutHash[$DayKey]['ArtistDetails']).Contains($ArtistHashKey)) {
                                        $OutPutHash[$DayKey]['ArtistDetails'][$ArtistHashKey] = @{}
                                    }
                                    $OutPutHash[$DayKey]['ArtistDetails'][$ArtistHashKey][$SourceHashVal] = 1

                                    if (-not $($OutPutHash[$DayKey]['AlbumDetails']).Contains($AlbumHashKey)) {
                                        $OutPutHash[$DayKey]['AlbumDetails'][$AlbumHashKey] = @{}
                                    }
                                    $OutPutHash[$DayKey]['AlbumDetails'][$AlbumHashKey][$SourceHashVal] = 1

                                    <# We found a match for the target Genre. Go to the next one #>
                                    break ArtistLoop

                                }
                                else {
                                    Write-Verbose "$($spacer*1)$($spaceTwo*3)$($DayIdx.ToString().PadLeft(2))) $($CurrentDate.ToString('MM/dd/yy')) --> $TitleTrack (Skipped)"
                                }
                                <#
                                if (-not $OutPutHash.ContainsKey($DayKey)) {
                                    $OutPutHash[$DayKey] = @{}
                                    $OutPutHash[$DayKey]['TitleList'] = @{}
                                    $OutPutHash[$DayKey]['TitleTrackList'] = @{}
                                    $OutPutHash[$DayKey]['GenreDetails'] = @{}
                                    $OutPutHash[$DayKey]['ArtistDetails'] = @{}
                                    $OutPutHash[$DayKey]['AlbumDetails'] = @{}
                                }
                            #>
                                if ($TotalListMinutes -ge $TargetPlayListDuration) {
                                    break TrackLoop
                                }

                                # TargetIterations
                                <# Calculate Pct complete for progress display #>
                                $RawPctComplete = $($TotalListMinutes / $TargetPlayListDuration)
                                $PctComplete = [math]::Floor(($RawPctComplete * 100))
                                if ($PctComplete -gt 100) {
                                    $PctComplete = 100
                                }
                                $PctCompleteString = $($RawPctComplete.ToString('P'))
                                $timeStr = Get-FormattedTimeString -startTimestamp $startBuildListDateTime

                                # -CurrentOperation "Processing $($RowsProcessed.ToString().PadLeft(4)) of $($SampleRows.ToString().PadLeft(4))"
                                # -Status "$PctCompleteString Complete:"
    
                                if ($RowsProcessed -eq 1 -or $PctComplete -ne $PriorProgressPctNbr) {
                                    Write-Progress -Activity "Building the Playlist for $($CurrentDate.ToString('MM/dd/yy'))" `
                                        -Status "$PctCompleteString Complete (Elapsed $timeStr)" `
                                        -Id $DayIdx -PercentComplete $PctComplete
                                    $PriorProgressPctNbr = $PctComplete
                                }
                            }

                            if ($TotalListMinutes -ge $TargetPlayListDuration) {
                                break AlbumLoop
                            }
                        }

                        if ($TotalListMinutes -ge $TargetPlayListDuration) {
                            break ArtistLoop
                        }
                    }
                
                    if ($TotalListMinutes -ge $TargetPlayListDuration) {
                        break GenreLoop
                    }
                }
            }

            <# End of day loop #>
            Write-Progress -Completed -Activity "Building the Playlist for $($CurrentDate.ToString('MM/dd/yy'))" `
                -Status "$PctCompleteString Complete (Elapsed $timeStr)" `
                -Id $DayIdx -PercentComplete $PctComplete
        }

        Write-Host ''
        Write-Host ' -------------------------------------------------------------------------------------'

        foreach ($DayKey in $OutPutHash.Keys | Sort-Object) {

            <# Calculate the actual minutes #>

            # $OutPutHash[$DayKey]['TitleTrackList'][$SourceHashVal] = $TitleHashKey

            <# Calculate the times for the list #>
            [decimal]$TotalListMinutes = 0.00
            [int]$TotalSeconds = 0

            $($OutPutHash[$DayKey]['TitleTrackList']).Keys | ForEach-Object {
                # $TrackLenString = $OutPutHash[$DayKey]['TitleList'][$_]
                # ([Int16]$Hours, [Int16]$Minutes, [Int16]$Seconds) = $TrackLenString.Split(':')
                # 00:02:38
                # $SecondsFraction = $Seconds / 60
                # $TotalMinutes = ($Hours * 60) + $Minutes + $SecondsFraction
                $TotalMinutes = $MusicHash[$_]['TrackDetail']['TotalMinutes']

                $TotalListMinutes += $TotalMinutes

                $IncrementalSeconds = ($Hours * 60 * 60) + ($Minutes * 60) + $Seconds
                $TotalSeconds += $IncrementalSeconds

            } 

            $PlayListCalcSeconds = [math]::Ceiling($TotalListMinutes * 60)
            [int]$RemainingSeconds = $PlayListCalcSeconds

            [int]$ElapsedsDays = 0
            [int]$ElapsedsHours = 0
            [int]$ElapsedsMinutes = 0
            [int]$ElapsedSeconds = 0

            Write-Verbose ''
            Write-Verbose ''

        
            for ($i = 2; $i -ge 0; $i--) {

                $BaseMultiplier = $([math]::Pow(60, $i))

                if ($i -eq 3) {
                    <# Days #>
                    $BaseMultiplier = $([math]::Pow(60, $i - 1)) * 24

                    if ($RemainingSeconds -ge $BaseMultiplier) {
                        $ElapsedsDays = [math]::Floor($RemainingSeconds / $BaseMultiplier)
                        $RemainingSeconds = $RemainingSeconds - ($BaseMultiplier * $ElapsedsDays)

                    }
                }
                elseif ($i -eq 2) {
                    <# Hours #>
                    $ElapsedsHours = [math]::Floor($RemainingSeconds / $BaseMultiplier)
                    $RemainingSeconds = $RemainingSeconds - ($BaseMultiplier * $ElapsedsHours)
                }
                elseif ($i -eq 1) {
                    <# Minutes #>

                    $ElapsedsMinutes = [math]::Floor($RemainingSeconds / $BaseMultiplier)
                    $RemainingSeconds = $RemainingSeconds - ($BaseMultiplier * $ElapsedsMinutes)
                }
                else {
                    <# Seconds #>
                    if ($RemainingSeconds -lt 60) {
                        $ElapsedSeconds = $RemainingSeconds
                    }
                    else {
                        Throw 'This is an error - we should not have more than a minute remaining when we get here.'
                    }
                
                }

                Write-Verbose "$($spacer)$($spaceTwo*(3-$i)) $($i.ToString().PadLeft(3))) $($BaseMultiplier.ToString()) $($TargetPlayListDuration.ToString())  $($TotalListMinutes.ToString())"
                Write-Verbose "$($spacer)$($spaceTwo*(3-$i)) $($spaceTwo*2) Original Playlist Seconds: <$($PlayListCalcSeconds.ToString('N0'))> Remaining Seconds: <$($RemainingSeconds.ToString('N0'))>"
                Write-Verbose "$($spacer)$($spaceTwo*(3-$i)) $($spaceTwo*2) Days: <$($ElapsedsDays.ToString('N0'))> Hours: <$($ElapsedsHours.ToString('N0'))> Minutes: <$($ElapsedsMinutes.ToString('N0'))> Seconds: <$($ElapsedSeconds.ToString('N0'))>"
            }

            Write-Verbose "$($spacer)$($spaceTwo) Found /$ElapsedsDays/$elapsedsHours/ elapsed days/hours and/$elapsedsMinutes/ elapsed minutes and /$elapsedSeconds/ elapsed seconds to format."
            Write-Verbose ''
            Write-Verbose ''

            [string]$elapsedDaysStr = '{0:d2}' -f $ElapsedsDays
            [string]$elapsedSecondsStr = '{0:d2}' -f $ElapsedSeconds
            [string]$elapsedsMinutesStr = '{0:d2}' -f $ElapsedsMinutes
            [string]$elapsedHoursStr = '{0:d2}' -f $ElapsedsHours

            if ($ElapsedsDays -gt 0) {
                $timeStr = "$($elapsedDaysStr):$($elapsedHoursStr):$($elapsedsMinutesStr):$($elapsedSecondsStr)"
            }
            else {
                $timeStr = "$($elapsedHoursStr):$($elapsedsMinutesStr):$($elapsedSecondsStr)"
            }
        
        
        
            Write-Host "$($spacer*1) Showing Results for $DayKey <Base Title Tracks: $($RowsProcessed.ToString('N0').PadLeft($MetricPadLen))>"
            Write-Host "$($spacer*1)$($spaceTwo) $('Tracks on List'.PadRight($TitlePadLen,'.')): $($($OutPutHash[$DayKey]['TitleTrackList']).Count.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Target Tracks on List'.PadRight($TitlePadLen,'.')): $($TargetIterations.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Music minutes on List'.PadRight($TitlePadLen,'.')): $($timeStr.PadLeft($MetricPadLen)) ($($TotalListMinutes.ToString('N0')))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Distinct Genres'.PadRight($TitlePadLen,'.')): $($($OutPutHash[$DayKey]['GenreDetails']).Count.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Distinct Artists'.PadRight($TitlePadLen,'.')): $($($OutPutHash[$DayKey]['ArtistDetails']).Count.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Distinct Albums'.PadRight($TitlePadLen,'.')): $($($OutPutHash[$DayKey]['AlbumDetails']).Count.ToString('N0').PadLeft($MetricPadLen))"
        
            Write-Host "$($spacer*1)$($spaceTwo) $('Music Calc Seconds'.PadRight($TitlePadLen,'.')): $($PlayListCalcSeconds.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Music Sum Seconds'.PadRight($TitlePadLen,'.')): $($TotalSeconds.ToString('N0').PadLeft($MetricPadLen))"
        
            Write-Host "$($spacer*1)$($spaceTwo) $('Target Duration (Minutes)'.PadRight($TitlePadLen,'.')): $($TargetPlayListDuration.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Total List Minutes'.PadRight($TitlePadLen,'.')): $($TotalListMinutes.ToString('N0').PadLeft($MetricPadLen))"

            Write-Host "$($spacer*1)$($spaceTwo) $('Total List Days'.PadRight($TitlePadLen,'.')): $($ElapsedsDays.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Total List Hours'.PadRight($TitlePadLen,'.')): $($ElapsedsHours.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Total List Minutes'.PadRight($TitlePadLen,'.')): $($ElapsedsMinutes.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host "$($spacer*1)$($spaceTwo) $('Total List Seconds'.PadRight($TitlePadLen,'.')): $($ElapsedSeconds.ToString('N0').PadLeft($MetricPadLen))"
            Write-Host ''

            <#
            [hashtable]$private:GenreToHash = @{}
            [hashtable]$private:HashToGenre = @{}

            [hashtable]$private:ArtistToHash = @{}
            [hashtable]$private:HashToArtist = @{}

            [hashtable]$private:HashToAlbum = @{}
            [hashtable]$private:AlbumToHash = @{}

            [hashtable]$private:HashToTitleTrack = @{}
            [hashtable]$private:TitleTrackToHash = @{}

            $MusicHash[$SourceHashVal]['TrackKeys']['Genre'] = $GenreHash
            $MusicHash[$SourceHashVal]['TrackKeys']['Artist'] = $ArtistHash
            $MusicHash[$SourceHashVal]['TrackKeys']['Album'] = $AlbumHash
            $MusicHash[$SourceHashVal]['TrackKeys']['Title'] = $TitleTrackHash
            $MusicHash[$SourceHashVal]['TrackDetail'][$MusicAttribute] = $hash[$MusicAttribute]

            $HashToFullPath[$SourceHashVal] = $Item  # This is what is written out in the list
            $MusicHash[$SourceHashVal]['TrackDetail'] = @{}
            $MusicHash[$SourceHashVal]['TrackKeys'] = @{}
            $MusicHash[$SourceHashVal]['TrackKeys']['Genre'] = $GenreHash
            $MusicHash[$SourceHashVal]['TrackKeys']['Artist'] = $ArtistHash
            $MusicHash[$SourceHashVal]['TrackKeys']['Album'] = $AlbumHash
            $MusicHash[$SourceHashVal]['TrackKeys']['Title'] = $TitleTrackHash

            $OutPutHash[$DayKey] = @{}
            $OutPutHash[$DayKey]['TitleList'] = @{}
            $OutPutHash[$DayKey]['TitleTrackList'] = [ordered]@{}
            $OutPutHash[$DayKey]['GenreDetails'] = [ordered]@{}
            $OutPutHash[$DayKey]['GenreDetails'][$GenreHashKey][$SourceHashVal] = 1
            
            $OutPutHash[$DayKey]['ArtistDetails'] = [ordered]@{}
            $OutPutHash[$DayKey]['AlbumDetails'] = [ordered]@{}

        #>

            <# Save the Output for the list #>


            <# Initially create a review list #>
            <#
            $private:OutLogTempFile = $null
            $OutLogTempFile = New-TemporaryFile
            Add-Content -Path $($OutLogTempFile.FullName) -Value $outputLine -Encoding Default
            Start notepad++ $($OutputTempFile.FullName)
        #>
        
            $private:OutLogTempFile = $null
            $private:OutPlayListTempFile = $null

            # Nov CA Trip.m3u
            # D:\Music\Pretenders\Pretenders\06 - The Wait.mp3

            $OutLogTempFile = New-TemporaryFile
            $OutPlayListTempFile = New-TemporaryFile

            $RowCount = 0
            $($OutPutHash[$DayKey]['TitleTrackList']).Keys | ForEach-Object {
                <# Get the keys for the outut #>
                # $_ --> $SourceHashVal
            
                $RowCount++

                $OutputString = "$($RowCount.ToString())"
                $OutputString += $outputSeparaterString

                $GenreHashKey = $MusicHash[$_]['TrackKeys']['Genre']
                $ArtistHashKey = $MusicHash[$_]['TrackKeys']['Artist']
                $AlbumHashKey = $MusicHash[$_]['TrackKeys']['Album']
                $TitleHashKey = $MusicHash[$_]['TrackKeys']['Title']

                $Genre = $HashToGenre[$GenreHashKey]
                $Artist = $HashToArtist[$ArtistHashKey]
                $Album = $HashToAlbum[$AlbumHashKey]
                $Title = $HashToTitleTrack[$TitleHashKey]
                $SongLength = $MusicHash[$_]['TrackDetail']['Length']

                # $QualifiedSongFile = $MusicHash[$_]['TrackDetail']['Folder path'] # Does not include the file name (might have to join path)
                # $QualifiedSongFile = $MusicHash[$_]['TrackDetail']['Path']
                $QualifiedSongFile = $HashToFullPath[$_]
                <# 
                This will also work
                $HashToFullPath[$SourceHashVal] = $Item

            #>
            
                $OutputString += "$Title"
                $OutputString += $outputSeparaterString

                $OutputString += "$Genre"
                $OutputString += $outputSeparaterString

                $OutputString += "$Artist"
                $OutputString += $outputSeparaterString

                $OutputString += "$Album"
                $OutputString += $outputSeparaterString

                $OutputString += $SongLength

                if ($RowCount -eq 1) {
                    Set-Content -Path $($OutLogTempFile.FullName) -Value $OutputString -Encoding Default
                    Set-Content -Path $($OutPlayListTempFile.FullName) -Value $QualifiedSongFile -Encoding Default
                }
                else {
                    Add-Content -Path $($OutLogTempFile.FullName) -Value $OutputString -Encoding Default
                    Add-Content -Path $($OutPlayListTempFile.FullName) -Value $QualifiedSongFile -Encoding Default
                }
            

            }
            <#
        'Folder path'
        [string]$private:OutputFileSuffix  = 'Nov2023-CA-Visit'
        [string]$private:PlayListExt = "m3u"
        [string]$private:LogFileExt = "tsv"
        OutputPathSuffix OutputPath
        #>
            $OutputCommponPrefix = $DayKey + '_' + $OutputFileSuffix + '.'
            $OutputPlayListFileName = $OutputCommponPrefix + $PlayListExt
            $OutputLogFileName = $OutputCommponPrefix + $LogFileExt

            if (-not $IsTest) {

                $QualifiedTargetPlaylistFile = (Join-Path $OutputPath $OutputPlayListFileName)

                Copy-Item -Path $($OutPlayListTempFile.FullName) -Destination $QualifiedTargetPlaylistFile -Force
                if (Test-Path $QualifiedTargetPlaylistFile) {
                    Remove-Item -Path $($OutPlayListTempFile.FullName)
                }
                Start-Process notepad++ $QualifiedTargetPlaylistFile

            }
            else {
                Start-Process notepad++ $($OutPlayListTempFile.FullName)
            }

            # Start-Process notepad++ $($OutPlayListTempFile.FullName)
            <# Always open the log: #>
            Start-Process notepad++ $($OutLogTempFile.FullName)
        

            Write-Host "$($spacer*1)$($spaceTwo) $("Saving $OutputPlayListFileName to".PadRight($TitlePadLen,'.')): $OutputPath"
            Write-Host ''

        }
        Write-Host ' -------------------------------------------------------------------------------------'
        Write-Host ''

    }  # End Build out lists 
    #endregion

    $timeStr = Get-FormattedTimeString -startTimestamp $startDateTime
    $endDateBuildTime = Get-Date
    
    Write-Host ''
    Write-Host ''
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host "$($spacer*1) Completed the to build $($NumberOfPlayListsToBuild.ToString()) unique playlists"
    Write-Host "$($spacer*1) from the music found on $($env:COMPUTERNAME) from $MusicSourcePath." 
    Write-Host "$($spacer*1) Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss')) Finished: $($endDateBuildTime.ToString('MM/dd/yy HH:mm:ss')) Elapsed: $timeStr "
    Write-Host ' -------------------------------------------------------------------------------------'
    Write-Host ''
    Write-Host ''

}
catch {
    Write-Host ' Hit some error!'
    $ScriptName = $PSItem.InvocationInfo.ScriptName
    $Line = $PSItem.InvocationInfo.Line 
    $ScriptLineNumber = $PSItem.InvocationInfo.ScriptLineNumber
    Write-Host "Error...Name: $ScriptName Line: $Line Script Line Nbr: $ScriptLineNumber"
    $err = $_.Exception
    $err | Select-Object -Property *
    "Response: $err.Response"
    $err.Response
}
finally {
    if ($shellobj) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$shellobj) | Out-Null
    }
    [System.GC]::Collect()
}