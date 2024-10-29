<#

These functions were written to simply pull devices from the Microsoft Defender security portal for checking status

Requires an App Registration in Entra ID with application permissions: Machine.Read.All for the WindowsDefenderATP API

When creating app registration:

    - select 'API permissions' blade
    - select 'Add a permission'
    - select 'APIs my organization uses'
    - select 'WindowsDefenderATP'
    - add the Machine.Read.All permission
    - select 'Add permission'
    - select 'Grant grant admin consent for $domain'
    - select 'Certificates & secrets' blade
    - select 'New client secret' - create a secret, document value
    - select 'Overview' blade
    - document App (client) ID and Tenant ID along with client secret
#>
function Get-DefenderAuthToken {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ClientId,
        [Parameter(Mandatory)]
        [SecureString]$ClientSecret,
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    Begin {

        $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

        Try {
            
            $clientSecretString = $ClientSecret | ConvertFrom-SecureString -AsPlainText -ErrorAction 'Stop'
        }
        Catch {

            $_.Exception.Message
        }

        $body = @{
            client_id     = $ClientId
            scope         = "https://api.securitycenter.microsoft.com/.default"
            client_secret = $clientSecretString
            grant_type    = "client_credentials"
        }

        Remove-Variable -Name 'clientSecretString'

        $paramsToken = @{
            Method = 'Post'
            Uri = $tokenUrl
            Body = $body
        }
    }

    Process {

        Try {

            $token = (Invoke-RestMethod @paramsToken).access_token
        }
        Catch {

            $_.Exception.Message
        }

        $headers = @{
            Authorization = "Bearer $token"
        }

        $headers
    }
}

function Get-DefenderDevice {

    [CmdletBinding(DefaultParameterSetName = 'DeviceName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'DeviceName')]
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [hashtable]$AuthToken,
        [Parameter(Mandatory, ParameterSetName = 'DeviceName')]
        [string]$DeviceName,
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    Begin {

        $paramsDevices = @{
            Method = 'Get'
            Uri = "https://api.securitycenter.microsoft.com/api/machines"
            Headers = $headers
        }
    }

    Process {

        if ($All) {

            $paramsDevices.Uri = "https://api.securitycenter.microsoft.com/api/machines"

            $allDevices = (Invoke-RestMethod @paramsDevices).value

            $allDevices
        }
        else {

            $allDevices = (Invoke-RestMethod @paramsDevices).value

            $device = $allDevices.Where({ $_.ComputerDnsName -like "*$deviceName*" })

            $device
        }
    }
}

# Variables
$tenantId = ""
$clientId = ""
$clientSecret = "" | ConvertTo-SecureString -AsPlainText -Force # not secure. recommend storing value in SecretManagement

# Get the OAuth token
$authToken = Get-DefenderAuthToken -ClientId $clientId -ClientSecret $clientSecret -TenantId $tenantId

# Get all devices
Get-DefenderDevice -AuthToken $authToken -All