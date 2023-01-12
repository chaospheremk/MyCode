function Check-ADGroupMembership {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputersCsvPath,
        [Parameter(Mandatory=$true)]
        [string]$GroupName,
        [Parameter(Mandatory=$true)]
        [string]$OutputCsvPath
    )

    # Connect to Active Directory
    Import-Module ActiveDirectory

    # Get the group object
    $group = Get-ADGroup -Identity $GroupName

    # Create a new ArrayList to store the results
    $results = New-Object System.Collections.ArrayList

    # Read the computers from the CSV file
    $computers = Import-Csv -Path $ComputersCsvPath
    $computersCount = $computers.Count
    Write-Progress -Activity "Reading Computers" -PercentComplete 0 -CurrentOperation "Reading $computersCount computers"
    # get all members of the group
    $Members = Get-ADGroupMember -Identity $GroupName -Recursive | Select-Object -ExpandProperty DistinguishedName
    # Loop through the computers
    $i = 0
    $computers | ForEach-Object -Parallel {
        $computer = $_
        # Add the result to the ArrayList
        $results.Add([PSCustomObject]@{
                Computer = $computer.Name
                GroupName = $GroupName
                IsMember = $Members -contains $computer.DistinguishedName
        })
        $i++
        Write-Progress -Activity "Checking Group Membership" -PercentComplete ($i/$computersCount*100) -CurrentOperation "Checking group membership for $i computers"
    }
    # Export the results to the output CSV file
    Write-Progress -Activity "Exporting Results" -PercentComplete 0 -CurrentOperation "Exporting $computersCount results"
    $results | Export-Csv -Path $OutputCsvPath -NoTypeInformation
    Write-Progress -Activity "Exporting Results" -Completed
}
