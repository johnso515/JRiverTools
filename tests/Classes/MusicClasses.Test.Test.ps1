# Test Script for MusicClasses.Test

# Import-Module -Force $PSScriptRoot\..\MusicClasses.Test.ps1

<#
    . Source the function
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\$sut"

<#
    Tests
        Describe a test case
        Describe another test case
        Describe another test case
        Etc.,
        
#>
<#
    Write a failing test
#>
Describe 'MusicClasses.Test' {

    It "does something useful" {
        $true | Should Be $false
    }

}
