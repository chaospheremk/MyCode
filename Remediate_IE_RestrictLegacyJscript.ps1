#=============================================================================================================================
#
# Script Name:     Remediate_IE_RestrictLegacyJscript.ps1
# Description:     Create registry key, registry properties, and set their value.
# Notes:           
#
#=============================================================================================================================

# Define Variables
$Path = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE"
$Processes = "excel.exe", "mspub.exe", "powerpnt.exe", "onenote.exe", "visio.exe", "winproj.exe", "winword.exe", "outlook.exe", "msaccess.exe"

try {
    if (!(Test-Path -Path $Path)) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl" -Name "FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE"
        Write-Host "Registry key: FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE was successfully created"
    }
    else {
        Write-Host "Registry key: FEATURE_RESTRICT_LEGACY_JSCRIPT_PER_SECURITY_ZONE already exists"
    }

    foreach ($Process in $Processes) {
        if (!(Get-ItemProperty -Path $Path -Name $Process)) {
            New-ItemProperty -Path $Path -PropertyType dword -Name $Process -Value 69632
            Write-Host "$Process registry property successfully created and value set to 69632"
            exit 0
        }
        elseif ((Get-ItemPropertyValue -Path $Path -Name $Process) -ne 69632) {
            Set-ItemProperty -Path $Path -Name $Process -Value 69632 -Force
            Write-Host "$Process registry property found and set to 69632"
            exit 0
        }
        else {
            Write-Host "$Process registry property found and was already set to 69632"
            exit 0
        }
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
