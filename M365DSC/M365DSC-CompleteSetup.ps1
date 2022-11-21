# Install Microsoft365DSC if it is not installed. Once installed, update Microsoft365DSC module along with dependencies.
$InstalledModules = Get-InstalledModule

Write-Host "Checking for the Microsoft365DSC Module..." -ForegroundColor Yellow
if ($InstalledModules.Name -notcontains "Microsoft365DSC") {
    Write-Host "Microsoft365DSC module is not installed." -ForegroundColor Yellow
    Write-Host "Installing Microsoft365DSC module..." -ForegroundColor Yellow
    Install-Module Microsoft365DSC -Force
    Write-Host "Microsoft365DSC module was successfully installed." -ForegroundColor Green
    Write-Host "Updating Microsoft365DSC dependencies..." -ForegroundColor Yellow
    Update-M365DSCDependencies
    Write-Host "Microsoft365DSC dependencies have been updated." -ForegroundColor Green
} else {
    Write-Host "Microsoft365DSC module is installed." -ForegroundColor Green
    Write-Host "Updating Microsoft365DSC module..." -ForegroundColor Yellow
    Update-Module Microsoft365DSC
    Write-Host "Microsoft365DSC module was successfully updated." -ForegroundColor Green
    Write-Host "Updating Microsoft365DSC dependencies..." -ForegroundColor Yellow
    Update-M365DSCDependencies
    Write-Host "Microsoft365DSC dependencies have been updated." -ForegroundColor Green
}

Write-Host "Checking for the Az.Resources Module..." -ForegroundColor Yellow
if ($InstalledModules.Name -notcontains "Az.Resources") {
    Write-Host "Az.Resources module is not installed." -ForegroundColor Yellow
    Write-Host "Installing Az.Resources module..." -ForegroundColor Yellow
    Install-Module Az.Resources -Force
    Write-Host "Microsoft365DSC module was successfully installed." -ForegroundColor Green
}

Write-Host "Getting required Microsoft365DSC permissions..." -ForegroundColor Yellow
$AllPermissions = Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources)
$ReadPermissions = $AllPermissions.ReadPermissions
$UpdatePermissions = $AllPermissions.UpdatePermissions
#$UpdatePermissions = (Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources)).UpdatePermissions

$PermList = @()
foreach ($UpdatePermission in $UpdatePermissions) {
    $PermObject = @{Api="Graph";PermissionName="$UpdatePermission"}
    $PermList += $PermObject
}

# Connect-MgGraph -Scopes $UpdatePermissions

# Create C:\temp folder if it doesn't exist
if (-NOT (Test-Path "C:\temp")) {
    New-Item -Path "c:\" -Name "temp" -ItemType "directory"
    Write-Host "Created folder C:\temp since it did not exist." -ForegroundColor Green
} else {
    Write-Host "C:\temp folder already exists." -ForegroundColor Green
}

# Create custom service principal for certificate authentication
Write-Host "Creating AzureAD App Registration called Microsoft365DSC..."
Update-M365DSCAzureAdApplication -ApplicationName 'Microsoft365DSC' -Permissions $PermList -AdminConsent -Type Certificate -CreateSelfSignedCertificate -CertificatePath c:\temp\M365DSC.cer