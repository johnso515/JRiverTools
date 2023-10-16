# ============================================================================================
# <Start> Get-MusicPathsFromHTPCForMusicSource
# ============================================================================================
<#
     Given the passed Music Source and connection return the set of valid music paths
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


function Get-MusicPathsFromHTPCForMusicSource {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        # Parameter help description
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
        [array]$private:TargetMediaDrives = @("I", "J", "K", "L")

        [hashtable]$private:driveLetterToNumberMap = @{"I" = 1;
                            "J" = 3;
                            "K" = 4;
                            "L" = 2;
                            }

        [PSCustomObject]$private:HTPCMusicPathObject = $null

        <# Working variables #>
        $private:mediaDrives = $null

        [int]$private:drivesChecked = 0

        [string]$private:rootString = $null
        [string]$private:DriveLetter = $null
        
        [int]$private:mediaDriveNbr = 0
        [string]$private:mediaTargetBase = $null

        [string]$private:baseDrivePath = $null
        
        [bool]$private:targetFullPathDetailExists = $false


    }
    
    process {
        try {
            Write-Verbose "$($spacer) Getting the remote drive letters"
            $mediaDrives = Invoke-Command -Session  $remoteSessionObj -ScriptBlock { Get-PSDrive -PSProvider FileSystem } 
            Write-Verbose "$($spacer) Found $($mediaDrives.Count) remote drive letters..."

            # [System.String[]]$LogsToGather = @('', '')
            

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
        
                # I:\Media1\Music\Flac
                :baseTargetLoop foreach ($musicTargetPath in $MusicFileSourses) {
        
                    $targetFullPathDetailExists = $false
    
                    # $baseDriveTargetPath = Join-Path -Path $baseDrivePath -ChildPath $musicTargetPath
    
                    $baseDriveTargetPath = Invoke-Command -Session $remoteSessionObj `
                            -ScriptBlock {  (Join-Path $using:baseDrivePath $using:musicTargetPath)  } 
    
                    # Write-Host "$spacer Debug: Testing $baseDriveTargetPath"
                    $targetFullPathDetailExists = Invoke-Command -Session $remoteSessionObj `
                            -ScriptBlock {  ($true -eq (Test-Path $using:baseDriveTargetPath) ) } 
    
        
                    if (-not $targetFullPathDetailExists) { 
                        Write-Verbose "$($spacer*2) Skipping $baseDriveTargetPath. Path does not exist on $rootString"
                        continue baseTargetLoop; 
                    }
    
                    Write-Verbose "$($spacer*2) Found $baseDriveTargetPath on $rootString"

                    $HTPCMusicPathObject = [PSCustomObject]@{
                            Drive = $rootString
                            Path = $baseDriveTargetPath
                            MusicSource = $musicTargetPath
                            # Used (GB)     Free (GB)
                            FreeSpaceBytes = $driveName.Free
                            UsedSpaceBytes = $driveName.Used
                        }
                        
                    Write-Output $HTPCMusicPathObject
                    # Write-Host "$spacer Debug: Pull sub-folders for $baseDriveTargetPath  ($musicTargetPath)"

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
# <End> Get-MusicPathsFromHTPCForMusicSource
# ============================================================================================