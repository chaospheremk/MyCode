#=============================================================================================================================
#
# Script Name:     Remediate_IE_RestrictLegacyJscript.ps1
# Description:     Create registry key, registry properties, and set their value.
# Notes:           
#
#=============================================================================================================================

#Set ErrorAction preference
$ErrorActionPreference = "SilentlyContinue"

# Define Variables
$Path = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE"
$Processes = "excel.exe", "msaccess.exe", "mspub.exe", "onenote.exe", "outlook.exe", "powerpnt.exe", "visio.exe", "winproj.exe", "winword.exe"

try {
    if (!(Test-Path -Path $Path)) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl" -Name "FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE" | Out-Null
    }

    foreach ($Process in $Processes) {
        if (!(Get-ItemProperty -Path $Path -Name $Process -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $Path -PropertyType dword -Name $Process -Value 69632 | Out-Null
        }
        elseif ((Get-ItemPropertyValue -Path $Path -Name $Process) -ne 69632) {
            Set-ItemProperty -Path $Path -Name $Process -Value 69632 -Force | Out-Null
        }
    }
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}