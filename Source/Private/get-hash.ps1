# ============================================================================================
# <Start> get-hash
# ============================================================================================
<#
    From https://xpertkb.com/compute-hash-string-powershell/

    To Do:  Move out to Utilities Micro-Project
#>

function get-hash {
    [CmdletBinding(
            PositionalBinding,
             SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory
            , ValueFromPipeline
            , ValueFromPipelineByPropertyName
            , HelpMessage = "Specify the project details.")]
        [ValidateNotNullOrEmpty()]
        [string]$textToHash
        
    )
    
    begin {
        $privete:hasher = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
        $private:toHash = $null
        $private:hashByteArray = $null
        $private:result = $null
    }
    
    process {
        
        $toHash = [System.Text.Encoding]::UTF8.GetBytes($textToHash)
        $hashByteArray = $hasher.ComputeHash($toHash)
        foreach ($byte in $hashByteArray)
        {
            $result += "{0:X2}" -f $byte
        }
        Write-Output $result
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> get-hash
# ============================================================================================