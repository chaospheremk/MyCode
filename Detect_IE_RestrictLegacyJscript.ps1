#=============================================================================================================================
#
# Script Name:     Detect_Detect_IE_RestrictLegacyJscript.ps1
# Description:     Determine whether following MS Security Guide registry value exists for
#                  setting: Restrict legacy JScript execution for Office
# Notes:           Part of the Microsoft Edge v103 baseline
#
#=============================================================================================================================

# Define Variables
$Path = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE"
$Processes = "excel.exe","mspub.exe","powerpnt.exe","onenote.exe","visio.exe","winproj.exe","winword.exe","outlook.exe","msaccess.exe"

try {
    if (!(Test-Path -Path $Path)) {
        $RemediationNeeded = $true
    }
    
    foreach($Process in $Processes) {
        if ((!(Test-Path -Path "$Path\$Process")) -or ((Get-ItemPropertyValue -Path "$Path\$Process") -ne 69632)) {
            $RemediationNeeded = $true
            Write-Host "$Process registry property either not found or not set to 69632"
        }
        else {
            Write-Host "$Process registry property found and set to 69632"
        }
    }

    if ($RemediationNeeded) {
        Write-Host "Either one of the required process keys doesn't exist or isn't set to 69632 - Remediation required"
        exit 1
    }
    else {
        Write-Host "All required process keys exist and are set to 69632"
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
