# 
<#

        FindJRiverDuplicateCoverArt.ps1

        Utilities Project

        JRIver assignments:
        Examine the folders on the HTPC for jpg and other image files.
        Look for albums that have the same cover art (using an MD5 hash of the file)

        List out the candidates

        Jss

        09/03/2023

        To Do: 
            Add Parameters for the target PC
            Improve deduplication.  
            Add support for filtering out compilation aibums (e.g. Richard Blade's ..)
            Move Hash from string to separate module
            

#>
# ---------------
# https://xpertkb.com/compute-hash-string-powershell/
function get-hash([string]$textToHash)
{
    $hasher = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $toHash = [System.Text.Encoding]::UTF8.GetBytes($textToHash)
    $hashByteArray = $hasher.ComputeHash($toHash)
    foreach ($byte in $hashByteArray)
    {
        $result += "{0:X2}" -f $byte
    }
    return $result
}
# https://stackoverflow.com/questions/71401162/creating-correct-sha256-hash-in-powershell
function hash($request)
{
    $sha256 = New-Object -TypeName System.Security.Cryptography.SHA256Managed
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    
    $hash = [System.BitConverter]::ToString($sha256.ComputeHash($utf8.GetBytes($request)))
    return $hash.replace('-', '').toLower()
}
# ============================================================================================
#  Get-HashFromStringStream 
# ============================================================================================
# 
# https://infosecscout.com/get-md5-hash-in-powershell/
Function Get-HashFromStringStream
{
    [CmdletBinding(PositionalBinding = $False)]
    Param (

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $stringToHash,

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string] $hashAlgo = 'MD5',

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [bool] $showDetails = $false

    )
    Begin
    {
        # 
        [string]$private:hashedString = $null
        $private:hashedStringResults = $null
        $private:stringAsStream = $null
        $private:writer = $null

        
    }
    Process
    {
        

        if ($showDetails)
        {
            Write-Host ""
            Write-Host " --> Hash $stringToHash using the $hashAlgo algo. "


        }

        $stringAsStream = [System.IO.MemoryStream]::new()

        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($stringToHash)
        $writer.Flush()

        $stringAsStream.Position = 0
            
        $hashedStringResults = Get-FileHash -InputStream $stringAsStream -Algorithm $hashAlgo

        $hashedString = $hashedStringResults.Hash

        if ($showDetails)
        {
            Write-Host " --> The $hashAlgo hash of $stringToHash resulted in $hashedString. "
            Write-Host ""

        }

    }
    End
    {

        [string] $hashedString
    }
}
# ============================================================================================
#  <End> Get-HashFromStringStream
# ============================================================================================



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

# C:\Users\johns\AppData\Roaming\J River\Media Center 25\Cover Art\Albums

# Big Brother & The Holding Company - Cheap Thrills.jpg


[hashtable]$coverVersions = @{}

[System.Collections.ArrayList]$coverArtExts = @()
[System.Collections.ArrayList]$pathsToCheck = @()


$variableExists = ((Get-Variable -Name hashToFilePath -ErrorAction SilentlyContinue) -ne $null    )  

if ($variableExists)
{
    Remove-Variable -Name hashToFilePath -Force
}
[hashtable]$hashToFilePath = @{}
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
[hashtable]$pathToHashPath = @{}
[hashtable]$artistNameToHash = @{}
[hashtable]$albumToHashPath = @{}
[hashtable]$imageFileToHashPath = @{}

[string]$local:spaceTwo = $(' ' * 2)
[string]$local:spacer = $(' ' * 4)


$jRiverPathSuffix = "Cover Art\Albums"
$jRiverVersionStub = "Media Center"

$userPathStub = 'Users\johns'
$searchPhrase = "Cover Art"

$jriverVersions = @('25', '26', '27', '28', '29', '30', '31')

$mediaDrives = @("I", "J", "K", "L")

$driveLetterToNumberMap = @{"I" = 1
    "J"                         = 3
    "K"                         = 4
    "L"                         = 2
}



[string]$Private:qualifiedCoverArtFile = $null

