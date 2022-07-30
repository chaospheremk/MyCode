#=============================================================================================================================
#
# Script Name:     Remediate_LSA_Protection.ps1
# Description:     Turn on LSA protection
# Notes:           Creates dword property on registry key and sets value to 1
#
#=============================================================================================================================

# Define Variables
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

try {
    New-ItemProperty -Path $Path -Value 00000001 -PropertyType dword -Name "RunAsPPL"
    exit 0
}
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}