# ============================================================================================
# <Start> Get-FileMetaDataHash
# ============================================================================================
<#
     Enter a comment or description
#>
<# 
    .SYNOPSIS 
        Get-FileMetaDataHash returns metadata information about a single file. 
 
    .DESCRIPTION 
        This function will return all metadata information about a specific file. It can be used to access the information stored in the filesystem. 
    
    .EXAMPLE 
        Get-FileMetaDataHash -File "c:\temp\image.jpg" 
 
        Get information about an image file. 
 
    .EXAMPLE 
        Get-FileMetaDataHash -File "c:\temp\image.jpg" | Select Dimensions 
 
        Show the dimensions of the image. 
 
    .EXAMPLE 
        Get-ChildItem -Path .\ -Filter *.exe | foreach {Get-FileMetaDataHash -File $_.Name | Select Name,"File version"} 
 
        Show the file version of all binary files in the current folder. 
    #> 
function Get-FileMetaDataHash {
    [CmdletBinding(
        PositionalBinding,
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the qualified playlist file to copy.'
        )]
        [System.IO.FileInfo[]] $FileItem,

        [Parameter(Mandatory = $false
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the list of attributes to extrac.  Null list means return all.'
        )]
        [array] $AttributeList = @(),

        [Parameter(Mandatory = $false
            , ValueFromPipelineByPropertyName
            , HelpMessage = 'Specify the ShellApplication Object to use.'
        )]
        [Object] $ShellObjectRef
        
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
         
        <# Assign the Shell Object #>

        if ($null -ne $ShellObjectRef) {
            $shellobj = $ShellObjectRef
        }
        else {
            $shellobj = New-Object -ComObject Shell.Application 
        }

        <# Define working varibles #>
        [string]$private:Item = $null
        [string]$private:pathname = $null
        [string]$private:filename = $null
        [string]$private:SourceHashVal = $null

        [string]$private:TrackLenString = $null

        [int]$private:Hours = 0
        [int]$private:Minutes = 0
        [int]$private:Seconds = 0
        [decimal]$private:SecondsFraction = 0
        [decimal]$private:TotalMinutes = 0

        [hashtable]$private:hash = $null

        $private:folderobj = $null
        $private:fileobj = $null

    }
    
    process {
        try {
            $Item = $FileItem.FullName


            Write-Verbose "<$($FileItem.GetType())>"

            $pathname = $FileItem.DirectoryName 
            $filename = $FileItem.Name 

            <# Get the Hash value of the Path/Song #>
            # $SourceHashResults = Get-FileHash -LiteralPath $Item -Algorithm MD5                 
            # $SourceHashVal = $SourceHashResults.'Hash'
            $SourceHashVal = Get-HashFromStringStream -stringToHash $Item -hashAlgo MD5

            <# Build out the attributes for the track #>
            $hash = @{}

            <# Calculate the Attribute objects#>
            $folderobj = $shellobj.namespace($pathname) 
            $fileobj = $folderobj.parsename($filename) 

            :AttributeLoop for ($i = 0; $i -le 294; $i++) { 
                $name = $folderobj.getDetailsOf($null, $i)
                if ($name) {


                    if ($AttributeList.Count -gt 0 -and -not $AttributeList.Contains($name)) {
                        continue AttributeLoop
                    }

                    $value = $folderobj.getDetailsOf($fileobj, $i)
                    if ($value) {
                        $hash[$($name)] = $($value)
                    }
                }
            } 

            # Add the hash
            $hash['HashVal'] = $SourceHashVal

            <# Patch Genre if needed #>
            $RawGenre = $($hash['Genre'])
            if ($RawGenre.Length -gt 0) {
                ($RawGenre, $remainder) = $RawGenre.Split(';')
                $hash['Genre'] = $RawGenre
            }

            <# Calculate the time factors #>
            $TrackLenString = $hash['Length']    
            # 00:02:38
            # Size - estimate based on size;
            if ($TrackLenString.Length -gt 0) {
                ([Int16]$Hours, [Int16]$Minutes, [Int16]$Seconds) = $TrackLenString.Split(':')
            }
            else {
                <# Default to 3 minutes #>
                ([Int16]$Hours, [Int16]$Minutes, [Int16]$Seconds) = (0, 3, 0)
            }
        
                
            <# Calculate the progress towards a target list #>
            [decimal]$SecondsFraction = $Seconds / 60
            [decimal]$TotalMinutes = ($Hours * 60) + $Minutes + $SecondsFraction

            $hash['TotalMinutes'] = $TotalMinutes

            $hash['ItemPath'] = $Item

            Write-Output $hash

        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        finally {
            <# Remove the Shell Obj if it was created locally #>
            if ($null -eq $ShellObjectRef) {
                if ($shellobj) {
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$shellobj) | Out-Null
                }
            }
        }
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> Get-FileMetaDataHash
# ============================================================================================