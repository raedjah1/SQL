# Delete all items (rows) from ADT RMA Data list
# This will keep the list structure and columns, but remove all items

Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

# Get total item count
Write-Host "Getting item count..." -ForegroundColor Yellow
$list = Get-PnPList -Identity $listName
$totalItems = $list.ItemCount

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "WARNING: DELETE ALL ITEMS OPERATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will DELETE ALL $totalItems items (rows) from the list." -ForegroundColor White
Write-Host ""
Write-Host "What will happen:" -ForegroundColor Cyan
Write-Host "  - All items (rows) will be PERMANENTLY DELETED" -ForegroundColor White
Write-Host "  - All columns will be KEPT (list structure remains)" -ForegroundColor White
Write-Host "  - The list will be empty, ready for new data" -ForegroundColor White
Write-Host ""
Write-Host "This operation CANNOT be undone!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Type 'DELETE ALL ROWS' to continue, or anything else to cancel"

if ($confirm -ne "DELETE ALL ROWS") {
    Write-Host ""
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    Disconnect-PnPOnline
    exit
}

Write-Host ""
Write-Host "Starting deletion of all items..." -ForegroundColor Cyan
Write-Host ""

# Get all items and delete them
$processed = 0
$deleted = 0
$errors = 0

try {
    Write-Host "Retrieving all items (this may take a moment)..." -ForegroundColor Yellow
    $allItems = Get-PnPListItem -List $listName -PageSize 500
    
    Write-Host "Found $($allItems.Count) items. Starting deletion..." -ForegroundColor Green
    Write-Host ""
    
    foreach ($item in $allItems) {
        $processed++
        
        try {
            # Delete the item
            Remove-PnPListItem -List $listName -Identity $item.Id -Force -ErrorAction Stop
            $deleted++
            
            # Show progress every 100 items
            if ($processed % 100 -eq 0) {
                $percent = [math]::Round(($processed / $totalItems) * 100, 1)
                Write-Host "  Progress: $processed / $totalItems ($percent%) | Deleted: $deleted | Errors: $errors" -ForegroundColor Gray
            }
        } catch {
            $errors++
            Write-Host "  [ERROR] Failed to delete Item ID $($item.Id): $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "DELETION COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total items processed: $processed" -ForegroundColor White
    Write-Host "Successfully deleted: $deleted" -ForegroundColor Green
    Write-Host "Errors: $errors" -ForegroundColor $(if($errors -gt 0){"Red"}else{"Green"})
    Write-Host ""
    Write-Host "All items have been deleted from the list." -ForegroundColor Green
    Write-Host "List structure and columns remain intact." -ForegroundColor Green
    Write-Host "The list is now empty and ready for new data." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Deletion failed: $_" -ForegroundColor Red
    Write-Host "Items processed before error: $processed" -ForegroundColor Yellow
}

Disconnect-PnPOnline


