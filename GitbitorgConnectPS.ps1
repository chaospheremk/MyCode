# Description: Set PSGallery as trusted repository
# Requirements: Run powershell as local admin
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Description: Install M365 powershell modules
# Azure AD v1 module - Microsoft 365 admin center
Install-Module MSOnline
# Azure AD v2 module - Azure AD
Install-Module -Name AzureAD
# Exchange Online v2 module
Install-Module -Name ExchangeOnlineManagement
# Sharepoint Online module
Install-Module -Name Microsoft.Online.SharePoint.PowerShell
# Teams module
Install-Module -Name MicrosoftTeams -Force -AllowClobber

# Set execution policy
Set-ExecutionPolicy RemoteSigned




# Microsoft 365 commands (MSOnline)
#
# Connect to M365
Connect-MsolService
# Disconnect
Disconnect-MsolService

# Exchange Online commands
#
# Connect to ExchangeOnline
Connect-ExchangeOnline
# Enable auditing for a user's mailbox
Set-Mailbox -Identity "User1" -AuditEnabled $true
# Created retention labels, but they havent propagated to users. User needs to use label today
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails UserMailbox | %{ Start-ManagedFolderAssistant $_.UserPrincipalName }
# Disconnect
Disconnect-ExchangeOnline

# Azure AD commands
#
# Connect to AzureAD
Connect-AzureAD
# Disconnect
Disconnect-AzureAD

# Security and Compliance center commands
#
# Connect to Security and Compliance center
Connect-IPPSSession
# Export rules XML file
$ruleCollections = Get-DlpSensitiveInformationTypeRulePackage
Set-Content -path "C:\custompath\exportedRules.xml" -Encoding Byte -Value $ruleCollections.SerializedClassificationRuleCollection
# Manually modify rules in XML file
# Upload new rules
New-DlpSensitiveInformationTypeRulePackage -FileData (Get-Content -Path "C:\custompath\exportedRules.xml" -Encoding Byte)
# Disconnect
Disconnect-ExchangeOnline

# SharePoint Online commands
#
# Connect to SharePoint Online
# Go to https://admin.microsoft.com/Adminportal/Home?source=applauncher#/alladmincenters > SharePoint
# Copy the SharePoint URL. Everything before _layouts
Connect-SPOService -Url "The URL you copied"
# Stop users from downloading, printing, and syncing files from SP Online using unmanaged devices
Set-SPOTenant -ConditionalAccessPolicy AllowLimitedAccess
# Disconnect
Disconnect-SPOService

# Microsoft Teams commands
#
# Connect to MicrosoftTeams
Connect-MicrosoftTeams
# Disconnect
Disconnect-MicrosoftTeams
