# ============================================================================================
# <Start> Get-LocalAblumDtlFromArtistPath
# ============================================================================================
<#
     Return Album Objects for all albums in passed path (with optional date filters)
#>

function Get-LocalAblumDtlFromArtistPath {
    [CmdletBinding(
            PositionalBinding,
            DefaultParameterSetName = 'LocalNoDateFilter',
            SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position=0, ValueFromPipelineByPropertyName
        , ParameterSetName = 'LocalDateFilter', HelpMessage = 'Specify the set of locations to search.'
            )]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName
            , ParameterSetName = 'LocalNoDateFilter', HelpMessage = 'Specify the set of locations to search.'
        )]
        [ItemLocation] $LocationList,

        [Parameter(Mandatory = $false
            , ValueFromPipelineByPropertyName
            , ParameterSetName = 'LocalDateFilter'
            , HelpMessage = 'Specify date to use to filter the resutls (all results should be no older than the passed date).'
        )]
        [nullable[DateTime]] $FirstDateToCheckSeed,

        [Parameter(Mandatory = $false
            , ValueFromPipelineByPropertyName
            , ParameterSetName = 'LocalDateFilter'
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


        <# Set date params for date filtered results #>
        #region InitDateFilterParams
        
        
        if ($PSCmdlet.ParameterSetName -eq 'LocalDateFilter' -or $PSCmdlet.ParameterSetName -eq 'RemoteDateFilter') {
            
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
        <# Albums found in the current folder that match the passed artist and source #>
        $private:localAlbums = $null

        <# Output variables #>
        $private:AlbumObj = $null
        $private:AlbumEncodingObj = $null
        $private:AlbumDetails = $null
        [ItemLocation]$private:AlbumLocation = $null

        <# Debug and display variables #>
        $private:spacer = $(' ' * 4)
        $private:spaceTwo = $(' ' * 2)

        [string]$private:AlbumTag = $null
        
    }
    
    process {
        try {

            <# Set the encoding and source for all albums in the path: #>
            $MusicSourceFolder = $($($($LocationList.Path).Parent).Name)
            $AlbumEncodingObj = $MusicSourceFolder | Get-MetaDataFromSourceFolder -Verbose:$ShowVerbose
            
            Write-Verbose "$($spacer*3) Looking for albums in $($LocationList.Path) - $MusicSourceFolder "

            switch ($PSCmdlet.ParameterSetName) {
                'LocalDateFilter' {
                    Write-Debug "$($spacer*3)$($spaceTwo) You used the LocalDateFilter parameter set."
                    
                    
                    $localAlbums = Get-ChildItem -Path $($LocationList.Path) `
                                -Directory -ErrorAction SilentlyContinue | `
                                    Where-Object { $_.LastWriteTime -ge $FirstDateToCheck -and $_.LastWriteTime -lt $LastDateToCheck} 
                    break
                }
                'LocalNoDateFilter' {
                    Write-Debug "$($spacer*3)$($spaceTwo) You used the LocalNoDateFilter parameter set."
                    $localAlbums = Get-ChildItem -Path $($LocationList.Path) `
                                -Directory -ErrorAction SilentlyContinue
                    break
                }
            }
            if ($($localAlbums.Count) -eq 0 -or $($localAlbums.Count) -gt 1) {
                $AlbumTag = ConvertTo-Plural -Word 'album'
            }
            else {
                $AlbumTag = 'album'
            }

            # Write-Verbose "$($spacer*3) Found $($localAlbums) $AlbumTag to report."
            <# Build the output objects #>
            $localAlbums | ForEach-Object {

                $AlbumLocation = [ItemLocation]::New()

                <# Use value from passed in parent location #>
                $AlbumLocation.Drive = $LocationList.Drive
                # [System.IO.FileSystemInfo]
                $AlbumLocation.Path = (Get-Item $_.FullName)

                $AlbumDetails = Get-ChildItem -Path $($_.FullName) -File | Measure-Object Length -Sum

                $AlbumObj = [PSCustomObject]@{
                    ArtistName = $($($LocationList.Path).Name)
                    AlbumName = $($($AlbumLocation.Path).Name)
                    Genre = $null
                    Location = [ItemLocation]$AlbumLocation  # [ItemLocation]
                    Encoding = [MusicEncodings]$($AlbumEncodingObj.FolderEncoding)   # [MusicEncodings] 'flac'
                    PurchaseSource = [MusicSources]$($AlbumEncodingObj.FolderSource) # [MusicSources] 'cd'
                    AlbumSizeBytes = $AlbumDetails.Sum      # [int64]
                    TracksFound = $AlbumDetails.Count 
                }
    
                Write-Output $AlbumObj

            }

            <# 
                These are derived later
                    [hashtable]$AlbumTracks = [ordered]@{}
                    [int]$TracksFound = $this.AlbumTrackHashes.Count
            #>


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
# <End> Get-LocalAblumDtlFromArtistPath
# ============================================================================================