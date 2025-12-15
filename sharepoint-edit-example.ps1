# Example SharePoint Editing Script
# This shows common SharePoint editing operations

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ListName = "Documents"
)

Write-Host "SharePoint Editing Example" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Import module
Import-Module PnP.PowerShell -Force

try {
    # Connect
    Connect-PnPOnline -Url $SiteUrl -Interactive
    
    Write-Host "✓ Connected to: $SiteUrl" -ForegroundColor Green
    Write-Host ""
    
    # Get list
    Write-Host "Getting list: $ListName" -ForegroundColor Yellow
    $list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    
    if ($list) {
        Write-Host "✓ Found list: $ListName" -ForegroundColor Green
        
        # Get items
        Write-Host ""
        Write-Host "Getting items from list..." -ForegroundColor Yellow
        $items = Get-PnPListItem -List $ListName -PageSize 5
        
        Write-Host "✓ Found $($items.Count) items (showing first 5)" -ForegroundColor Green
        Write-Host ""
        
        # Display items
        foreach ($item in $items) {
            Write-Host "  Item ID: $($item.Id) - Title: $($item.FieldValues.Title)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Example: To update an item, use:" -ForegroundColor Cyan
        Write-Host "  Set-PnPListItem -List '$ListName' -Identity 1 -Values @{Title='Updated Title'}" -ForegroundColor White
        
    } else {
        Write-Host "✗ List '$ListName' not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available lists:" -ForegroundColor Yellow
        Get-PnPList | Select-Object -First 10 Title, ItemCount | Format-Table
    }
    
    Write-Host ""
    Write-Host "Disconnecting..." -ForegroundColor Yellow
    Disconnect-PnPOnline
    
} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}


