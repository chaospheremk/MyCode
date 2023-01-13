Import-Module ActiveDirectory

$allGroups = Get-ADGroup -Filter * -Properties MemberOf
$output = New-Object System.Collections.ArrayList

foreach ($group in $allGroups) {
    $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive
    $output.Add((New-Object PSObject -Property @{
        GroupName = $group.Name
        NestedGroups = ($group.MemberOf | ForEach-Object {(Get-ADGroup -Identity $_).Name}) -join ';'
        Members = ($members | Select-Object -ExpandProperty Name) -join ';'
    }))
}

$output | Export-Csv -Path "C:\output.csv" -NoTypeInformation
