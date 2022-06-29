Connect-AzureAD -AzureEnvironmentName AzureUSGovernment
    
 $Users = Import-Csv -Path "C:\temp\Users.csv"
    
 $Group = "GroupName"
    
 foreach($user in $Users) {
    $AzureADUser = Get-AzureADUser -Filter "UserPrincipalName eq '$($user.UPN)'"
     if($AzureADUser -ne $null) {
         try {
             $AzureADGroup = Get-AzureADGroup -Filter "DisplayName eq '$Group'" -ErrorAction Stop
             $isUserMemberOfGroup = Get-AzureADGroupMember -ObjectId $AzureADGroup.ObjectId -All $true | Where-Object {$_.UserPrincipalName -like "*$($AzureADUser.UserPrincipalName)*"}
             if($isUserMemberOfGroup -eq $null) {
                 Add-AzureADGroupMember -ObjectId $AzureADGroup.ObjectId -RefObjectId $AzureADUser.ObjectId -ErrorAction Stop
             }
         }
         catch {
             Write-Output "Azure AD Group $Group does not exist or insufficient right"
         }
     }
     else {
         Write-Output "User $($AzureADUser.UserPrincipalName) does not exist"
     }
 }