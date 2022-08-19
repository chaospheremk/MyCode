Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -match 'GraphAutomation' } | Remove-Item
Remove-Item -Path HKCU:\Software\dougjohnsonme\GraphAutomationCert