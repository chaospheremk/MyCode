# This script enables LSA protection on a Windows computer. It checks the registry key
# in the $Path variable for the RunAsPPL dword property with the value 1. If it does not
# exist it gets created.
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if ((Get-ItemProperty -Path $Path).RunAsPPL -ne 1) {
	New-ItemProperty -Path $Path -Value 00000001 -PropertyType dword -Name "RunAsPPL"
}