#=============================================================================================================================
#
# Script Name:     Remediate_Edge_SharedArrayBuffers_setting.ps1
# Description:     Disable Microsoft Edge
#                  setting: Specifies whether SharedArrayBuffers can be used in a non cross-origin-isolated context
# Notes:           Creates dword property on registry key and sets value to 1
#
#=============================================================================================================================

# Define Variables
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

try {
    New-ItemProperty -Path $Path -Value 00000000 -PropertyType dword -Name "SharedArrayBufferUnrestrictedAccessAllowed"
    Write-Host "SharedArrayBufferUnrestrictedAccessAllowed dword property was successfully set to 0"
    exit 0
}
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}