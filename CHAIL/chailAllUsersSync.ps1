# DESCRIPTION
# This script will import an AllUsers csv and set all information about all users based on what is in the csv.
# Note: If a field in the csv file is blank, that information will be removed on the user.
#
# REQUIREMENTS
# 1. The csv must contain the same field names as the exported csv from the chailGetAllUsers.ps1 script.
# 2. This script uses the ObjectId field generated from the chailGetAllUsers.ps1 script.
# 4. Name the csv file to be imported to chailAllUsers_Sync.csv and place it in C:\temp before running this script.

#### Begin script ####

# Set the file path for the csv to import
$FilePath = "C:\temp\chailAllUsers_Sync.csv"

# If the AzureAD module is not installed, it will be installed
if(-not (Get-Module AzureAD -ListAvailable)){
    Install-Module AzureAD -Scope CurrentUser -Force
}

# Imports the AzureAD module
Import-Module -Name AzureAD

# Connects to AzureAD and prompts for credentials and MFA
Connect-AzureAD

# Imports the csv into an array
$Imported = Import-Csv -Path $FilePath

# For each record in the imported csv, this foreach loop will sync in the info in the csv to the corresponding fields in Azure AD for the user specified by the ObjectId field in the csv.
# Note: The fields in the csv that will not be imported or used are "Email Address", "Object Type", and "Account Enabled"
foreach ($import in $Imported) {
    $EmployeeId = $import."Employee Number"
    $GivenName = $import."First Name"
    $Surname = $import."Last Name"
    $JobTitle = $import."Job Title"
    $SupUserPrincipalName = $import."Supervisor Email"
    $Division = $import."Division"
    $PhysicalDeliveryOfficeName = $import."Office"
    $Department = $import."Department"
    $Contract = $import."Contract"
    $TelephoneNumber = $import."Office Phone"
    $Mobile = $import."Mobile Phone"
    $ObjectId = $import."ObjectId"

    # If "Employee Number" in the CSV has data, set "EmployeeId" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($EmployeeId)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "employeeId" -ExtensionValue $EmployeeId
    }

    # If "Employee Number" in the CSV is null, empty, or has white space, set "EmployeeId" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($EmployeeId)) {
        Remove-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "employeeId"
    }

    # If "First Name" in the CSV has data, set "GivenName" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($GivenName)) {
        Set-AzureADUser -ObjectId $ObjectId -GivenName $GivenName
    }

    # If "First Name" in the CSV is null, empty, or has white space, set "GivenName" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($GivenName)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("GivenName", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    # If "Last Name" in the CSV has data, set "Surname" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Surname)) {
        Set-AzureADUser -ObjectId $ObjectId -Surname $Surname
    }

    # If "Last Name" in the CSV is null, empty, or has white space, set "Surname" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($Surname)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("Surname", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    # If "Job Title" in the CSV has data, set "jobTitle" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($JobTitle)) {
        Set-AzureADUser -ObjectId $ObjectId -jobTitle $JobTitle
    }

    # If "Job Title" in the CSV is null, empty, or has white space, set "jobTitle" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($JobTitle)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("jobTitle", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    # If "Supervisor Email" in the CSV has data, add associated user as the user's manager in Azure AD with the UserPrincipalName in the CSV field.
    if (![string]::IsNullOrWhiteSpace($SupUserPrincipalName)) {
        $SupObjectId = (Get-AzureADUser -ObjectId $SupUserPrincipalName).ObjectId
        Set-AzureADUserManager -ObjectId $ObjectId -RefObjectId $SupObjectId
        $SupObjectId = $null
    }

    # If "Supervisor Email" in the CSV is null, empty, or has white space, remove any users as the user's manager in Azure AD.
    elseif ([string]::IsNullOrWhiteSpace($SupUserPrincipalName)) {
        Remove-AzureADUserManager -ObjectId $ObjectId
        $SupObjectId = $null
    }

    # If "Division" in the CSV has data, set "extension_1fbb2531061941e08a8a8707c2ae8c11_Division" extension property in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Division)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Division" -ExtensionValue $Division
    }

    # If "Division" in the CSV is null, empty, or has white space, remove "extension_1fbb2531061941e08a8a8707c2ae8c11_Division" extension property in Azure AD.
    elseif ([string]::IsNullOrWhiteSpace($Division)) {
        Remove-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Division"
    }

    # If "Office" in the CSV has data, set "PhysicalDeliveryOfficeName" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($PhysicalDeliveryOfficeName)) {
        Set-AzureADUser -ObjectId $ObjectId -PhysicalDeliveryOfficeName $PhysicalDeliveryOfficeName
    }

    # If "Office" in the CSV is null, empty, or has white space, set "PhysicalDeliveryOfficeName" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($PhysicalDeliveryOfficeName)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("PhysicalDeliveryOfficeName", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    # If "Department" in the CSV has data, set "Department" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Department)) {
        Set-AzureADUser -ObjectId $ObjectId -Department $Department
    }

    # If "Department" in the CSV is null, empty, or has white space, set "Department" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($Department)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("Department", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    # If "Contract" in the CSV has data, set "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract" extension property in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Contract)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract" -ExtensionValue $Contract
    }

    # If "Contract" in the CSV is null, empty, or has white space, remove "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract" extension property in Azure AD.
    elseif ([string]::IsNullOrWhiteSpace($Contract)) {
        Remove-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract"
    }

    # If "Office Phone" in the CSV has data, set "TelephoneNumber" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($TelephoneNumber)) {
        Set-AzureADUser -ObjectId $ObjectId -TelephoneNumber $TelephoneNumber
    }

    # If "Office Phone" in the CSV is null, empty, or has white space, set "TelephoneNumber" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($TelephoneNumber)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("TelephoneNumber", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    # If "Mobile Phone" in the CSV has data, set "Mobile" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Mobile)) {
        Set-AzureADUser -ObjectId $ObjectId -Mobile $Mobile
    }

    # If "Mobile Phone" in the CSV is null, empty, or has white space, set "Mobile" in Azure AD to null.
    elseif ([string]::IsNullOrWhiteSpace($Mobile)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("Mobile", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }
}

#### End script ####