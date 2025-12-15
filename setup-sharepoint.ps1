# SharePoint PowerShell Setup Script
# This script helps set up SharePoint PowerShell modules

Write-Host "Checking SharePoint PowerShell modules..." -ForegroundColor Cyan

# Check if SharePoint Online Management Shell is installed
$sharePointModule = Get-Module -ListAvailable -Name "Microsoft.Online.SharePoint.PowerShell"
if ($sharePointModule) {
    Write-Host "✓ SharePoint Online Management Shell is installed" -ForegroundColor Green
    Write-Host "  Version: $($sharePointModule.Version)" -ForegroundColor Gray
} else {
    Write-Host "✗ SharePoint Online Management Shell not found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install SharePoint Online Management Shell:" -ForegroundColor Cyan
    Write-Host "  1. Download from: https://www.microsoft.com/en-us/download/details.aspx?id=35588" -ForegroundColor White
    Write-Host "  2. Or install via: Install-Module -Name Microsoft.Online.SharePoint.PowerShell" -ForegroundColor White
}

# Check if PnP PowerShell is installed (modern alternative)
$pnpModule = Get-Module -ListAvailable -Name "PnP.PowerShell"
if ($pnpModule) {
    Write-Host "✓ PnP.PowerShell is installed" -ForegroundColor Green
    Write-Host "  Version: $($pnpModule.Version)" -ForegroundColor Gray
} else {
    Write-Host "✗ PnP.PowerShell not found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install PnP.PowerShell (recommended modern approach):" -ForegroundColor Cyan
    Write-Host "  Install-Module -Name PnP.PowerShell -Scope CurrentUser" -ForegroundColor White
}

Write-Host ""
Write-Host "Example SharePoint connection commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "# For SharePoint Online (classic):" -ForegroundColor Yellow
Write-Host "Connect-SPOService -Url https://yourtenant-admin.sharepoint.com" -ForegroundColor White
Write-Host ""
Write-Host "# For PnP PowerShell (modern):" -ForegroundColor Yellow
Write-Host "Connect-PnPOnline -Url https://yourtenant.sharepoint.com -Interactive" -ForegroundColor White


