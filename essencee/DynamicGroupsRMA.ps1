# Import required modules
Import-Module ActiveDirectory
Import-Module PnP.PowerShell

# Define constants
$sharePointSiteUrl = "https://yoursharepointsiteurl"
$roleMapListName = "RoleMap"
$ouRMAGroups = "OU=RMAGroups,DC=yourdomain,DC=com"

# Authenticate to SharePoint
Connect-PnPOnline -Url $sharePointSiteUrl -Interactive

# Get the RoleMap list items
$roleMapItems = Get-PnPListItem -List $roleMapListName

# Create a hash table for quick lookup of RoleMap data
$roleMapHashTable = @{}
foreach ($item in $roleMapItems) {
    $roleMapHashTable[$item["BusinessTitle"]] = $item["RoleName"]
}

# Get all users in Active Directory
$allUsers = Get-ADUser -Filter * -Property title, memberOf

# Process each user
foreach ($user in $allUsers) {
    $userTitle = $user.title
    $userDn = $user.DistinguishedName
    $currentGroups = $user.memberOf | Where-Object { $_ -like "CN=*,OU=RMAGroups,DC=yourdomain,DC=com" }
    
    if ($roleMapHashTable.ContainsKey($userTitle)) {
        $roleName = $roleMapHashTable[$userTitle]
        $targetGroupDn = (Get-ADGroup -Filter { Name -eq $roleName }).DistinguishedName

        # Ensure user is a member of the correct group
        if (-not ($currentGroups -contains $targetGroupDn)) {
            Add-ADGroupMember -Identity $targetGroupDn -Members $userDn
        }

        # Remove user from any other RMAGroups
        foreach ($group in $currentGroups) {
            if ($group -ne $targetGroupDn) {
                Remove-ADGroupMember -Identity $group -Members $userDn -Confirm:$false
            }
        }
    } else {
        # If user's title does not match any RoleMap entry, remove them from all RMAGroups
        foreach ($group in $currentGroups) {
            Remove-ADGroupMember -Identity $group -Members $userDn -Confirm:$false
        }
    }
}

# Disconnect from SharePoint
Disconnect-PnPOnline

#####################################################
# add efficiency and best practices

# Import required modules
Import-Module ActiveDirectory
Import-Module PnP.PowerShell

# Define constants
$sharePointSiteUrl = "https://yoursharepointsiteurl"
$roleMapListName = "RoleMap"
$ouRMAGroups = "OU=RMAGroups,DC=yourdomain,DC=com"

# Function to connect to SharePoint
function Connect-ToSharePoint {
    Connect-PnPOnline -Url $sharePointSiteUrl -Interactive
}

# Function to get RoleMap data from SharePoint
function Get-RoleMap {
    param (
        [string]$listName
    )

    $roleMapItems = Get-PnPListItem -List $listName
    $roleMapHashTable = @{}
    foreach ($item in $roleMapItems) {
        $roleMapHashTable[$item["BusinessTitle"]] = $item["RoleName"]
    }
    return $roleMapHashTable
}

# Function to update user group memberships
function Update-UserGroupMemberships {
    param (
        [object]$user,
        [hashtable]$roleMap,
        [string]$rmaGroupsOU
    )

    $userTitle = $user.title
    $userDn = $user.DistinguishedName
    $currentGroups = $user.memberOf | Where-Object { $_ -like "CN=*,OU=RMAGroups,DC=yourdomain,DC=com" }

    if ($roleMap.ContainsKey($userTitle)) {
        $roleName = $roleMap[$userTitle]
        $targetGroupDn = (Get-ADGroup -Filter { Name -eq $roleName }).DistinguishedName

        # Ensure user is a member of the correct group
        if (-not ($currentGroups -contains $targetGroupDn)) {
            Add-ADGroupMember -Identity $targetGroupDn -Members $userDn -ErrorAction Stop
        }

        # Remove user from any other RMAGroups
        foreach ($group in $currentGroups) {
            if ($group -ne $targetGroupDn) {
                Remove-ADGroupMember -Identity $group -Members $userDn -Confirm:$false -ErrorAction Stop
            }
        }
    } else {
        # If user's title does not match any RoleMap entry, remove them from all RMAGroups
        foreach ($group in $currentGroups) {
            Remove-ADGroupMember -Identity $group -Members $userDn -Confirm:$false -ErrorAction Stop
        }
    }
}

