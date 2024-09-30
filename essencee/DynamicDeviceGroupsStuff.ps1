using namespace System.Collections.Generic

$propsGetADGroup = @( 'Name', 'Members' )
$paramsGetADGroup = @{ Filter = '*'; Property = $propsGetADGroup; Server = $server; Credential = $credential }

$paramsGetADGroup.SearchBase = 'UserPersonaGroupsOU'
[List[PSObject]]$initAllUserPersonaGroups = Get-ADGroup @paramsGetADGroup | Select-Object -Property $propsGetADGroup

$allUserPersonaGroups = @{}
foreach ($group in $initAllUserPersonaGroups) { $allUserPersonaGroups[$group.DistinguishedName] = $group }

$paramsGetADGroup.SearchBase = 'DevicePersonaGroupsOU'
[List[PSObject]]$initAllDevicePersonaGroups = Get-ADGroup @paramsGetADGroup | Select-Object -Property $propsGetADGroup

$allDevicePersonaGroups = @{}
foreach ($group in $initAllDevicePersonaGroups) { $allDevicePersonaGroups[$group.DistinguishedName] = $group }

$propsGetADUser = @( 'Name', 'DistinguishedName', 'SamAccountName' )
$paramsGetADUser = @{ Filter = '*'; Property = $propsGetADUser; Server = $server; Credential = $credential }

[List[PSObject]]$initAllADUsers = Get-ADUser @paramsGetADUser | Select-Object -Property $propsGetADUser

$allADUsers = @{}
foreach ($user in $initAllADUsers) { $allADUsers[$user.DistinguishedName] = $user }

$propsGetADComputer = @( 'Name', 'DistinguishedName' )
$paramsGetADComputer = @{

    Filter = { OperatingSystem -like 'Windows*' -and OperatingSystem -notlike '*Server*' }
    Property = $propsGetADComputer
    Server = $server
    Credential = $credential
}

[List[PSObject]]$initAllADComputers = Get-ADComputer @paramsGetADComputer | Select-Object -Property $propsGetADComputer

$allADComputers = @{}
foreach ($computer in $initAllADComputers) { $allADComputers[$computer.Name] = $computer }

$propsGetMgUser = @( 'Id', 'OnPremisesSamAccountName' )
$paramsGetMgUser = @{ All = $true; Property = $propsGetMgUser }

[List[PSObject]]$initAllEntraUsers = Get-MgUser @paramsGetMgUser | Select-Object -Property $propsGetMgUser

$allEntraUsers = @{}
foreach ($user in $initAllEntraUsers) { if( $null -ne $user.OnPremisesSamAccountName) { $allEntraUsers[$user.OnPremisesSamAccountName] = $user } }

$processResultsList = [List[PSObject]]::new()

foreach ($userPersonaGroup in $allUserPersonaGroups) {

    $devicePersonaGroupName = $userPersonaGroup.Name -replace 'User', 'Device'

    [PSObject]$devicePersonaGroup = $allDevicePersonaGroups[$devicePersonaGroupName]

    foreach ($member in $userPersonaGroup.Members) {

        [PSObject]$memberADUser = $allADUsers[$member]

        [PSObject]$memberEntraUser = $allEntraUsers[$memberADUser.SamAccountName]

        [List[PSObject]]$registeredDevices = (Get-MgUserRegisteredDevice -UserId $memberEntraUser.Id).Where({ ($_.AdditionalProperties.operatingSystem -eq 'Windows') -and ($true -eq $_.AdditionalProperties.accountEnabled) })

        foreach ( $registeredDevice in $registeredDevices ) {

            [PSObject]$memberADComputer = $allADComputers[$registeredDevice.DisplayName]

            if ($devicePersonaGroup.Members -notcontains $memberADComputer.DistinguishedName) {

                $processResultsList.Add(

                    [PSCustomObject] @{

                        UserName = $memberADUser.Name
                        UserDN = $memberADUser.DistinguishedName
                        UserPersonaGroupName = $userPersonaGroup.Name
                        UserPersonaGroupDN = $userPersonaGroup.DistinguishedName
                        DevicePersonaGroupName = $devicePersonaGroup.Name
                        DevicePersonaDN = $devicePersonaGroup.DistinguishedName
                        ComputerName = $memberADComputer.Name
                        ComputerDN = $memberADComputer.DistinguishedName
                        ProcessState = 'AD computer not in device persona group'
                        ActionToTake = 'Add'
                    }
                )
            }
        }
    }
}