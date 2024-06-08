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

        Write-Host "Checking if property '$propertyName' exists..."
        $itemProperties = Get-ItemProperty -Path $path -Name $propertyName -ErrorAction SilentlyContinue
        if ($itemProperties) {

            Write-Host "Property '$propertyName' exists"
            Write-Host "Property '$propertyName': Checking if property value is '$propertyValue'"

            if ($itemProperties.$propertyName -eq $propertyValue) {

                Write-Host "Property '$propertyName': Property value is '$propertyValue'"
                Exit 0
            }
            else {

                Write-Host "Property '$propertyName': Property value is not '$propertyValue'"
                Write-Host "Property '$propertyName': Setting property value to '$propertyValue...'"

                Set-ItemProperty -Path $path -Name $propertyName -Value $propertyValue -PropertyType String -Force -ErrorAction Stop

                Write-Host "Property '$propertyName': Set property value to '$propertyValue'"
            }
        }
        else {

            Write-Host "Property $propertyName does not exist"
            Write-Host "Creating property '$propertyName' with value '$propertyValue'..."

            New-ItemProperty -Path $path -Name $propertyName -Value $propertyValue -PropertyType String -Force -ErrorAction Stop

            Write-Host "Created property '$propertyName' with value '$propertyValue'"
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error $errMsg
        Exit 1
    }
}

Exit 0