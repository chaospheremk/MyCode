Function Install-M365DSCCertAuth {
    [CmdletBinding()]
    param(
        [ValidateSet("Commercial", "GCC", "GCCHigh", "DoD", "China", "Germany")]
        [String]
        $CloudEnvironment,
        [String]
        $ExportPath,
        [String]
        $CertPath,
        [String]
        $TenantId
    )
    # PREREQS
    # You must run this script interactively as there are a number of interactive prompts you must use to sign in with a Global Administrator

    switch ($CloudEnvironment) {
        Commercial {
            $PnPEnvironment = "Production"
            $ExchangeEnvironment = "O365Default"
            $GraphEnvironment = "Global"
        }
        GCC {
            $PnPEnvironment = "USGovernment"
            $ExchangeEnvironment = "O365Default"
            $GraphEnvironment = "USGov"
        }
        GCCHigh {
            $PnPEnvironment = "USGovernmentHigh"
            $ExchangeEnvironment = "O365USGovGCCHigh"
            $GraphEnvironment = "USGov"
        }
        DoD {
            $PnPEnvironment = "USGovernmentDoD"
            $ExchangeEnvironment = "O365USGovDoD"
            $GraphEnvironment = "USGovDoD"
        }
        China {
            $PnPEnvironment = "China"
            $ExchangeEnvironment = "O365China"
            $GraphEnvironment = "China"
        }
        Germany {
            $PnPEnvironment = "Germany"
            $ExchangeEnvironment = "O365GermanyCloud"
            $GraphEnvironment = "Global"
        }

    }

    # Enter a password for the .pfx certificate file generated for the self-signed certificate.
    $CertPassword = (Get-Credential -Message "Please enter a password for the .pfx file generated for self-signed certificate." -UserName "Enter password below").Password

    # Install Microsoft365DSC if it is not installed. Once installed, update Microsoft365DSC module along with dependencies.
    $InstalledModules = Get-InstalledModule

    Write-Host "Checking for the Microsoft365DSC Module..." -ForegroundColor Yellow
    if ($InstalledModules.Name -notcontains "Microsoft365DSC") {
        Write-Host "Microsoft365DSC module is not installed." -ForegroundColor Yellow
        Write-Host "Installing Microsoft365DSC module..." -ForegroundColor Yellow
        Install-Module Microsoft365DSC -Confirm:$false
        Write-Host "Microsoft365DSC module was successfully installed." -ForegroundColor Green
        Write-Host "Updating Microsoft365DSC dependencies..." -ForegroundColor Yellow
        Update-M365DSCDependencies
        Write-Host "Microsoft365DSC dependencies have been updated." -ForegroundColor Green
    }
    else {
        Write-Host "Microsoft365DSC module is installed." -ForegroundColor Green
        Write-Host "Updating Microsoft365DSC module..." -ForegroundColor Yellow
        Update-Module Microsoft365DSC -Force
        Write-Host "Microsoft365DSC module was successfully updated." -ForegroundColor Green
        Write-Host "Updating Microsoft365DSC dependencies..." -ForegroundColor Yellow
        Update-M365DSCDependencies
        Write-Host "Microsoft365DSC dependencies have been updated." -ForegroundColor Green
    }

    # Due to bug in M365DSC module, Az.Resources module is not recognized as a required dependency. Must add manually.
    Write-Host "Checking for the Az.Resources Module..." -ForegroundColor Yellow
    if ($InstalledModules.Name -notcontains "Az.Resources") {
        Write-Host "Az.Resources module is not installed." -ForegroundColor Yellow
        Write-Host "Installing Az.Resources module..." -ForegroundColor Yellow
        Install-Module Az.Resources -Force
        Write-Host "Microsoft365DSC module was successfully installed." -ForegroundColor Green
    }
    else {
        Write-Host "Az.Resources module is installed." -ForegroundColor Green
    }

    Write-Host "Getting required Microsoft365DSC permissions..." -ForegroundColor Yellow
    $AllPermissions = Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources)
    $UpdatePermissions = $AllPermissions.UpdatePermissions

    $PermList = @()
    foreach ($UpdatePermission in $UpdatePermissions) {
        $PermObject = @{Api = "Graph"; PermissionName = "$UpdatePermission" }
        $PermList += $PermObject
    }

    # Create $ExportPath folder if it doesn't exist
    Write-Host "Checking for $ExportPath folder..." -ForegroundColor Yellow
    if (-NOT (Test-Path $ExportPath)) {
        Write-Host "$ExportPath folder does not exist" -ForegroundColor Yellow
        Write-Host "Creating $ExportPath folder..." -ForegroundColor Yellow
        New-Item -Path $ExportPath -ItemType "directory"
        Write-Host "$ExportPath folder was successfully created." -ForegroundColor Green
    }
    else {
        Write-Host "$ExportPath folder already exists." -ForegroundColor Green
    }

    # Create $ExportPath folder if it doesn't exist
    Write-Host "Checking for $CertPath folder..." -ForegroundColor Yellow
    if (-NOT (Test-Path $CertPath)) {
        Write-Host "$CertPath folder does not exist" -ForegroundColor Yellow
        Write-Host "Creating $CertPath folder..." -ForegroundColor Yellow
        New-Item -Path $CertPath -ItemType "directory"
        Write-Host "$CertPath folder was successfully created." -ForegroundColor Green
    }
    else {
        Write-Host "$CertPath folder already exists." -ForegroundColor Green
    }

    # Create initial App registration via PnP module including certificate creation. Add required Sharepoint permissions to service principal
    Write-Host "Creating AzureAD App Registration called Microsoft365DSC and adding required Sharepoint permissions..." -ForeGroundColor Yellow
    Register-PnPAzureADApp -ApplicationName "Microsoft365DSC" -Tenant $TenantId -Interactive -AzureEnvironment $PnPEnvironment -SharePointApplicationPermissions Sites.FullControl.All -GraphApplicationPermissions Group.ReadWrite.All -OutPath $CertPath -CertificatePassword $CertPassword
    Write-Host "App registration for Microsoft365DSC was added successfully" -ForegroundColor Green
    Write-Host "Sharepoint permissions added to Microsoft365DSC service principal" -ForegroundColor Green

    # Install generated certificate
    Write-Host "Installing Microsoft365DSC certificate..." -ForegroundColor Yellow
    # $CertificateThumbprint = (Import-PfxCertificate -FilePath "$CertPath\Microsoft365DSC.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $CertPassword).Thumbprint
    Import-PfxCertificate -FilePath "$CertPath\Microsoft365DSC.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $CertPassword
    Write-Host "Microsoft365DSC certificate successfully installed." -ForegroundColor Green

    # Add previously compiled Graph permissions to service principal
    Write-Host "Adding required Graph permissions to service principal..." -ForegroundColor Yellow
    Update-M365DSCAzureAdApplication -ApplicationName 'Microsoft365DSC' -Permissions $PermList -AdminConsent -Type Certificate -CertificatePath "$CertPath\Microsoft365DSC.cer"
    Write-Host "Required Graph permissions were successfully added to service principal." -ForegroundColor Green

    # Add Exchange Organization Management role group to service principal. Interactive logon.
    $RequiredScopes = @("Application.ReadWrite.All", "User.ReadWrite.All", "Group.ReadWrite.All", "GroupMember.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory")
    Connect-MgGraph -Environment $GraphEnvironment -Scopes $RequiredScopes
    
    $user = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft365DSC'"

    $requiredRoleTemplates = Get-MgDirectoryRoleTemplate | Where-Object Id -in "69091246-20e8-4a56-aa4d-066075b2a7a8"
    $aadRoles = Get-MgDirectoryRole

    $requiredRoleTemplates |
    ForEach-Object {
        $aadRoles | Where-Object RoleTemplateId -eq $_.Id
    } | ForEach-Object {
        $Members = Get-MgDirectoryRoleMember -DirectoryRoleId $_.Id
        if ($User.Id -notin $Members.Id) {
            Write-Verbose "Adding user to Azure AD role '$($_.DisplayName)'" -Verbose
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $_.Id -BodyParameter @{"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)" }
        }
    }
    
    $ExchangeServicePrincipal = Get-MgApplication | Where-Object DisplayName -eq "Microsoft365DSC"
    $ServiceId = $ExchangeServicePrincipal.Id
    $AppId = $ExchangeServicePrincipal.AppId

    Write-Host "Required Teams Administrator role was added successfully to service principal." -ForegroundColor Green

    Disconnect-MgGraph

    Connect-ExchangeOnline -ExchangeEnvironmentName $ExchangeEnvironment

    # The AzureAD service principal must be duplicated in the ExchangeOnline module to be able to add it to a role group
    Write-Host "Creating service principal for ExchangeOnline module..." -ForegroundColor Yellow
    New-ServicePrincipal -DisplayName "Microsoft365DSC" -AppId $AppId -ServiceId $ServiceId
    Write-Host "Service principal for ExchangeOnline module was successfully created." -ForegroundColor Green

    # Add newly duplicated service principal to the two required EXO Role Groups
    Write-Host "Adding service principal to required Exchange Online roles..." -ForegroundColor Yellow
    Update-RoleGroupMember -Identity "Organization Management" -Members @{Add = "Microsoft365DSC" } -Confirm:$false
    Update-RoleGroupMember -Identity "Compliance Management" -Members @{Add = "Microsoft365DSC" } -Confirm:$false
    Write-Host "Required Exchange Online roles were successfully added to service principal." -ForegroundColor Green
    Disconnect-ExchangeOnline -Confirm:$false

    Write-Host "Installation and service principal configuration is complete" -ForegroundColor Green
}