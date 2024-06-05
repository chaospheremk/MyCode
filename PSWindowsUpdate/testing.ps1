$credential = Get-Credential -UserName "dougjohnson\doug-adm"

$paramGetADComputer = @{

    Filter = "OperatingSystem -eq 'Windows Server 2022 Datacenter' -or OperatingSystem -eq 'Hyper-V Server'"
    Property = "OperatingSystem"
    Server = "yavin4.dougjohnson.me"
    Credential = $credential
}

$servers = Get-ADComputer @paramGetADComputer

$pswuSettings = @{

    SmtpServer = ""
    From = ""
    To = ""
    Port = 0
    Subject = ""
    Style = "List"
}

foreach ($server in $servers) {

    $serverName = $server.DNSHostName
    
    $paramGetWindowsUpdate = @{

        ComputerName = $serverName
        Install = $true
        AcceptAll = $true
        IgnoreReboot = $true
        SendReport = $true
        PSWUSettings = $pswuSettings
        WindowsUpdate = $true
    }

    Get-WindowsUpdate @paramGetWindowsUpdate
}

#################################


$password = "HrFYUehLCUBtJu8I"
$mailuser = 'dougjohnson.me'
$cred = New-Object System.Management.Automation.PSCredential $mailUser, ($Password | ConvertTo-SecureString -AsPlainText -Force)

$pswuSettings = @{

    SmtpServer = "mail.smtp2go.com"
    From = "smtp2go@dougjohnson.me"
    To = "doug@dougjohnson.me"
    Port = 2525
    Subject = ""
    Style = "List"
}

$paramGetWindowsUpdate = @{

    WindowsUpdate = $true
    SendReport = $true
    PSWUSettings = @{

        SmtpServer = "mail.smtp2go.com"
        Credential = $cred
        From = "smtp2go@dougjohnson.me"
        To = "doug@dougjohnson.me"
        Port = 25
        Subject = "Windows Update Report"
        Style = "List"
    }

}

Get-WindowsUpdate @paramGetWindowsUpdate

Get-WindowsUpdate -WindowsUpdate -SendReport -PSWUSettings `
@{
    SmtpServer = "mail.smtp2go.com";
    Credential = $cred;
    From = "smtp2go@dougjohnson.me";
    To = "doug@dougjohnson.me";
    Port = 25;
    Subject = "Windows Update Report"
    # Style = "List"
} -Verbose


Send-Mg