# Main script logic
try {
    Connect-ToSharePoint
    $roleMap = Get-RoleMap -listName $roleMapListName
    $allUsers = Get-ADUser -Filter * -Property title, memberOf

    foreach ($user in $allUsers) {
        Update-UserGroupMemberships -user $user -roleMap $roleMap -rmaGroupsOU $ouRMAGroups
    }
} catch {
    Write-Error "An error occurred: $_"
} finally {
    Disconnect-PnPOnline
}

#########################################
#### add error logging details

# Import required modules
Import-Module ActiveDirectory
Import-Module PnP.PowerShell

# Define constants
$sharePointSiteUrl = "https://yoursharepointsiteurl"
$roleMapListName = "RoleMap"
$ouRMAGroups = "OU=RMAGroups,DC=yourdomain,DC=com"

# Function to connect to SharePoint
function Connect-ToSharePoint {
    try {
        Connect-PnPOnline -Url $sharePointSiteUrl -Interactive
    } catch {
        Write-Error "Error in Connect-ToSharePoint: $_"
        throw
    }
}

# Function to get RoleMap data from SharePoint
function Get-RoleMap {
    param (
        [string]$listName
    )

    try {
        $roleMapItems = Get-PnPListItem -List $listName
        $roleMapHashTable = @{}
        foreach ($item in $roleMapItems) {
            $roleMapHashTable[$item["BusinessTitle"]] = $item["RoleName"]
        }
        return $roleMapHashTable
    } catch {
        Write-Error "Error in Get-RoleMap: $_"
        throw
    }
}

# Function to update user group memberships
function Update-UserGroupMemberships {
    param (
        [object]$user,
        [hashtable]$roleMap,
        [string]$rmaGroupsOU
    )

    try {
        $userTitle = $user.title
        $userDn = $user.DistinguishedName
        $currentGroups = $user.memberOf | Where-Object { $_ -like "CN=*,OU=RMAGroups,DC=yourdomain,DC=com" }

        if ($roleMap.ContainsKey($userTitle)) {
            $roleName = $roleMap[$userTitle]
            $targetGroupDn = (Get-ADGroup -Filter { Name -eq $roleName }).DistinguishedName

            # Ensure user is a member of the correct group
            if (-not ($currentGroups -contains $targetGroupDn)) {
                Add-ADGroupMember -Identity $targetGroupDn -Members $userDn -ErrorAction Stop
            }

            # Remove user from any other RMAGroups
            foreach ($group in $currentGroups) {
                if ($group -ne $targetGroupDn) {
                    Remove-ADGroupMember -Identity $group -Members $userDn -Confirm:$false -ErrorAction Stop
                }
            }
        } else {
            # If user's title does not match any RoleMap entry, remove them from all RMAGroups
            foreach ($group in $currentGroups) {
                Remove-ADGroupMember -Identity $group -Members $userDn -Confirm:$false -ErrorAction Stop
            }
        }
    } catch {
        Write-Error "Error in Update-UserGroupMemberships for user $($user.SamAccountName): $_"
        throw
    }
}

# Main script logic
try {
    Connect-ToSharePoint
    $roleMap = Get-RoleMap -listName $roleMapListName
    $allUsers = Get-ADUser -Filter * -Property title, memberOf

    foreach ($user in $allUsers) {
        try {
            Update-UserGroupMemberships -user $user -roleMap $roleMap -rmaGroupsOU $ouRMAGroups
        } catch {
            Write-Error "Error processing user $($user.SamAccountName): $_"
        }
    }
} catch {
    Write-Error "An error occurred in the main script: $_"
} finally {
    Disconnect-PnPOnline
}
