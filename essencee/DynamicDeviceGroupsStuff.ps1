using namespace System.Collections.Generic

[List[PSObject]]$allPersonaUserGroups = #Get all user persona groups

[List[PSObject]]$allPersonaDeviceGroups = #Get all device persona groups

[List[PSObject]]$allADUsers = #get all AD users

# scope this down somehow
[List[PSObject]]$allADComputers = #get all AD computers

[List[PSObject]]$allEntraUsers = #get all Entra ID users

#$caGroupMembers = Get all users in CA group

#$allCloudPCs = Get all cloud PCs

#$allAVDPCs = Get all AVD PCs

$processResultsList = [List[Object]]::new()

foreach ($userPersonaGroup in $userPersonaGroups) {

    [PSObject]$devicePersonaGroup = $allDevicePersonaGroups.Where({ $_.Name -eq ($userPersonaGroup.Name -replace 'User', 'Device') })

    foreach ($member in $userPersonaGroup.Members) {

        [PSObject]$memberADUser = $allADUsers.Where({ $_.DistinguishedName -eq $member })

        [PSObject]$memberEntraUser = $allEntraUsers.Where({ $_.SamAccountName -eq $memberADUser.SamAccountName })

        foreach ( $memberEntraDevice in $memberEntraUser.Devices ) {

            $memberADComputer = $allADComputers.Where({ $_.Name -eq $memberEntraDevice.Name })

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