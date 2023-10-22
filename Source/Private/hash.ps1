# ============================================================================================
# <Start> hash
# ============================================================================================
<#
     From https://stackoverflow.com/questions/71401162/creating-correct-sha256-hash-in-powershell

     To Do:  Move out to Utilities Micro-Project
#>

function hash {
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
        $privete:sha256 = New-Object -TypeName System.Security.Cryptography.SHA256Managed
        $privete:utf8 = New-Object -TypeName System.Text.UTF8Encoding
        $private:hash = $null
    }
    
    process {
        $hash = [System.BitConverter]::ToString($sha256.ComputeHash($utf8.GetBytes($textToHash)))

        Write-Output $($hash.replace('-', '').toLower())
    }
    
    end {
        
    }
}
# ============================================================================================
# <End> hash
# ============================================================================================