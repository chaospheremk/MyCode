$TenantID = "092ec6d1-91bb-41cc-a354-90068582d5c8"  #Your Tenant ID
$SubscriptionID = "10832e7c-e977-4cca-926a-ddc32daf9398" #Your Subscription ID
$ResourceGroup = "dougjohnson_me-rg" #Your resroucegroup
$DCRName = "Windows-EventLogs" #Your Data collection rule name

Connect-AzAccount -Tenant $TenantID

#Select the subscription
Select-AzSubscription -SubscriptionId $SubscriptionID

#Grant Access to User at root scope "/"
$user = Get-AzADUser -UserPrincipalName (Get-AzContext).Account

New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id

#Create Auth Token
$auth = Get-AzAccessToken

$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer " + $auth.Token
    }


#1. Assign ‘Monitored Object Contributor’ Role to the operator
$newguid = (New-Guid).Guid
$UserObjectID = $user.Id

$body = @"
{
            "properties": {
                "roleDefinitionId":"/providers/Microsoft.Authorization/roleDefinitions/56be40e24db14ccf93c37e44c597135b",
                "principalId": `"$UserObjectID`"
        }
}
"@

$request = "https://management.azure.com/providers/microsoft.insights/providers/microsoft.authorization/roleassignments/$newguid`?api-version=2021-04-01-preview"


Invoke-RestMethod -Uri $request -Headers $AuthenticationHeader -Method PUT -Body $body


##########################

#2. Create Monitored Object

$request = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"
$body = @'
{
    "properties":{
        "location":"eastus"
    }
}
'@

$Respond = Invoke-RestMethod -Uri $request -Headers $AuthenticationHeader -Method PUT -Body $body -Verbose
$RespondID = $Respond.id

#########

#3. Associate DCR to Monitored Object

$request = "https://management.azure.com$RespondId/providers/microsoft.insights/datacollectionruleassociations/assoc?api-version=2021-04-01"
$body = @"
        {
            "properties": {
                "dataCollectionRuleId": "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$DCRName"
            }
        }

"@

Invoke-RestMethod -Uri $request -Headers $AuthenticationHeader -Method PUT -Body $body