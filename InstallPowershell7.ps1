$Version = "7.3.8.0"
$InstallType = "Microsoft.Powershell.Preview"

$CheckPowershell = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  `
    Where-Object {($_.DisplayName -ne $null) -and ($_.DisplayName -eq "PowerShell 7-preview-x64")} | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

if ($CheckPowershell) {
    
    if (-NOT ($CheckPowershell.DisplayVersion -eq $Version)) {

        # Update powershell
        winget upgrade --id $InstallType -v $Version
    }
}
else {

    # install powershell
    winget install -h --id $InstallType -s winget --accept-package-agreements
}