try
{
    $hashToFilePath.Clear()
    # -----------------------------------------
    $startDateTime = Get-Date
    Write-Host ""
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host "    Starting the check for cover art on HTPC"
    Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss'))"
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host ""

    # -------------
    # C:\Users\johns\AppData\Roaming\J River\Media Center 25\Cover Art\Albums

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

    # -credential $remoteCreds   -ComputerName HTPC 
    Write-Host "$($spacer) Getting the remote drive letters"
    $mediaDrives = Invoke-Command -Session $remoteSessionObj -ScriptBlock { Get-PSDrive -PSProvider FileSystem } 
    Write-Host "$($spacer) Found $($mediaDrives.Count) remote drive letters..."
    # $mediaDrives = (Get-PSDrive -PSProvider FileSystem).Name

    # -------------
    Write-Host ""
    Write-Host ""
    # Sample Path
    # C:\Users\johns\AppData\Roaming\J River\Media Center 30\Cover Art\Albums
    $baseCheckPath = "C:\Users\johns\AppData\Roaming\J River\"
    $versionCount = 0
    $coverArtExts.Clear()

    Write-Host "$($spacer) Getting the remote file extensions for the Media Player versions ($jriverVersions)"

    :versionLoop foreach ($jRiverVersion in $jriverVersions )
    {
        $versionCount++
        $targetFullPathDetailExists = $false

        $jRiverVersion = $jRiverVersionStub + " " + $jRiverVersion
        $targetPathBase = Join-Path -Path $baseCheckPath -ChildPath $jRiverVersion
        $targetPath = Join-Path -Path $targetPathBase -ChildPath $jRiverPathSuffix

        $InputDisplayLeaf = Get-DisplayLeafPath -basePath $targetPath -levelsToShow 4

        $targetFullPathDetailExists = Invoke-Command -Session $remoteSessionObj -ScriptBlock { ($true -eq (Test-Path $using:targetPath) ) } 

        Write-Verbose "$($spacer) $($versionCount.ToString().PadLeft(3))) Checking $jRiverVersion  for distinct file extensions <..\$InputDisplayLeaf><$targetFullPathDetailExists>."


        if ($targetFullPathDetailExists)
        {
            <# Action to perform if the condition is true #>
            Write-Verbose ""
            # $InputDisplayLeaf = Get-DisplayLeafPath -basePath $targetPath -levelsToShow 4
            $results = Invoke-Command -Session $remoteSessionObj -ScriptBlock { Param ($localPath, $localSpace)

                [System.Collections.ArrayList] $localExtensions = @()
                                                                    
                Write-Verbose "$($localSpace*2) $localPath ($($localExtensions.Count))"


                Get-ChildItem -Path $localPath `
                    -Recurse -File -Force -ErrorAction SilentlyContinue `
                | Where-Object { $localExt = $_.Extension
                    # $localExt = $($localExt.Replace('.',''));

                    # Write-Host "$($localSpace*2) $localExt ($($localExtensions.IndexOf($localExt)))";

                    if ($($localExtensions.IndexOf($localExt)) -lt 0)
                    {
                        <# Action to perform if the condition is true #>
                        Write-Verbose "$($localSpace*2) Adding $localExt"
                        $localExtensions.Add($localExt)
                    }
                }
                $localExtensions
                if ($localExtensions.Count -gt 1)
                {
                    <# Action to perform if the condition is true #>
                    $localExtensions
                }
                else
                {
                    <# Action when all if and elseif conditions are false #>
                    @($localExtensions.Count)
                }
        
            } -ArgumentList $targetPath, $spacer

            Write-Verbose ""
            Write-Verbose " -------------------------"
            foreach ($localExtension in $results)
            {
                <# $currentItemName is the current item #>
                if (-not $coverArtExts.Contains($localExtension))
                {
                    <# Action to perform if the condition is true #>
                    [void]$coverArtExts.Add($localExtension)
                }
                        
            }
        }
    }

    Write-Host ""
    Write-Host ""


    $drivesChecked = 0

    :driveLoop foreach ($driveName in $mediaDrives )
    {
        # L:\Media2\Video\4KUHD
        # Initialize the paths to check for the target drive:
        $pathsToCheck.Clear()

        $drivesChecked++

        # --------------------------------------------------

        $driveRootString = $null
        $displayRootString = $null
        $rootString = $null
        $targetPathDetailExists = $false
        $targetFullPathDetailExists = $false
        # --------------------------------------------------

        $displayRootString = $driveName.DisplayRoot
        $rootString = $driveName.Root.ToString()

        Write-Host ""
        Write-Host "$($spacer) Debug: Begin Path check for $rootString"
        Write-Host "$($spaceTwo) $('-'*$($($spacer.Length)*10))"

        if (($null -eq $displayRootString -or $displayRootString.Length -eq 0) -and $rootString.Contains($userPathStub))
        {
            <# Action to perform if the condition is true #>
            $driveRootString = $rootString
        }
        elseif ($null -eq $displayRootString -or $displayRootString.Length -eq 0)
        {
            <# Action to perform if the condition is true #>

            # Under PowerShell Core Join-Path checks the local file system for the file
            # $tempPath = Join-Path -Path $driveDtl -ChildPath $userPathStub -ErrorAction Ignore
            # $tempPath = Join-Path -Path $driveDtl -ChildPath $userPathStub -ErrorAction SilentlyContinue

            $tempPath = $rootString + $userPathStub

            $driveRootString = $tempPath
    
        }
        else
        {
            <# Action when all if and elseif conditions are false #>
            $driveRootString = $displayRootString
        }
        # $userPathStub

        if ($null -eq $driveRootString)
        {
            <# Action to perform if the condition is true #>
            Write-Host "$($spacer)$($spaceTwo) $($drivesChecked.ToString().PadLeft(3))) Warning: Invalid Drive String <$driveRootString><$displayRootString> for $($driveName.Root)"
        }
        # ($($drive.DisplayRoot))($($drive.Root))

        <#
                Check a subset of the paths:

            #>
        Write-Host ""
        Write-Host "$($spacer)$($spaceTwo) Debug: AppData/J River Path check:"

        $versionCount = 0
        <# 
            :versionLoop foreach ($jRiverVersion in $jriverVersions )
                {
                    $versionCount++
                    $targetFullPathDetailExists = $false

                    # C:\Users\johns\AppData\Roaming\J River\Media Center 30\Cover Art\Albums
                    $jRiverVersion = $jRiverVersionStub + " " + $jRiverVersion

                    $jRiverStub = $jRiverCoverArtBase + "\" + $jRiverVersion
                    # $targetPathBase = Join-Path -Path $driveRootString -ChildPath $jRiverVersion
                    Write-Host ""
                    Write-Host "$($spacer) Checking for the JRiver Folder folder: <JRiver Path> $jRiverStub <Root> $driveRootString <Version> $jRiverVersion "

                    $targetPath = Invoke-Command -Session $remoteSessionObj `
                            -ScriptBlock {  Join-Path -Path $using:driveRootString -ChildPath $using:jRiverStub } 

                    
                    # $targetPath = Join-Path -Path $targetPathBase -ChildPath $jRiverPathSuffix
                    $InputDisplayLeaf = Get-DisplayLeafPath -basePath $targetPath -levelsToShow 4

                    $targetPathDetailExists = Invoke-Command -Session $remoteSessionObj `
                                                -ScriptBlock {  ($true -eq (Test-Path $using:targetPath) ) } 

                    Write-Host "$($spacer) $($versionCount.ToString().PadLeft(3))) Checking ..\$InputDisplayLeaf> from $rootString <$targetFullPathDetailExists>."

                    if ($targetPathDetailExists) {
                        
                            Write-Host ""
                            if (-not $pathsToCheck.Contains($targetPath)) {
                                
                                [void]$pathsToCheck.Add($targetPath)
                            }
                        }
                    
                }
            #>
        # C:\Users\johns\AppData\Roaming\J River
        $filterString = '*Media Center*'
        $targetPathDetail = Invoke-Command -Session $remoteSessionObj `
            -ScriptBlock { Get-ChildItem -Path $using:driveRootString -Recurse -Filter $using:filterString `
                -Directory -Force -ErrorAction SilentlyContinue }

        # 
        Write-Host "$($spacer)$($spaceTwo) Checking for the AppData/J River folder: <Root> $rootString <Drive Base> $driveRootString <Candidate Paths> $($targetPathDetail.COunt))"

        $tempFolderCount = 0 
        <#
            | Where-Object { $localExt = $_.Extension;
                    # $localExt = $($localExt.Replace('.',''));

                    # Write-Host "$($localSpace*2) $localExt ($($localExtensions.IndexOf($localExt)))";

                    if ($($localExtensions.IndexOf($localExt)) -lt 0) {
                            Write-Verbose "$($localSpace*2) Adding $localExt"
                            $localExtensions.Add($localExt);
                        }
                    }
            #>
        Write-Host "$($spacer)$($spaceTwo) Debug: AppData/J River check:"
        :folderLoop foreach ($targetPath in $targetPathDetail)
        {
            $tempFolderCount++
            $targetPathName = $($targetPath.FullName.ToString())
            $InputDisplayLeaf = Get-DisplayLeafPath -basePath $targetPathName -levelsToShow 4

            $pathToTest = $targetPathName
            $pathToTest += '*' 

            $targetPathDetailExists = Invoke-Command -Session $remoteSessionObj `
                -ScriptBlock { (Test-Path -Path $using:targetPathName) } 

            Write-Host "$($spacer)$($spaceTwo) $($tempFolderCount.ToString().PadLeft(3))) Checking <$pathToTest> from $rootString <$targetFullPathDetailExists>."

            if (-not $pathsToCheck.Contains($targetPathName))
            {
                <# Action to perform if the condition is true #>
                [void]$pathsToCheck.Add($targetPathName)
            }

            if ($targetPathDetailExists)
            {
                <# Action to perform if the condition is true #>
                            
            }

        }
        Write-Host ""


        # Check for other JRiver paths
        # Check for Media XX
        $targetFullPathDetailExists = $false
        $drive = $rootString.Replace(":\", "")
        $mediaDriveNbr = $driveLetterToNumberMap[$drive]
        $versionCount++
        Write-Host "$($spacer)$($spaceTwo) Debug: Alternate Path check:"
        Write-Host "$($spacer)$($spaceTwo) Checking for the MediaXX folder: <Root> $rootString <Drive> $drive <Drive Number> $mediaDriveNbr"

        if ($mediaDriveNbr.Length -gt 0)
        {
            <# Action to perform if the $mediaDriveNbr.Length -gt 0 is true #>
            $mediaTargetBase = "Media" + $($mediaDriveNbr.ToString())
        }
        else
        {
            <# Action when all if and elseif conditions are false #>
            $mediaTargetBase = "Media"
        }
        
        # $baseDrivePath = Join-Path -Path $rootString -ChildPath $mediaTargetBase

        $baseDrivePath = Invoke-Command -Session $remoteSessionObj `
            -ScriptBlock { Join-Path -Path $using:rootString -ChildPath $using:mediaTargetBase }

        $baseDrivePath = Invoke-Command -Session $remoteSessionObj `
            -ScriptBlock { Join-Path -Path $using:baseDrivePath -ChildPath 'Music' }

        $targetPathDetailExists = Invoke-Command -Session $remoteSessionObj -ScriptBlock { ($true -eq (Test-Path $using:baseDrivePath) ) } 

        Write-Host "$($spacer)$($spaceTwo) $($versionCount.ToString().PadLeft(3))) Checking whether $baseDrivePath path exists from $rootString.  <$targetPathDetailExists>."

        # $musicTargetPaths

        if ($targetPathDetailExists)
        {
            <# Action to perform if the condition is true #>
            if (-not $pathsToCheck.Contains($baseDrivePath))
            {
                <# Action to perform if the condition is true #>
                [void]$pathsToCheck.Add($baseDrivePath)
            }
        }

        # Check the Base music path:
        # C:\Users\johns\Music\HDtracks
        $versionCount++
        Write-Host ""
        Write-Host "$($spacer)$($spaceTwo) Checking for the Music folder: <Root> $rootString <Drive> $drive <Drive Number> $mediaDriveNbr"


        $targetFullPathDetailExists = $false
        $mediaTargetBase = 'Music'
        # $baseMusicPath = Join-Path -Path $driveRootString -ChildPath 'Music'

        $baseMusicPath = Invoke-Command -Session $remoteSessionObj `
            -ScriptBlock { Join-Path -Path $using:driveRootString -ChildPath $using:mediaTargetBase }



        $targetPathDetailExists = Invoke-Command -Session $remoteSessionObj -ScriptBlock { ($true -eq (Test-Path $using:baseMusicPath) ) } 

        Write-Host "$($spacer)$($spaceTwo) $($versionCount.ToString().PadLeft(3))) Checking whether $baseMusicPath path exists from $rootString.  <$targetPathDetailExists>."

        if ($targetPathDetailExists)
        {
            <# Action to perform if the condition is true #>
            if (-not $pathsToCheck.Contains($baseMusicPath))
            {
                <# Action to perform if the condition is true #>
                [void]$pathsToCheck.Add($baseMusicPath)
            }
        }

        # $targetPathDetail = Get-ChildItem -Path $driveRootString -Recurse -Directory | Select-Object FullName
        # -Session  $remoteSessionObj
        <#
            $targetPathDetail = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock { Get-ChildItem -Path $using:driveRootString -Recurse `
                                        -Directory -Exclude $using:excludeList -Force -ErrorAction SilentlyContinue |`
                                        Select-Object FullName }
            #>


        Write-Host ""
        Write-Host "$($spacer) $($drivesChecked.ToString().PadLeft(3))) Checking for album art from $driveRootString. Found $($pathsToCheck.Count) paths to scan. "
        Write-Host "$($spaceTwo) -----------------------------------------------------------------------------------------------------------------------------------"
        Write-Host ""

        Write-Host "$($spacer) $($versionCount.ToString().PadLeft(3))) <Debug> Checking ($($pathsToCheck)) from $rootString."
        Write-Host ""

        $pathsChecked = 0


        :folderLoop foreach ($targetPathName in $pathsToCheck)
        {
            # $targetPathName = $($targetPath.FullName.ToString())
            $subPath = $($targetPathName.Replace($($driveRootString + '\'), ''))
            $targetFullPathDetailExists = $false

            Write-Host "$($spacer) $($pathsChecked.ToString().PadLeft(3))) <Debug> Checking ($targetPathName) from $rootString."
            Write-Host ""

            if ($subPath.StartsWith('.nuget'))
            {
                <# Action to perform if the condition is true #>
                continue folderLoop
            }
            elseif ($subPath.StartsWith('.vscode'))
            {
                <# Action to perform if the condition is true #>
                continue folderLoop
            }
            elseif ($subPath.StartsWith('Music\JRiver Conversion Cache'))
            {
                <# Action to perform if the condition is true #>
                # Music\JRiver Conversion Cache
                # continue folderLoop;
            }

            $targetFullPathDetailExists = Invoke-Command -Session $remoteSessionObj `
                -ScriptBlock { ($true -eq (Test-Path $using:targetPathName) ) } 

            $InputDisplayLeaf = Get-DisplayLeafPath -basePath $targetPathName -levelsToShow 4 

            Write-Verbose "$($spacer) $($pathsChecked.ToString().PadLeft(3))) Checking album art from ..\$subPath..."

            # Validate that the path exists:
            if (-not $targetFullPathDetailExists)
            {
                Write-Host "  Warning: <$targetPathName> ..\$subPath does not exist. Skipping."
                continue folderLoop
            }
            <#
                    if (-not $targetPathName.Contains($searchPhrase))
                        {
                            Write-Verbose "$($spacer) Warning: ..\$InputDisplayLeaf does not contain $searchPhrase. Skipping."
                            continue folderLoop;
                        }
                    #>

            $pathsChecked++

            # $coverArtDetails = Get-ChildItem -Path $using:targetPathName -Recurse -File
            $coverArtDetails = Invoke-Command -Session $remoteSessionObj `
                -ScriptBlock { Get-ChildItem -Path $using:targetPathName -Recurse `
                    -File -Force -ErrorAction SilentlyContinue } 

            if ($($coverArtDetails.Count) -gt 0)
            {
                <# Action to perform if the condition is true #>
                Write-Host "$($spacer) $($pathsChecked.ToString().PadLeft(3))) Checking $subPath for $searchPhrase."
                Write-Host "$($spacer*2)  Found $($coverArtDetails.Count) files to scan. "
                Write-Host "$($spaceTwo) ---------------------------------------------------------------------------------------------------------------------------"
                Write-Host ""
            }
            elseif ($pathsChecked % 100 -eq 0)
            {
                <# Action to perform if the condition is true #>

                Write-Host "$($spacer) Checking $subPath for $searchPhrase."
                Write-Host "$($spacer*2)  Path $($pathsChecked.ToString('N0').PadLeft(5)) of $($targetPathDetail.Count.ToString('N0').PadLeft(5))."
                Write-Host "$($spacer*2)  Found $($coverArtDetails.Count) files to scan. "
                Write-Host "$($spaceTwo) ---------------------------------------------------------------------------------------------------------------------------"
                Write-Host ""

            }
                
            $itemCount = 0

            :fileLoop foreach ($fileItem in $coverArtDetails)
            {
                $qualifiedCoverArtFile = $null
                $SourceHashResults = $null

                $SourceHashVal = $null

                # Skip non-image files
                if (-not  $coverArtExts.Contains($($fileItem.Extension)) )
                {
                    <# Action to perform if the condition is true #>
                    continue fileLoop
                }
                            
                $itemCount++

                $qualifiedCoverArtFile = $($fileItem.FullName)

                $FileName = $($fileItem.Name)
                $AlbumFileName = $fileItem.BaseName

                # Whiskeytown - Return of the Grievous Angel_ a Tribute to Gram Parsons.jpg
                # Break out Album if possible
                $albumName = "Unknown"
                $artistName = "Unknown"
                $fileItemPath = "Unknown"

                if ($($fileItem.Directory).Length -gt 0)
                {
                    <# Action to perform if the condition is true #>
                    $fileItemPath = $($fileItem.Directory)
                }
                            
                if ($FileName.Contains('-'))
                {

                    <#
                                    Need to accomodate names where there is a dash in the album/artist name 
                                    such as these: <B-52s, The - Just Can't Get Enough_ New Wave Hits of the '80s, Volume 3
                                    and D-Day - Just Can't Get Enough_ New Wave Hits of the '80s, Volume 1.jpg
                                    , The -

                                #>
                    $hyphenMatches = ($FileName | Select-String "-" -AllMatches).Matches.Index

                    $theSearchString = ', The -'
                    $theSearchStringLen = $($theSearchString.length)

                    if ($FileName.IndexOf($theSearchString) -gt 0)
                    {
                        <# Action to perform if the condition is true #>
                        $theSearchStringStartPos = $FileName.IndexOf($theSearchString)

                        $artistName = $FileName.Substring(0, $($theSearchStringStartPos + $theSearchStringLen - 1))
                        $albumName = $FileName.Substring($($theSearchStringLen + 1), $($FileName.Length - $($theSearchStringLen + 1)))

                    }
                    elseif ($hyphenMatches.Count -gt 1)
                    {
                        <# There are at least two "-" chars in the string.  Use the second match #>
                        $theHyphenStartPos = $hyphenMatches[1]  # The second match

                        $artistName = $FileName.Substring(0, $($theHyphenStartPos - 1))
                        $albumName = $FileName.Substring($($theHyphenStartPos + 1), $($FileName.Length - $($theHyphenStartPos + 1)))
                    }
                    else
                    {
                        <# Action when all if and elseif conditions are false #>
                        $artistName = $FileName.Substring(0, $($FileName.IndexOf('-')) - 1)
                        $albumName = $FileName.Substring($($FileName.IndexOf('-')) + 1, $($FileName.Length - $($($FileName.IndexOf('-')) + 1)))
                    }
                                
                    # ($albumName, $artistName) = $FileName.Split('-')
                    $albumName = $($albumName.Trim())
                    $artistName = $($artistName.Trim())
                }
                if ($($albumName.Length) -eq 0 `
                        -or $($artistName.Length) -eq 0 `
                )
                {
                    <# Action to perform if the condition is true #>
                            
                    Write-Host ""
                    Write-Host "$($spacer*2)----"
                    Write-Host "$($spacer*2) Debug:      FileName <$FileName> "
                    Write-Host "$($spacer*2) Debug:     albumName <$albumName> <$($albumName.Length)>"
                    Write-Host "$($spacer*2) Debug:      artistName <$artistName> <$($artistName.Length)>"
                    Write-Host "$($spacer*2) Debug:      artistName <$($artistName.GetType())> - Type< $($($artistName.GetType()) -ne 'string')>"
                    Write-Host "$($spacer*2)----"
                }
                $pathHashResults = Get-HashFromStringStream -stringToHash $fileItemPath
                $albumHashResults = Get-HashFromStringStream -stringToHash $albumName
                $artistNameHashResults = Get-HashFromStringStream -stringToHash $artistName

                if (-not $pathToHashPath.ContainsKey($pathHashResults))
                {
                    $pathToHashPath[$pathHashResults] = $fileItemPath

                }

                if (-not $artistNameToHash.ContainsKey($artistNameHashResults))
                {
                    $artistNameToHash[$artistNameHashResults] = $artistName

                }

                if (-not $albumToHashPath.ContainsKey($albumHashResults))
                {
                    $albumToHashPath[$albumHashResults] = $albumName

                }

                            
                # $SourceHashResults = Get-FileHash -Path $qualifiedCoverArtFile -Algorithm MD5

                $SourceHashResults = Invoke-Command -Session $remoteSessionObj `
                    -ScriptBlock { Get-FileHash -LiteralPath $using:qualifiedCoverArtFile -Algorithm MD5 } 
                            
                $SourceHashVal = $SourceHashResults."Hash"

                            

                if ($SourceHashVal.Length -gt 0)
                {
                                
                    if (-not $imageFileToHashPath.ContainsKey($SourceHashVal))
                    {
                        <# Action to perform if the condition is true #>
                        $imageFileToHashPath[$SourceHashVal] = $FileName
                    }


                            
                    if (-not $hashToFilePath.ContainsKey($SourceHashVal))
                    {
                        <# Action to perform if the condition is true #>
                        $hashToFilePath[$SourceHashVal] = @{}
                    }

                    if (-not $($hashToFilePath[$SourceHashVal]).ContainsKey($albumName))
                    {
                        <# Action to perform if the condition is true #>
                        $hashToFilePath[$SourceHashVal][$albumHashResults] = @{}
                    }

                    if (-not $($hashToFilePath[$SourceHashVal][$albumHashResults]).ContainsKey($artistNameHashResults))
                    {
                        <# Action to perform if the condition is true #>
                        $hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults] = @{}
                    }
                    if ($false)
                    {
                        Write-Host "$($spacer)$($spaceTwo) ----"

                        Write-Host "$($spacer*2) Debug: <$($($hashToFilePath[$SourceHashVal]).Count)><$($($hashToFilePath[$SourceHashVal][$albumHashResults]).Count)><$($($hashToFilePath[$SourceHashVal][$albumHashResults][$artistName]).Count)>"
                        Write-Host "$($spacer*2) Debug: SourceHashVal <$SourceHashVal>"
                        Write-Host "$($spacer*2) Debug:     albumName <$albumName>"
                        Write-Host "$($spacer*2) Debug:     albumName <$albumHashResults> - hash"
                                    
                        Write-Host "$($spacer*2) Debug:      artistName <$artistName>"
                        Write-Host "$($spacer*2) Debug:      artistName <$artistNameHashResults> - hash"

                        Write-Host "$($spacer*2) Debug:      FileName <$FileName>"
                        Write-Host "$($spacer*2) Debug:  fileItemPath <$fileItemPath>"
                        Write-Host "$($spacer*2) Debug:  fileItemPath <$pathHashResults> - Hash"
                                    
                        Write-Host "$($spacer*2) Debug:          Keys <($($($hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults]).Keys)))>"
                    }
                                
                    <#
                                if (-not $($hashToFilePath[$SourceHashVal][$albumName][$artistName]).ContainsKey($fileItemPath)) {
                                    
                                    
                                }
                                #>
                    $hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults][$pathHashResults] = ""
                    $hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults][$pathHashResults] = $FileName

                    if ($SourceHashVal -eq '008CDA884E60127FD66047D8519F9DFB')
                    {
                        Write-Host "$($spacer) ----"
                        Write-Host ""
                    }
                }
                else
                {
                    <# Action when all if and elseif conditions are false #>
                    Write-Host "$($spacer)$($spaceTwo) Warning: <$FileName> did not generate a hash <$SourceHashVal> <>."
                }

                if ($coverVersions.ContainsKey($FileName))
                {
                    <# Update the existing version #>
                                

                }
                else
                {
                    <# Add new #>
                    $coverVersions[$FileName] = @{}
                                
                }
                $coverVersions[$FileName][$targetPathName] = $SourceHashVal

                if ($itemCount % 500 -eq 0)
                {
                    Write-Host ""
                    Write-Host "$($spacer)$($spaceTwo) $($itemCount.ToString().PadLeft(3))) Found in ..\$InputDisplayLeaf "
                    Write-Host "$($spacer*2)$($spaceTwo) File: <$AlbumFileName>"
                    Write-Host "$($spacer*2)$($spaceTwo) Hash Value: $SourceHashVal"
                    Write-Host "$($spacer*2)$($spaceTwo) File $($itemCount.ToString('N0').PadLeft(5)) of $($($coverArtDetails.Count).ToString('N0').PadLeft(5))."
                }

                            

            }  
            
        }
        <#
                        $logConflictFileDetails = Get-ChildItem -Path $SkyWeatherEventDataPath -Recurse -Filter $inputFileMask | sort | `
                                        Where-Object { $_.CreationTime -gt ($AsOfDate.AddDays(-$DaysBackToCheck))}
                    #>
    }
    
    $songCount = 0
    # Debug
    # $hashToFilePath[$SourceHashVal][$albumName][$artistName][$($fileItem.Directory)] = $fileName
    # Prep for output
    $TempFile = New-TemporaryFile

    $OutLogRow = ""
    Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

    $OutLogRow = "$($spaceTwo)----------------------------------------------------------------"
    Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

    $OutLogRow = ""
    Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

    :hashLoop foreach ($SourceHashVal in $hashToFilePath.Keys | Sort-Object)
    {
        <# $AlbumFileName is the current item #>

        if ($($hashToFilePath[$SourceHashVal]).Count -eq 1)
        {
            <# Action to perform if the condition is true #>
            continue hashLoop
        }
        $songCount++

        $imageFileName = $imageFileToHashPath[$SourceHashVal]

        $OutLogRow = "$($spacer)$($spaceTwo) $($songCount.ToString().PadLeft(3))) Image Hash Key $SourceHashVal  <$imageFileName> "
        Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default
        $OutLogRow = "$($spaceTwo)----------------------------------------------------------------"
        Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

        $pathCount = 0
        foreach ($albumHashResults in $($hashToFilePath[$SourceHashVal]).Keys | Sort-Object )
        {
            <# $targetPathName is the current item #>
            $pathCount++
            $albumName = $albumToHashPath[$albumHashResults]
            <#
                $hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults][$pathHashResults]
                $pathToHashPath
                $albumToHashPath
                $artistNameToHash
            #>
            
            foreach ($artistNameHashResults in $($hashToFilePath[$SourceHashVal][$albumHashResults]).Keys | Sort-Object )
            {

                $artistName = $artistNameToHash[$artistNameHashResults]

                # $FilePath = $hashToFilePath[$SourceHashVal][$FileName]

                $OutLogRow = "$($spacer*2)$($spaceTwo) $($pathCount.ToString().PadLeft(3))) [$albumName]"
                Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

                $OutLogRow = "$($spacer*3)$($spaceTwo)  --> <$artistName>" 
                Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

                foreach ($pathHashResults in $($hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults]).Keys | Sort-Object )
                {
                    $FilePath = $pathToHashPath[$pathHashResults] 
                    $imageFileName = $hashToFilePath[$SourceHashVal][$albumHashResults][$artistNameHashResults][$pathHashResults]
                    
                    $OutLogRow = "$($spacer*3)$($spaceTwo)  --> Image File: <$imageFileName>"
                    Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

                    $OutLogRow = "$($spacer*3)$($spaceTwo)  --> <$FilePath> " 
                    Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default
                    
                }
            }


        }

        $OutLogRow = ""
        Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default
        
    }  

    $OutLogRow = "$($spaceTwo)----------------------------------------------------------------"
    Add-Content -Path $($TempFile.FullName) -Value $OutLogRow -Encoding Default

    Start-Process notepad++ $($TempFile.FullName)

    Write-Host ""

    $timeStr = Get-FormattedTimeString -startTimestamp $startDateTime
    $endDateTime = Get-Date
    Write-Host ""
    Write-Host ""
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host "    Completed checking for cover art on HTPC."
    Write-Host "    Started: $($startDateTime.ToString('MM/dd/yy HH:mm:ss')) Finished: $($endDateTime.ToString('MM/dd/yy HH:mm:ss')) Elapsed: $timeStr "
    Write-Host " -------------------------------------------------------------------------------------"
    Write-Host ""
    Write-Host ""
    # -----------------------------------------
    # -----------------------------------------
}
catch
{


}
finally
{
    <#Do this after the try block regardless of whether an exception occurred or not#>
    # Remove-Item $($TempFile.FullName) -Force

    Remove-PSSession -Session $remoteSessionObj
    [System.GC]::Collect()
}
