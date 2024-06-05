# Function to write to log
function Write-Log {
    
    [CmdletBinding()]
    Param (
        [string]$message
    )

    Begin {
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if (-NOT (Test-Path -Path "C:\Intune")) {

            $null = New-Item -Path "C:\" -Name "Intune" -ItemType "directory"
            $null = New-Item -Path "C:\Intune" -Name "Logs" -ItemType "directory"
        }
        else {

            if (-NOT (Test-Path -Path "C:\Intune\Logs")) {

                $null = New-Item -Path "C:\Intune" -Name "Logs" -ItemType "directory"
            }
        }
    } # begin

    Process {
        
        $logMessage = "$timestamp - $message"
        Write-Output $logMessage
        Add-Content -Path "C:\Intune\Logs\TargetedWindowsUpdate_$KBNumber.log" -Value $logMessage
    } # process

    End {
        # no content
    } # end
}

# function to install a targeted Windows Update
function Install-TargetedWindowsUpdate {

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [string]$KBNumber
    )

    Begin {
        # no content
    } # begin

    Process {

        # Start logging
        Write-Log "Starting Windows Update script for $KBNumber."

        # Check if the PSWindowsUpdate module is already installed
        Write-Log "Checking if PSWindowsUpdate powershell module is already installed..."

        if (-NOT (Get-InstalledModule | Where-Object Name -eq "PSWindowsUpdate")) {

            Write-Log "Checking if PSWindowsUpdate powershell module is already installed: FAILED"

            Try {
                
                # Install PSWindowsUpdate module
                Write-Log "Installing PSWindowsUpdate powershell module..."
                Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force -ErrorAction Stop

                if (-NOT (Get-InstalledModule | Where-Object Name -eq "PSWindowsUpdate")) {

                    Write-Log "Installing $KBNumber update: FAILED"
                }
                Else {

                    Write-Log "Installing PSWindowsUpdate powershell module: SUCCESS"
                } 
                
            }
            Catch {

                Write-Log "Installing PSWindowsUpdate powershell module: ERROR"
            }
        }
        else {

            Write-Log "Checking if PSWindowsUpdate powershell module is already installed: SUCCESS"
        }

        # Check if the update is already installed
        Write-Log "Checking if $KBNumber is already installed..."

        # Check for installed updates
        Write-Log "Getting Windows Update History..."

        Try {

            $wuHistory = Get-WUHistory -ErrorAction Stop
            Write-Log "Getting Windows Update History: SUCCESS"
        }
        Catch {

            Write-Log "Getting Windows Update History: ERROR"
        }

        $installedUpdates = $wuHistory.KB | Sort-Object -Unique

        if (-NOT ($installedUpdates -contains $kbNumber)) {

            Write-Log "Checking if $KBNumber is already installed: Not Installed"
            
            Try {

                Write-Log "Installing $KBNumber update..."
                Get-WindowsUpdate -KBArticleID $kbNumber -MicrosoftUpdate -AcceptAll -Install -ErrorAction Stop

                if (-NOT (((Get-WUHistory -ErrorAction Stop).KB | Sort-Object -Unique) -contains $kbNumber)) {

                    Write-Log "Installing $KBNumber update: FAILED"
                }
                Else {

                    Write-Log "Installing $KBNumber update: SUCCESS"
                } 
            }
            Catch {

                Write-Log "Installing $KBNumber update: ERROR"
            }
        }
        else {

            Write-Log "Checking if $KBNumber is already installed: Installed"
        }
    }

    End {

        Write-Log "Ending Windows Update script for $KBNumber."
    }
}

Install-TargetedWindowsUpdate -KBNumber "KB000001"