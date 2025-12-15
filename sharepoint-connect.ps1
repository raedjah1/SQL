# SharePoint Connection Script
# This script helps you connect to SharePoint Online

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl
)

Write-Host "Connecting to SharePoint..." -ForegroundColor Cyan

# Import PnP PowerShell module
Import-Module PnP.PowerShell -Force

try {
    # Connect to SharePoint Online
    Connect-PnPOnline -Url $SiteUrl -Interactive
    
    Write-Host "✓ Successfully connected to SharePoint!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now use SharePoint PowerShell commands like:" -ForegroundColor Cyan
    Write-Host "  Get-PnPList" -ForegroundColor White
    Write-Host "  Get-PnPListItem -List 'YourListName'" -ForegroundColor White
    Write-Host "  Set-PnPListItem -List 'YourListName' -Identity 1 -Values @{Title='New Title'}" -ForegroundColor White
    Write-Host ""
    Write-Host "To disconnect, run: Disconnect-PnPOnline" -ForegroundColor Yellow
} catch {
    Write-Host "✗ Error connecting to SharePoint: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have the correct permissions and URL." -ForegroundColor Yellow
}


