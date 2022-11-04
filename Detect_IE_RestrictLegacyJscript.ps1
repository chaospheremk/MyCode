#=============================================================================================================================
#
# Script Name:     Detect_Detect_IE_RestrictLegacyJscript.ps1
# Description:     Determine whether following MS Security Guide registry value exists for
#                  setting: Restrict legacy JScript execution for Office
# Notes:           Part of the Microsoft 365 Apps for Enterprise baseline Restrict Legacy JScript settings
#
#=============================================================================================================================

# Set ErrorAction preference
$ErrorActionPreference = "SilentlyContinue"

# Define Variables
$Path = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE"
$Processes = "excel.exe", "msaccess.exe", "mspub.exe", "onenote.exe", "outlook.exe", "powerpnt.exe", "visio.exe", "winproj.exe", "winword.exe"

try {
    if (!(Test-Path -Path $Path)) {
        $ExitCode = 1
    }
    foreach ($Process in $Processes) {
        if ((!(Get-ItemProperty -Path $Path -Name $Process -ErrorAction SilentlyContinue)) -or ((Get-ItemPropertyValue -Path $Path -Name $Process -ErrorAction SilentlyContinue) -ne 69632)) {
            $ExitCode = 1
        }
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    $ExitCode = 1
}

if ($ExitCode = 1) {
    exit 1
}
else {
    exit 0
}