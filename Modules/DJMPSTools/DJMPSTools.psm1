function Copy-Object {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]$InputObject
    )

    Process {

        Try { [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($InputObject)) }
        Catch { $_.Exception.Message }
    }
}

# prompt and save password file

function New-DJMSecretStorePassword {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecStoreFilePath
    )

    Process {

        Try {

            $secStorePassword = New-DJMComplexPassword -Length 1024 | ConvertTo-SecureString -AsPlainText
            $secStorePassword | Export-Clixml -Path $SecStoreFilePath -Force
        }
        Catch { $_.Exception.Message }
    }
}
# set up secret store
function New-DJMSecretStore {

    [CmdletBinding()]
    Param ()

    Begin {

        Write-Verbose -Message "Start function [New-DJMSecretStore]"

        $secretVaultName = 'SecretStore'
        $secStoreFolderPath = "$env:USERPROFILE\$secretVaultName"
        $secStoreFilePath = Join-Path -Path $secStoreFolderPath -ChildPath "$secretVaultName.Vault.Credential"

        $paramsSetStoreConfig = @{

            Authentication  = 'Password'
            Confirm         = $false
            Interaction     = 'None'
            PasswordTimeout = 300
            ErrorAction     = 'Stop'    
        }
    } # begin

    Process {

        Write-Verbose -Message "Checking if folder path [$secStoreFolderPath] exists..."
        
        if (-not (Test-Path -Path $secStoreFolderPath )) {

            Write-Verbose -Message "Checking if folder path [$secStoreFolderPath] exists: FALSE"
            Write-Verbose -Message "Creating folder path [$secStoreFolderPath]..."

            Try {

                $null = New-Item -Path $secStoreFolderPath -ItemType Directory -Force -ErrorAction 'Stop'

                Write-Verbose -Message "Creating folder path [$secStoreFolderPath]: COMPLETED"
            }
            Catch {
                
                Write-Verbose -Message "Creating folder path [$secStoreFolderPath]: FAILED"
                $_.Exception.Message
            }
        }
        else { Write-Verbose -Message "Checking if folder path [$secStoreFolderPath] exists: TRUE" }

        Write-Verbose -Message "Checking if secret vault [$secretVaultName] exists..."

        if ((Get-SecretVault).Name -notcontains $secretVaultName) {
            
            Write-Verbose -Message "Checking if secret vault [$secretVaultName] exists: FALSE"
            Write-Verbose -Message "Registering secret vault [$secStoreFolderPath]..."

            Try {

                Register-SecretVault -Name $secretVaultName -ModuleName 'Microsoft.PowerShell.SecretStore' -DefaultVault -ErrorAction 'Stop'

                Write-Verbose -Message "Registering secret vault [$secStoreFolderPath]: COMPLETED"
            }
            Catch {

                Write-Verbose -Message "Registering secret vault [$secStoreFolderPath]: FAILED"
                $_.Exception.Message
            }
        }
        else { Write-Verbose -Message "Checking if secret vault [$secretVaultName] exists: TRUE" }

        Write-Verbose -Message "Generating new secret store password..."

        Try {

            New-DJMSecretStorePassword -SecStoreFilePath $secStoreFilePath

            Write-Verbose -Message "Generating new secret store password: COMPLETED"
        }
        Catch {
            
            Write-Verbose -Message "Generating new secret store password: FAILED"
            $_.Exception.Message
        }

        $paramsSetStoreConfig.Password = Import-Clixml -Path $secStoreFilePath
        
        Write-Verbose -Message "Checking if secret store configuration already exists..."

        Try {
            $existingStoreConfig = Get-SecretStoreConfiguration -ErrorAction 'SilentlyContinue'
        }
        Catch [Microsoft.PowerShell.SecretManagement.PasswordRequiredException] { $null = $existingStoreConfig }
        Catch { $null = $existingStoreConfig }

        if ((-not $existingStoreConfig) -or ($existingStoreConfig.Authentication -eq 'None')) { 

            if (-not $existingStoreConfig) { Write-Verbose -Message "Checking if secret store configuration already exists: FALSE" }

            if ($existingStoreConfig.Authentication -eq 'None') {

                Write-Verbose -Message "Checking if secret store configuration already exists: TRUE"
                Write-Verbose -Message "Secret store configuration authentication set to [$($existingStoreConfig.Authentication)]"
                
            }

            Write-Verbose -Message "Setting secret store configuration..."

            Try {
                
                Set-SecretStoreConfiguration @paramsSetStoreConfig

                Write-Verbose -Message "Setting secret store configuration: COMPLETED"
            }
            Catch {

                Write-Verbose -Message "Setting secret store configuration: FAILED"
                $_.Exception.Message
            }
        }
        else {

            Write-Verbose -Message "Checking if secret store configuration already exists: TRUE"
            Write-Verbose -Message "Secret store configuration authentication set to [$($existingStoreConfig.Authentication)]"

            $message = @(
                "Warning: Secret store configuration already exists and will need to be reset.",
                'Choosing to continue will remove all existing secrets.'
            ) -join ' '

            Write-Host -Message $message -ForegroundColor 'Yellow'

            $response = Read-Host -Prompt 'Continue? Y/N'

            if ($response -like "y") {

                Write-Verbose -Message "User responded [$response]: CONTINUE"
                Write-Verbose -Message "Resetting secret store configuration..."

                Try {

                    $paramsResetStore = Copy-Object -InputObject $paramsSetStoreConfig -ErrorAction 'Stop'
                    $paramsResetStore.Force = $true
                    $paramsResetStore.WarningAction = 'Ignore'

                    Reset-SecretStore @paramsResetStore
                    Write-Verbose -Message "Resetting secret store configuration: COMPLETED"
                }
                Catch {

                    Write-Verbose -Message "Resetting secret store configuration: FAILED"
                    $_.Exception.Message
                }

                Write-Verbose -Message "Resetting secret store configuration..."
                #$oldPassword = Get-Credential -UserName 'SecretStore' -Message "Enter existing Secret Store password"
                #Set-SecretStorePassword
                #Set-SecretStoreConfiguration @paramsSetStoreConfig
                #Write-Host "New-DJMSecretStore: COMPLETED" -ForeGroundColor 'Green'
            }
            else {

                Write-Verbose -Message "User responded [$response]: STOP"
            }
        }
    } # process

    End { Write-Verbose -Message "End function [New-DJMSecretStore]" } # end
}
###############

function New-DJMComplexPassword {
    param ( [int]$Length = 16 )

    Begin {

        $upperCase = [char[]]"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        $lowerCase = [char[]]"abcdefghijklmnopqrstuvwxyz"
        $digits = [char[]]"0123456789"
        $specialChars = [char[]]"!@#$%^&*()-_=+[]{}|;:,.<>?/"

        # Combine all character sets
        [char[]]$allChars = $upperCase + $lowerCase + $digits + $specialChars
    }

    Process {

        $passwordList = [System.Collections.Generic.List[object]]::new()
        $passwordList.Add(($upperCase | Get-Random))
        $passwordList.Add(($lowerCase | Get-Random))
        $passwordList.Add(($digits | Get-Random))
        $passwordList.Add(($specialChars | Get-Random))

        # Generate the remaining characters randomly
        for ($i = $passwordList.count; $i -lt $Length; $i++) { $passwordList.Add(( $allChars | Get-Random )) }

        # Convert the password array to a string and return
        [string]$passwordString = ($passwordList | Get-Random -Shuffle) -join ''

        return $passwordString
    }
}

# Example: Generate a 20-character long password
$complexPassword = Generate-ComplexPassword -Length 20
$complexPassword