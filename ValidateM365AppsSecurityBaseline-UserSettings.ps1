$ImportPath = "C:\Users\DougJohnson\OneDrive - dougjohnson.me\Microsoft Security Baselines\Microsoft 365 Apps for Enterprise-2206-FINAL\reginfo.csv"
$ExportPath = "C:\Users\DougJohnson\OneDrive - dougjohnson.me\Microsoft Security Baselines\Microsoft 365 Apps for Enterprise-2206-FINAL\regreport.csv"
$Records = Import-csv -Path $ImportPath

$Results = foreach ($Record in $Records) {
    $RegInfo = $Record.RegInfo
    $RegValue = $Record.Value
    $RegInfoArray = $RegInfo.Split("!")
    $RegPath = $RegInfoArray[0]
    $CSPRegPath = $RegPath.Insert(34, 'cloud\')
    $RegProperty = $RegInfoArray[1]

    if (Get-ItemProperty -Path $CSPRegPath -Name $RegProperty -ErrorAction Ignore) {
        $CurrentRegPropertyValue = (Get-ItemPropertyValue -Path $CSPRegPath -Name $RegProperty).ToString()

        if ($RegValue = $CurrentRegPropertyValue) {
            [PSCustomObject]@{
                PropertyExists  = "Yes"
                ValuesMatch     = "Yes"
                CSPRegPath      = $CSPRegPath
                CSPRegProperty  = $RegProperty
                CurrentValue    = $CurrentRegPropertyValue
                BaselineValue   = $RegValue
                BaselineRegPath = $RegInfo
            }
        }
        elseif ($RegProperty = "fbaenabledhosts") {
            if (!$CurrentRegPropertyValue) {
                [PSCustomObject]@{
                    PropertyExists  = "Yes"
                    ValuesMatch     = "Yes"
                    CSPRegPath      = $CSPRegPath
                    CSPRegProperty  = $RegProperty
                    CurrentValue    = $CurrentRegPropertyValue
                    BaselineValue   = $RegValue
                    BaselineRegPath = $RegInfo
                }
            } else {
                [PSCustomObject]@{
                    PropertyExists  = "Yes"
                    ValuesMatch     = "No"
                    CSPRegPath      = $CSPRegPath
                    CSPRegProperty  = $RegProperty
                    CurrentValue    = $CurrentRegPropertyValue
                    BaselineValue   = $RegValue
                    BaselineRegPath = $RegInfo
                }
            }
        }
        else {
            [PSCustomObject]@{
            PropertyExists  = "Yes"
            ValuesMatch     = "No"
            CSPRegPath      = $CSPRegPath
            CSPRegProperty  = $RegProperty
            CurrentValue    = $CurrentRegPropertyValue
            BaselineValue   = $RegValue
            BaselineRegPath = $RegInfo
            }
        }
    }
    else {
        [PSCustomObject]@{
            PropertyExists  = "No"
            ValuesMatch     = $null
            CSPRegPath      = $CSPRegPath
            CSPRegProperty  = $RegProperty
            CurrentValue    = $null
            BaselineValue   = $RegValue
            BaselineRegPath = $RegInfo
        }
    }
}

$Results | Export-csv -Path $ExportPath -NoTypeInformation