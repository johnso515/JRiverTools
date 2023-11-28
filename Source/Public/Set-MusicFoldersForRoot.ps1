# ============================================================================================
# <Start> Set-MusicFoldersForRoot
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


function Set-MusicFoldersForRoot {
    [CmdletBinding(
        PositionalBinding,
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position=0, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
            )]
        [ValidateSet("HTPC"
            )]
        [string] $TargetServer,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
            )]
        [string] $TargetDriveLetter = 'C',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
            )]
        [string] $TargetBasePath = 'Media1'

        
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
        <#
        s/b one of these.. 
        $musicTargetPaths = @("Amazon MP3"
                                , "Bandcamp"
                                , "Flac"
                                , "HDTracks"
                                , "Playlists"
                                , "Wma"
                                , "MP3"
                            )
        #>
        <# Working variables #>
        $private:mediaDrives = $null

        <# Display and debug vars #>
        [string]$private:spaceTwo = $(' ' * 2)
        [string]$private:spacer = $(' ' * 4)

        #region InitializationVars
        $private:remoteUserName = $null
        $private:remotePswd = $null

        <# To do: Move this to a function in the common tools process #>
        switch ($TargetServer) {
            'HTPC' { 
                $remoteUserName = Get-SecretForPassedName -SecretToFetch "htpcUserName" -FetchPlainText $true
                $remotePswd = Get-SecretForPassedName -SecretToFetch "htpcPswd" -FetchPlainText $false
             }
            Default {
                $remoteUserName = Get-SecretForPassedName -SecretToFetch "htpcUserName" -FetchPlainText $true
                $remotePswd = Get-SecretForPassedName -SecretToFetch "htpcPswd" -FetchPlainText $false
            }
        }
        
        $private:remoteCreds = New-Object System.Management.Automation.PSCredential ($remoteUserName, $remotePswd)

        $private:remoteSessionObj = New-PSSession -ComputerName $TargetServer -Credential $remoteCreds
        #endregion

        <# Processing varibles #>

        [bool]$private:targetBasePathExists = $false


    }
    
    process {
        try {
            
            Write-Verbose "$($spacer) Getting the remote drive letters"
            $mediaDrives = Invoke-Command -Session  $remoteSessionObj -ScriptBlock { Get-PSDrive -PSProvider FileSystem } 
            Write-Verbose "$($spacer) Found $($mediaDrives.Count) remote drive letters..."
            
            Write-Verbose "$($spacer*1)Building out the music tree for $TargetDriveLetter and $TargetBasePath in Music on $TargetServer"
        
            $drivesChecked = 0

            :driveLoop foreach ($driveName in $mediaDrives ) {
        
                $rootString = $null
        
                # L:\Media2\Video\4KUHD
                $DriveLetter = $($driveName.Name)
        
                
                if (-not $TargetDriveLetter -eq $DriveLetter) {
                    Write-Verbose "$($spacer) Skipping $DriveLetter"
                    continue driveLoop;
                }
                $drivesChecked++
        
                $rootString = $driveName.Root.ToString()
        
                Write-Verbose ""
                Write-Verbose "$($spacer) $($drivesChecked.ToString().PadLeft(2)): Begin Path check for $rootString"
                Write-Verbose "$($spaceTwo) $('-'*$($($spacer.Length)*10))"
        

                $mediaTargetBase = $TargetBasePath
        
                $ComputerName = Invoke-Command -Session $remoteSessionObj `
                                    -ScriptBlock {  $env:COMPUTERNAME  } 

                $TargetRootPath = Build-PathFromParts -PathParts @($rootString, $TargetBasePath)
                # Write-Host "$spacer Debug: Testing $baseDriveTargetPath"
                $targetBasePathExists = Invoke-Command -Session $remoteSessionObj `
                                        -ScriptBlock {  ($true -eq (Test-Path $using:baseDriveTargetPath) ) } 

                $baseDrivePath = Invoke-Command -Session $remoteSessionObj `
                                -ScriptBlock {  (Join-Path $using:rootString $using:TargetRootPath)  } 
        
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
                            ComputerName = $ComputerName
                        }
                        
                    Write-Output $HTPCMusicPathObject
                    # Write-Host "$spacer Debug: Pull sub-folders for $baseDriveTargetPath  ($musicTargetPath)"

                }
            }
        
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        finally {
            if (-not $null -eq $remoteSessionObj) {
                Remove-PSSession -Session $remoteSessionObj
            }
        
            [System.GC]::Collect()
        }
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Set-MusicFoldersForRoot
# ============================================================================================