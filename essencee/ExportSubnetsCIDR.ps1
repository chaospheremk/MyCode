# Specify the Windows Firewall rule you want to check
$rule_name = "MyFirewallRule"

# Get the Scope section of the rule
$output = netsh advfirewall firewall show rule name=$rule_name rmtcomputer

# Parse the Scope section to extract the IP address subnets
$subnets = $output | Select-String "Remote IP address" | ForEach-Object {$_.Line.Split(":")[1].Trim()}

# Convert subnet masks to CIDR notation
$cidr_subnets = $subnets | ForEach-Object {[System.Net.IPNetwork]::Parse($_).ToString()}

# Export the list of subnets to a CSV file
$cidr_subnets | Export-Csv -Path .\subnets.csv -NoTypeInformation
