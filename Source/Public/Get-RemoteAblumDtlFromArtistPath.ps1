# ============================================================================================
# <Start> Get-RemoteAblumDtlFromArtistPath
# ============================================================================================
<#
     Return Album Objects for all albums in passed path (with optional date filters) from Remote host
#>

function Get-RemoteAblumDtlFromArtistPath {
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
            Write-Verbose "$($spacer*2) $($FirstDateToCheck.ToString('MM/dd/yyyy HH:MM')) to $($LastDateToCheck.ToString('MM/dd/yyyy HH:MM'))"

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

        [string]$private:WorkingFolder = $null

        <# Debug and display variables #>
        $private:spacer = $(' ' * 4)
        $private:spaceTwo = $(' ' * 2)

        [string]$private:AlbumTag = $null
    }
    
    process {
        try {

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
            
            Write-Verbose "$($spacer*2) Looking for albums in $WorkingFolder - $MusicSourceFolder "
            $AlbumEncodingObj = $MusicSourceFolder | Get-MetaDataFromSourceFolder -Verbose:$ShowVerbose
            
            
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
# <End> Get-RemoteAblumDtlFromArtistPath
# ============================================================================================