# Test editing a SharePoint item
Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

# Get first item
Write-Host "Getting first item..." -ForegroundColor Yellow
$item = Get-PnPListItem -List $listName -PageSize 1

if ($item) {
    $itemId = $item.Id
    $currentTitle = $item.FieldValues.Title
    
    Write-Host "Item ID: $itemId" -ForegroundColor Cyan
    Write-Host "Current Title: $currentTitle" -ForegroundColor White
    Write-Host ""
    
    # Test edit - add a test suffix to title
    $testTitle = "$currentTitle [TEST EDIT]"
    Write-Host "Updating Title to: $testTitle" -ForegroundColor Yellow
    
    Set-PnPListItem -List $listName -Identity $itemId -Values @{Title=$testTitle}
    
    Write-Host "[OK] Item updated successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify the update
    Write-Host "Verifying update..." -ForegroundColor Yellow
    $updatedItem = Get-PnPListItem -List $listName -Identity $itemId
    Write-Host "Updated Title: $($updatedItem.FieldValues.Title)" -ForegroundColor Green
    
    # Restore original title
    Write-Host ""
    Write-Host "Restoring original title..." -ForegroundColor Yellow
    Set-PnPListItem -List $listName -Identity $itemId -Values @{Title=$currentTitle}
    Write-Host "[OK] Original title restored" -ForegroundColor Green
    
} else {
    Write-Host "[ERROR] No items found" -ForegroundColor Red
}

Disconnect-PnPOnline


