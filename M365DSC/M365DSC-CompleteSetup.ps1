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
} else {
    Write-Host "Az.Resources module is installed." -ForegroundColor Green
}

Write-Host "Getting required Microsoft365DSC permissions..." -ForegroundColor Yellow
$AllPermissions = Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources)
$ReadPermissions = $AllPermissions.ReadPermissions
$UpdatePermissions = $AllPermissions.UpdatePermissions | Where-Object {$_ -notlike "Tasks*"}
# Due to bug in M365DSC module, must manually add the below two permissions as there's a typo in the source code
$UpdatePermissions += "Tasks.ReadWrite.All"
$UpdatePermissions += "Tasks.Read.All"
#$UpdatePermissions = (Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources)).UpdatePermissions

$PermList = @()
foreach ($UpdatePermission in $UpdatePermissions) {
    $PermObject = @{Api="Graph";PermissionName="$UpdatePermission"}
    $PermList += $PermObject
}

# Create C:\temp folder if it doesn't exist
Write-Host "Checking for C:\temp folder..." -ForegroundColor Yellow
if (-NOT (Test-Path "C:\temp")) {
    Write-Host "C:\temp folder does not exist" -ForegroundColor Yellow
    Write-Host "Creating C:\temp folder..." -ForegroundColor Yellow
    New-Item -Path "c:\" -Name "temp" -ItemType "directory"
    Write-Host "C:\temp folder was successfully created." -ForegroundColor Green
} else {
    Write-Host "C:\temp folder already exists." -ForegroundColor Green
}

# Create initial App registration via PnP module including certificate creation. Add required Sharepoint permissions to service principal
Write-Host "Creating AzureAD App Registration called Microsoft365DSC and adding required Sharepoint permissions..." -ForeGroundColor Yellow
Register-PnPAzureADApp -ApplicationName "Microsoft365DSC" -Tenant dougjohnsonme.onmicrosoft.com -Interactive -AzureEnvironment Production -SharePointApplicationPermissions Sites.FullControl.All -GraphApplicationPermissions Group.ReadWrite.All
Write-Host "App registration for Microsoft365DSC was added successfully" -ForegroundColor Green
Write-Host "Sharepoint permissions added to Microsoft365DSC service principal" -ForegroundColor Green

# Add previously compiled Graph permissions to service principal
Write-Host "Adding required Graph permissions to Microsoft365DSC service princiapl..." -ForegroundColor Yellow
Update-M365DSCAzureAdApplication -ApplicationName 'Microsoft365DSC' -Permissions $PermList -AdminConsent -Type Certificate -CertificatePath c:\temp\Microsoft365DSC.cer
Write-Host "Graph permissions added to Microsoft365DSC service principal" -ForegroundColor Green

# Add Exchange Organization Management role group to service principal