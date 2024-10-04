function Setup-SecretVault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VaultName = 'MySecretVault',

        [Parameter(Mandatory = $false)]
        [string]$VaultKeyFilePath = "$env:USERPROFILE\secretvaultpassword.xml"
    )

    # This will allow for verbose logging if -Verbose is provided
    $ErrorActionPreference = 'Stop'

    function Install-ModuleIfNeeded {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ModuleName
        )
        if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
            Write-Verbose "Installing $ModuleName module..."
            Install-Module -Name $ModuleName -Force -ErrorAction Stop
        }
        else {
            Write-Verbose "$ModuleName is already installed."
        }
    }

    function Prompt-And-Save-Password {
        param (
            [string]$VaultKeyFilePath
        )
        Write-Host "Secret Store password required."
        $SecurePassword = Read-Host -AsSecureString "Enter Secret Store password"
        Write-Verbose "Saving password to $VaultKeyFilePath"
        $SecurePassword | Export-Clixml -Path $VaultKeyFilePath
        return $SecurePassword
    }

    function Unlock-SecretStore {
        param (
            [Parameter(Mandatory = $true)]
            [SecureString]$SecurePassword
        )
        Write-Verbose "Unlocking SecretStore"
        Unlock-SecretStore -Password $SecurePassword -ErrorAction Stop
    }

    # Install necessary modules
    Install-ModuleIfNeeded -ModuleName 'Microsoft.PowerShell.SecretManagement'
    Install-ModuleIfNeeded -ModuleName 'Microsoft.PowerShell.SecretStore'

    # Import the modules
    Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
    Import-Module Microsoft.PowerShell.SecretStore -ErrorAction Stop

    # Check if the SecretStore vault is already registered
    $secretVaultExists = Get-SecretVault | Where-Object { $_.Name -eq 'SecretStore' }

    if (-not $secretVaultExists) {
        Write-Verbose "SecretStore is not initialized. Setting it up now."
        
        # Check if password file exists
        if (Test-Path $VaultKeyFilePath) {
            Write-Verbose "Password file found. Loading password."
            $SecurePassword = Import-Clixml -Path $VaultKeyFilePath
        }
        else {
            Write-Verbose "Password file not found. Prompting for password."
            $SecurePassword = Prompt-And-Save-Password -PasswordFilePath $VaultKeyFilePath
        }

        # Register and initialize the secret vault
        Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore -ErrorAction Stop
        Set-SecretStoreConfiguration -Scope CurrentUser -Authentication Password -PasswordTimeout 900 -ErrorAction Stop

        # Unlock Secret Store
        Unlock-SecretStore -SecurePassword $SecurePassword
    }
    else {
        Write-Verbose "SecretStore is already initialized."

        # Check if password file exists
        if (Test-Path $VaultKeyFilePath) {
            Write-Verbose "Password file found. Loading password."
            $SecurePassword = Import-Clixml -Path $VaultKeyFilePath
            # Attempt to unlock the SecretStore
            Unlock-SecretStore -SecurePassword $SecurePassword
        }
        else {
            Write-Warning "SecretStore is already configured but no password file was found. Please manually unlock the store."
        }
    }

    Write-Host "Secret vault setup complete." -ForegroundColor Green
}

# Example usage:
# Setup-SecretVault -VaultName 'MyVault'

Get-AzAutomation