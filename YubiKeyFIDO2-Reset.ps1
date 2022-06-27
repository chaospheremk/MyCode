# This script is for resetting a YubiKey for a user who has locked their PIN or forgot their PIN. CMDB is
# not updated in this script since the YubiKey remains assigned to the same user.
#
# 1. Enables all applications on the YubiKey.
# 2. Resets all applications on the YubiKey.
# 3. Disables all applications except for FIDO2.
#
# This script requires YubiKey Manager to be installed on the computer where the script runs. The default
# location is C:\Program Files\Yubico\YubiKey Manager.
#
#################################################################################################################

# Change to YubiKey Manager directory
Set-Location "C:\Program Files\Yubico\YubiKey Manager"

# Enables all applications over USB and NFC interfaces.
.\ykman config usb -a -f
.\ykman config nfc -a -f

# Reset FIDO2 application as a good measure
.\ykman fido reset -f
.\ykman oath reset -f
.\ykman openpgp reset -f
.\ykman otp delete 1 -f
.\ykman otp delete 2 -f
.\ykman piv reset -f

# Disable all applications except for FIDO2 over USB and NFC interfaces.
.\ykman config usb -d OTP -f
.\ykman config usb -d U2F -f
.\ykman config usb -d OATH -f
.\ykman config usb -d PIV -f
.\ykman config usb -d OPENPGP -f
.\ykman config usb -d HSMAUTH -f
.\ykman config nfc -d OTP -f
.\ykman config nfc -d U2F -f
.\ykman config nfc -d OATH -f
.\ykman config nfc -d PIV -f
.\ykman config nfc -d OPENPGP -f
.\ykman config nfc -d HSMAUTH -f

Write-Host "FIDO2 YubiKey was successfully reset."
Read-Host -Prompt "Press any key to exit"
Exit