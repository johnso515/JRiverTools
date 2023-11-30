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
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
        )]
        [ValidateSet('HTPC'
        )]
        [string] $TargetServer,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
        )]
        [string] $TargetDriveLetter = 'C',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of locations to search.'
        )]
        [string] $TargetBasePath = 'Media1',


        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the set of folders to create in the target.'
        )]
        [hashtable] $FoldersToCreate = @{}

        
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
        <# Definition vars #>
        <# To Do: Pull these from a config or function #>
        [array]$private:TargetMediaPaths = @('Music', 'Podcasts', 'Video')

        [hashtable]$private:TargetMediaSubPaths = @{}

        [hashtable]$private:MasterMediaSubPaths = @{
            'Music'    = @('Amazon MP3'
                , 'Bandcamp'
                , 'Flac'
                , 'HDTracks'
                , 'Playlists'
                , 'Wma'
                , 'MP3'
            )
            'Podcasts' = @()
            'Video'    = @('4KUHD'
                , 'BluRay'
                , 'Dvd'
            )
        }

        [System.Collections.ArrayList]$private:CandidateSubPathsToCheck = @()

        Write-Debug ""
        if ($null -eq $FoldersToCreate -or $FoldersToCreate.Count -eq 0) {
            Write-Debug "$($spacer*1)$($spaceTwo*1) Initializing Sub paths from default."
            
            foreach ($MediaTypePath in $MasterMediaSubPaths.Keys) {
                $CandidateSubPathsToCheck.Clear()
                Write-Debug "$($spacer*2)$($spaceTwo*1) Initializing $MediaTypePath."
                foreach ($currentItemName in $($MasterMediaSubPaths[$MediaTypePath])) {
                    Write-Debug "$($spacer*2)$($spaceTwo*2) Initializing $currentItemName for $MediaTypePath."
                    [void]$CandidateSubPathsToCheck.Add($currentItemName)
                }
                $TargetMediaSubPaths[$MediaTypePath] = $CandidateSubPathsToCheck
                Write-Debug "$($spacer*2)$($spaceTwo*1) Initializing $MediaTypePath.<$($CandidateSubPathsToCheck.Count)>"
                Write-Debug ""
            }

        }
        else {
            Write-Debug "$($spacer*1)$($spaceTwo*1) Initializing Sub paths from passed set."
            
            foreach ($MediaTypePath in $FoldersToCreate.Keys) {
                $CandidateSubPathsToCheck.Clear()
                Write-Debug "$($spacer*2)$($spaceTwo*1) Initializing $MediaTypePath."
                foreach ($currentItemName in $($FoldersToCreate[$MediaTypePath])) {
                    Write-Debug "$($spacer*2)$($spaceTwo*2) Initializing $currentItemName for $MediaTypePath."
                    [void]$CandidateSubPathsToCheck.Add($currentItemName)
                }
                $TargetMediaSubPaths[$MediaTypePath] = $CandidateSubPathsToCheck
                Write-Debug "$($spacer*2)$($spaceTwo*1) Initializing $MediaTypePath.<$($CandidateSubPathsToCheck.Count)>"
                Write-Debug ""
            }
        }
        Write-Debug ""

        [System.Collections.ArrayList]$private:SubPathsToCheck = @()

        <# Working variables #>
        $private:mediaDrives = $null

        <# Display and debug vars #>
        [string]$private:spaceTwo = $(' ' * 2)
        [string]$private:spacer = $(' ' * 4)

        [string]$private:PathTag = $null
        
        #region InitializationVars
        $private:remoteUserName = $null
        $private:remotePswd = $null

        <# To do: Move this to a function in the common tools process #>
        switch ($TargetServer) {
            'HTPC' { 
                $remoteUserName = Get-SecretForPassedName -SecretToFetch 'htpcUserName' -FetchPlainText $true
                $remotePswd = Get-SecretForPassedName -SecretToFetch 'htpcPswd' -FetchPlainText $false
            }
            Default {
                $remoteUserName = Get-SecretForPassedName -SecretToFetch 'htpcUserName' -FetchPlainText $true
                $remotePswd = Get-SecretForPassedName -SecretToFetch 'htpcPswd' -FetchPlainText $false
            }
        }
        
        $private:remoteCreds = New-Object System.Management.Automation.PSCredential ($remoteUserName, $remotePswd)

        $private:remoteSessionObj = New-PSSession -ComputerName $TargetServer -Credential $remoteCreds
        #endregion

        <# Processing varibles #>

        [bool]$private:targetBasePathExists = $false
        [string]$private:ComputerName = $null
        

        <# Path Vars for the new paths #>
        [string]$private:TargetRootPath = $null     # e.g. Media5
        [string]$private:TargetMediaPath = $null    # e.g. Media/Podcasts/Video
        [string]$private:TargetMediaSubPath = $null # e.g. flac/4KUHD/etc.

        [int]$private:PathCount = 0
        <# Return value #>
        [psobject]$private:RemotePathObject = $null 
        [bool]$private:PathCreated = $false
        
    }
    
    process {
        try {
            
            Write-Verbose "$($spacer) Getting the remote drive letters"
            $mediaDrives = Invoke-Command -Session $remoteSessionObj -ScriptBlock { Get-PSDrive -PSProvider FileSystem } 
            Write-Verbose "$($spacer) Found $($mediaDrives.Count) remote drive letters..."
            
            Write-Verbose "$($spacer*1)Building out the music tree for $TargetDriveLetter and $TargetBasePath in Music on $TargetServer"
        
            $drivesChecked = 0

            $ComputerName = Invoke-Command -Session $remoteSessionObj `
                -ScriptBlock { $env:COMPUTERNAME } 

            :driveLoop foreach ($driveName in $mediaDrives ) {
        
                $rootString = $null
        
                # L:\Media2\Video\4KUHD
                $DriveLetter = $($driveName.Name)
        
                Write-Debug "$($spacer) $($drivesChecked.ToString().PadLeft(2)): Pre-check for $DriveLetter vs $TargetDriveLetter"
                
                if ($TargetDriveLetter -ne $DriveLetter) {
                    Write-Debug "$($spacer*2) Skipping $DriveLetter"
                    continue driveLoop
                }

                $drivesChecked++
        
                $rootString = $driveName.Root.ToString()
        
                Write-Verbose ''
                Write-Verbose "$($spacer) $($drivesChecked.ToString().PadLeft(2)): Begin Path check for $DriveLetter"
                Write-Verbose "$($spaceTwo) $('-'*$($($spacer.Length)*10))"
        
                Write-Verbose "$($spacer*1)$($spaceTwo*1) Checking for $TargetBasePath, $rootString"

                
                $TargetRootPath = Set-RemotePath -TargetBasePath $($DriveLetter + ':') `
                    -TargetLeafPath $TargetBasePath -session $remoteSessionObj  `
                    -Verbose:$showVerbose -WhatIf:$ShowWhatIf


                if (-not $ShowWhatIf -and $TargetRootPath.Length -eq 0) {
                    <# We did not create the path #>
                    Write-Verbose "$($spacer*2) Failed to Create $TargetRootPath."
                    Throw 'Failed to create new path'
                }

                Write-Verbose "$($spacer*2) Created/found $TargetRootPath. <Root>"

                if ($null -eq $TargetMediaSubPaths -or $($TargetMediaSubPaths.Count) -eq 0) {
                    $PathCount = 0
                }
                else {
                    $PathCount = $($TargetMediaSubPaths.Count)
                }

                $PathTag = ConvertTo-CorrectCase -Word 'Sub-path' -ItemCount $PathCount

                Write-Verbose "$($spacer*1)$($spaceTwo*1) Checking for $($TargetMediaSubPaths.Count) $PathTag for $TargetBasePath. <$($($TargetMediaSubPaths.Keys))>"
                
                :MediaLoop foreach ($MediaPath in $TargetMediaSubPaths.Keys | Sort-Object) {
                    <# $currentItemName is the current item #>


                    $TargetMediaPath = Set-RemotePath -TargetBasePath $TargetRootPath `
                        -TargetLeafPath $MediaPath -session $remoteSessionObj  `
                        -DisplayOffset 2 `
                        -Verbose:$showVerbose -WhatIf:$ShowWhatIf

                    if (-not $ShowWhatIf -and $TargetMediaPath.Length -eq 0) {
                        <# We did not create the path #>
                        Write-Verbose "$($spacer*2)$($spaceTwo) Failed to Create $MediaPath in $TargetRootPath."
                        Throw 'Failed to create new path'
                    }
                    
                    Write-Verbose "$($spacer*2)$($spaceTwo) Created/found $TargetMediaPath. <Level 1>"

                    <# Build out the sub-folders for the media root #>
                    if (-not $null -eq $SubPathsToCheck) {
                        [void]$SubPathsToCheck.Clear()
                    }
                    
                    $SubPathsToCheck = $TargetMediaSubPaths[$MediaPath]

                    <# 
                            Default path if ShowWhatIf is set 
                            - e.g. we wont have created the parent path
                    #>
                    if ($ShowWhatIf -and $TargetMediaPath.Length -eq 0) {
                        <# Suppress Verbose for this specific call #>
                        $TargetMediaPath = Build-PathFromParts -PathParts @($TargetRootPath, $MediaPath) -Verbose:$false
                    }
                    if ($null -eq $SubPathsToCheck -or $SubPathsToCheck.Count -eq 0) {
                        $PathCount = 0
                    }
                    else {
                        $PathCount = $SubPathsToCheck.Count
                    }

                    $PathTag = ConvertTo-CorrectCase -Word 'sub-path' -ItemCount $PathCount
                    Write-Verbose "$($spacer*2)$($spaceTwo) Creating $($PathCount.ToString()) $PathTag for $TargetMediaPath."
                    Write-Verbose "$($spacer*2)$($spaceTwo) Debug: <$($TargetMediaPath.Length.ToString())>. Basis -> $MediaPath in $TargetRootPath. <$ShowWhatIf>"

                    :SubPathLoop foreach ($MediaSubPath in $SubPathsToCheck) {
                        Write-Verbose "$($spacer*3) Attempting to create $MediaSubPath in $TargetMediaPath."
                        
                        $TargetMediaSubPath = Set-RemotePath -TargetBasePath $TargetMediaPath `
                            -TargetLeafPath $MediaSubPath -session $remoteSessionObj  `
                            -DisplayOffset 3 `
                            -Verbose:$showVerbose -WhatIf:$ShowWhatIf

                        if (-not $ShowWhatIf -and $TargetMediaSubPath.Length -eq 0) {
                            <# We did not create the path #>
                            Write-Verbose "$($spacer*3) Failed to Create $MediaSubPath in $TargetMediaPath."
                            Throw 'Failed to create new path'
                        }
                    
                        if ($ShowWhatIf -and $TargetMediaSubPath.Length -eq 0) {
                            <# Suppress Verbose for this specific call #>
                            $TargetMediaSubPath = Build-PathFromParts -PathParts @($TargetMediaPath, $MediaSubPath) -Verbose:$false
                        }

                        Write-Verbose "$($spacer*3) Created/found $TargetMediaSubPath."

                        $PathCreated = Test-RemotePath -TargetPathToCheck $TargetMediaSubPath `
                                                        -DisplayOffset $(3 + 1) `
                                                        -session $remoteSessionObj -Verbose:$ShowVerbose

                        $RemotePathObject = [PSCustomObject]@{
                            Drive          = $rootString
                            Path           = $TargetMediaSubPath
                            MusicSource    = $MediaSubPath
                            FreeSpaceBytes = $driveName.Free
                            UsedSpaceBytes = $driveName.Used
                            ComputerName   = $ComputerName
                            Created        = $PathCreated
                        }
                        
                        Write-Output $RemotePathObject
                    }

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