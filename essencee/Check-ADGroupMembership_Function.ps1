function Check-ADGroupMembership {
    <#
    .SYNOPSIS
        Check if a list of computers are members of a specific Active Directory group and export the results to a CSV file
    .DESCRIPTION
        This function uses the Microsoft Active Directory module to connect to AD and check if a list of computers are members of a specific group.
    .PARAMETER ComputersCsvPath
        The path of the CSV file that contains the list of computers
    .PARAMETER GroupName
        The name of the Active Directory group
    .PARAMETER OutputCsvPath
        The path of the output CSV file where the results will be exported
    .EXAMPLE
        Check-ADGroupMembership -ComputersCsvPath C:\computers.csv -GroupName "Domain Computers" -OutputCsvPath C:\results.csv
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$ComputersCsvPath,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$GroupName,
        [Parameter(Mandatory=$true, Position=2)]
        [ValidateScript({ Test-Path -Path (Split-Path -Parent $_) -PathType Container })]
        [string]$OutputCsvPath
    )

    try {
        # Connect to Active Directory
        Import-Module ActiveDirectory -ErrorAction Stop

        # Get the group object
        $group = Get-ADGroup -Identity $GroupName -ErrorAction Stop

        # Create a new ArrayList to store the results
        $results = New-Object System.Collections.ArrayList

        # Read the computers from the CSV file
        $computers = Import-Csv -Path $ComputersCsvPath -ErrorAction Stop

        # Get all members of the group
        $Members = Get-ADGroupMember -Identity $GroupName -Recursive | Select-Object -ExpandProperty DistinguishedName

        # Loop through the computers
        foreach ($computer in $computers) {
            # Add the result to the ArrayList
            $results.Add([PSCustomObject]@{
                Computer = $computer.Name
                GroupName = $GroupName
                IsMember = $Members -contains $computer.DistinguishedName
            })
        }
        # Export the results to the output CSV file
        $results | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Force
    } catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}
