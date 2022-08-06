#=============================================================================================================================
#
# Script Name:     Detect_Edge_SharedArrayBuffers_setting.ps1
# Description:     Determine whether following Microsoft Edge registry value exists for
#                  setting: Specifies whether SharedArrayBuffers can be used in a non cross-origin-isolated context
# Notes:           Part of the Microsoft Edge v103 baseline
#
#=============================================================================================================================

# Define Variables
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

try {
    if ((Get-ItemProperty -Path $Path).RunAsPPL -ne 0) {
        Write-Host "SharedArrayBufferUnrestrictedAccessAllowed dword property is not set to 0"
        exit 1
    }
    else {
        Write-Host "SharedArrayBufferUnrestrictedAccessAllowed dword property is already set to 0"
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
