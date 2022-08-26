#Requires -Version 5.1

<#
    
    .SYNOPSIS
        This script converts Global security groups to DomainLocal security groups.


    .DESCRIPTION
        This script converts Global security groups to DomainLocal security groups. It uses logic to take nested
        groups into account along with the various rules that apply to converting a group's scope from one scope
        to another. The script parses through a security group's nested group hierarchy to determine the order
        that groups need to be converted.


    .PARAMETER inputFile
        This parameter accepts string input of a full file path to the CSV file that contains a list of the
        names of the security groups to convert in a single column with the heading "Name".


    .PARAMETER outputPath
        This parameter accepts string input of a full folder path to the directory where output CSV files are to
        be stored.


    .INPUTS
        This script relies on a CSV file to provide the list of groups to be converted. The CSV file requires one
        column that contains the group names with a single header of "Name".


    .OUTPUTS
        This script generates a separate set of CSV files per section of the script - a "Global to Universal"
        section and a "Universal to DomainLocal" section. If no success results are generated, the
        SuccessArrayFinal_$Timestamp.csv file is not generated. If no error results are generated, the
        ErrorsArrayFinal_$Timestamp.csv file is not generated.

    
    .EXAMPLE
        PS> .\Convert-GroupsGlobalToDomainLocal.ps1 -inputFile "C:\temp\GroupsToImport.csv" -outputPath "C:\temp"


    .NOTES
        Authored by: Doug Johnson
        Version: 1
        Last Updated: 08.22.2022

        Requirements:
            1. The ActiveDirectory PowerShell module must be installed on the device that runs the script
            2. The device that runs the script must have network connectivity to a domain controller
            3. The user that runs the script must have permissions to read and modify objects in Active Directory


#>


