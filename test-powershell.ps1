# Test script to verify PowerShell execution works
Write-Host "PowerShell execution test successful!" -ForegroundColor Green
Write-Host "Current execution policy: $((Get-ExecutionPolicy -List | Where-Object {$_.Scope -eq 'MachinePolicy'}).ExecutionPolicy)" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now run PowerShell scripts using:" -ForegroundColor Cyan
Write-Host "  powershell.exe -ExecutionPolicy Bypass -File your-script.ps1" -ForegroundColor White
Write-Host "  or use run-powershell.bat your-script.ps1" -ForegroundColor White


