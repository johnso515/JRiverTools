# ============================================================================================
# <Start> GetArtistPathFromHTPC
# ============================================================================================
<#
     Get the Local Paths from the HTPC for the passed set of artists and music sources
#>
<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


function GetArtistPathFromHTPC {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        # Parameter help description
        # Parameter help description
        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateNotNullOrEmpty()]
        [string[]] $ArtistNamesToFind, 

        # Note:  We should add this as a class
        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateSet("Amazon MP3"
                    , "Bandcamp"
                    , "Flac"
                    , "HDTracks"
                    , "Wma"
                    , "MP3")]
        [string[]] $MusicFileSourses,

        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateNotNullOrEmpty()]
        $remoteSessionObj
        
    )
    
    begin {
        $private:spacer = $(" "*4)
        $private:spaceTwo = $(" "*2)

        [array]$private:TargetMediaDrives = @("I", "J", "K", "L")

        [hashtable]$private:driveLetterToNumberMap = @{"I" = 1;
                            "J" = 3;
                            "K" = 4;
                            "L" = 2;
                            }

        [PSCustomObject]$private:HTPCArtistPathObject = $null

        <# Working Variables #>

        $private:curDriveObj = $null

        $private:ArtistFolders = $null

        [string]$private:artistTag = $null

        [hashtable]$private:alternameArtistMapping = @{'Commander Cody' = @('Commander Cody & His Lost Planet Airmen'
                                                            );
                                            }
        <# 
            Get the initial information about the drive structure on the HTPC
        #>
            
        # Turn off Verbose if set
        $oldVerbose = $VerbosePreference
        $VerbosePreference = 'SilentlyContinue'

        [System.Collections.ArrayList]$local:SourcePathsToCheck = @()
        $private:MediaSourcePathObjs = Get-MusicPathsFromHTPCForMusicSource -MusicFileSourses $SourcesToCheck -remoteSessionObj $remoteSessionObj 
        # Set it back
        $VerbosePreference = $oldVerbose

        $MediaSourcePathObjs | ForEach-Object {

            if ($null -ne $_.Path) {
                <# Suppress any null paths.  
                    A null path causes the Get-ChildItem to drop out of the FileSystem provider
                    which, in turn, causes the -Directory param to fail (it is not available with other provider types)
                #>
                if (-not $SourcePathsToCheck.Contains($($_.Path))) {
                    <# Action to perform if the condition is true #>
                    [void]$SourcePathsToCheck.Add($_.Path)
                }
            }
        }

        Write-Verbose "$($spacer*2) Found ($SourcePathsToCheck)"
    }
    
    process {
        # GetArtistPathFromHTPC

        try {
            
            # [System.String[]]$LogsToGather = @('', '')

            Write-Verbose ""
            if ($ArtistNamesToFind.Length -gt 0) {
                <# There are artist name fragments to check #>

                :artistLoop foreach ($ArtistName in $ArtistNamesToFind) {
                    <#
                        \\Syn414JNas\Backup\Passthrough
                        \\Syn414JNas\Backup\Passthrough\Music
                        \\Syn414JNas\Backup\Passthrough\Music\Flac
                    #>

                    Write-Verbose "$($spacer*2) Looking for paths for $ArtistName "
                    Write-Verbose "$($spacer*1)$($spaceTwo) $('-'*30)"

                    $ArtistFolders = Invoke-Command -Session $remoteSessionObj `
                                            -ScriptBlock { Param ($localSearchPhrase, $pathArray) Get-ChildItem -Path $pathArray `
                                                -Directory  -Filter $localSearchPhrase `
                                                -ErrorAction SilentlyContinue  } -ArgumentList $ArtistName, $SourcePathsToCheck

                    Write-Verbose "$($spacer*2) Debug" 
                    $line = 0
                    if ($ArtistFolders.Count -eq 0) {

                        <#
                            Check Alternate ArtistNames
                        #>
                        if ($alternameArtistMapping.ContainsKey($ArtistName)) {
                            <# Action to perform if the condition is true #>
                            :artistLoop foreach ($altArtist in $($alternameArtistMapping[$ArtistName])) {

                                $altArtistFolders = Invoke-Command -Session $remoteSessionObj `
                                                        -ScriptBlock { Param ($localSearchPhrase) Get-ChildItem -Path $using:SourcePathsToCheck `
                                                            -Directory -Filter $localSearchPhrase -ErrorAction SilentlyContinue  } -ArgumentList $altArtist
                                                
                                if ($altArtistFolders.Count -gt 0) {
                                    $altArtistFolders | ForEach-Object {
                                        [void]$ArtistFolders.Add($_)

                                    }
                                }
                            }
                        }
                    }
                    if ($ArtistFolders.Count -eq 0) {
                        Write-Verbose "$($spacer*2) No files matching $ArtistName found in ($SourcePathsToCheck)."
                        continue artistLoop; 
                    }

                    $artistTag = 'folders'
                    if ($($ArtistFolders.Count) -eq 1) {
                        <# Action to perform if the condition is true #>
                        $artistTag = 'folder'
                    }

                    Write-Verbose "$($spacer*2) Found $($($ArtistFolders.Count).ToString('N0').PadLeft(2)) $artistTag matching $ArtistName."

                    foreach ($ArtistFolder in $ArtistFolders) {
                        <# $ArtistFolder is the current item #>

                        <#
                            FreeSpaceBytes = $driveName.Free
                            UsedSpaceBytes 
                        #>
                        $curDriveObj = $MediaSourcePathObjs | Where-Object {
                                                                if ($_.Drive -eq $($artistFolder.Root)) {
                                                                    <# Action to perform if the condition is true #>
                                                                    $_
                                                                }
                                                            }
                        

                        # $ArtistFolderPath = (Join-Path $ArtistAlbumPath $($localAlbum.Name))
                        $HTPCArtistPathObject = [PSCustomObject]@{
                            Drive = $($artistFolder.Root)
                            ArtistName = $($artistFolder.BaseName)
                            Path = $($artistFolder.FullName)
                            MusicSource = $($artistFolder.Parent)
                            FreeSpaceBytes = $curDriveObj.FreeSpaceBytes
                            UsedSpaceBytes = $curDriveObj.UsedSpaceBytes
                            PSComputerName = $($artistFolder.PSComputerName)
                        }
                        
                        Write-Output $HTPCArtistPathObject

                    }
                    <#
                    if ($MusicFileSourse.Length -gt 0) {

                        foreach ($MusicFileSourse in $MusicFileSourses) {
                            Write-Verbose "$($spacer*2) Looking in ..\$MusicFileSourse for $ArtistName across $($TargetMediaDrives) "
                        }
                        Write-Verbose ""
                    }
                    #>
                }
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
            $ScriptName = $PSItem.InvocationInfo.ScriptName
            $Line  = $PSItem.InvocationInfo.Line 
            $ScriptLineNumber = $PSItem.InvocationInfo.ScriptLineNumber
            Write-Host "Error...Name: $ScriptName Line: $Line Script Line Nbr: $ScriptLineNumber"
        }
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> GetArtistPathFromHTPC
# ============================================================================================