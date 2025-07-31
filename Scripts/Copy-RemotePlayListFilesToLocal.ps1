# ============================================================================================
# <Start> Copy-RemotePlayListFilesToLocal
# ============================================================================================
<#
     Enter a comment or description
#>

function Copy-RemotePlayListFilesToLocal {
    [CmdletBinding(
        PositionalBinding,
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the qualified playlist file to copy.'
        )]
        [string[]] $QualifiedPlaylist,

        [Parameter(ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the target path to copy the music to.'
        )]
        [string] $TargetPath = $(Resolve-Path "$env:USERPROFILE\*\Music" | Select-Object -ExpandProperty Path),

        [Parameter(ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the target path to copy the music to.'
        )]
        [string] $RemoteComputerName = 'HTPC',

        [Parameter(ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the target path to copy the music to.'
        )]
        [int] $SampleRows = 100,

        

        [Parameter(ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the Source music path to copy from.'
        )]
        [array] $MusicSourcePaths = @('Bandcamp'
            , 'Flac'
            , 'HDTracks'
            , 'Amazon MP3'
            , 'MP3'
        )


    )
    
    begin {
        <# Passed preference variables from caller #>
        [bool]$private:ShowVerbose = $false
        [bool]$private:ShowDebug = $false
        [bool]$private:ShowWhatIf = $false
         
        <# Capture the passed -Verbose setting #>
        if ($PSBoundParameters.ContainsKey('Verbose')) {
            [bool]$ShowVerbose = $($PSBoundParameters['Verbose'])
        }
        <# Capture the passed -Debug setting #>
        if ($PSBoundParameters.ContainsKey('Debug')) {
            [bool]$ShowDebug = $($PSBoundParameters['Debug'])
        }
        <# Capture the passed -WhatIf setting #>
        if ($PSBoundParameters.ContainsKey('WhatIf')) {
            [bool]$ShowWhatIf = $($PSBoundParameters['WhatIf'])
        }

        <# Working variables #>
         

        $private:RemotePathObj = $null

        #region SetUpHtpcSession
        $private:remoteUserName = Get-SecretForPassedName -SecretToFetch 'htpcUserName' -FetchPlainText $true
        $private:remotePswd = Get-SecretForPassedName -SecretToFetch 'htpcPswd' -FetchPlainText $false
        $private:remoteCreds = New-Object System.Management.Automation.PSCredential ($remoteUserName, $remotePswd)

        $remotePswd = $null
        $private:remoteSessionObj = $null
        #endregion

        

        [string]$private:FullTargetPath = $null

        [int]$private:basicRowCount = 0
        [int]$private:PriorProgressPctNbr = 0

        $private:SourcePathTmp = New-TemporaryFile
        $private:TargetPathTmp = New-TemporaryFile



        $private:RemoteWorkingAlbums = $null

        [int]$private:RemoteMusicTypeNode = 3

        [string]$private:IntTargetPathPrefix = '\\syn414jnas\Backup\Transfer\Music'


        <# Debug and display variables #>
        $private:spacer = $(' ' * 4)
        $private:spaceTwo = $(' ' * 2)

        [int]$private:LabelPadLen = 30
    }
    
    process {
        try {

            <# Override ShowDebug for Child Processes #>
            $ShowVerbose = $false

            <# Could derive the remote name if we pass the remote object #>
            $remoteSessionObj = New-PSSession -ComputerName HTPC -Credential $remoteCreds
                       


            <#
            Invoke-Command -Session $remoteSessionObj `
                                -ScriptBlock {

                                    # Import-PSSession -Session $localSessionObj -Type All -Name Start-Console*, Invoke-R* -FormatTypeName *
                                    . '\\syn414jnas\Backup\Transfer\Start-ConsoleProcess.ps1'
                                    . '\\syn414jnas\Backup\Transfer\Invoke-Robocopy.ps1'
                                    Get-Command Invoke-Robocopy 
                            } 
            #>
            
            $TotalCandidates = 0 
 
            Write-Verbose " --> $QualifiedPlaylist <$TotalCandidates> "
            Get-Content $QualifiedPlaylist -ReadCount 1000 | ForEach-Object { $TotalCandidates += $_.count } 
            Write-Verbose " --> $QualifiedPlaylist <$TotalCandidates> "
            
            if ($TotalCandidates -lt $SampleRows) {
                $SampleRows = $TotalCandidates
            }

            $PassThroughLocation = [ItemLocation]::New()
            $RawLocationObj = Get-LocationDtlForPassthrough -WhatIf:$ShowWhatIf -Verbose:$showVerbose -Debug:$showDebug

            if ($null -ne $RawLocationObj) {
                $PassThroughLocation.Drive = $RawLocationObj.Drive
                $PassThroughLocation.Path = $RawLocationObj.Path
            }

 
            $LineCount = 0
            $PlaylistRows = [System.IO.File]::ReadAllLines( ( Resolve-Path $QualifiedPlaylist ) ) 
            
            # | ForEach-Object {
            :LineLoop foreach ($CurrentItem in $PlaylistRows) {
                <# $CurrentItem is the current item #>

                

                $SongPathParts = $CurrentItem.Split($([IO.Path]::DirectorySeparatorChar))

                <#
                Write-Verbose "$($spacer*1) $($LineCount.ToString().PadLeft(4))) <$($SongPathParts.Count)> Found $_."
                Write-Verbose ''
                Write-Verbose "$($spacer*2)$($spaceTwo) Drive: $($SongPathParts[0])"
                Write-Verbose "$($spacer*2)$($spaceTwo) Root: $($SongPathParts[1])"
                Write-Verbose "$($spacer*2)$($spaceTwo) MusicType: $($SongPathParts[3])"
                Write-Verbose "$($spacer*2)$($spaceTwo) Artist: $($SongPathParts[4])"
                Write-Verbose "$($spacer*2)$($spaceTwo) Album: $($SongPathParts[($($SongPathParts.Count)-2)])"
                Write-Verbose "$($spacer*2)$($spaceTwo) Song: $($SongPathParts[($($SongPathParts.Count)-1)])"
                Write-Verbose ''
                Write-Verbose ''
                #>

                <# Assume the Full path is all parts after Music #>
                $FullTargetPath = $TargetPath + $([IO.Path]::DirectorySeparatorChar)
                $IntTaregetPath = $IntTargetPathPrefix + $([IO.Path]::DirectorySeparatorChar)

                $TargetSong = $($SongPathParts[($($SongPathParts.Count) - 1)])

                <# Check for bad chars that cannot be copied with Copy-Item #>
                if ($TargetSong.Contains('[') -or $TargetSong.Contains(']')) {
                    Write-Warning "$($spacer*1) $($LineCount.ToString().PadLeft(4))) <$($SongPathParts.Count)> Found bad song name."
                    Write-Warning ''
                    Write-Warning "$($spacer*2)$($spaceTwo*2) $('Drive'.PadRight($LabelPadLen,'.')): $($SongPathParts[0])"
                    Write-Warning "$($spacer*2)$($spaceTwo*2) $('Root'.PadRight($LabelPadLen,'.')): $($SongPathParts[1])"
                    Write-Warning "$($spacer*2)$($spaceTwo*2) $('MusicType'.PadRight($LabelPadLen,'.')): $($SongPathParts[3])"
                    Write-Warning "$($spacer*2)$($spaceTwo*2) $('Artist'.PadRight($LabelPadLen,'.')): $($SongPathParts[4])"
                    Write-Warning "$($spacer*2)$($spaceTwo*2) $('Album'.PadRight($LabelPadLen,'.')): $($SongPathParts[($($SongPathParts.Count)-2)])"
                    Write-Warning "$($spacer*2)$($spaceTwo*2) $('Song'.PadRight($LabelPadLen,'.')): $($SongPathParts[($($SongPathParts.Count)-1)])"
                    Write-Warning ''
                    Write-Warning "$($spacer*2)$($spaceTwo) Skipping.  Remove from master and run again."
                    Write-Warning ''
                    Write-Warning ''

                    continue LineLoop;
                }
                $LineCount++

                $RemoteMusicTypeNode..($($SongPathParts.Count) - 2) | ForEach-Object {

                    Write-Debug "$($spacer*2)$($spaceTwo) Adding <$_> $($SongPathParts[$_])"
                    
                    if (-not (Test-Path $($FullTargetPath + $($SongPathParts[$_])))) {
                        Write-Debug "$($spacer*2)$($spaceTwo) Creating Child Path $($SongPathParts[$_])"
                        New-Item -Path "$FullTargetPath" -Name "$($SongPathParts[$_])" -ItemType 'directory' -WhatIf:$ShowWhatIf -Verbose:$showVerbose -Debug:$showDebug | Out-Null
                    }
                    $UpdatedTarget = $($IntTaregetPath + $($SongPathParts[$_]))

                    Write-Debug "$($spacer*2)$($spaceTwo) Checking $UpdatedTarget"

                    if (-not (Test-Path $UpdatedTarget)) {
                        Write-Debug "$($spacer*2)$($spaceTwo) $UpdatedTarget does not exist. Creating."
                        Write-Debug "$($spacer*2)$($spaceTwo) Creating Child Path $($SongPathParts[$_])"
                        New-Item -Path "$IntTaregetPath" -Name "$($SongPathParts[$_])" -ItemType 'directory' -WhatIf:$ShowWhatIf -Verbose:$showVerbose -Debug:$showDebug | Out-Null
                    }

                    $FullTargetPath += $($SongPathParts[$_])
                    $IntTaregetPath += $($SongPathParts[$_])

                    if ($_ -lt ($($SongPathParts.Count) - 1)) {
                        $FullTargetPath += $([IO.Path]::DirectorySeparatorChar)
                        $IntTaregetPath += $([IO.Path]::DirectorySeparatorChar)
                    }
                }

                if ($TargetSong -eq '10 Time Zone - World Destruction [Extended 12'' Mix].flac') {

                    Write-Verbose "$($spacer*1) $($LineCount.ToString().PadLeft(4))) <$($SongPathParts.Count)> Found $_."
                    Write-Verbose ''
                    Write-Verbose "$($spacer*2)$($spaceTwo) Drive: $($SongPathParts[0])"
                    Write-Verbose "$($spacer*2)$($spaceTwo) Root: $($SongPathParts[1])"
                    Write-Verbose "$($spacer*2)$($spaceTwo) MusicType: $($SongPathParts[3])"
                    Write-Verbose "$($spacer*2)$($spaceTwo) Artist: $($SongPathParts[4])"
                    Write-Verbose "$($spacer*2)$($spaceTwo) Album: $($SongPathParts[($($SongPathParts.Count)-2)])"
                    Write-Verbose "$($spacer*2)$($spaceTwo) Song: $($SongPathParts[($($SongPathParts.Count)-1)])"
                    Write-Verbose ''
                    Write-Verbose ''
                }

                Write-Verbose ''
                if ( (Test-Path $($FullTargetPath + $TargetSong))) {
                    Write-Verbose "$($spacer*2)$($spaceTwo) $TargetSong "
                    Write-Verbose "$($spacer*2)$($spaceTwo*2) already exists in <$FullTargetPath>. Skipping."
                }
                else {

                    Write-Verbose "$($spacer*2)$($spaceTwo) Here we Copy $TargetSong"
                    Write-Verbose "$($spacer*2)$($spaceTwo)  to <$IntTaregetPath>"

                    $SongPath = Build-PathFromArray -PathParts $SongPathParts -Verbose:$showVerbose -Debug:$showDebug

                    <# Create the Location Object for the Song #>
                    $RemoteMusicLocation = [ItemLocation]::New()

                    if ($null -ne $SongPathParts) {

                        $RemoteArtistList = $($SongPathParts[($($SongPathParts.Count) - 1)])

                        $RemoteMusicLocation.Drive = $($SongPathParts[0]) + $([IO.Path]::DirectorySeparatorChar)
                        $RemoteMusicLocation.ComputerName = $RemoteComputerName
                        $RemoteMusicLocation.PathString = $SongPath

                        if ($null -eq $RemoteWorkingAlbums) {
                            # Write-Host "$($spacer*2) Pre-Step: Check RemoteWorkingAlbums is null"
                        }
                        else {
                            $RemoteWorkingAlbums = $null
                        }

                        # $RemoteWorkingAlbums = 
                        Get-RemoteTrackDetailsForAlbum -LocationList $RemoteMusicLocation -remoteSessionObj $remoteSessionObj `
                            -WhatIf:$ShowWhatIf -Verbose:$showVerbose -Debug:$showDebug | Where-Object {

                            $_.TrackName -eq $TargetSong
                        } | ForEach-Object {
                            <# Format the Source File #>

                            $SourcePath = $($_.Location.GetPathString())
                            $SourceSongTrack = $_.TrackName
                            $QualifiedSourceSongTrack = $SourcePath + $([IO.Path]::DirectorySeparatorChar) + $SourceSongTrack
                            $QualifiedTargtSongTrack = $FullTargetPath + $SourceSongTrack
                            

                            # Handle special chars
                            # (Get-Item -literalpath (gc 'C:\Temp\path.txt')).creationTime
                            # 'K:\Media4\Music\Flac\Various Artists\Richard Blade's Flashback Favorites, Vol. 1\10 Time Zone - World Destruction [Extended 12'' Mix].flac'
                            
                            <#
                                K:\Media4\Music\Flac\Various Artists\Richard Blade's Flashback Favorites, Vol. 1\10 Time Zone - World Destruction [Extended 12'' Mix].flac
                            #>
                            Write-Verbose "$($spacer*3)$($spaceTwo) Verify file exists on remote"

                            if ($SourceSongTrack.Contains('[')) {
                                $SourceStub = $($SourceSongTrack.Substring(0, $SourceSongTrack.IndexOf('[')).Trim()) + '*'
                            }
                            else {
                                $SourceStub = $SourceSongTrack
                            }

                            if (-not $IntTaregetPath.EndsWith($([IO.Path]::DirectorySeparatorChar))) {
                                
                                $QualifiedIntermedSongTrack = $IntTaregetPath + $([IO.Path]::DirectorySeparatorChar) + $SourceStub
                            }
                            else {
                                $QualifiedIntermedSongTrack = $IntTaregetPath + $SourceStub
                            }

                            if (-not $IntTaregetPath.EndsWith($([IO.Path]::DirectorySeparatorChar))) {
                                
                                $QualifiedIntermedTarget = $IntTaregetPath + $([IO.Path]::DirectorySeparatorChar) + $SourceSongTrack
                            }
                            else {
                                $QualifiedIntermedTarget = $IntTaregetPath + $SourceSongTrack
                            }

                            if (-not $SourcePath.EndsWith($([IO.Path]::DirectorySeparatorChar))) {
                                
                                $QualifiedSourceSongTrack = $SourcePath + $([IO.Path]::DirectorySeparatorChar) + $SourceStub
                            }
                            else {
                                $QualifiedSourceSongTrack = $SourcePath + $SourceStub
                            }



                            <# Get File Extension #>
                            $RemoteFileResolves = Invoke-Command -Session $remoteSessionObj `
                                -ScriptBlock { ($true -eq (Test-Path -Path $using:QualifiedSourceSongTrack)) 
                            } 
                            if ($RemoteFileResolves) {

                                Write-Verbose "$($spacer*3)$($spaceTwo) File exists on remote"

                                <# Try Robo - Copy #>
                                # robocopy $SourcePath $TargetPath $SongTrack /mt /z
                                # Copy-Item -LiteralPath $SourcePath -Destination $TargetPath 
                                # xcopy $QualifiedSourceSongTrack $FullTargetPath
                                # $($(Get-Item $SourcePath).FullName)
                                

                                <# Copy the file to the intermediate passthrough #>
                                Write-Verbose "$($spacer*3)$($spaceTwo) Song $SourceStub  "
                                Write-Verbose "$($spacer*3)$($spaceTwo*2) does not exist in local <$FullTargetPath>. Copy now."
                                    
                                # $QualifiedTarget = (Join-Path $TargetPath $($_.Name))
                                Copy-Item -Path $QualifiedSourceSongTrack -Destination $QualifiedIntermedTarget -FromSession $remoteSessionObj  -Verbose:$showVerbose

                                <#
                                $RemoteFileCopyOutput = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock { Param ($SourcePath, $TargetPath, $SongTrack) 


                                    Get-ChildItem -Path $SourcePath -File -Filter $SongTrack | ForEach-Object {
                                        $QualifiedTarget = (Join-Path $TargetPath $($_.Name))
                                        $CopyResults = Copy-Item -Path $($_.FullName) -Destination $QualifiedTarget -Verbose:$showVerbose -PassThru -Force
                                        Write-Output $CopyResults
                                    }
                                    #  

                                } -ArgumentList $SourcePath, $IntTaregetPath, $SourceStub
                                #>

                               

                                $RemoteFileCopyOutput

                                <# Try Robocopy
                                    Robocopy C:\Users\Administrator\Downloads\Common C:\Users\Administrator\Desktop\ *.dll
                                #>


                                <#
                                $RemoteFileCopyOutput = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock { Param ($SourcePath, $TargetPath, $SongTrack) 
                                     
                                        # "$TargetPath" | Invoke-Robocopy -Path "$SourcePath" -ArgumentList @('/R:2', '/XO' )

                                        # $Result.ExitCode = [Robocopy.ExitCode]$Result.ExitCode
                                


                                        # c:\Windows\System32\robocopy.exe "$SourcePath" "$TargetPath" "$SongTrack" /l

                                    #  

                                } -ArgumentList $SourcePath, $IntTaregetPath, $SourceStub
                                #>
                                
                                # Copy-Item -Path $QualifiedIntermedSongTrack -Destination $QualifiedIntermedTarget -FromSession $remoteSessionObj  -Verbose:$showVerbose

                                if ((Test-Path $QualifiedIntermedTarget)) {
                                    Write-Verbose "$($spacer*3)$($spaceTwo) Song $SourceStub Copy from intermediate to local "
                                    # xcopy $QualifiedIntermedSongTrack $FullTargetPath  /l
                                    <#
                                        
                                        Copy-Item -LiteralPath $QualifiedIntermedSongTrack -Destination $FullTargetPath `
                                            -WhatIf:$ShowWhatIf -Verbose:$showVerbose -Debug:$showDebug
                                        #>
                                }
                                else {
                                    Write-Verbose "$($spacer*3)$($spaceTwo) Song $SourceStub "
                                    Write-Verbose "$($spacer*3)$($spaceTwo*2) Copy to $IntTaregetPath failed "
                                }
                                # robocopy c:\reports "\\marketing\videos" yearly-report.mov /mt /z

                            }
                            else {
                                Write-Verbose "$($spacer*2)$($spaceTwo) <<$QualifiedSourceSongTrack>> cannot be found on remote host." 
                            }
                                
                            <# TrackCopyRequest #> 

                            # -Path $NewSourcePath
                            # (gc $($SourcePathTmp.FullName)) | 
                            # $RemoteWorkingAlbums
                            # $RemoteWorkingAlbums.Location.GetPathString()

                        }
                    }

                    if ($LineCount -gt $SampleRows) {
                        break LineLoop
                    }
                }
                Write-Verbose ''

                if ($SampleRows -gt 0) {
                    $RawPctComplete = $($LineCount / $SampleRows)
                }
                else {
                    $RawPctComplete = 0
                }
                
                $PctComplete = [math]::Floor(($RawPctComplete * 100))
                if ($PctComplete -gt 100) {
                    $PctComplete = 100
                }
                $PctCompleteString = $($RawPctComplete.ToString('P0'))

                # -CurrentOperation "Processing $($RowsProcessed.ToString().PadLeft(4)) of $($SampleRows.ToString().PadLeft(4))"
                # -Status "$PctCompleteString Complete:"

                if ($RowsProcessed -eq 1 -or $PctComplete -ne $PriorProgressPctNbr) {
                    Write-Progress -Activity "Copying songs found in $QualifiedPlaylist to $TargetPath" `
                        -Status "$PctCompleteString Complete:" `
                        -PercentComplete $PctComplete
                    $PriorProgressPctNbr = $PctComplete
                }
            }

            Write-Verbose "$($spacer*1)$($spaceTwo) Done. Checked $($LineCount.ToString('N0')) songs."
            <#
            AlbumTrack {
                
            [string] $TrackName
            [int] $TrackNumber
            [string] $ArtistName
            [int] $Rating
            [ItemLocation] $Location

            #>
             
            Write-Progress -Complete -Activity "Copying songs found in $QualifiedPlaylist to $TargetPath" `
                -Status "$PctCompleteString Complete:" `
                -PercentComplete $PctComplete
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


            if (-not $null -eq $remoteSessionObj) {

                Invoke-Command -Session $remoteSessionObj `
                    -ScriptBlock {
                    if (-not $null -eq $localSessionObj) {
                        Remove-PSSession -Session $localSessionObj
                    }
                } 

                Remove-PSSession -Session $remoteSessionObj
            }

            
            if (Test-Path $($SourcePathTmp.FullName)) {
                Remove-Item -Path $($SourcePathTmp.FullName)
            }
            if (Test-Path $($TargetPathTmp.FullName)) {
                Remove-Item -Path $($TargetPathTmp.FullName)
            }

            [System.GC]::Collect()
        }
    }
    end {
        
    }
}
# ============================================================================================
# <End> Copy-RemotePlayListFilesToLocal
# ============================================================================================