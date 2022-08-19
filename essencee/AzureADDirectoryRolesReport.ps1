Connect-AzureAD -AzureEnvironmentName "AzureUSGovernment"

# Get all assigned roles in the directory
$AllDirectoryRoles = Get-AzureADDirectoryRole
$TimeStamp = get-date -Format yyyy_MM_dd_hh_mm_ss
$ExportPath = "C:\Reports\DirectoryRolesReport-$TimeStamp.csv"

$DirectoryRolesReport = foreach ($role in $AllDirectoryRoles) {
    $RoleObjectID = $role.ObjectId
    $RoleName = $role.DisplayName
    $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $RoleObjectID
    foreach ($member in $RoleMembers) {
        if ($member.ObjectType -eq "User") {
            [PSCustomObject] @{
                DisplayName = $member.DisplayName
                FirstName = $member.GivenName
                LastName = $member.SurName
                UserPrincipalName = $member.UserPrincipalName
                RoleName = $RoleName
            }
        }
    }
}

$DirectoryRolesReport | Export-Csv -Path $ExportPath -NoTypeInformation