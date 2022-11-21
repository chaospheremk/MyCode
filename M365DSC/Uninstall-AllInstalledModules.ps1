workflow Uninstall-AllInstalledModules
{
    $Modules = @()
    $Modules += (Get-InstalledModule).Name
    Foreach -parallel ($Module in ($Modules | Get-Unique))
    { 
        Write-Output ("Uninstalling: $Module")
        Uninstall-Module $Module -Force
    }
}
Uninstall-AllInstalledModules
Uninstall-AllInstalledModules  #second invocation to truly remove everything