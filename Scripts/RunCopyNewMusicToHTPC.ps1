
using module 'C:\Users\johns\Projects\JRiverTools\Release\0.2.0\JRiverTools.psm1'

# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
. 'C:\Users\johns\Tools\PSScripts\PSIncludeFiles\includeUtilities.ps1'

. 'C:\Users\johns\Tools\PSScripts\PSIncludeFiles\includeWWParityVars.ps1'
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------



Import-Module ListUtils -Force
Import-Module DateUtils -Force
Import-Module PathUtils -Force
Import-Module FormatUtils -Force
Import-Module RawFileUtils -Force
Import-Module FileHeaderUtils -Force
Import-Module VistaAlAguaSecurityDetails -Force


<# Display and debug vars #>
[string]$private:spaceTwo = $(' '*2)
[string]$private:spacer = $(' '*4)

$VerbosePreference = 'SilentlyContinue'  # $oldVerbose

[string]$local:spaceTwo = $(' '*2)
[string]$local:spacer = $(' '*4)



[hashtable]$driveDetails = @{}

$baseTargetPaths = @("Music"
                        , "Video"
                        )

$musicTargetPaths = @("Amazon MP3"
                        , "Bandcamp"
                        , "Flac"
                        , "HDTracks"
                        , "Playlists"
                        , "Wma"
                        , "MP3"
                    )

$videoTargetPaths = @("4KUHD"
                        , "BluRay"
                        , "Dvd"
                    )

$TargetMediaDrives = @("I", "J", "K", "L")

$driveLetterToNumberMap = @{"I" = 1;
                            "J" = 3;
                            "K" = 4;
                            "L" = 2;
                            }

[hashtable]$artistDetail = @{}

[hashtable]$alternameArtistMapping = @{'Commander Cody' = @('Commander Cody & His Lost Planet Airmen'
                                                            );
}

$private:remoteArtistAlbumObjs = [System.Collections.Generic.list[object]]::New()

[System.Collections.ArrayList]$local:ArtistsToCheck = @()
[System.Collections.ArrayList]$local:SourcesToCheck = @()

$SearchPhrase = "Cody"
<#
s/b one of these.. 
$musicTargetPaths = @("Amazon MP3"
                        , "Bandcamp"
                        , "Flac"
                        , "HDTracks"
                        , "Playlists"
                        , "Wma"
                        , "MP3"
                    )
#>
$MusicFileSourse = ''

if (-not $musicTargetPaths.Contains($MusicFileSourse)) {
    <# Default to flac (ripped cd) #>
 
    $MusicFileSourse = "Flac"
}

