# ============================================================================================
# <Start> GetLocalAlbumToCopyToHTPC
# ============================================================================================
<#
     Get the most Recent Album folder in the music passthrough path that matches the passed 
     Artist and music source info
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


function GetLocalAlbumToCopyToHTPC {
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
        [string[]] $ArtistNamesToCopy, 

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

        [Parameter(Mandatory=$false, 
                     ValueFromPipeline=$true
                    )]
        [string] $NASUNCPath = '\\syn414jnas\Backup',

        [Parameter(Mandatory=$false, 
                     ValueFromPipeline=$true
                    )]
        [string] $TransferRoot = 'Passthrough',

        [Parameter(Mandatory=$false, 
                     ValueFromPipeline=$true
                    )]
        [string] $AlbumRoot = 'Music',
        
        [Parameter(Mandatory=$false, 
                     ValueFromPipeline=$true
                    )]
        [nullable[DateTime]] $FirstDateToCheckSeed = $null,

        [Parameter(Mandatory=$false, 
                     ValueFromPipeline=$true
                    )]
        [ValidateRange(0,90)]
        [int]$DaysBackToCheck = 2

        
    )
    
    begin {
        $private:spacer = $(" "*4)
        $private:spaceTwo = $(" "*2)

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
        [nullable[DateTime]]$private:FirstDateToCheck = $null

        if ($null -eq $FirstDateToCheckSeed) {
            <# Action to perform if the condition is true #>
            $FirstDateToCheck = $(Get-Date).AddDays(-$DaysBackToCheck)
        }
        else {
            <# Action when all if and elseif conditions are false #>
            if  ($FirstDateToCheckSeed -gt (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-$DaysBackToCheck) `
                    -and $FirstDateToCheckSeed -le (Get-Date)) {
                $FirstDateToCheck = $FirstDateToCheckSeed
            }
            else {
                <# Action when all if and elseif conditions are false #>
                Throw "$($FirstDateToCheckSeed.ToString('MM/dd/yyyy HH:MM')) is invalid. Valid Filter dates must be within the last $DaysBackToCheck days."
            }
        }

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

        [PSCustomObject]$private:LocalAlbumObject = $null
    }
    
    process {
        <#
            Find any artist paths for the passed set. 
            Then find any albums within the artist that are within the date window
        #>

        try {
                            
            <#
                Set up the basic file paths to check
            #>
            if (-not (Test-Path $NASUNCPath)) {
                <# Action to perform if the condition is true #>
                Throw "$($spacer*1) $NASUNCPath is invalid"
                
            } 
            $baseDrivePath = (Join-Path $NASUNCPath $TransferRoot)  
            if (-not (Test-Path $baseDrivePath)) {
                <# Action to perform if the condition is true #>
                Throw "$($spacer*1) $baseDrivePath is invalid"
                
            } 
            $baseDrivePath = (Join-Path $baseDrivePath $AlbumRoot)
            if (-not (Test-Path $baseDrivePath)) {
                <# Action to perform if the condition is true #>
                Throw "$($spacer*1) $baseDrivePath is invalid"
                
            } 

            Write-Verbose ""
            if ($ArtistNamesToCopy.Length -gt 0) {
                <# There are artist name fragments to check #>

                :artistLoop foreach ($ArtistNameFragment in $ArtistNamesToCopy) {
                    <#
                        \\Syn414JNas\Backup\Passthrough
                        \\Syn414JNas\Backup\Passthrough\Music
                        \\Syn414JNas\Backup\Passthrough\Music\Flac
                    #>

                    $artistFilterPhrase = "*" + $($ArtistNameFragment.ToLower()) + "*"
                    Write-Verbose ""
                    Write-Verbose "$($spacer*1) Looking for albums from $artistFilterPhrase "

                    if ($MusicFileSourse.Length -gt 0) {

                        foreach ($MusicFileSourse in $MusicFileSourses) {
                            <# $currentItemName is the current item #>

                        
                            $baseDriveTargetPath = (Join-Path $baseDrivePath $MusicFileSourse) 
                            if (-not (Test-Path $baseDriveTargetPath)) {
                                <# Action to perform if the condition is true #>
                                Throw "$($spacer*1) $baseDriveTargetPath is invalid"
                                
                            } 

                            Write-Verbose ""
                            Write-Verbose "$($spacer*2) Looking in  $baseDriveTargetPath "
                            Write-Verbose ""

                            $folders = Get-ChildItem -Path $baseDriveTargetPath -Filter $artistFilterPhrase `
                                                        -Directory -ErrorAction SilentlyContinue  | `
                                                        Sort-Object -Property LastWriteTime -Descending | `
                                                        Select-Object -First 1
                            
                            
                            $artistTag = 'Artists'
                            if ($($folders.Count) -eq 1) {
                                <# Action to perform if the condition is true #>
                                $artistTag = 'Artist'
                            }
                            Write-Verbose "$($spacer*3) Found $($folders.Count) $artistTag in $baseDriveTargetPath "
                            Write-Verbose "$($spacer*3) that match $artistFilterPhrase"
                            Write-Verbose "$($spacer*3) ------"

                            if ($folders.Count -gt 0)
                                {
                                    
                                    foreach ($artistFolder in $folders) {
                                        <# $artistFolder is the current item #>
                                        $ArtistAlbumPath = (Join-Path $baseDriveTargetPath $($artistFolder.Name)) 
                                        if (-not (Test-Path $ArtistAlbumPath)) {
                                            <# Action to perform if the condition is true #>
                                            Throw "$($spacer*4) $ArtistAlbumPath is invalid"
                                            
                                        } 

                                        Write-Verbose "$($spacer*4) Looking for albums to transfer in $ArtistAlbumPath "
                                        $localAlbums = Get-ChildItem -Path $ArtistAlbumPath `
                                                                -Directory -ErrorAction SilentlyContinue  | `
                                                                Where-Object {$_.LastWriteTime -ge $FirstDateToCheck} 

                                        
                                        $AlbumTag = 'albums'
                                        if ($($localAlbums.Count) -eq 1) {
                                            <# Action to perform if the condition is true #>
                                            $AlbumTag = 'album'
                                        }
                                        Write-Verbose "$($spacer*4) Found <$($localAlbums.Count)> $AlbumTag to transfer for $($artistFolder.Name) in $ArtistAlbumPath "

                                        foreach ($localAlbum in $localAlbums) {
                                            <# $currentItemName is the current item #>
                                            
                                            
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

                                            Write-Verbose "$($spacer*5) Found <$($localAlbum.Name)> with <$($AlbumTracks.Count)> $TrackTag to transfer for $($artistFolder.Name)"

                                            $LocalAlbumObject = [PSCustomObject]@{
                                                AlbumName = $localAlbum.Name
                                                LastWriteTime = $localAlbum.LastWriteTime
                                                ArtistName = $artistFolder.Name
                                                TrackCount = $($AlbumTracks.Count)
                                                Path = $ArtistAlbumPath
                                                MusicSource = $MusicFileSourse
                                            }
                                            
                                            Write-Output $LocalAlbumObject
                                        }
                                        
                                    }
                                }
                        }
                        Write-Verbose ""
                    }
                }

            }
        }
        catch {

            Write-Host " Hit some error!"
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
# <End> GetLocalAlbumToCopyToHTPC
# ============================================================================================