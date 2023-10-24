# ============================================================================================
# <Start> Get-AlbumDtlForArtistList
# ============================================================================================
<#
     Get the Album Details from passed path that matches the passed 
     Artist and music source info witth optional date filter
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


function Get-AlbumDtlForArtistList {
    [CmdletBinding(
        PositionalBinding,
        DefaultParameterSetName = 'LocalNoDateFilter',
        SupportsShouldProcess
    )]
    param (
        # Parameter help description
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]] $ArtistNameList, 

        # Note:  We should add this as a class
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
        )]
        [ItemLocation] $LocationList,
        
        [Parameter(Mandatory, ParameterSetName = 'LocalNoDateFilter', HelpMessage = 'Specify whether to use the remote connection.')]
        [Parameter(Mandatory, ParameterSetName = 'LocalDateFilter', HelpMessage = 'Specify whether to use the remote connection.')]
        [switch]$UseLocal,

        [Parameter(Mandatory, ParameterSetName = 'RemoteNoDateFilter', HelpMessage = 'Specify whether to use the remote connection.')]
        [Parameter(Mandatory, ParameterSetName = 'RemoteDateFilter', HelpMessage = 'Specify whether to use the remote connection.')]
        [switch]$UseRemote,

        [Parameter(Mandatory, ParameterSetName = 'LocalDateFilter', HelpMessage = 'Specify whether to use the Date filter.')]
        [Parameter(Mandatory, ParameterSetName = 'RemoteDateFilter', HelpMessage = 'Specify whether to use the Date filter.')]
        [switch]$UseDateFilter,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteNoDateFilter', HelpMessage = 'Specify remote session to search.'
        )]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , ParameterSetName = 'RemoteDateFilter', HelpMessage = 'Specify remote session to search.'
        )]
        [ValidateNotNullOrEmpty()]
        $remoteSessionObj,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'RemoteDateFilter'
            , HelpMessage = 'Specify date to use to filter the resutls (all results should be no older than the passed date).')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'LocalDateFilter'
            , HelpMessage = 'Specify date to use to filter the resutls (all results should be no older than the passed date).')]
        [DateTime] $FirstDateToCheckSeed,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'RemoteDateFilter'
            , HelpMessage = 'Specify number of days to add to the passed date to calculate the date window. This defaults to 5 days.')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'LocalDateFilter'
            , HelpMessage = 'Specify number of days to add to the passed date to calculate the date window. This defaults to 5 days.')]
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
         
        $private:spacer = $(' ' * 4)
        $private:spaceTwo = $(' ' * 2)

        # \\syn414jnas\Backup\Passthrough\Music\Flac

        <#
        ,
                        ErrorMessage = "{0} is invalid. Valid Filter dates must be within the last two days."
        [ValidateScript({
            ($_ -gt (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-90) -and $_ -le (Get-Date))
        })]


            [ValidateScript({
            $_ -eq 20            
        },
        ErrorMessage = "{0} is invalid. Valid value is 20 only."
        )]

        [parameter()]
        [ValidateScript(
            {
                # Check if the From and To parameters are specified

                if ($PSBoundParameters.Keys -contains 'From' -AND
                    $PSBoundParameters.Keys -contains 'To') {
                        $true
                }
                else {
                    throw "From and To parameters are required when using SendEmail"
                }
            }
        )]
        
        #>
        

        # Working variables
        [string]$private:artistFilterPhrase = $null
        [string]$private:baseDrivePath = $null
        [string]$private:ArtistAlbumPath = $null
        [string]$private:AlbumTrackPath = $null
        
        <# Folders that match the passed artist and source #>
        $private:folders = $null

        <# Albums found in the current folder that match the passed artist and source #>
        $private:localAlbums = $null
        
        <# Fracks for the current Album found in the current folder that match the passed artist and source #>
        $private:AlbumTracks = $null
        
        [string]$private:artistTag = $null
        [string]$private:AlbumTag = $null
        [string]$private:TrackTag = $null

        [ItemLocation]$private:SearchFolderLocation = $null

        [PSCustomObject]$private:LocalAlbumObject = $null
    }
    
    process {
        <#
            Find any artist paths for the passed set. 
            Then find any albums within the artist that are within the date window
        #>

        try {
            Write-Debug ''
            Write-Debug "$($spacer*1) Found $($PSCmdlet.ParameterSetName) parameter set."
            if ($PSBoundParameters.ContainsKey('FirstDateToCheckSeed')) {
                Write-Debug "$($spacer*1)$($spaceTwo) Passed Start Date: $($FirstDateToCheckSeed.ToString('MM/dd/YY HH:mm'))"
            }
            if ($PSBoundParameters.ContainsKey('DaysBackToCheck')) { 
                Write-Debug "$($spacer*1)$($spaceTwo) Passed Days Back: $($DaysBackToCheck.ToString().PadLeft(3))"
            }
            Write-Debug ''

            <#
                Set up the basic file paths to check
            #>

            if ($PSBoundParameters.ContainsKey('UseLocal')) {
                $baseDrivePath = $LocationList.GetPathString()
                if (-not (Test-Path $baseDrivePath)) {
                    <# Action to perform if the condition is true #>
                    Throw "$($spacer*1) $baseDrivePath is invalid"
                    
                } 
            }
            elseif ($PSBoundParameters.ContainsKey('UseRemote')) {
                $baseDrivePath = $LocationList.GetPathString()
                $RemotePathDetailExists = Invoke-Command -Session $remoteSessionObj `
                            -ScriptBlock {  ($true -eq (Test-Path $using:baseDrivePath) ) } 
                if (-not $RemotePathDetailExists) {
                    Throw "$($spacer*1) $baseDrivePath is invalid"
                }
            }

            Write-Verbose ''
            if ($ArtistNameList.Length -gt 0) {
                <# There are artist name fragments to check #>

                :artistLoop foreach ($ArtistNameFragment in $ArtistNameList) {
                    <#
                        \\Syn414JNas\Backup\Passthrough
                        \\Syn414JNas\Backup\Passthrough\Music
                        \\Syn414JNas\Backup\Passthrough\Music\Flac
                    #>

                    $artistFilterPhrase = '*' + $($ArtistNameFragment.ToLower()) + '*'
                    Write-Verbose ''
                    Write-Verbose "$($spacer*1) Looking for albums from $artistFilterPhrase "

                    $baseDriveTargetPath = $baseDrivePath

                    if ($PSBoundParameters.ContainsKey('UseLocal')) {
                        
                        if (-not (Test-Path $baseDriveTargetPath)) {
                            <# Action to perform if the condition is true #>
                            Throw "$($spacer*1) $baseDriveTargetPath is invalid"
                            
                        } 
                    }
                    elseif ($PSBoundParameters.ContainsKey('UseRemote')) {
                        
                        $RemotePathDetailExists = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock {  ($true -eq (Test-Path $using:baseDriveTargetPath) ) } 
                        if (-not $RemotePathDetailExists) {
                            Throw "$($spacer*1) $baseDriveTargetPath is invalid"
                        }
                    }

                    Write-Verbose ''
                    Write-Verbose "$($spacer*2) Looking in  $baseDriveTargetPath "
                    Write-Verbose ''

                    if ($PSBoundParameters.ContainsKey('UseLocal')) {
                        $folders = Get-ChildItem -Path $baseDriveTargetPath -Filter $artistFilterPhrase `
                            -Directory -Recurse -ErrorAction SilentlyContinue | `
                                Sort-Object -Property LastWriteTime -Descending | `
                                Select-Object -First 1
                    }
                    elseif ($PSBoundParameters.ContainsKey('UseRemote')) {
                        $folders = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock {  Get-ChildItem -Path $using:baseDriveTargetPath -Filter $using:artistFilterPhrase `
                                        -Directory -Recurse -ErrorAction SilentlyContinue | `
                                            Sort-Object -Property LastWriteTime -Descending | `
                                            Select-Object -First 1 } 
                    }

                    if ($($folders.Count) -eq 0 -or $($folders.Count) -gt 1) {
                        $artistTag = ConvertTo-Plural -Word 'Artist'
                    }
                    else {
                        $artistTag = 'Artist'
                    }

                    Write-Verbose "$($spacer*3) Found $($folders.Count) $artistTag in $baseDriveTargetPath "
                    Write-Verbose "$($spacer*3) that match $artistFilterPhrase"
                    Write-Verbose "$($spacer*3) ------"

                    if ($folders.Count -gt 0) {
                            
                        foreach ($artistFolder in $folders) {

                            if ($PSBoundParameters.ContainsKey('UseRemote')) {
                                $artistFolder
                            }

                            $SearchFolderLocation = [ItemLocation]::New()

                            $SearchFolderLocation.Drive = $LocationList.Drive

                            if ($PSBoundParameters.ContainsKey('UseLocal')) {
                                $SearchFolderLocation.Path = (Get-Item $artistFolder.FullName)
                                $SearchFolderLocation.ComputerName = $env:COMPUTERNAME
                            }
                            elseif ($PSBoundParameters.ContainsKey('UseRemote')) {
                                $SearchFolderLocation.PathString = $($artistFolder.FullName)
                                $SearchFolderLocation.ComputerName = $artistFolder.PSComputerName
                            }
                            
                            Write-Verbose "$($spacer*3) Looking for albums to transfer in $($artistFolder.FullName) "
                            switch ($PSCmdlet.ParameterSetName) {
                                'LocalDateFilter' {
                                    Write-Verbose "$($spacer*3)$($spaceTwo) You used the LocalDateFilter parameter set."
                                    if ($PSBoundParameters.ContainsKey('FirstDateToCheckSeed')) {
                                        $localAlbums = $SearchFolderLocation | Get-LocalAblumDtlFromArtistPath -FirstDateToCheckSeed $FirstDateToCheckSeed `
                                                                                    -Verbose:$ShowVerbose -Debug:$ShowDebug
                                    }
                                    elseif ($PSBoundParameters.ContainsKey('DaysBackToCheck')) {

                                        $localAlbums = $SearchFolderLocation | Get-LocalAblumDtlFromArtistPath -DaysBackToCheck $DaysBackToCheck `
                                                                                    -Verbose:$ShowVerbose -Debug:$ShowDebug
                                    }
                                    break
                                }
                                'LocalNoDateFilter' {
                                    Write-Verbose "$($spacer*3)$($spaceTwo) You used the LocalNoDateFilter parameter set."
                                    $localAlbums = $SearchFolderLocation | Get-LocalAblumDtlFromArtistPath -Verbose:$ShowVerbose
                                    break
                                }
                                'RemoteDateFilter' {
                                    Write-Verbose "$($spacer*3)$($spaceTwo) You used the RemoteDateFilter parameter set."
                                    break
                                }
                                'RemoteNoDateFilter' {
                                    Write-Verbose "$($spacer*3)$($spaceTwo) You used the RemoteNoDateFilter parameter set."
                                    $localAlbums = $SearchFolderLocation | Get-RemoteAblumDtlFromArtistPath -remoteSessionObj $remoteSessionObj -Verbose:$ShowVerbose
                                    
                                    
                                    break
                                }
                            }

                                        
                            if ($($localAlbums.Count) -eq 0 -or $($localAlbums.Count) -gt 1) {
                                $AlbumTag = ConvertTo-Plural -Word 'album'
                            }
                            else {
                                $AlbumTag = 'album'
                            }

                            Write-Verbose "$($spacer*4) Found <$($localAlbums.Count)> $AlbumTag to transfer for $($artistFolder.Name) in $ArtistAlbumPath "

                            foreach ($localAlbum in $localAlbums) {
                                <# $currentItemName is the current item #>
                                    
                                
                                Write-Verbose "$($spacer*5) Found <$($localAlbum.Name)> with <$($AlbumTracks.Count)> $TrackTag to transfer for $($artistFolder.Name)"

                                $localAlbum

                                #debug
                                Continue 


                                $AlbumTrackPath = (Join-Path $ArtistAlbumPath $($localAlbum.Name))
                                if (-not (Test-Path $AlbumTrackPath)) {
                                    <# Action to perform if the condition is true #>
                                    Throw "$($spacer*4) $AlbumTrackPath is invalid"
                                        
                                } 

                                $AlbumTracks = Get-ChildItem -Path $AlbumTrackPath `
                                    -File -ErrorAction SilentlyContinue

                                $TrackTag = 'tracks'
                                if ($($AlbumTracks.Count) -eq 1) {
                                    <# Action to perform if the condition is true #>
                                    $TrackTag = 'track'
                                }

                                

                                $LocalAlbumObject = [PSCustomObject]@{
                                    AlbumName     = $localAlbum.Name
                                    LastWriteTime = $localAlbum.LastWriteTime
                                    ArtistName    = $artistFolder.Name
                                    TrackCount    = $($AlbumTracks.Count)
                                    Path          = $ArtistAlbumPath
                                    MusicSource   = $MusicFileSourse
                                }
                                            
                                Write-Output $LocalAlbumObject
                            }
                                
                        }
                    }
                        
                    Write-Verbose ''
                    
                }

            }
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
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Get-AlbumDtlForArtistList
# ============================================================================================