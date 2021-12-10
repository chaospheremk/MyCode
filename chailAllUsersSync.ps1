# This script will import an AllUsers csv and set all information about all users based on what is in the csv.
# Note: If a field in the csv file is blank, that information will be removed on the user.

#### Begin script ####

# Set the file path for the csv to import
# Note: The csv must contain the same field names as the exported csv from the chailGetAllUsers.ps1 script.
#       This script uses the ObjectId field generated from the chailGetAllUsers.ps1 script.
#       Rename the csv file to be imported to chaiAllUsers_Sync.csv and place it in C:\temp before running this script.
$FilePath = "C:\temp\chaiAllUsers_Sync.csv"

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

# If Employee Number in the CSV has data, set Employee Number to the value in the field.
    if (![string]::IsNullOrWhiteSpace($EmployeeId)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "employeeId" -ExtensionValue $EmployeeId
    }
    elseif ([string]::IsNullOrWhiteSpace($EmployeeId)) {
        Remove-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "employeeId"
    }

    if (![string]::IsNullOrWhiteSpace($GivenName)) {
        Set-AzureADUser -ObjectId $ObjectId -GivenName $GivenName
    }
    elseif ([string]::IsNullOrWhiteSpace($GivenName)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("GivenName", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    if (![string]::IsNullOrWhiteSpace($Surname)) {
        Set-AzureADUser -ObjectId $ObjectId -Surname $Surname
    }
    elseif ([string]::IsNullOrWhiteSpace($Surname)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("Surname", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    if (![string]::IsNullOrWhiteSpace($JobTitle)) {
        Set-AzureADUser -ObjectId $ObjectId -jobTitle $JobTitle
    }
    elseif ([string]::IsNullOrWhiteSpace($JobTitle)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("jobTitle", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    if (![string]::IsNullOrWhiteSpace($SupUserPrincipalName)) {
        $SupObjectId = (Get-AzureADUser -ObjectId $SupUserPrincipalName).ObjectId
        Set-AzureADUserManager -ObjectId $ObjectId -RefObjectId $SupObjectId
        $SupObjectId = $null
    }
    elseif ([string]::IsNullOrWhiteSpace($SupUserPrincipalName)) {
        Remove-AzureADUserManager -ObjectId $ObjectId
        $SupObjectId = $null
    }

    if (![string]::IsNullOrWhiteSpace($Division)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Division" -ExtensionValue $Division
    }
    elseif ([string]::IsNullOrWhiteSpace($Division)) {
        Remove-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Division"
    }

    if (![string]::IsNullOrWhiteSpace($PhysicalDeliveryOfficeName)) {
        Set-AzureADUser -ObjectId $ObjectId -PhysicalDeliveryOfficeName $PhysicalDeliveryOfficeName
    }
    elseif ([string]::IsNullOrWhiteSpace($PhysicalDeliveryOfficeName)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("PhysicalDeliveryOfficeName", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    if (![string]::IsNullOrWhiteSpace($Department)) {
        Set-AzureADUser -ObjectId $ObjectId -Department $Department
    }
    elseif ([string]::IsNullOrWhiteSpace($Department)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("Department", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    if (![string]::IsNullOrWhiteSpace($Contract)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract" -ExtensionValue $Contract
    }
    elseif ([string]::IsNullOrWhiteSpace($Contract)) {
        Remove-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract"
    }

    if (![string]::IsNullOrWhiteSpace($TelephoneNumber)) {
        Set-AzureADUser -ObjectId $ObjectId -TelephoneNumber $TelephoneNumber
    }
    elseif ([string]::IsNullOrWhiteSpace($TelephoneNumber)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("TelephoneNumber", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }

    if (![string]::IsNullOrWhiteSpace($Mobile)) {
        Set-AzureADUser -ObjectId $ObjectId -Mobile $Mobile
    }
    elseif ([string]::IsNullOrWhiteSpace($Mobile)) {
        $nullvalue = [Collections.Generic.Dictionary[[String],[String]]]::new()
        $nullvalue.Add("Mobile", [NullString]::Value)
        Set-AzureADUser -ObjectId $ObjectId -ExtensionProperty $nullvalue
        $nullvalue = $null
    }
}

#### End script #### 







