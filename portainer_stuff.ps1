# authentication
function Get-DJMPortainerAuthToken {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential,
        [String]$BaseUri = "https://portainer.dougjohnson.me/api"
    )

    Begin {

        $uri = "$BaseUri/auth"

        $body = @{
            
            username = $Credential.UserName
            password = $Credential.Password | ConvertFrom-SecureString -AsPlainText
        } | ConvertTo-Json

        $params = @{

            Body = $body
            ContentType = 'application/json'
            Method = 'Post'
            Uri = $uri
        }
    } # begin

    Process { ConvertTo-SecureString -String (Invoke-RestMethod @params).jwt -AsPlainText } # process
}

##############
# Get stacks

function Get-DJMPortainerStack {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [SecureString]$Token,
        [String]$BaseUri = "https://portainer.dougjohnson.me/api"
    )

    Begin {

        $uri = "$BaseUri/stacks"

        $params = @{

            ContentType = 'application/json'
            Authentication = 'Bearer'
            Token = $token
            Method = 'GET'
            Uri = $uri
        }
    } # begin

    Process { Invoke-RestMethod @params } # process
}

########################
# Get stack files

function Get-DJMPortainerStackFile {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Int64[]]$StackId,
        [Parameter(Mandatory=$true)]
        [SecureString]$Token,
        [String]$BaseUri = "https://portainer.dougjohnson.me/api"
    )

    Begin {

        $params = @{

            ContentType = 'application/json'
            Authentication = 'Bearer'
            Token = $token
            Method = 'GET'
        }

        
    } # begin

    Process {

        foreach ($id in $StackId) {

            $params.Uri = "$BaseUri/stacks/$id/file"

            (Invoke-RestMethod @params).StackFileContent
        }
    } # process
}

#######

$token = Get-DJMPortainerAuthToken -Credential (Get-Credential)

$stacks = Get-DJMPortainerStack -Token $token

$stackFiles = Get-DJMPortainerStackFile -StackId $stacks.Id -Token $token

$date = Get-Date -Format 'FileDateTime'

foreach ( $stackFile in $stackFiles) {

    $yaml = $stackFile | ConvertFrom-Yaml

    $stackName = $yaml.services.Keys[0]

    $fileName = "$stackName`_$date.yaml"

    $stackFile | Out-File -FilePath "C:\temp\Portainer Backup Test\$fileName"
}
####

$credential = Get-Credential -UserName 'SecureStore'

$secVaultFilePath = Join-Path "$env:USERPROFILE\SecretStore" SecretStore.Vault.Credential

$credential.Password | Export-Clixml -Path $secVaultFilePath -Force

Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

$secVaultFilePath = Join-Path "$env:USERPROFILE\SecretStore" SecretStore.Vault.Credential
Unlock-SecretStore -Password (Import-CliXml -Path $secVaultFilePath)


$paramsStoreConfiguration = @{
    Authentication = 'Password'
    PasswordTimeout = 30
    Interaction = 'None'
    Password = $password
    Confirm = $false
}

Set-SecretStoreConfiguration @$paramsStoreConfiguration

########### modules stuff

$requiredModules = @( 'Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.SecretStore' )

$installedModules = (Get-InstalledModule).Name

$paramsInstallModule = @{

    AcceptLicense = $true
    Confirm = $false
    Force = $true
}

foreach ($requiredModule in $requiredModules) {

    if ($installedModules -notcontains $requiredModule) {
        
        $paramsInstallModule.Name = $requiredModule
        Install-Module -Name $requiredModule
    }
}

function Install-ModuleIfNeeded {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $ModuleName
    )

    Process {

        foreach ($module in $moduleName) {

            if (-not (Get-InstalledModule -Name $ModuleName)) {

                Try { Install-Module -Name $ModuleName -Force -ErrorAction 'Stop' }
                Catch { $_.Exception.Message }
            }
        }
    }
}

$folder = "C:\Users\DougJohnson\OneDrive - dougjohnson.me\Documents"

attrib +s $folder

$folders = @(
    "C:\Users\DougJohnson\OneDrive - dougjohnson.me\Documents\PowerShell\Modules",
    "C:\Users\DougJohnson\OneDrive - dougjohnson.me\Documents\WindowsPowerShell\Modules"
)

$test = Get-ChildItem "C:\Users\DougJohnson\OneDrive - dougjohnson.me\Documents\WindowsPowerShell\Modules"