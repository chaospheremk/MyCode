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
    }
    else {
        Write-Host "Microsoft365DSC module is installed." -ForegroundColor Green
        Write-Host "Updating Microsoft365DSC module..." -ForegroundColor Yellow
        Update-Module Microsoft365DSC
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
    $UpdatePermissions = $AllPermissions.UpdatePermissions | Where-Object { $_ -notlike "Tasks*" }
    # Due to bug in M365DSC module, must manually add the below two permissions as there's a typo in the source code
    $UpdatePermissions += "Tasks.ReadWrite.All"
    $UpdatePermissions += "Tasks.Read.All"
    #$UpdatePermissions = (Get-M365DSCCompiledPermissionList -ResourceNameList (Get-M365DSCAllResources)).UpdatePermissions

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

    # Enter a password for the .pfx certificate file generated in the next step
    $CertPassword = (Get-Credential -Message "Please enter a password for the .pfx file generated in the next step." -UserName "Enter password below").Password

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
    Write-Host "Adding required Graph permissions to Microsoft365DSC service principal..." -ForegroundColor Yellow
    Update-M365DSCAzureAdApplication -ApplicationName 'Microsoft365DSC' -Permissions $PermList -AdminConsent -Type Certificate -CertificatePath "$CertPath\Microsoft365DSC.cer"
    Write-Host "Graph permissions added to Microsoft365DSC service principal" -ForegroundColor Green

    <# $ExchangePerms = @("EXOAcceptedDomain", "EXOActiveSyncDeviceAccessRule", "EXOAddressBookPolicy", "EXOAddressList", "EXOAntiPhishPolicy", "EXOAntiPhishRule", `
            "EXOApplicationAccessPolicy", "EXOAtpPolicyForO365", "EXOAuthenticationPolicy", "EXOAuthenticationPolicyAssignment", "EXOAvailabilityAddressSpace", "EXOAvailabilityConfig", `
            "EXOCASMailboxPlan", "EXOCASMailboxSettings", "EXOClientAccessRule", "EXODataClassification", "EXODataEncryptionPolicy", "EXODistributionGroup", "EXODkimSigningConfig", `
            "EXOEmailAddressPolicy", "EXOGlobalAddressList", "EXOHostedConnectionFilterPolicy", "EXOHostedContentFilterPolicy", "EXOHostedContentFilterRule", `
            "EXOHostedOutboundSpamFilterPolicy", "EXOHostedOutboundSpamFilterRule", "EXOInboundConnector", "EXOIntraOrganizationConnector", "EXOIRMConfiguration", "EXOJournalRule", `
            "EXOMailboxPlan", "EXOMailboxSettings", "EXOMailContact", "EXOMailTips", "EXOMalwareFilterPolicy", "EXOMalwareFilterRule", "EXOManagementRole", "EXOManagementRoleAssignment", `
            "EXOMessageClassification", "EXOMobileDeviceMailboxPolicy", "EXOOfflineAddressBook", "EXOOMEConfiguration", "EXOOnPremisesOrganization", "EXOOrganizationConfig", `
            "EXOOrganizationRelationship", "EXOOutboundConnector", "EXOOwaMailboxPolicy", "EXOPartnerApplication", "EXOPerimeterConfiguration", "EXOPolicyTipConfig", "EXOQuarantinePolicy", `
            "EXORemoteDomain", "EXOResourceConfiguration", "EXORoleAssignmentPolicy", "EXOSafeAttachmentPolicy", "EXOSafeAttachmentRule", "EXOSafeLinksPolicy", "EXOSafeLinksRule", `
            "EXOSharedMailbox", "EXOSharingPolicy", "EXOTransportConfig", "EXOTransportRule"
    )

    $ExchangeUpdatePerms = Get-M365DSCCompiledPermissionList -ResourceNameList $ExchangePerms -Source 'Exchange' -PermissionsType 'Application'
    $ExchangeRequiredRoles = $ExchangeUpdatePerms.RequiredRoles #>

    # Add Exchange Organization Management role group to service principal. Interactive logon.
    Connect-ExchangeOnline -ExchangeEnvironmentName $ExchangeEnvironment
    Connect-MgGraph -Environment $GraphEnvironment -Scopes "Application.ReadWrite.All", "User.ReadWrite.All", "Group.ReadWrite.All", "GroupMember.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"
    $ExchangeServicePrincipal = Get-MgServicePrincipal | Where-Object DisplayName -eq "Microsoft365DSC"
    $ServiceId = $ExchangeServicePrincipal.Id
    $AppId = $ExchangeServicePrincipal.AppId
    # Get all Organization Management Roles
    <# $OrgManRoles = (Get-RoleGroup -Identity "Organization Management").Roles
    $CompManRoles = (Get-RoleGroup -Identity "Compliance Management").Roles

    foreach ($ExchangeRequiredRole in $ExchangeRequiredRoles) {
        if ($OrgManRoles -contains $ExchangeRequiredRole) {
            Write-Host "Required role $ExchangeRequiredRole exists in OrgManRoles" -ForegroundColor Green
        } else {
            if ($CompManRoles -contains $ExchangeRequiredRole) {
                Write-Host "Required role $ExchangeRequiredRole exists in CompManRoles" -ForegroundColor Green
            } else {
                Write-Host "Required role $ExchangeRequiredRole does not exist in OrgManRoles or CompManRoles" -ForegroundColor Red
            }
        }
    }

    Get-M365DSCCompiledPermissionList -ResourceNameList @('EXOAcceptedDomain') -Source 'Exchange' -PermissionsType 'Application' #>
    #########

    # The AzureAD service principal must be duplicated in the ExchangeOnline module to be able to add it to a role group
    Write-Host "Creating service principal for ExchangeOnline module..." -ForegroundColor Yellow
    New-ServicePrincipal -DisplayName "Microsoft365DSC" -AppId $AppId -ServiceId $ServiceId
    Write-Host "Service principal for ExchangeOnline module was successfully created." -ForegroundColor Green

    # Add newly duplicated service principal to the two required EXO Role Groups
    Write-Host "Adding service principal to required Exchange Online roles..." -ForegroundColor Yellow
    Update-RoleGroupMember -Identity "Organization Management" -Members @{Add = "Microsoft365DSC" } -Confirm:$false
    Update-RoleGroupMember -Identity "Compliance Management" -Members @{Add = "Microsoft365DSC" } -Confirm:$false
    Write-Host "Service principal required Exchange Online roles were added successfully." -ForegroundColor Green
    Disconnect-ExchangeOnline -Confirm:$false
    # Get-M365DSCCompiledPermissionList -ResourceNameList @("TeamsCallingPolicy", "TeamsChannel", "TeamsChannelsPolicy", "TeamsChannelTab", "TeamsClientConfiguration", "TeamsDialInConferencingTenantSettings", "TeamsEmergencyCallingPolicy", "TeamsEmergencyCallRoutingPolicy", "TeamsEventsPolicy", "TeamsFederationConfiguration", "TeamsGuestCallingConfiguration", "TeamsGuestMeetingConfiguration", "TeamsGuestMessagingConfiguration", "TeamsMeetingBroadcastConfiguration", "TeamsMeetingBroadcastPolicy", "TeamsMeetingConfiguration", "TeamsMeetingPolicy", "TeamsMessagingPolicy", "TeamsOnlineVoicemailPolicy", "TeamsOnlineVoicemailUserSettings", "TeamsOnlineVoiceUser", "TeamsPstnUsage", "TeamsTeam", "TeamsTenantDialPlan", "TeamsUpdateManagementPolicy", "TeamsUpgradeConfiguration", "TeamsUpgradePolicy", "TeamsUser", "TeamsUserCallingSettings", "TeamsVoiceRoute", "TeamsVoiceRoutingPolicy") -Source 'Teams' -PermissionsType 'Application'

    
    # Write-Host "Ensure that you add the service principal to the Teams Administrator role in the Azure portal before exporting Teams settings" -ForegroundColor Red

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
    Disconnect-MgGraph
    Write-Host "Service principal required Teams Administrator role was added successfully." -ForegroundColor Green
    Write-Host "Installation and service principal configuration is complete" -ForegroundColor Green
}