try {

    <#
        For now just call for the details directly. 
        To Do:  Add function to VistaAlAguaSecurityDetails.psm1 to get credential object for a passed machine name
        "htpcPswd" 
        "htpcUserName
    #>
    $remoteUserName = Get-SecretForPassedName -SecretToFetch "htpcUserName" -FetchPlainText $true
    $remotePswd = Get-SecretForPassedName -SecretToFetch "htpcPswd" -FetchPlainText $false

    $remoteCreds = New-Object System.Management.Automation.PSCredential ($remoteUserName, $remotePswd)

    <#

    $remoteCreds.UserName
    $remoteCreds.Password
    #>

    $remoteSessionObj = New-PSSession -ComputerName HTPC -Credential $remoteCreds

    $remoteSessionObj.GetType()
    # -----------------------------------------
    $startDateTime = Get-Date
    Write-Host ""
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host "    Starting the check for *$($SearchPhrase)*...in Music on HTPC"
    Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss'))"
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host ""

    [datetime]$FilterStartDate = "2023-09-18"

    <#
        TBD - Derive albums to copy based on type and date
    #>

    Write-Host "$($spacer*2) Get the albums to copy..."
    $localFolder = GetLocalAlbumToCopyToHTPC -ArtistNamesToCopy "Cody", "Ashley" -MusicFileSourse "Flac", "Bandcamp" `
                        -FirstDateToCheckSeed $FilterStartDate -DaysBackToCheck 60

    $artistList = ""
    $sourceList = ""


    $localFolder | ForEach-Object {

        $_
        
        if (-not $ArtistsToCheck.Contains($($_.ArtistName))) {
            <# Action to perform if the condition is true #>
            $artistList += $( '"' + $_.ArtistName + '"' )
            $artistList += ','
            [void]$ArtistsToCheck.Add($_.ArtistName)
            Write-Host "$($spacer*2)$($spaceTwo) Found $($_.ArtistName)" 
        }
        if (-not $SourcesToCheck.Contains($($_.MusicSource))) {
            <# Action to perform if the condition is true #>
            $sourceList += $_.MusicSource
            $sourceList += ','
            [void]$SourcesToCheck.Add($_.MusicSource)
            Write-Host "$($spacer*2)$($spaceTwo) Found $($_.MusicSource)" 
        }
    }

    break

    if ($artistList.EndsWith(',')) {
        <# Action to perform if the condition is true #>
        $artistList = $artistList.Substring(0,$($artistList.Length)-1)

    }
    if ($sourceList.EndsWith(',')) {
        <# Action to perform if the condition is true #>
        $sourceList = $sourceList.Substring(0,$($sourceList.Length)-1)

    }

    $artistList = ""
    $artistCount = 0
    foreach ($ArtistName in $ArtistsToCheck) {
        $artistCount++
        $artistList += $( '"' + $ArtistName + '"' )

        if ($artistCount -lt $ArtistsToCheck.Count) {
            <# Action to perform if the condition is true #>
            $artistList += ','
            $artistList += ' '
        }

    }

    <#
        Need a custom return class that allows for sorting
    #>

    <#
        Also - pass to copy object, pull artist names (and alternates) from passed object
    #>
    $remoteArtistPathObjs = GetArtistPathFromHTPC -ArtistNamesToFind $ArtistsToCheck -MusicFileSourses $SourcesToCheck -remoteSessionObj $remoteSessionObj 

    <#
        Also - pass to copy object, pull artist names (and alternates) from passed object
    #>
    # $remoteArtistAlbumObjs = 
    Get-HTPCAlbumDetails -ArtistPathsToCheckObjs $remoteArtistPathObjs `
                                -ArtistAlbumToCheckObjs $localFolder  `
                                -remoteSessionObj $remoteSessionObj  | ForEach-Object {

                                    $_ | Where-Object {$_.ArtistName -eq 'Ashley McBryde'}

                                    # -ArtistAlbumToCopyObjs $_ 
                                    $_ | Copy-LocalAlbumsToHTPC -remoteSessionObj $remoteSessionObj -WhatIf -Verbose -UpdateExisting

                                }



    

    break

    $remoteArtistAlbumObjs.Count

    $remoteArtistAlbumObjs | Select-Object  -First 1


    


    $timeStr = Get-FormattedTimeString -startTimestamp $startDateTime 
    $endDateTime = Get-Date
    Write-Host ""
    Write-Host ""
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host "    Completed checking for *$($SearchPhrase)*...in Music on HTPC."
    Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss')) Finished: $($endDateTime.ToString('MM/dd/yy HH:mm:ss')) Elapsed: $timeStr "
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host ""
    Write-Host ""
    # -----------------------------------------
    # -----------------------------------------
}
catch {

    Write-Host " Hit some error!"
    $ScriptName = $PSItem.InvocationInfo.ScriptName
    $Line  = $PSItem.InvocationInfo.Line 
    $ScriptLineNumber = $PSItem.InvocationInfo.ScriptLineNumber
    Write-Host "Error...Name: $ScriptName Line: $Line Script Line Nbr: $ScriptLineNumber"
}

Remove-PSSession -Session $remoteSessionObj
[System.GC]::Collect()

Return


    # -------------
    # C:\Users\johns\AppData\Roaming\J River\Media Center 25\Cover Art\Albums

    

    # -credential $remoteCreds   -ComputerName HTPC 
    Write-Verbose "$($spacer) Getting the remote drive letters"
    $mediaDrives = Invoke-Command -Session  $remoteSessionObj -ScriptBlock { Get-PSDrive -PSProvider FileSystem } 
    Write-Verbose "$($spacer) Found $($mediaDrives.Count) remote drive letters..."
    # $mediaDrives = (Get-PSDrive -PSProvider FileSystem).Name

# :driveLoop foreach ($driveLetter in $driveLetterToNumberMap.Keys | sort)


    $drivesChecked = 0

    :driveLoop foreach ($driveName in $mediaDrives ) {

        $rootString = $null

        # L:\Media2\Video\4KUHD
        $DriveLetter = $($driveName.Name)

        if (-not $TargetMediaDrives.Contains($DriveLetter)) {
            Write-Verbose "$($spacer) Skipping $DriveLetter"
            continue driveLoop;
        }
        $drivesChecked++

        $rootString = $driveName.Root.ToString()

        Write-Verbose ""
        Write-Verbose "$($spacer) $($drivesChecked.ToString().PadLeft(2)): Begin Path check for $rootString"
        Write-Verbose "$($spaceTwo) $('-'*$($($spacer.Length)*10))"

        $mediaDriveNbr = $driveLetterToNumberMap[$DriveLetter]
        $mediaTargetBase = "Media" +  $($mediaDriveNbr.ToString())

        $baseDrivePath = Invoke-Command -Session $remoteSessionObj `
                        -ScriptBlock {  (Join-Path $using:rootString $using:mediaTargetBase)  } 

        $baseDrivePath = Invoke-Command -Session $remoteSessionObj `
                        -ScriptBlock {  (Join-Path $using:baseDrivePath "Music")  } 


        :baseTargetLoop foreach ($musicTargetPath in $musicTargetPaths)
            {

                $targetFullPathDetailExists = $false

                # $baseDriveTargetPath = Join-Path -Path $baseDrivePath -ChildPath $musicTargetPath

                $baseDriveTargetPath = Invoke-Command -Session $remoteSessionObj `
                        -ScriptBlock {  (Join-Path $using:baseDrivePath $using:musicTargetPath)  } 



                # Write-Host "$spacer Debug: Testing $baseDriveTargetPath"
                $targetFullPathDetailExists = Invoke-Command -Session $remoteSessionObj `
                        -ScriptBlock {  ($true -eq (Test-Path $using:baseDriveTargetPath) ) } 


                if (-not $targetFullPathDetailExists)
                    { 
                        Write-Verbose "$($spacer*2) Skipping $baseDriveTargetPath. Path does not exist on $rootString"
                        continue baseTargetLoop; 
                    }

                # Write-Host "$spacer Debug: Pull sub-folders for $baseDriveTargetPath  ($musicTargetPath)"


                $ArtistFolders = Invoke-Command -Session $remoteSessionObj `
                    -ScriptBlock { Param ($localSearchPhrase) Get-ChildItem -Path $using:baseDriveTargetPath `
                        -Filter "*$($localSearchPhrase.ToLower())*" `
                        -Recurse -File -ErrorAction SilentlyContinue  } -ArgumentList $SearchPhrase

                $line = 0
                if ($ArtistFolders.Count -eq 0) {
                    Write-Verbose "$($spacer*2) No files matching *$($SearchPhrase.ToLower())* found in $baseDriveTargetPath."
                    continue baseTargetLoop; 
                }
                Write-Verbose "$($spacer*2) Found $($($ArtistFolders.Count).ToString('N0').PadLeft(4)) music files matching *$($SearchPhrase.ToLower())* in $baseDriveTargetPath."

                # Write-Host ""
                :fileLoop foreach ($file in $files)
                    {
                        $line++

                        $trackNumber = ""
                        $trackName = ""
                        $matchedTitle = $null

                        $fileName = $($file.Name)
                        $filePath = $($file.Directory)
                        $fileExt = $($file.Extension).Replace('.','')

                        $subPath = $($file.Directory).Replace($($baseDriveTargetPath+'\'),'')
                        
                        $AlbumName = Invoke-Command -Session $remoteSessionObj `
                                        -ScriptBlock {  (Split-Path -Path $using:filePath -Leaf)  } 

                        $pathStub = $baseDriveTargetPath = Invoke-Command -Session $remoteSessionObj `
                                        -ScriptBlock {  (Split-Path -Path $using:filePath -Parent)  } 

                        $ArtistName = Invoke-Command -Session $remoteSessionObj `
                                        -ScriptBlock {  (Split-Path -Path $using:pathStub -Leaf)  } 

                        # Could use a regex to match to the actual track name and number
                        $matchedTitle = [regex]::Match($fileName,"(\d{2}) ($ArtistName)\s-\s(.*?)\.($fileExt)")
       
                        $matchWasSuccess = $matchedTitle.Success

                        <#
                            Try alternate artist mappings if default artist did not match:

                            2) 02 Commander Cody & His Lost Planet Airmen - Truckin' And Fuckin'.flac did not match track regex!
                                    (\d{2}) (Commander Cody)\s-\s(.*?)\.(flac)
                        #>
                        if (-not $matchWasSuccess) {
                            if ($alternameArtistMapping.ContainsKey($ArtistName)) {
                                <# Action to perform if the condition is true #>
                                :artistLoop foreach ($altArtist in $($alternameArtistMapping[$ArtistName])) {
                                    $matchedTitle = $null
                                    $matchedTitle = [regex]::Match($fileName,"(\d{2}) ($altArtist)\s-\s(.*?)\.($fileExt)")
                                    $matchWasSuccess = $matchedTitle.Success
                                    if ($matchWasSuccess) {
                                        break artistLoop;
                                    }
                                }
                            }

                        }
                        

                        if ($matchWasSuccess) {
                            <#
                                2) <05>
                                3) <Cody Jinks>
                                4) <Birds>
                                5) <flac>
                            #>
                            $trackNumber = $matchedTitle.Groups[1].Value
                            $trackName = $matchedTitle.Groups[3].Value

                            Write-Debug "$($spacer*1)$($spaceTwo) ---------------------------------------"
                            Write-Debug "$($spacer*2) Matched!"
                            
                            if ($DebugPreference -ne 'SilentlyContinue') {
                                <# Only loop over match groups when -DEBUG is set #>
                                $groupNbr = 0

                                foreach ($matchValue in $($matchedTitle.Groups))
                                    {
                                        $groupNbr++
                                        Write-Debug "$($spacer*2)$($spaceTwo) $($groupNbr.ToString().PadLeft(3))) <$matchValue> "

                                    }
                                    Write-Debug ""
                            }

                        }
                        else {
                            <# Action when all if and elseif conditions are false #>
                            Write-Verbose ""
                            Write-Verbose "$($spacer*3) $($line.ToString().PadLeft(3))) $fileName did not match track regex!"
                            Write-Verbose "$($spacer*4) (\d{2}) ($ArtistName)\s-\s(.*?)\.($fileExt)"
                            Write-Verbose ""
                        }

                        # Debug

                        if ($ArtistName -eq 'Flying Burrito Brothers, The' -and $false) {

                            Write-Host ""
                            Write-Host ""
                            Write-Host "$($spacer*3) $($line.ToString().PadLeft(3))) $($file.FullName)"
                            
                            Write-Host "$($spacer*4) $subPath"
                            Write-Host "$($spacer*4) $pathStub"
                            Write-Host "$($spacer*4) (Artist) $ArtistName"
                            Write-Host "$($spacer*4) (Album) $AlbumName"
                            Write-Host "$($spacer*4) (Track) $trackName"
                            Write-Host "$($spacer*4) (Track Nbr) $trackNumber"
                            Write-Host ""
                            Write-Host "$($spacer*4) $fileName regex debug <$matchWasSuccess>"
                            Write-Host "$($spacer*4) (\d{2}) ($ArtistName)\s-\s(.*?)\.($fileExt)"


                        }
                        # Show:
                        # --> $fileName
                        Write-Verbose "$($spacer*2) $($line.ToString().PadLeft(3))) Checking Artist ($ArtistName) Album ($AlbumName)"
                        Write-Verbose "$($spacer*5)$($spaceTwo) Track ($trackName) Track Nbr ($trackNumber) ($pathStub) <$matchWasSuccess>."
                        Write-Verbose ""

                        if (!$artistDetail.ContainsKey($ArtistName))
                            {
                                $artistDetail[$ArtistName] = @{}
                            }

                        if (-not $($artistDetail[$ArtistName]).ContainsKey($pathStub))
                            {
                                $artistDetail[$ArtistName][$pathStub] = @{}
                            }

                        if (-not $($artistDetail[$ArtistName][$pathStub]).ContainsKey($AlbumName))
                            {
                                $artistDetail[$ArtistName][$pathStub][$AlbumName] = @{}
                            }
                        $artistDetail[$ArtistName][$pathStub][$AlbumName][$trackName] = $line

                        # Test
                        if ($line -gt 5) {
                            <# debug #>
                            break fileLoop;
                        }
                    }

            }
    }

Write-Host ""
Write-Host ""
Write-Host ""


$line = 0
foreach ($Artist in $artistDetail.Keys | sort )
    {
        $line++
        $locationCount = 0

        
        if ($Artist -notlike "*$SearchPhrase*")
            { continue }
        
        Write-Host "$spacer $($line.ToString().PadLeft(3))) $Artist "
        Write-Host " -----------------------------------------------"

        # $artistDetail[$ArtistName][$pathStub][$AlbumName][$trackName] = $line
        foreach ($localPath in $($artistDetail[$Artist]).keys | sort )
            {
                $locationCount++
                Write-Host "$($spacer*3)$($locationCount.ToString().PadLeft(2))) $localPath "

                $albumCount = 0
                if ($($artistDetail[$Artist][$localPath]).Count -gt 0) {
                    <# Action to perform if the condition is true #>
                    foreach ($AlbumName in $($artistDetail[$Artist][$localPath]).keys | sort )
                        {
                            $albumCount++
                            Write-Host "$($spacer*4)$($albumCount.ToString().PadLeft(2))) $AlbumName ($($($artistDetail[$Artist][$localPath][$AlbumName]).Count) Tracks) "
                        }
                    Write-Host ""
                }
            }
        Write-Host ""  
    }

Write-Host ""
Write-Host ""
Write-Host " -----------------------------------------------"

    # $artistDetail[$fileName][$baseDriveTargetPath]
<#
    \\Syn414JNas\Backup\Passthrough
    \\Syn414JNas\Backup\Passthrough\Music
    \\Syn414JNas\Backup\Passthrough\Music\Flac


#>
$BackupDriveDetails = Get-PSDrive -PSProvider FileSystem 

$PassthroughSourcePath = $null

:driveLoop foreach ($driveName in $BackupDriveDetails ) {


    $displayRootString = $null
    $rootString = $null

    $displayRootString = $driveName.DisplayRoot
    $rootString = $driveName.Root.ToString()

    if ($displayRootString -eq '\\syn414jnas\Backup') {
        <# Action to perform if the condition is true #>
        $PassthroughSourcePath = $displayRootString
    }

    Write-Host ""
    Write-Host "$($spacer) Debug: Begin Path check for $rootString ($displayRootString)"
    Write-Host "$($spaceTwo) $('-'*$($($spacer.Length)*10))"

}

$artistFilterPhrase = "*" + $($SearchPhrase.ToLower()) + "*"

if ($PassthroughSourcePath.Length -gt -0) {

    $baseDrivePath = (Join-Path $PassthroughSourcePath "Passthrough")  

    $baseDrivePath = (Join-Path $baseDrivePath "Music")  

    $baseDriveTargetPath = (Join-Path $baseDrivePath $MusicFileSourse) 

    $targetFullPathDetailExists = ($true -eq (Test-Path $baseDriveTargetPath) )  

    $folders = Get-ChildItem -Path $baseDriveTargetPath -Filter $artistFilterPhrase `
                            -Recurse -Directory -ErrorAction SilentlyContinue  | `
                            Sort-Object -Property LastWriteTime -Descending | `
                            Select-Object -First 1


    $folders
}
else {
    <# Action when all if and elseif conditions are false #>
    Write-Host "$($spacer) Cannot find passthrough base:"
}


$timeStr = Get-FormattedTimeString -startTimestamp $startDateTime
$endDateTime = Get-Date
Write-Host ""
Write-Host ""
Write-Host " -------------------------------------------------------------------------------------"
Write-Host "    Completed checking for *$($SearchPhrase)*...in Music on HTPC."
Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss')) Finished: $($endDateTime.ToString('MM/dd/yy HH:mm:ss')) Elapsed: $timeStr "
Write-Host " -------------------------------------------------------------------------------------"
Write-Host ""
Write-Host ""
# -----------------------------------------
# -----------------------------------------
try {
    # Debug 
}
catch {

    Write-Host " Hit some error!"
    $ScriptName = $PSItem.InvocationInfo.ScriptName
    $Line  = $PSItem.InvocationInfo.Line 
    $ScriptLineNumber = $PSItem.InvocationInfo.ScriptLineNumber
    Write-Host "Error...Name: $ScriptName Line: $Line Script Line Nbr: $ScriptLineNumber"
}
finally {
<#Do this after the try block regardless of whether an exception occurred or not#>
# Remove-Item $($TempFile.FullName) -Force
    if (-not $null -eq $remoteSessionObj) {
        Remove-PSSession -Session $remoteSessionObj
    }

[System.GC]::Collect()
}