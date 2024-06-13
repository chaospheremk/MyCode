

# https://pnp.github.io/powershell/articles/connecting.html
# https://pnp.github.io/powershell/articles/authentication.html

# Steps
# create certificate for auth
#$certname = "RoleManagementTest"    ## Replace {certificateName}
#$cert = New-SelfSignedCertificate -Subject "CN=$certname" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256

#Export-Certificate -Cert $cert -FilePath "C:\temp\$certname.cer"   ## Specify your preferred location

# create app registration in Entra portal
# permissions. API permissions > Add a permission > APIs my organization uses > search for "Office 365" > Select "Office 365 SharePoint Online" > Application permissions >
# Sites.FullControl.All, Sites.ReadWrite.All

########### SCRIPT
# List Notes
# - BusinessTitle and RoleName fields have "list formatting" set to not be null
# Requirements:
# - sharepoint list RoleMap table can NOT have a null value in BusinessTitle or RoleName fields. Script will stop and report an error.
[CmdletBinding()]
Param()

Begin {

    $timestamp = get-date -Format yyyy_MM_dd_hh_mm_ss
    function Write-Log {

        [CmdletBinding()]
        Param(
    
            [string]$message
        )
    
        Begin {
    
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
            if (-NOT (Test-Path "C:\RoleManagement")) {
    
                $null = New-Item -Path "C:\" -Name "RoleManagement" -ItemType "directory"
            }
        }
    
        Process {
    
            $logMessage = "$timestamp - $message"
            Write-Output $logMessage
            Add-Content -Path "C:\RoleManagement\RoleManagement.log" -Value $logMessage
        }
    
        End {
            # no content
        } # end
    }

    Write-Log "Starting RoleManagement script..."
} # begin

