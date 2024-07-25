# Define the path to the CSV file containing group names
$csvPath = "C:\Path\To\GroupNames.csv"

# Define the path to the output file
$outputPath = "C:\Path\To\GroupMembersReport.csv"

# Import the list of group names from the CSV file
$groupNames = Import-Csv -Path $csvPath

# Initialize a list to store the output
$report = @()

# Function to recursively get all members of a group, including nested groups
function Get-AllGroupMembers {
    param (
        [string]$GroupName
    )

    # Get all members of the group
    $members = Get-ADGroupMember -Identity $GroupName -Recursive

    foreach ($member in $members) {
        # Check if the member is a group
        if ($member.objectClass -eq 'group') {
            # If the member is a group, call the function recursively
            Get-AllGroupMembers -GroupName $member.SamAccountName
        } else {
            # Otherwise, add the user to the report
            $report += [PSCustomObject]@{
                GroupName   = $GroupName
                MemberName  = $member.SamAccountName
                MemberType  = $member.objectClass
            }
        }
    }
}

# Loop through each group in the list and get members
foreach ($group in $groupNames) {
    Get-AllGroupMembers -GroupName $group.GroupName
}

# Export the report to a CSV file
$report | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "Group members report has been generated at: $outputPath"
