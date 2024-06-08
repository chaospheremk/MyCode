#=============================================================================================================================
#
# Script Name:     Detect_HP830G5-DMAWhitelist.ps1
# Description:     Determine whether the DMA whitelist has particular devices
# Notes:           Created to allow for all virtualization-based security features to enable
#
#=============================================================================================================================

$path = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses"
$propertiesToCheck = @{

    'PCI Express Downstream Switch Port' = 'PCI\VEN_8086&DEV_15DA'
    'PCI Express Upstream Switch Port' = 'PCI\VEN_8086&DEV_15DA'
}

foreach ($property in $propertiesToCheck.GetEnumerator()) {

    try {

        $propertyName = $property.Key
        $propertyValue = $property.Value
        $itemProperties = Get-ItemProperty -Path $path -Name $propertyName -ErrorAction SilentlyContinue

        Write-Host "Checking if property '$propertyName' exists..."
        if ($itemProperties) {

            Write-Host "Property '$propertyName' exists"
            Write-Host "Property '$propertyName': Checking if property value is '$propertyValue'"

            if ($itemProperties.$propertyName -eq $propertyValue) {

                Write-Host "Property '$propertyName': Property value is '$propertyValue'"
                Exit 0
            }
            else {

                Write-Host "Property '$propertyName': Property value is not '$propertyValue'"
                Exit 1
            }
        }
        else {

            Write-Host "Property $propertyName does not exist"
            Exit 1
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error $errMsg
        Exit 1
    }
}