Process {
    # connect to site via PnP.Powershell
    $url = "https://company.sharepoint.us/sites/sitename"

    $paramConnect = @{

        #Interactive = $true
        Url = $url
        Tenant = "company.onmicrosoft.com"
        AzureEnvironment = "USGovernmentHigh"
        ClientId = "placeholder"
        Thumbprint = "placeholder"
        ErrorAction = "Stop"
    }

    Write-Log "Connecting to Sharepoint site: $url ..."

    try {
        
        $null = Connect-PnPOnline @paramConnect
        Write-Log "Connecting to Sharepoint site: SUCCEEDED"
    }
    catch {

        Write-Log "Connecting to Sharepoint site: FAILED"
    }

    # get/create role mapping table
    $roleMapArray = New-Object System.Collections.ArrayList
    $roleMapArrayErrors = New-Object System.Collections.ArrayList
    $roleMapArrayErrorsFilePath = "C:\RoleManagement\RoleMapArrayErrors_$timestamp.csv"

    Write-Log "Getting list items from SharePoint list RoleMap..."
    try {

        $listItems = Get-PnPListItem -List "RoleMap" -ErrorAction Stop
        Write-Log "Getting list items from SharePoint list RoleMap: SUCCEEDED"
    }
    catch {

        Write-Log "Getting list items from SharePoint list RoleMap: FAILED"
    }

    Write-Log "Processing RoleMapArray..."
    foreach ($item in $listItems) {
        
        $listId = $item.Id
        $businessTitle = $item.FieldValues.BusinessTitle
        $roleName = $item.FieldValues.RoleName

        if ((-not $businessTitle) -or (-not $roleName)) {

            if (-not $businessTitle) {
                
                $errMessage = "BusinessTitle value is null at ListID: $listId"
            }

            if (-not $roleName) {

                $errMessage = "RoleName value is null at ListID: $listId"
            }

            $errLogMessage =  "ERROR: RoleMapArray - $errMessage"

            $null = $roleMapArrayErrors.Add(

                [PSCustomObject] @{

                    Message = $errMessage
                    ListId = $listId
                    BusinessTitle = $businessTitle
                    RoleName = $roleName
                }
            )

            Write-Log "$errLogMessage"
            continue
        }

        $null = $roleMapArray.Add(
            
            [PSCustomObject] @{

                BusinessTitle = $businessTitle.Trim()
                RoleName = $roleName.Trim()
            }
        )
    }

    if ($roleMapArrayErrors) {

        $roleMapArrayErrors | Export-csv -Path $roleMapArrayErrorsFilePath -NoTypeInformation
        Write-Log "Processing RoleMapArray: SUCCEEDED with errors. Check $roleMapArrayErrorsFilePath"
    } else {

        Write-Log "Processing RoleMapArray: SUCCEEDED with no errors"
    }

    # get all standard AD users - NEED TO ADD CUSTOM ATTRIBUTES TO THIS EVENTUALLY
    Write-Log "Getting all standard users in Active Directory..."
    $paramAllUsers = @{

        Filter = "Enabled -eq 'True' -and employeeId -ne 'null' -and SamAccountName -notlike '*svc*'"
        SearchBase = "OU=Users,DC=company,DC=com"
        Property = @(

            "title",
            "msDS-cloudExtensionAttribute16"
        )
        ErrorAction = "Stop"
    }

    Write-Log "Getting all standard users in Active Directory..."
    try {

        $allUsers = Get-ADUser @paramAllUsers | Select-Object -First 100
        Write-Log "Getting all standard users in Active Directory: SUCCEEDED"
    }
    catch {

        Write-Log "Getting all standard users in Active Directory: FAILED"
    }

    # get all role group group members
    # get all role groups from sharepoint table
    $groupsToGet = $roleMapArray.RoleName | Select-Object -Unique
    $groupsArray = New-Object System.Collections.ArrayList
    $groupsArrayErrors = New-Object System.Collections.ArrayList
    $groupsArrayErrorsFilePath = "C:\RoleManagement\GroupsArrayErrors_$timestamp.csv"

    foreach ($group in $groupsToGet) {

        try {

            $groupObject = Get-ADGroup -Identity $group -Property Members -ErrorAction Stop
        }
        catch {

            $null = $groupsArrayErrors.Add(
                
                [PSCustomObject] @{

                    Level        = "Warning"
                    ErrorRecord  = $_
                    Message      = $_.Exception.Message
                    FunctionName = $_.InvocationInfo.MyCommand
                }
            )
        }

        $groupObjectGuid = $groupObject.ObjectGUID
        $groupName = $groupObject.Name
        $groupMembers = $groupObject.Members

        foreach ($groupMember in $groupMembers) {
            
            $null = $groupsArray.Add(
                
                [PSCustomObject] @{
                    
                    GroupObjectGuid = $groupObjectGuid
                    GroupName = $groupName
                    DistinguishedName = $groupMember
                }
            )
        }
    }

    if ($groupsArrayErrors) {

        $groupsArrayErrors | Export-csv -Path $groupsArrayErrorsFilePath -NoTypeInformation
        Write-Log "Processing GroupsArray: SUCCEEDED with errors. Check $groupsArrayErrorsFilePath"
    } else {

        Write-Log "Processing GroupsArray: SUCCEEDED with no errors"
    }

    # for each user loop

    Write-Log "Processing users..."

    $usersNotProcessedArray = New-Object System.Collections.ArrayList
    $usersNotProcessedFilePath = "C:\RoleManagement\UsersNotProcessed_$timestamp.csv"
    $usersRoleNameChangeRecordArray = New-Object System.Collections.ArrayList
    $usersRoleNameChangeRecordFilePath = "C:\RoleManagement\UsersRoleNameChange_$timestamp.csv"
    $usersRoleNameStayRecordArray = New-Object System.Collections.ArrayList
    $usersRoleNameStayRecordFilePath = "C:\RoleManagement\UsersRoleNameStay_$timestamp.csv"

    foreach ($user in $allUsers) {

        $userName = $user.Name
        $userUserPrincipalName = $user.UserPrincipalName
        $userDistinguishedName = $user.DistinguishedName
        $userTitle = $user.title
        $msdsCloudExtensionAttribute16 = $user.'msDS-cloudExtensionAttribute16'

        if ($roleMapArray.BusinessTitle -notcontains $userTitle) {

            # roleMapArray doesn't contain the user's business title

            $null = $usersNotProcessedArray.Add(
                
                [PSCustomObject] @{

                    UserName = $userName
                    UserPrincipalName = $userUserPrincipalName
                    UserDistinguishedName = $userDistinguishedName
                    UserTitle = $userTitle
                    UserRoleName = $msdsCloudExtensionAttribute16
                    Error = "RoleMapArray does not contain user's BusinessTitle. Check $roleMapArrayErrorsFilePath"
                }
            )

            continue
        }

        $roleMapArrayRecord = $roleMapArray.where({ $_.BusinessTitle -eq $userTitle})
        #$roleMapArrayRecordBusinessTitle = $roleMapArrayRecord.BusinessTitle
        $roleMapArrayRecordRoleName = $roleMapArrayRecord.RoleName

        if ($msdsCloudExtensionAttribute16 -ne $roleMapArrayRecordRoleName) {
            # if user's RoleName doesn't match RoleName in title-to-role mapping in RoleMapArray 

            # add record to Change array
            $null = $usersRoleNameChangeRecordArray.Add(

                [PSCustomObject] @{

                    UserName = $userName
                    UserPrincipalName = $userUserPrincipalName
                    UserDistinguishedName = $userDistinguishedName
                    UserTitle = $userTitle
                    UserRoleNameOld = $msdsCloudExtensionAttribute16
                    UserRoleNameNew = $roleMapArrayRecordRoleName
                }
            )

            continue
        }

        # at this point, the following users should all match and not need any action

        # do nothing with the users. they are good to go
        $null = $usersRoleNameStayRecordArray.Add(

            [PSCustomObject] @{

                UserName = $userName
                UserPrincipalName = $userUserPrincipalName
                UserDistinguishedName = $userDistinguishedName
                UserTitle = $userTitle
                UserRoleNameOld = $msdsCloudExtensionAttribute16
                UserRoleNameNew = $roleMapArrayRecordRoleName
            }
        )
    }

    if ($usersNotProcessedArray) {

        $usersNotProcessedArray | Export-csv -Path $usersNotProcessedFilePath -NoTypeInformation
        Write-Log "Processing UsersNotProcessedArray: SUCCEEDED - Check $usersNotProcessedFilePath"
    } else {

        Write-Log "Processing UsersNotProcessedArray: N/A - All users were processed"
    }

    if ($usersRoleNameStayRecordArray) {

        $usersRoleNameStayRecordArray | Export-csv -Path $usersRoleNameStayRecordFilePath -NoTypeInformation
        Write-Log "Processing UsersRoleNameStayRecordArray: SUCCEEDED - Check $usersRoleNameStayRecordFilePath"
    } else {

        Write-Log "Processing UsersRoleNameStayRecordArray: N/A - All users required a RoleName change"
    }

    if ($usersRoleNameChangeRecordArray) {

        $usersRoleNameChangeActionArray = New-Object System.Collections.ArrayList
        $usersRoleNameChangeActionErrorsArray = New-Object System.Collections.ArrayList
        $usersRoleNameChangeActionErrorsArrayFilePath = "C:\RoleManagement\UsersRoleNameChangeActionErrors_$timestamp.csv"
        $usersRoleNameChangeActionCompleteArray = New-Object System.Collections.ArrayList
        $usersRoleNameChangeActionCompleteArrayFilePath = "C:\RoleManagement\UsersRoleNameChangeActionComplete_$timestamp.csv"

        $usersRoleNameChangeRecordArray | Export-csv -Path $usersRoleNameChangeRecordFilePath -NoTypeInformation
        Write-Log "Processing UsersRoleNameChangeRecordArray: SUCCEEDED - Check $usersRoleNameChangeRecordFilePath"

        Write-Log "Updating RoleNameChange users..."

        foreach ($user in $usersRoleNameChangeRecordArray) {

            $userDistinguishedName = $user.UserDistinguishedName
            $userRoleNameOld = $user.UserRoleNameOld
            $userRoleNameNew = $user.UserRoleNameNew

            $paramSetADUser = @{

                Identity = $userDistinguishedName
                Replace = @{'msDS-cloudExtensionAttribute16'=$userRoleNameNew}
                ErrorAction = "Stop"
            }

            try {

                Set-ADUser @paramSetADUser -WhatIf
            }
            catch {

                $null = $usersRoleNameChangeActionErrorsArray.Add(
                
                    [PSCustomObject] @{

                        Level        = "Warning"
                        ErrorRecord  = $_
                        Message      = $_.Exception.Message
                        FunctionName = $_.InvocationInfo.MyCommand
                    }
                )
            }

            $null = $usersRoleNameChangeActionArray.Add(

                [PSCustomObject] @{

                    UserName = $user.UserName
                    UserPrincipalName = $user.UserPrincipalName
                    UserDistinguishedName = $userDistinguishedName
                    UserTitle = $user.UserTitle
                    UserRoleNameOld = $userRoleNameOld
                    UserRoleNameNew = $userRoleNameNew
                }
            )
        }

        foreach ($user in $usersRoleNameChangeActionArray) {

            $userDistinguishedName = $user.UserDistinguishedName
            $userUserRoleNameNew = $user.UserRoleNameNew

            if ((Get-ADUser -Identity $userDistinguishedName).'msDS-cloudExtensionAttribute16' -ne $userUserRoleNameNew) {

                $checkUserObjectStart = Get-Date

                Do {

                    $checkUser = Get-ADUser -Identity $userDistinguishedName | Select-Object -Property 'msDS-cloudExtensionAttribute16'
                    $checkUserRoleName = $checkUser.'msDS-cloudExtensionAttribute16'
                    Start-Sleep -Seconds 1
                } Until (($checkUserRoleName -eq $userUserRoleNameNew) -or ((Get-Date) -ge $checkUserObjectStart.AddSeconds(30)))

                if ($checkUserRoleName -ne $userUserRoleNameNew) {

                    $errMsg = "$userDistinguishedName - Set-ADUser completed for user but multiple Get-ADUser checks did not confirm the updating of the RoleName"

                    $null = $usersRoleNameChangeActionErrorsArray.Add(
                        
                        [PSCustomObject] @{

                            Level        = "Warning"
                            ErrorRecord  = $errMsg
                            Message      = $errMsg
                            FunctionName = $_.InvocationInfo.MyCommand
                        }
                    )

                    continue
                }
            }

            $null = $usersRoleNameChangeActionCompleteArray.Add(

                [PSCustomObject] @{
                    
                    UserName = $user.UserName
                    UserPrincipalName = $user.UserPrincipalName
                    UserDistinguishedName = $userDistinguishedName
                    UserTitle = $user.UserTitle
                    UserRoleNameOld = $user.UserRoleNameOld
                    UserRoleNameNew = $userRoleNameNew
                }
            )
        }


        if ($usersRoleNameChangeActionErrorsArray) {

            $usersRoleNameChangeActionErrorsArray | Export-csv -Path $usersRoleNameChangeActionErrorsArrayFilePath -NoTypeInformation
            Write-Log "Updating RoleNameChangeUsers: Errors - Check $usersRoleNameChangeActionErrorsArrayFilePath"
        }

        if ($usersRoleNameChangeActionCompleteArray) {

            $usersRoleNameChangeActionCompleteArray | Export-csv -Path $usersRoleNameChangeActionCompleteArrayFilePath -NoTypeInformation
            Write-Log "Updating RoleNameChangeUsers: SUCCEEDED - Check $usersRoleNameChangeActionCompleteArrayFilePath"
        }
    }
    else {

        Write-Log "Processing UsersRoleNameChangeRecordArray: N/A - All users did not require a RoleName change"
    }
} # process

End {
    # disconnect from SPO
    $null = Disconnect-PnPOnline
    Write-Log "Ending RoleManagement script"
} # end
