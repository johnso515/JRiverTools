# ============================================================================================
# <Start> Get-MetaDataFromSourceFolder
# ============================================================================================
<#
     Derive the encoding and source attributes from the name of the passed folder root (e.g Flac, Bandcamp, etc.)
#>

function Get-MetaDataFromSourceFolder {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline, Position = 0
        , ValueFromPipelineByPropertyName
        , HelpMessage = "Specify the folder name to classify. This defaults to Flac."
                    )]
        [string[]] $SourceFolder = 'Music'
        
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
         
        <# Output variables #>
        
        [MusicEncodings]$private:FolderEncoding = 'unknown'
        [MusicSources]$private:FolderSource = 'unknown'

        $private:EncodingDtl = $null

        <# Debug and display variables #>
        $private:spacer = $(' ' * 4)
        $private:spaceTwo = $(' ' * 2)
        
    }
    
    process {
        try {
            <#
                flac = 1
                mp3 =  2
                wma = 4
                unknown = 0

                amazonmusic = 1
                applemusic = 2
                bandcamp = 4
                bluray = 8
                cd = 16
                dvd = 32
                hdtracks = 64
                tidal = 128
                primemusic
                unknown = 0
            #>
            switch ($SourceFolder) {
                'Amazon MP3' {
                    $FolderEncoding = 'mp3'
                    $FolderSource = 'amazonmusic'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource>"
                    break
                }
                'Bandcamp' {
                    $FolderEncoding = 'flac'
                    $FolderSource = 'bandcamp'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource>"
                    break
                }
                'Flac' {
                    $FolderEncoding = 'flac'
                    $FolderSource = 'cd'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource>"
                    break
                }
                'HDTracks' {
                    $FolderEncoding = 'flac'
                    $FolderSource = 'hdtracks'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource>"
                    break
                }
                'Wma' {
                    $FolderEncoding = 'wma'
                    $FolderSource = 'unknown'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource>"
                    break
                }
                'MP3' {
                    $FolderEncoding = 'mp3'
                    $FolderSource = 'unknown'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource>"
                    break
                }
                'default' {
                    $FolderEncoding = 'flac'
                    $FolderSource = 'cd'
                    Write-Verbose "$($spacer*4)$($spaceTwo) Found Folder $MusicSourceFolder for encoding <$FolderEncoding> and source <$FolderSource> (Defaulted)"
                    break

                }
            }
            $EncodingDtl = [PSCustomObject]@{
                FolderEncoding = $FolderEncoding
                FolderSource = $FolderSource
            }

            Write-Output $EncodingDtl

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
# <End> Get-MetaDataFromSourceFolder
# ============================================================================================