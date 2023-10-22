# ============================================================================================
#  Get-HashFromStringStream 
# ============================================================================================
# 
# https://infosecscout.com/get-md5-hash-in-powershell/
Function Get-HashFromStringStream
{
    [CmdletBinding(PositionalBinding = $False)]
    Param (

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $stringToHash,

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string] $hashAlgo = 'MD5',

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [bool] $showDetails = $false

    )
    Begin
    {
        # 
        [string]$private:hashedString = $null
        $private:hashedStringResults = $null
        $private:stringAsStream = $null
        $private:writer = $null

        
    }
    Process
    {
        

        if ($showDetails)
        {
            Write-Host ""
            Write-Host " --> Hash $stringToHash using the $hashAlgo algo. "


        }

        $stringAsStream = [System.IO.MemoryStream]::new()

        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($stringToHash)
        $writer.Flush()

        $stringAsStream.Position = 0
            
        $hashedStringResults = Get-FileHash -InputStream $stringAsStream -Algorithm $hashAlgo

        $hashedString = $hashedStringResults.Hash

        if ($showDetails)
        {
            Write-Host " --> The $hashAlgo hash of $stringToHash resulted in $hashedString. "
            Write-Host ""

        }

    }
    End
    {

        [string] $hashedString
    }
}
# ============================================================================================
#  <End> Get-HashFromStringStream
# ============================================================================================