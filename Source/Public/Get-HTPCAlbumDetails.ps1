# ============================================================================================
# <Start> Get-HTPCAlbumDetails
# ============================================================================================
<#
     Get whether passed album(s) exist, and if so, where they reside and the hash sigs of the tracks, etc.
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


function Get-HTPCAlbumDetails {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        # Parameter help description
        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]] $ArtistPathsToCheckObjs, 

        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]] $ArtistAlbumToCheckObjs, 


        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateNotNullOrEmpty()]
        $remoteSessionObj,

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string] $hashAlgo = 'MD5'
        
    )
    
    begin {
        <#

            Drive          : J:\
            ArtistName     : Ashley McBryde
            Path           : J:\Media3\Music\Flac\Ashley McBryde
            MusicSource    : Flac
            FreeSpaceBytes : 4657212895232
            UsedSpaceBytes : 3344348921856
            PSComputerName : HTPC
        
        #>
        [PSCustomObject]$private:HTPCArtistAlbumObject = $null

        [PSCustomObject]$private:HTPCAlbumTrackObject = $null

        <# Working Variables #>
        [System.Collections.ArrayList]$local:SourcePathsToCheck = @()
        [System.Collections.ArrayList]$local:SourceAlbumsToCheck = @()

        [string]$private:ArtistName = $null
        [string]$private:AlbumName = $null
        
        [string]$private:AlbumTag = $null
        [string]$private:TrackTag = $null
        

        $private:ArtistAlbumFolders = $null
        $private:currentTargetPath = $null

        $private:AlbumTracks = $null

        [PSCustomObject[]]$private:TrackDetails = @{}
        
        [string]$private:TrackName = $null
        [string]$private:TrackPath = $null
        [string]$private:QualifiedTrackName = $null
        [string]$private:TrackHashVal = $null
        $private:TrackHashResults = $null

        
    }
    
    process {
        try {
            $ArtistPathsToCheckObjs | ForEach-Object {

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
    
            $ArtistAlbumToCheckObjs | ForEach-Object {

                if ($null -ne $_.AlbumName) {
                    <# Suppress any null paths.  
                        A null path causes the Get-ChildItem to drop out of the FileSystem provider
                        which, in turn, causes the -Directory param to fail (it is not available with other provider types)
                    #>
                    if (-not $SourceAlbumsToCheck.Contains($($_.AlbumName))) {
                        <# Action to perform if the condition is true #>
                        [void]$SourceAlbumsToCheck.Add($_.AlbumName)
                    }
                }
            }
            
            Write-Verbose "$($spacer*2) Source Albums to find: ($SourceAlbumsToCheck)"

            <#
                AlbumName     : The Devil I Know
                LastWriteTime : 9/18/2023 2:42:07 PM
                Artist        : Ashley McBryde
                TrackCount    : 12
                Path          : \\syn414jnas\Backup\Passthrough\Music\Flac\Ashley McBryde
                MusicSource   : Flac

                ArtistAlbumToCheckObjs
            #>
            foreach ($AlbumNameObj in $ArtistAlbumToCheckObjs) {
                <# $AlbumNameObj is the current item #>
                $SourcePathsToCheck.Clear()
                $AlbumName = $($AlbumNameObj.AlbumName)
                $ArtistName = $($AlbumNameObj.ArtistName)
                
                <# Get the paths for the album's artist #>
                $ArtistPathsToCheckObjs | Where-Object {
                    if ($_.ArtistName -eq $ArtistName) {
                        <# Action to perform if the condition is true #>
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
                }

                Write-Verbose "$($spacer*2) $AlbumName : Found ($SourcePathsToCheck) paths to check. "

                Write-Verbose "$($spacer*2) Checking each path for $AlbumName "
                Write-Verbose "$($spacer*1)$($spaceTwo) $('-'*30)"

                $ArtistAlbumFolders = Invoke-Command -Session $remoteSessionObj `
                                            -ScriptBlock { Param ($localSearchPhrase, $pathArray) Get-ChildItem -Path $pathArray `
                                                -Directory  -Filter $localSearchPhrase `
                                                -ErrorAction SilentlyContinue  } -ArgumentList $AlbumName, $SourcePathsToCheck

                Write-Verbose "$($spacer*2)" 
                $AlbumTag = 'albums'
                    if ($($ArtistAlbumFolders.Count) -eq 1) {
                        <# Action to perform if the condition is true #>
                        $AlbumTag = 'album'
                    }

                if ($ArtistAlbumFolders.Count -eq 0) {
                    Write-Verbose "$($spacer*2) No folders matching $AlbumName for $ArtistName found in ($SourcePathsToCheck)."

                    <# Get the target location object for the artist #>
                    $currentTargetPath = $ArtistPathsToCheckObjs | Where-Object {
                        
                        if ($_.ArtistName -eq $ArtistName) {
                            $_
                        }
                    } | Sort-Object -Property FreeSpaceBytes -Descending | Select-Object -First 1
                

                    <#
                        ArtistName     : Ashley McBryde
                        Path           : J:\Media3\Music\Flac\Ashley McBryde
                        MusicSource    : Flac
                        FreeSpaceBytes : 4657212895232
                        UsedSpaceBytes : 3344348921856
                    #>

                    $HTPCArtistAlbumObject = [PSCustomObject]@{
                        Drive = $($currentTargetPath.Drive)
                        ArtistName = $($AlbumNameObj.ArtistName)
                        AlbumName = $AlbumName
                        TargetAlbumPath = $($currentTargetPath.Path)  
                        SourceAlbumPath = $AlbumNameObj.Path 
                        MusicSource = $($currentTargetPath.MusicSource)
                        FreeSpaceBytes = $currentTargetPath.FreeSpaceBytes
                        UsedSpaceBytes = $currentTargetPath.UsedSpaceBytes
                        TargetFileFound = $false
                        AlbumTrackHashes = $null
                        TracksFound = 0
                        # PSComputerName = $($artistFolder.PSComputerName)
                    }

                    Write-Output $HTPCArtistAlbumObject

                }
                else {
                    <# Found 1 or more albums #>
                    foreach ($ArtistAlbumFolderObj in $ArtistAlbumFolders) {
                        <# $ArtistAlbumFolderObj is the current item #>

                        $currentTargetPath = $ArtistPathsToCheckObjs | Where-Object {
                        
                            if ($_.Drive -eq $($ArtistAlbumFolderObj.Root) -and $_.ArtistName -eq $ArtistAlbumFolderObj.Parent) {
                                $_
                            }
                        } | Sort-Object -Property FreeSpaceBytes -Descending | Select-Object -First 1

                        <# Get the track details #>
                        $AlbumTracks = Invoke-Command -Session $remoteSessionObj `
                                            -ScriptBlock { Param ($pathArray) Get-ChildItem -Path $pathArray `
                                                -File -ErrorAction SilentlyContinue  } `
                                                -ArgumentList $($ArtistAlbumFolderObj.FullName)

                                            
                        $TrackTag = 'tracks'
                        if ($($AlbumTracks.Count) -eq 1) {
                            <# Action to perform if the condition is true #>
                            $TrackTag = 'track'
                        }

                        
                        $TrackDetails.Clear()

                        <# 
                            To Do:
                            Can we collapse this into a single call to the remote server - eg pipe the tracks to
                            where-object that for each track calculates the hash and updates the DB?
                        #>


                        <# $currentItemName is the current item 
                                LastWriteTime  : 4/3/2023 4:02:19 PM
                                Length         : 17377618
                                Name           : 01 Ashley McBryde, Caylee Hammack & Pillbox Patti - Brenda Put Your Bra On.flac
                                PSComputerName : HTPC
                            
                            #>

                        # -------------------------------------
                        <# 
                        foreach ($currentTrackName in $AlbumTracks) {
                            $TrackCount++
                            
                            $TrackName = $currentTrackName.Name
                            $TrackPath = $ArtistAlbumFolderObj.FullName

                            $QualifiedTrackName = Invoke-Command -Session $remoteSessionObj `
                                                        -ScriptBlock {(Join-Path $using:TrackPath $using:TrackName ) }

                            $TrackHashResults = Invoke-Command -Session $remoteSessionObj `
                                -ScriptBlock { Get-FileHash -LiteralPath $using:QualifiedTrackName -Algorithm $using:hashAlgo } 
                                        
                            $TrackHashVal = $TrackHashResults."Hash"

                            if (-not $TrackDetails.ContainsKey($TrackName)) {
                                $TrackDetails[$TrackName] = @{}
                                $TrackDetails[$TrackName]['RemoteHashVal'] = $TrackHashVal
                                $TrackDetails[$TrackName]['HashAlgoUsed'] = $hashAlgo
                                $TrackDetails[$TrackName]['LastWriteTime'] = $currentTrackName.LastWriteTime
                                $TrackDetails[$TrackName]['Length'] = $currentTrackName.Length
                                $TrackDetails[$TrackName]['PSComputerName'] = $currentTrackName.PSComputerName
                            }

                        }
                        #>

                        <# All in one action on remote server 
                            Do we need to generate a suragate key for the hash?
                        #>
                        $TrackDetails = Invoke-Command -Session $remoteSessionObj `
                                            -ScriptBlock {Param ($AlbumTracks, $hashAlgo, $TrackPath, $TrackDetails)

                                                $TrackCount = 0
                                                $AlbumTracks | Sort-Object -Property Name | ForEach-Object {
                                                    # $currentTrackName --> $_
                                                    $TrackCount++

                                                    $TrackName = $_.Name
                                                    $QualifiedTrackName = Join-Path $TrackPath $TrackName
                                                    $TrackHashResults = Get-FileHash -LiteralPath $QualifiedTrackName -Algorithm $hashAlgo
                                                    $TrackHashVal = $TrackHashResults."Hash"

                                                    $TrackKey = $($TrackCount.ToString().PadLeft(5,'0'))

                                                    <# Update the results for the current track #>
                                                    $HTPCAlbumTrackObject = [PSCustomObject]@{
                                                        TrackName = $TrackName
                                                        RemoteHashVal = $TrackHashVal
                                                        HashAlgoUsed = $hashAlgo
                                                        LastWriteTime = $_.LastWriteTime
                                                        Length = $_.Length
                                                        PSComputerName = $_.PSComputerName
                                                    }
                                                    $HTPCAlbumTrackObject
                                                }


                                            } -ArgumentList $AlbumTracks, $hashAlgo, $($ArtistAlbumFolderObj.FullName), $TrackDetails 


                        Write-Verbose "$($spacer*5) Found <$AlbumName> with <$($AlbumTracks.Count)> ($($TrackDetails.Count)) ($($TrackDetails.Keys))$TrackTag to transfer for $($ArtistAlbumFolderObj.Parent)"
                        # $TrackDetails
                        Write-Verbose "$($spacer*4)$($spaceTwo) $('-'*60)"
                        # $ArtistAlbumFolderObj

                        $HTPCArtistAlbumObject = [PSCustomObject]@{
                            Drive = $($ArtistAlbumFolderObj.Root)
                            ArtistName = $ArtistAlbumFolderObj.Parent
                            AlbumName = $AlbumName
                            TargetAlbumPath = $($currentTargetPath.Path)  
                            SourceAlbumPath = $AlbumNameObj.Path 
                            MusicSource = $($currentTargetPath.MusicSource)
                            FreeSpaceBytes = $currentTargetPath.FreeSpaceBytes
                            UsedSpaceBytes = $currentTargetPath.UsedSpaceBytes
                            TargetFileFound = $true
                            AlbumTrackHashes = $TrackDetails
                            TracksFound = $($TrackDetails.Count)
                        }
    
                        Write-Output $HTPCArtistAlbumObject
                    }
                    
                }
                Write-Verbose "$($spacer*2) Found $($($ArtistAlbumFolders.Count).ToString('N0').PadLeft(2)) $AlbumTag matching $AlbumName."
                Write-Verbose ""

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
# <End> Get-HTPCAlbumDetails
# ============================================================================================