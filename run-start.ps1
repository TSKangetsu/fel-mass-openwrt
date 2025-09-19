while ($true) {
    Write-Host "Executing start.bat..."
    & .\start.bat
    Write-Host "start.bat finished. Restarting in 1 second..."
    Start-Sleep -Seconds 1
}