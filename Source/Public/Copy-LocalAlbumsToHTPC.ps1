# ============================================================================================
# <Start> Copy-LocalAlbumsToHTPC
# ============================================================================================
<#
     Enter a comment or description
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


function Copy-LocalAlbumsToHTPC {
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
        [PSCustomObject[]] $ArtistAlbumToCopyObjs, 

        [Parameter(Mandatory=$true, 
                     ValueFromPipeline=$true
                    )]
        [ValidateNotNullOrEmpty()]
        $remoteSessionObj,

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string] $hashAlgo = 'MD5', 

        [Parameter(Mandatory=$false, 
                     ValueFromPipeline=$true
                    )]
        [switch]$UpdateExisting
        
    )
    
    begin {
        
    }
    
    process {
        try {

            Write-Verbose ""
            Write-Verbose "$($spacer*2) Checking whether to copy $($remoteArtistAlbumObjs.Count) albums to HTPC."
            Write-Verbose "$($spacer*1) $('-'*60)"

            :albumLoop foreach ($LocalAlbum in $remoteArtistAlbumObjs) {
                # $LocalAlbum
                
                <#
                    Find out where that artist lives on HTPC
                    Check whether the album is already there
                    If not
                        Transfer if not what if
                #>
        
                <#
                    Can we define this as a class?
        
                    AlbumName     : The Devil I Know
                    LastWriteTime : 9/18/2023 2:42:07 PM
                    Artist        : Ashley McBryde
                    TrackCount    : 12
                    Path          : \\syn414jnas\Backup\Passthrough\Music\Flac\Ashley McBryde
                #>
        
                <#
                    Drive            : J:\
                    ArtistName       : Ashley McBryde
                    AlbumName        : Ashley McBryde Presents; Lindeville
                    TargetAlbumPath  : J:\Media3\Music\Flac\Ashley McBryde
                    SourceAlbumPath  : \\syn414jnas\Backup\Passthrough\Music\Flac\Ashley McBryde
                    MusicSource      : Flac
                    FreeSpaceBytes   : 4657212895232
                    UsedSpaceBytes   : 3344348921856
                    TargetFileFound  : True
                    AlbumTrackHashes : {[04 Ashley McBryde - Women Ain't Whiskey.flac, System.Collections.Hashtable], [11 Ashley McBryde - 6th Of        
                                    October.flac, System.Collections.Hashtable], [09 Ashley McBryde - Whiskey And Country Music.flac,
                                    System.Collections.Hashtable], [Folder.jpg, System.Collections.Hashtable]…}
                    TracksFound      : 14

                        $TrackDetails[$TrackName] = @{}
                        $TrackDetails[$TrackName]['HashAlgoUsed'] = $hashAlgo
                        $TrackDetails[$TrackName]['RemoteHashVal'] = $TrackHashVal
                        $TrackDetails[$TrackName]['LastWriteTime'] = $currentTrackName.LastWriteTime
                        $TrackDetails[$TrackName]['Length'] = $currentTrackName.Length
                        $TrackDetails[$TrackName]['PSComputerName'] = $currentTrackName.PSComputerName

                        $TrackDetails[$TrackName]['LocalHashVal'] = TBD
                #>

                <# Set Defaults #>

                $AlbumExistsOnHTPC = $false

                <# ------------------------------------ #>

                Write-Verbose ""
                Write-Verbose ""
                Write-Verbose "$($spacer*3) Found <$($LocalAlbum.AlbumName)> by $($LocalAlbum.ArtistName) Starting the process..."
                Write-Verbose "$($spacer*1) $('-'*60)"

                $ArtistName = $($LocalAlbum.ArtistName)
                $AlbumName = $($LocalAlbum.AlbumName)
                $AlbumSourcePath = (Join-Path $($LocalAlbum.SourceAlbumPath) $AlbumName )
                $AlbumExistsOnHTPC = $LocalAlbum.TargetFileFound
        
                $AlbumTargetPath = $LocalAlbum.TargetAlbumPath
                $MusicSource = $LocalAlbum.MusicSource


                Write-Verbose "$($spacer*3) Found <$AlbumName> by $ArtistName -- Source: $MusicSource "
                Write-Verbose "$($spacer*3) Source Path: <$($LocalAlbum.SourceAlbumPath)>"
                Write-Verbose "$($spacer*3) <$AlbumExistsOnHTPC><$UpdateExisting> "

                
                            
                if ($AlbumExistsOnHTPC -and $UpdateExisting) {
                    <# 
                        Album already exists on remote server
        
                        Check each track and compare the hashes
                    
                    #>
                    Write-Verbose "$($spacer*3) Found <$AlbumName> Checking Tracks for changes <$AlbumExistsOnHTPC><$UpdateExisting>"

                    $QualifiedAlbumTargetPath = Invoke-Command -Session $remoteSessionObj `
                                                    -ScriptBlock { (Join-Path $using:AlbumTargetPath $using:AlbumName ) }
        

                    #  
                    $LocalAlbumTracks = Get-ChildItem -Path $AlbumSourcePath `
                                                -File -ErrorAction SilentlyContinue 
        

                    # 
                    $FirstTrackDtl = $LocalAlbumTracks | Select-Object -Property Name -First 1
                    
                    $FirstTrackDtlHash = $LocalAlbum | Select-Object -Property AlbumTrackHashes -First 1

                    Write-Verbose ""
                    Write-Verbose "$($spacer*3) Debug"
                    Write-Verbose "$($spacer*3) $('-'*45)"

                    $LocalAlbum.AlbumTrackHashes
                    $LocalAlbum.AlbumName
                    
                    $hashAlgo = $LocalAlbum.AlbumTrackHashes[$($FirstTrackDtl.Name)]['HashAlgoUsed']

                    Write-Verbose "$($spacer*3) Found <$AlbumName> Sample Track --> ($FirstTrackDtl) <$hashAlgo>"

                    <# Update the Track hash with the local Hash value of the track #>
                    $LocalAlbumTracks | ForEach-Object {
                        $TrackHashResults = $null
                        $TrackHashVal = $null

                        $QualifiedTrackName = (Join-Path $AlbumSourcePath $_)

                        $TrackHashResults = Get-FileHash -Path $QualifiedTrackName -Algorithm $hashAlgo               
                        $TrackHashVal = $TrackHashResults."Hash"

                        <# Update the source hash #>
                        $LocalAlbum.AlbumTrackHashes[$_]['LocalHashVal'] = $TrackHashVal


                    }
                    
                    

                    $TrackTag = 'tracks'
                    if ($($LocalAlbumTracks.Count) -eq 1) {
                        <# Action to perform if the condition is true #>
                        $TrackTag = 'track'
                    }
        
                    Write-Verbose ""
                    Write-Verbose "$($spacer*3) Found <$AlbumName> with <$($LocalAlbumTracks.Count)> ($TrackCount) $TrackTag "
                    Write-Verbose "$($spacer*3) to transfer from $AlbumSourcePath"
                    Write-Verbose "$($spacer*3) to $QualifiedAlbumTargetPath"
                    Write-Verbose "$($spacer*2) $('-'*60)"
                    # Debug
                    $TrackCount = 0
                    foreach ($TrackName in $($LocalAlbum.AlbumTrackHashes).Keys | sort) {
                        <# $TrackName is the current item #>
                        $TrackCount++

                        $LocalHashVal = $LocalAlbum.AlbumTrackHashes[$TrackName]['LocalHashVal']
                        $RemoteHashVal = $LocalAlbum.AlbumTrackHashes[$TrackName]['RemoteHashVal']
                        $HashAlgoUsed = $LocalAlbum.AlbumTrackHashes[$TrackName]['HashAlgoUsed']

                        Write-Verbose "$($spacer*4) $($TrackCount.ToString().PadLeft(2))) $TrackName"
                        Write-Verbose "$($spacer*4)$($spaceTwo) Local: $LocalHashVal Remote: $RemoteHashVal <$HashAlgoUsed>"
                    }
                    # $LocalAlbum
                    Write-Verbose "$($spacer*2) $('-'*30)"

                }
                elseif (-not $AlbumExistsOnHTPC) {
                    <# Action when all if and elseif conditions are false #>
                    Write-Verbose "$($spacer*3) Found <$AlbumName> does not exists in $AlbumTargetPath. Create album folder and copy."


                    $QualifiedAlbumTargetPath = $( $AlbumTargetPath + '\' + $AlbumName ) 

        
                    <#
                        ## $PSCmdlet.ShouldProcess('TARGET','OPERATION')
                        What if: Performing the operation "OPERATION" on target "TARGET".
                    #>
                    $AlbumName

                    if ($PSCmdlet.ShouldProcess($QualifiedAlbumTargetPath,$('Copy the album ' + $AlbumName))) {
                        Write-Host "$($spacer*3) Here we would copy the album folder to HTPC"
                        Copy-Item $AlbumSourcePath -Destination $QualifiedAlbumTargetPath -ToSession $remoteSessionObj -Recurse

                    }
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
# <End> Copy-LocalAlbumsToHTPC
# ============================================================================================