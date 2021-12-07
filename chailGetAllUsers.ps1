# This script will pull all information about all users and export the info into a csv file

# Begin script

# Prevent seeing a ton of errors if users don't have anything in the custom extension attributes
$ErrorActionPreference= 'silentlycontinue'

# Gets a date time stamp for naming the file to be exported

$DateTime = Get-Date -Format "MM-dd-yyyy_HH-mm"

# Sets the file path for the csv file to be exported

$FilePath = "C:\temp\chaiAllUsers_$DateTime"

# Prompts for Global Admin credentials upon running the script

$Credential = Get-Credential

# If the AzureAD module is not installed, it will be installed

if(-not (Get-Module AzureAD -ListAvailable)){
    Install-Module AzureAD -Scope CurrentUser -Force
}

# Imports the AzureAD module

Import-Module -Name AzureAD

# Connects to AzureAD

Connect-AzureAD -Credential $Credential

# Grabs a list of all users and the required properties

$Results = Get-AzureADUser -All $true | Select UserPrincipalName,GivenName,Surname,JobTitle,PhysicalDeliveryOfficeName,Department,TelephoneNumber,Mobile,ObjectType,AccountEnabled,ObjectId

# For each user in the list, grabs supervisor, employee number, and the two custom extension properties for users
# For each user, creates a PSCustomObject to store all of the correct information with the correct attribute labels

$FinalResults = foreach($result in $Results){
    $UserId = $result.ObjectId
    $Supervisor = Get-AzureADUserManager -ObjectId $result.ObjectId
    $EmpId = (Get-AzureADUserExtension -ObjectId $UserId).get_item("employeeId")
    $Contract = (Get-AzureADUserExtension -ObjectId $UserId).get_item("extension_1fbb2531061941e08a8a8707c2ae8c11_Contract")
    $Division = (Get-AzureADUserExtension -ObjectId $UserId).get_item("extension_1fbb2531061941e08a8a8707c2ae8c11_Division")
    [PSCustomObject] @{
        "Email Address" = $result.UserPrincipalName
        "Employee Number" = $EmpId
        "First Name" = $result.GivenName
        "Last Name" = $result.Surname
        "Job Title" = $result.JobTitle
        "Supervisor Email" = $Supervisor.UserPrincipalName
        "Division" = $Division
        "Office" = $result.PhysicalDeliveryOfficeName
        "Department" = $result.Department
        "Contract" = $Contract
        "Office Phone" = $result.TelephoneNumber
        "Mobile Phone" = $result.Mobile
        "Object Type" = $result.ObjectType
        "Account Enabled" = $result.AccountEnabled
        "ObjectId" = $result.ObjectId
    }
    $Contract = $null
    $Division = $null
}

# Exports all of the PSCustomObject objects to a csv

$FinalResults | Export-csv -Path $FilePath -NoTypeInformation