# This script will import a NewUsers CSV and set all information about all users contained within based on what is in the CSV.
# Note: If a field in the csv file is blank, that information will be removed on the user.

#### Begin script ####

# REQUIREMENTS
# 1. The CSV must contain the field names list below. A template is provided in the code repository called chailNewUsers_Template.csv.
#       * = Minimum required values for a new user to be created. Columns must still exist, even if they have no values.
#       Required columns for script to run:
#           Email Address*
#           Initial Password*
#           Employee Number
#           First Name*
#           Last Name*
#           Job Title
#           Supervisor Email
#           Division
#           Office
#           Department
#           Contract
#           Office Phone
#           Mobile Phone
#
# 2. Name the CSV file to be imported to chaiNewUsers.csv and place it in C:\temp before running this script.

# Set the file path for the CSV to import
$FilePath = "C:\temp\chailNewUsers.csv"

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

# For each record in the imported csv, this foreach loop will create a new user with the info in the csv to the corresponding fields in Azure AD for the user specified by the UserPrincipalName field in the csv.
# Note: The fields in the csv that will not be imported or used are "Email Address", "Object Type", and "Account Enabled"
foreach ($import in $Imported) {
    $EmailAddress = $import."Email Address"
    $InitialPassword = $import."Initial Password"
    $MailNickName = $EmailAddress.Split("@")[0]
    $EmployeeId = $import."Employee Number"
    $GivenName = $import."First Name"
    $Surname = $import."Last Name"
    $DisplayName = $GivenName+" "+$Surname
    $JobTitle = $import."Job Title"
    $SupUserPrincipalName = $import."Supervisor Email"
    $Division = $import."Division"
    $PhysicalDeliveryOfficeName = $import."Office"
    $Department = $import."Department"
    $Contract = $import."Contract"
    $TelephoneNumber = $import."Office Phone"
    $Mobile = $import."Mobile Phone"
    $ObjectId = $import."ObjectId"

    # Sets the password to the value in the "Initial Password" field in the CSV. User will be asked to change their password upon first login.
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = $InitialPassword
    $PasswordProfile.ForceChangePasswordNextLogin = $true

    # Creates the new user with the minimum required fields.
    New-AzureADUser -DisplayName $DisplayName -UserPrincipalName $EmailAddress -MailNickName $MailNickName -PasswordProfile $PasswordProfile -AccountEnabled $true
    
    # Gets the ObjectId of the user for setting the rest of the properties that exist in the CSV file.
    $ObjectId = (Get-AzureADUser -Searchstring $EmailAddress).ObjectId

    # If "Employee Number" in the CSV has data, set "EmployeeId" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($EmployeeId)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "employeeId" -ExtensionValue $EmployeeId
    }

    # If "First Name" in the CSV has data, set "GivenName" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($GivenName)) {
        Set-AzureADUser -ObjectId $ObjectId -GivenName $GivenName
    }

    # If "Last Name" in the CSV has data, set "Surname" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Surname)) {
        Set-AzureADUser -ObjectId $ObjectId -Surname $Surname
    }

    # If "Job Title" in the CSV has data, set "jobTitle" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($JobTitle)) {
        Set-AzureADUser -ObjectId $ObjectId -jobTitle $JobTitle
    }

    # If "Supervisor Email" in the CSV has data, add associated user as the user's manager in Azure AD with the UserPrincipalName in the CSV field.
    if (![string]::IsNullOrWhiteSpace($SupUserPrincipalName)) {
        $SupObjectId = (Get-AzureADUser -ObjectId $SupUserPrincipalName).ObjectId
        Set-AzureADUserManager -ObjectId $ObjectId -RefObjectId $SupObjectId
        $SupObjectId = $null
    }

    # If "Division" in the CSV has data, set "extension_1fbb2531061941e08a8a8707c2ae8c11_Division" extension property in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Division)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Division" -ExtensionValue $Division
    }

    # If "Office" in the CSV has data, set "PhysicalDeliveryOfficeName" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($PhysicalDeliveryOfficeName)) {
        Set-AzureADUser -ObjectId $ObjectId -PhysicalDeliveryOfficeName $PhysicalDeliveryOfficeName
    }

    # If "Department" in the CSV has data, set "Department" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Department)) {
        Set-AzureADUser -ObjectId $ObjectId -Department $Department
    }

    # If "Contract" in the CSV has data, set "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract" extension property in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Contract)) {
        Set-AzureADUserExtension -ObjectId $ObjectId -ExtensionName "extension_1fbb2531061941e08a8a8707c2ae8c11_Contract" -ExtensionValue $Contract
    }

    # If "Office Phone" in the CSV has data, set "TelephoneNumber" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($TelephoneNumber)) {
        Set-AzureADUser -ObjectId $ObjectId -TelephoneNumber $TelephoneNumber
    }

    # If "Mobile Phone" in the CSV has data, set "Mobile" in Azure AD to the value in the CSV field.
    if (![string]::IsNullOrWhiteSpace($Mobile)) {
        Set-AzureADUser -ObjectId $ObjectId -Mobile $Mobile
    }
}

#### End script ####


License Info
MICROSOFT 365 BUSINESS PREMIUM - SPB
MICROSOFT 365 BUSINESS BASIC - O365_BUSINESS_ESSENTIALS
MICROSOFT 365 E3 - SPE_E3
MICROSOFT 365 E5 - SPE_E5