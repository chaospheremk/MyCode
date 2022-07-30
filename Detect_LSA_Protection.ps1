#=============================================================================================================================
#
# Script Name:     Detect_LSA_Protection.ps1
# Description:     Determine whether LSA protection is on or not
# Notes:           
#
#=============================================================================================================================

# Define Variables
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

try {
    if ((Get-ItemProperty -Path $Path).RunAsPPL -ne 1) {
        Write-Host "RunAsPPL dword property is not set to 1"
        exit 1
    }
    else {
        Write-Host "RunAsPPL dword property is already set to 1"
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
