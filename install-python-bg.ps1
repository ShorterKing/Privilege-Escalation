# Script to download and install Python silently

# Download Python installer
$pythonUri = "https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe"
$outputPath = "C:\Temp\python-3.11.0-amd64.exe"

# Create Temp directory if it doesn't exist
if (!(Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

# Download the installer silently
Invoke-WebRequest -UseBasicParsing -Uri $pythonUri -OutFile $outputPath -ErrorAction Stop

# Install Python silently
Start-Process -FilePath $outputPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -NoNewWindow -Wait

# Set system PATH
$pythonPath = "C:\Program Files\Python311\"
[System.Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$pythonPath", "Machine")

# Update current session PATH
$env:PATH = "$env:PATH;$pythonPath"

Write-Host "Python installation completed successfully"