[CmdletBinding()]
Param (
    # String must contain the full file path to the CSV input file.
    [Parameter(Mandatory = $true,
    ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$inputFile,
    
    # String must contain the folder path to where the output CSV files should be stored.
    [Parameter(Mandatory = $true,
    ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$outputPath
    
)


Begin {
    
    # Uncomment the following two lines after this comment if you'd like to manually set these two variables
#    $inputFile = "C:\users\114435-adm\Desktop\CreateTestGroups.csv"
#    $outputPath = "C:\users\114435-adm\Desktop\GroupConversionResults"
    
    # Sets a timestamp variable used for naming the CSV files that are output by the script
    $TimeStamp = get-date -Format yyyy_MM_dd_hh_mm_ss

    # Creates various ArrayList objects used for processing groups
    $GSuccessObject = New-Object -TypeName "System.Collections.ArrayList"
    $GGoBackObject = New-Object -TypeName "System.Collections.ArrayList"
    $GErrorsObject = New-Object -TypeName "System.Collections.ArrayList"
    $USuccessObject = New-Object -TypeName "System.Collections.ArrayList"
    $UGoBackObject = New-Object -TypeName "System.Collections.ArrayList"
    $UErrorsObject = New-Object -TypeName "System.Collections.ArrayList"    

}

Process {
    
    # SECTION: Convert Global to Universal
    
    $ImportedGroups = Import-csv -Path $inputFile | ForEach-Object {Get-AdGroup -Identity $_.Name | `
        Select-Object Name, GroupScope, GroupCategory, DistinguishedName}

    $Counter = 0

    <#

        Do While loop first converts all global groups that are not members of other groups to Univeral groups and
        stores those groups in the SuccessArray which does not get reset when the loop starts over. Groups that are
        members of other groups during the current iteration are stored in the GoBackObject along with the loop
        iteration count for when the group was added to the GoBackObject. The GoBackObject does not
        get reset when the loop starts over. The other groups are stored in a NextRunObject which gets reset
        to null after the loop starts over. At the end of the loop, the data in the NextRunArray object gets
        stored in the ImportedGroups object which re-runs the loop on all groups that any of the groups from the
        previous iteration were members of. The While condition is for the NextRunObject to contain any data
        at the end of the loop. If the NextRunObject is empty at the end of the loop, then that means none
        of the groups in the current iteration are members of any other groups. Once the loop finally breaks, all
        groups stored in the GoBackObject are converted to Universal groups in descending order by the
        iteration count in which the group was added to the GoBackObject during the previous Do While loop.
        This ensures all groups can be converted without running into the rule that prevents Universal groups from
        being nested in a Global group.

    #>

    Do {
        
        $Counter += 1    
        $NextRunObject = New-Object -TypeName "System.Collections.ArrayList"   
        
        $GSuccessDn = $GSuccessObject.DistinguishedName
        $GGoDn = $GGoBackObject.DistinguishedName

        foreach ($ImportedGroup in $ImportedGroups) {
            
            try {                                   
                
                $ImpName = $ImportedGroup.Name
                $ImpDn = $ImportedGroup.DistinguishedName
                $ImpGs = $ImportedGroup.GroupScope
                $ImpGc = $ImportedGroup.GroupCategory
                
                if ($GSuccessDn -notcontains $ImpDn) {
                    
                    if ($ImpGs -eq "Global"){
                        
                        $MemberOfGroups = Get-ADPrincipalGroupMembership `
                            -Identity $ImpDn
                        
                        if ($MemberOfGroups) {
                            
                            foreach ($MemberOfGroup in $MemberOfGroups) {                
                                
                                $MogDn = $MemberOfGroup.DistinguishedName

                                $NrgInfo = Get-AdGroup -Identity $MogDn | `
                                    Select-Object Name, GroupScope, GroupCategory, DistinguishedName
                                
                                $NrgName = $NrgInfo.Name
                                $NrgGs = $NrgInfo.GroupScope
                                $NrgGc = $NrgInfo.GroupCategory
                                $NrgDn = $NrgInfo.DistinguishedName

                                $NextRunGroup = [PSCustomObject] @{
                                    Name = $NrgName
                                    GroupScope = $NrgGs
                                    GroupCategory = $NrgGc
                                    DistinguishedName = $NrgDn
                                    IterationMissed = $Counter
                                }

                                $NextRunObject.Add($NextRunGroup) | Out-Null


                                if ($GGoDn -contains $ImpDn){
                                    
                                    $GGoBackObject | Where-Object {$_.DistinguishedName -eq $ImpDn} | `
                                        foreach {$_.GoBackIteration = $Counter}
                                }
                                else {
                                    
                                    $GoBackGroup = [PSCustomObject] @{
                                        Name = $ImpName
                                        GroupScope = $ImpGs
                                        GroupCategory = $ImpGc
                                        DistinguishedName = $ImpDn
                                        GoBackIteration = $Counter
                                    }
                                    
                                    $GGoBackObject.Add($GoBackGroup) | Out-Null
                                }
                            }
                        }
                        else {
                            
                            Set-ADGroup -Identity $ImpName -GroupScope Universal -GroupCategory Security
                            
                            $SuccessGroup = [PSCustomObject] @{
                                Name = $ImpName
                                GroupScope = $ImpGs
                                GroupCategory = $ImpGc
                                DistinguishedName = $ImpDn
                                IterationType = "Success"
                                IterationCompleted = $Counter
                            }

                            $GSuccessObject.Add($SuccessGroup) | Out-Null
                        }
                    }
                    else {
                        
                        $SuccessGroup = [PSCustomObject] @{
                            Name = $ImpName
                            GroupScope = $ImpGs
                            GroupCategory = $ImpGc
                            DistinguishedName = $ImpDn
                            IterationType = "Skipped: Not Global Group"
                            IterationCompleted = $Counter
                        }

                        $GSuccessObject.Add($SuccessGroup) | Out-Null
                    }
                }
            }
            catch {
                
                $ErrorScriptStackTrace = $_.ScriptStackTrace
                $ErrorException = $_.Exception
                $ErrorDetails = $_.ErrorDetails
           
                $ErrorGroup = [PSCustomObject] @{
                    Name = $ImpName
                    GroupScope = $ImpGs
                    GroupCategory = $ImpGc
                    DistinguishedName = $ImpDn
                    IterationType = "ImportedGroup Error"
                    IterationNumber = $Counter
                    ScriptStackTrace = $ErrorScriptStackTrace
                    Exception = $ErrorException
                    ErrorDetails = $ErrorDetails
                }

                $GErrorsObject.Add($ErrorGroup) | Out-Null
            }
        }

        $ImportedGroups = $NextRunObject

    } While ($NextRunObject)
    
    $GGoBackObject = $GGoBackObject | Sort-Object -Property GoBackIteration -Descending
    
    foreach ($GoBackGroup in $GGoBackObject) {
        
        $GoName = $GoBackGroup.Name
        $GoGS = $GoBackGroup.GroupScope
        $GoGC = $GoBackGroup.GroupCategory
        $GoDN = $GoBackGroup.DistinguishedName
        $GoI = $GoBackGroup.GoBackIteration

        try {
            
            Set-ADGroup -Identity $GoDN -GroupScope Universal -GroupCategory Security
            
            $GoBackSuccessGroup = [PSCustomObject] @{
                Name = $GoName
                GroupScope = $GoGS
                GroupCategory = $GoGC
                DistinguishedName = $GoDN
                IterationType = "GoBack"
                IterationCompleted = $GoI
            }

            $GSuccessObject.Add($GoBackSuccessGroup) | Out-Null
        }
        catch {
            
            $ErrorScriptStackTrace = $_.ScriptStackTrace
            $ErrorException = $_.Exception
            $ErrorDetails = $_.ErrorDetails
        
            $ErrorGroup = [PSCustomObject] @{
                Name = $ImpName
                GroupScope = $ImpGs
                GroupCategory = $ImpGc
                DistinguishedName = $ImpDn
                IterationType = "Success"
                IterationNumber = $Counter
                ScriptStackTrace = $ErrorScriptStackTrace
                Exception = $ErrorException
                ErrorDetails = $ErrorDetails
            }

            $GErrorsObject.Add($ErrorGroup) | Out-Null
        }
    }
    

    # SECTION: Convert Universal to DomainLocal

    $Counter = 0
    $ImportedGroups = Import-csv -Path $inputFile | ForEach-Object {Get-AdGroup -Identity $_.Name | `
        Select-Object Name, GroupScope, GroupCategory, DistinguishedName}

    <#

        Do While loop first converts all global groups that are not members of other groups to Univeral groups and
        stores those groups in the SuccessArray which does not get reset when the loop starts over. Groups that are
        members of other groups during the current iteration are stored in the GoBackObject along with the loop
        iteration count for when the group was added to the GoBackObject. The GoBackObject does not
        get reset when the loop starts over. The other groups are stored in a NextRunObject which gets reset
        to null after the loop starts over. At the end of the loop, the data in the NextRunArray object gets
        stored in the ImportedGroups object which re-runs the loop on all groups that any of the groups from the
        previous iteration were members of. The While condition is for the NextRunObject to contain any data
        at the end of the loop. If the NextRunObject is empty at the end of the loop, then that means none
        of the groups in the current iteration are members of any other groups. Once the loop finally breaks, all
        groups stored in the GoBackObject are converted to Universal groups in descending order by the
        iteration count in which the group was added to the GoBackObject during the previous Do While loop.
        This ensures all groups can be converted without running into the rule that prevents Universal groups from
        being nested in a Global group.

    #>

    Do {

        $Counter += 1    
        $NextRunObject = New-Object -TypeName "System.Collections.ArrayList"   
        
        $USuccessDn = $USuccessObject.DistinguishedName
        $UGoDn = $UGoBackObject.DistinguishedName

        foreach ($ImportedGroup in $ImportedGroups) {
            
            try {                                   
                
                $ImpName = $ImportedGroup.Name
                $ImpDn = $ImportedGroup.DistinguishedName
                $ImpGs = $ImportedGroup.GroupScope
                $ImpGc = $ImportedGroup.GroupCategory

                if ($USuccessObject.DistinguishedName -notcontains $ImpDn) {
                    
                    if ($ImpGs -eq "Universal"){
                        
                        $MemberOfGroups = Get-ADPrincipalGroupMembership -Identity $ImpDn
                       
                        if ($MemberOfGroups) {
                            
                            foreach ($MemberOfGroup in $MemberOfGroups) {                
                                
                                $MogDn = $MemberOfGroup.DistinguishedName
                                
                                $NrgInfo = Get-AdGroup -Identity $MogDn | `
                                    Select-Object Name, GroupScope, GroupCategory, DistinguishedName

                                $NrgName = $NrgInfo.Name
                                $NrgGs = $NrgInfo.GroupScope
                                $NrgGc = $NrgInfo.GroupCategory
                                $NrgDn = $NrgInfo.DistinguishedName
                                
                                $NextRunGroup = [PSCustomObject] @{
                                    Name = $NrgName
                                    GroupScope = $NrgGs
                                    GroupCategory = $NrgGc
                                    DistinguishedName = $NrgDn
                                    IterationMissed = $Counter
                                }
                                
                                $NextRunObject.Add($NextRunGroup) | Out-Null
                                
                                if ($UGoBackObject.DistinguishedName -contains $ImpDn){
                                    
                                    $UGoBackObject | Where-Object {$_.DistinguishedName -eq $ImpDn} | `
                                        foreach {$_.GoBackIteration = $Counter}
                                }
                                else {
                                    
                                    $GoBackGroup = [PSCustomObject] @{
                                        Name = $ImpName
                                        GroupScope = $ImpGs
                                        GroupCategory = $ImpGc
                                        DistinguishedName = $ImpDn
                                        GoBackIteration = $Counter
                                    }

                                    $UGoBackObject.Add($GoBackGroup) | Out-Null
                                }
                            }
                        }
                        else {
                            
                            Set-ADGroup -Identity $ImpName -GroupScope DomainLocal -GroupCategory Security
                            
                            $SuccessGroup = [PSCustomObject] @{                               
                                Name = $ImpName
                                GroupScope = $ImpGs
                                GroupCategory = $ImpGc
                                DistinguishedName = $ImpDn
                                IterationType = "Success"
                                IterationCompleted = $Counter
                            }

                            $USuccessObject.Add($SuccessGroup) | Out-Null
                        }
                    }
                    else {
                        
                        $SuccessGroup = [PSCustomObject] @{
                            Name = $ImpName
                            GroupScope = $ImpGs
                            GroupCategory = $ImpGc
                            DistinguishedName = $ImpDn
                            IterationType = "Skipped: Not Universal Group"
                            IterationCompleted = $Counter
                        }
                        
                        $USuccessObject.Add($SuccessGroup) | Out-Null
                    }
                }
            }
            catch {
                
                $ErrorScriptStackTrace = $_.ScriptStackTrace
                $ErrorException = $_.Exception
                $ErrorDetails = $_.ErrorDetails

                $ErrorGroup = [PSCustomObject] @{
                    Name = $ImpName
                    GroupScope = $ImpGs
                    GroupCategory = $ImpGc
                    DistinguishedName = $ImpDn
                    IterationType = "ImportedGroup Error"
                    IterationNumber = $Counter
                    ScriptStackTrace = $ErrorScriptStackTrace
                    Exception = $ErrorException
                    ErrorDetails = $ErrorDetails

                }

                $UErrorsObject.Add($ErrorGroup) | Out-Null
            }
        }

        $ImportedGroups = $NextRunObject

    } While ($NextRunObject)

    $UGoBackObject = $UGoBackObject | Sort-Object -Property GoBackIteration -Descending
   
    foreach ($GoBackGroup in $UGoBackObject) {

        $GoName = $GoBackGroup.Name
        $GoGS = $GoBackGroup.GroupScope
        $GoGC = $GoBackGroup.GroupCategory
        $GoDN = $GoBackGroup.DistinguishedName
        $GoI = $GoBackGroup.GoBackIteration
        
        try {
            
            Set-ADGroup -Identity $GoDN -GroupScope DomainLocal -GroupCategory Security
                $GoBackSuccessGroup = [PSCustomObject] @{
                Name = $GoName
                GroupScope = $GoGS
                GroupCategory = $GoGC
                DistinguishedName = $GoDN
                IterationType = "GoBack"
                IterationCompleted = $GoI
            }
            
            $USuccessObject.Add($GoBackSuccessGroup) | Out-Null
        }
        catch {
            
            $ErrorScriptStackTrace = $_.ScriptStackTrace
            $ErrorException = $_.Exception
            $ErrorDetails = $_.ErrorDetails
        
            $ErrorGroup = [PSCustomObject] @{
                Name = $ImpName
                GroupScope = $ImpGs
                GroupCategory = $ImpGc
                DistinguishedName = $ImpDn
                IterationType = "Success"
                IterationNumber = $Counter
                ScriptStackTrace = $ErrorScriptStackTrace
                Exception = $ErrorException
                ErrorDetails = $ErrorDetails
            }
            
            $UErrorsObject.Add($ErrorGroup) | Out-Null
        }
    }
}

End {
    
    if ($GSuccessObject) {$GSuccessObject | `
        Export-csv -Path "$outputPath\G2USuccessArrayFinal_$Timestamp.csv" -NoTypeInformation}
    if ($GErrorsObject) {$GErrorsObject | `
        Export-csv -Path "$outputPath\G2UErrorsArrayFinal_$Timestamp.csv" -NoTypeInformation}
    if ($USuccessObject) {$USuccessObject | `
        Export-csv -Path "$outputPath\U2DLSuccessArrayFinal_$Timestamp.csv" -NoTypeInformation}
    if ($UErrorsObject) {$UErrorsObject | `
        Export-csv -Path "$outputPath\U2DLErrorsArrayFinal_$Timestamp.csv" -NoTypeInformation}

}
