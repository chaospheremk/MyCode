using namespace System.Collections.Generic

function Get-YubiKeyFIDOPin {

    [CmdletBinding()]
    param (

    )

    Process { Read-Host -Prompt "Enter your YubiKey's FIDO2 PIN" -AsSecureString }
}

function Get-YubiKeyFIDOCredentials {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory)]
        [System.Security.SecureString]$PIN = $(Read-Host -Prompt "Enter your YubiKey's FIDO2 PIN" -AsSecureString)
    )

    Begin {
        
        Invoke-Expression -Command 'using namespace System.Collections.Generic'
        $ykman = "C:\Program Files\Yubico\YubiKey Manager\ykman.exe"

        $pinText = $Pin | ConvertFrom-SecureString -AsPlainText
    }

    Process { 
        
        [List[PSObject]]$credentials = & $ykman fido credentials list --pin $pinText --csv  | ConvertFrom-Csv

        foreach ($credential in $credentials) {

            [PSCustomObject] @{
                CredentialId = $credential.credential_id
                RelyingPartyId = $credential.rp_id
                UserName = $credential.user_name
                UserDisplayName = $credential.user_display_name
                UserId = $credential.user_id
            }
        }
    }
}