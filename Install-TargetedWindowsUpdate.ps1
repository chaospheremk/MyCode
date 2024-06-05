$targetedKBNumber = "kb2809279"

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
        Add-Content -Path "C:\Intune\Logs\WindowsUpdate_$KBNumber.log" -Value $logMessage
    } # process

    End {
        # no content
    } # end
}

function Install-TargetedWindowsUpdate {

    <#
    .SYNOPSIS
        This function installs a specific Windows update if it is not already installed.

    .DESCRIPTION
        The function checks for the presence of a specific Windows update (by KB number).
        If the update is not installed, it downloads and installs the update.
        The function logs its actions and errors for troubleshooting.

    .PARAMETER KBNumber
        The KB number of the Windows update to be installed.

    .EXAMPLE
        Install-TargetedWindowsUpdate.ps1 -KBNumber "KB5005565"
    #>

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [string]$KBNumber
    )

    Begin {

        if (-NOT (Test-Path -Path "C:\Intune")) {

            $null = New-Item -Path "C:\" -Name "Intune" -ItemType "directory"
            $null = New-Item -Path "C:\Intune" -Name "Updates" -ItemType "directory"
        }
        else {

            if (-NOT (Test-Path -Path "C:\Intune\Updates")) {

                $null = New-Item -Path "C:\Intune" -Name "Updates" -ItemType "directory"
            }
        }
    }

    Process {

        # Start logging
        Write-Log "Starting update script for $KBNumber."

        # Check if the update is already installed
        Write-Log "Checking if $KBNumber is already installed."
        $updateInstalled = Get-HotFix -Id $KBNumber -ErrorAction SilentlyContinue

        if ($updateInstalled) {
            Write-Log "$KBNumber is already installed. Exiting script."
            Exit 0
        }
        else {
            Write-Log "$KBNumber is not installed. Proceeding with installation."
        }

        # Define the URL for the update package
        $updateUrl = "https://www.catalog.update.microsoft.com/Search.aspx?q=$KBNumber"

        # Download the update package
        $updatePackagePath = "C:\Intune\Updates\$KBNumber.msu"
        if (-Not (Test-Path -Path $updatePackagePath)) {
            Write-Log "Downloading update package from $updateUrl."
            try {
                Invoke-WebRequest -Uri $updateUrl -OutFile $updatePackagePath
                Write-Log "Download completed successfully."
            }
            catch {
                Write-Log "Error downloading update package: $_"
                Exit 1
            }
        }
        else {
            Write-Log "Update package already downloaded."
        }

        # Install the update package
        Write-Log "Installing update package $KBNumber."
        try {
            Start-Process -FilePath "wusa.exe" -ArgumentList "$updatePackagePath /quiet /norestart" -Wait
            Write-Log "Update package installed successfully."
        }
        catch {
            Write-Log "Error installing update package: $_"
            Exit 1
        }

        # Verify installation
        Write-Log "Verifying installation of $KBNumber."
        $updateInstalled = Get-HotFix -Id $KBNumber -ErrorAction SilentlyContinue

        if ($updateInstalled) {
            Write-Log "$KBNumber installation verified successfully."
        }
        else {
            Write-Log "Verification failed. $KBNumber is not installed."
            Exit 1
        }

        Write-Log "Update script for $KBNumber completed successfully."
        Exit 0
    } # process

    End {
        # no content
    } # end
}

Install-TargetedWindowsUpdate -KBNumber $targetedKBNumber


Get-HotFix -Id "kb2809279"

$Searcher.QueryHistory(0, $historyCount)  | where date -gt (Get-Date "1/1/2000") | Select-Object  @{name="HostName";expression = { $hostname }}, @{name="Install_Date"; expression = { $_.Date }},@{name="KB"; expression = { (select-string $regex -inputobject $_.Title).matches.groups[1].value }}, Title, Description, @{name="Operation"; expression={switch($_.operation){1 {"Installation"}; 2 {"Uninstallation"}; 3 {"Other"}}}}, @{name="Status"; expression={switch($_.resultcode){1 {"In Progress"}; 2 {"Succeeded"}; 3 {"Succeeded With Errors"};4 {"Failed"}; 5 {"Aborted"} }}}, SupportUrl | Export-Csv -NoTypeInformation -path "c:\temp\Windows_Patch_History-for-$hostname-runon-$(get-date -f yyyyMMdd-hhmm).csv"

############################

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
        Add-Content -Path "C:\Intune\Logs\WindowsUpdate_$KBNumber.log" -Value $logMessage
    } # process

    End {
        # no content
    } # end
}


function Install-TargetedWindowsUpdate {

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [string]$KBNumber
    )

    # Start logging
    Write-Log "Starting update script for $KBNumber."

    # Check if the PSWindowsUpdate module is already installed
    Write-Log "Checking if PSWindowsUpdate powershell module is already installed..."

    if (-NOT (Get-InstalledModule | Where-Object Name -eq "PSWindowsUpdate")) {

        Write-Log "Checking if PSWindowsUpdate powershell module is already installed: FAILED"

        # Install PSWindowsUpdate module
        Write-Log "Installing PSWindowsUpdate powershell module..."

        Try {
            
            Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force -ErrorAction Stop
            Write-Log "Installing PSWindowsUpdate powershell module: SUCCESS"
        }
        Catch {

            Write-Log "Installing PSWindowsUpdate powershell module: FAILED"
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

        Write-Log "Getting Windows Update History: FAILED"
    }

    $installedUpdates = $wuHistory.KB | Sort-Object -Unique

    if (-NOT ($installedUpdates -contains $kbNumber)) {

        Write-Log "Checking if $KBNumber is already installed: Not Installed"
        Write-Log "Installing $KBNumber update..."

        Try {

            Get-WindowsUpdate -KBArticleID $kbNumber -MicrosoftUpdate -AcceptAll -Install -ErrorAction Stop
            Write-Log "Installing $KBNumber update: SUCCESS"
        }
        Catch {

            Write-Log "Installing $KBNumber update: FAILED"
        }
    }
    else {

        Write-Log "Checking if $KBNumber is already installed: Installed"
    }
}

Install-TargetedWindowsUpdate -KBNumber 