# ============================================================================================
# <Start> Get-RemoteTrackDetailsForAlbum
# ============================================================================================
<#
     Enter a comment or description
#>

function Get-RemoteTrackDetailsForAlbum {
    [CmdletBinding(
            PositionalBinding,
            DefaultParameterSetName = 'RemoteNoDateFilter',
             SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position=0, ValueFromPipelineByPropertyName
        , ParameterSetName = 'RemoteDateFilter', HelpMessage = 'Specify the set of locations to search.'
            )]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteNoDateFilter', HelpMessage = 'Specify the set of locations to search.'
        )]
        [ItemLocation] $LocationList,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteNoDateFilter', HelpMessage = 'Specify remote session to search.'
        )]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteDateFilter', HelpMessage = 'Specify remote session to search.'
        )]
        [ValidateNotNullOrEmpty()]
        $remoteSessionObj,

        [Parameter(Mandatory = $false
            , ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteDateFilter'
            , HelpMessage = 'Specify date to use to filter the resutls (all results should be no older than the passed date).'
        )]
        [nullable[DateTime]] $FirstDateToCheckSeed,

        [Parameter(Mandatory = $false
            , ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteDateFilter'
            , HelpMessage = 'Specify number of days to add to the passed date to calculate the date window. This defaults to 5 days.'
        )]
        [int] $DaysBackToCheck 
        
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
         
        #region InitDateFilterParams
        if ($PSCmdlet.ParameterSetName -eq 'RemoteDateFilter') {
            
            [nullable[DateTime]]$private:FirstDateToCheck = $null
            [nullable[DateTime]]$private:LastDateToCheck = $null

            if ($null -eq $FirstDateToCheckSeed -and -not  $PSBoundParameters.ContainsKey('DaysBackToCheck') ) {
                <# Action to perform if the condition is true #>
                $FirstDateToCheck = $(Get-Date).AddDays(-$DaysBackToCheck)
                $LastDateToCheck = $(Get-Date)
            }
            elseif ($null -ne $FirstDateToCheckSeed) {
                $FirstDateToCheck = $FirstDateToCheckSeed
                $LastDateToCheck = $(Get-Date)
            }
            elseif ($PSBoundParameters.ContainsKey('DaysBackToCheck')) {
                $FirstDateToCheck = $(Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-$DaysBackToCheck)
                $LastDateToCheck = $(Get-Date)
            }
            else {
                <# Action when all if and elseif conditions are false #>
                Throw "$($FirstDateToCheckSeed.ToString('MM/dd/yyyy HH:MM')) is invalid. Valid Filter dates must be within the last $DaysBackToCheck days."
                
            }
            Write-Verbose "$($spacer*3) $($FirstDateToCheck.ToString('MM/dd/yyyy HH:MM')) to $($LastDateToCheck.ToString('MM/dd/yyyy HH:MM'))"

        }
        #endregion

        <# Processing variables #>
        <# Tracks found in the current folder that match the passed album and source #>
        $private:localTracks = $null

        <# Output variables #>
        $private:AlbumObj = $null
        $private:AlbumEncodingObj = $null
        $private:AlbumDetails = $null
        [ItemLocation]$private:AlbumTrackLocation = $null

        [string]$private:WorkingFolder = $null

        [array]$private:SongPathParts = $null

        <# Debug and display variables #>
        $private:spacer = $(' ' * 4)
        $private:spaceTwo = $(' ' * 2)

        [string]$private:AlbumTag = $null

        [int]$private:TrackCount = 0


    }
    
    process {
        try {
            <# Pass the full album path #>
            $WorkingFolder = $LocationList.GetPathString()

            <# To Do:  Should we assume path exists? #>
            $MusicSourceFolder = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock {  if ($true -eq (Test-Path $using:WorkingFolder)) {
                                        $(Get-Item $using:WorkingFolder).Parent.Name

                                    } 
                                    else {
                                        $null
                                    }
                                } 
            
            Write-Verbose "$($spacer*3) Looking for tracks in $WorkingFolder - $MusicSourceFolder "
            $AlbumEncodingObj = $MusicSourceFolder | Get-MetaDataFromSourceFolder -Verbose:$ShowVerbose
            
            <# Get the set of Albums in the arist folder #>

            switch ($PSCmdlet.ParameterSetName) {
                'RemoteDateFilter' {
                    Write-Debug "$($spacer*3)$($spaceTwo) You used the RemoteDateFilter parameter set."
                    
                    $localTracks =  Invoke-Command -Session $remoteSessionObj `
                    -ScriptBlock { Param ($AlbumPath, $FirstDate, $LastDate) Get-ChildItem -Path $AlbumPath `
                                            -File -ErrorAction SilentlyContinue | `
                                    Where-Object { $_.LastWriteTime -ge $FirstDate -and $_.LastWriteTime -lt $LastDate} 
                                } -ArgumentList $WorkingFolder, $FirstDateToCheck, $LastDateToCheck
                    break
                }
                'RemoteNoDateFilter' {
                    Write-Debug "$($spacer*3)$($spaceTwo) You used the RemoteNoDateFilter parameter set."
                    $localTracks = Invoke-Command -Session $remoteSessionObj `
                                        -ScriptBlock { Param ($AlbumPath) Get-ChildItem -Path $AlbumPath `
                                            -File -ErrorAction SilentlyContinue
                                        } -ArgumentList $WorkingFolder

                    break
                }
            }
            if ($($localTracks.Count) -eq 0 -or $($localTracks.Count) -gt 1) {
                $AlbumTag = ConvertTo-Plural -Word 'track'
            }
            else {
                $AlbumTag = 'track'
            }

            Write-Verbose "$($spacer*3) Found $($localTracks.Count) $AlbumTag to report."

            $TrackCount = 0
            $localTracks | ForEach-Object {
                $TrackCount++

                $AlbumTrackLocation = [ItemLocation]::New()

                $AlbumTrackLocation.PathString = $($_.FullName)
                $AlbumTrackLocation.Drive = $LocationList.Drive
                $AlbumTrackLocation.ComputerName = $_.PSComputerName

                $SongPathParts = $($_.FullName).Split($([IO.Path]::DirectorySeparatorChar))

                Write-Verbose "$($spacer*1)$('-'*30)"
                Write-Verbose "$($spacer*2)$($spaceTwo) Artist: $($SongPathParts[4])"
                

                $TrackObj = [PSCustomObject]@{
                    ArtistName = $($SongPathParts[4])
                    TrackName = $_.Name
                    TrackNumber = $null
                    Rating = $null
                    Location = [ItemLocation]$LocationList  # [ItemLocation]

                }
         
                Write-Output $TrackObj
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
        }
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Get-RemoteTrackDetailsForAlbum
# ============================================================================================