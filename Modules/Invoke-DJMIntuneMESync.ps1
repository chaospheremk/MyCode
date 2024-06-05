function Invoke-DJMIntuneMESync {

    [CmdletBinding()]
    Param()

    Begin {
        # no content
    } # begin

    Process {
        
        $shell = New-Object -ComObject Shell.Application
        $shell.open("intunemanagementextension://syncapp")
    } # process

    End {
        # no content
    } # end
}