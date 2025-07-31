# based on https://gallery.technet.microsoft.com/scriptcenter/Get-FileMetaData-3a7ddea7

function Get-FileMetaData 
{ 
    <# 
    .SYNOPSIS 
        Get-FileMetaData returns metadata information about a single file. 
 
    .DESCRIPTION 
        This function will return all metadata information about a specific file. It can be used to access the information stored in the filesystem. 
    
    .EXAMPLE 
        Get-FileMetaData -File "c:\temp\image.jpg" 
 
        Get information about an image file. 
 
    .EXAMPLE 
        Get-FileMetaData -File "c:\temp\image.jpg" | Select Dimensions 
 
        Show the dimensions of the image. 
 
    .EXAMPLE 
        Get-ChildItem -Path .\ -Filter *.exe | foreach {Get-FileMetaData -File $_.Name | Select Name,"File version"} 
 
        Show the file version of all binary files in the current folder. 
    #> 
 
    param([Parameter(Mandatory=$True,ValueFromPipeline)][string]$File = $(throw "Parameter -File is required.")) 
 
    if(!(Test-Path -LiteralPath $File)) 
    { 
        throw "File does not exist: $File" 
        Exit 1 
    } 
 
    $tmp = Get-ChildItem $File 
    $pathname = $tmp.DirectoryName 
    $filename = $tmp.Name 
 
    $hash = @{}
    try{
        $shellobj = New-Object -ComObject Shell.Application 
        $folderobj = $shellobj.namespace($pathname) 
        $fileobj = $folderobj.parsename($filename) 
        
        for($i=0; $i -le 294; $i++) 
        { 
            $name = $folderobj.getDetailsOf($null, $i);
            if($name){
                $value = $folderobj.getDetailsOf($fileobj, $i);
                if($value){
                    $hash[$($name)] = $($value)
                }
            }
        } 
    }finally{
        if($shellobj){
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$shellobj) | out-null
        }
    }

    return New-Object PSObject -Property $hash
} 

# Export-ModuleMember -Function Get-FileMetadata