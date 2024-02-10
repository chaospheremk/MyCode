Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -match 'GraphAutomation' } | Remove-Item
Remove-Item -Path HKCU:\Software\dougjohnsonme\GraphAutomationCert

Invoke-WUJob -ComputerName util.dougjohnson.me -Credential $cred -Script { ipmo PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File "C:\Windows\PSWindowsUpdate.log"} -RunNow -Confirm:$false -Verbose