# Update all Ticket Numbers (field_2) to "000" for all items in ADT RMA Data list

Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"
$newTicketNumber = "000"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

# Get total item count first
Write-Host "Getting item count..." -ForegroundColor Yellow
$list = Get-PnPList -Identity $listName
$totalItems = $list.ItemCount

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "WARNING: BULK UPDATE OPERATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will update ALL $totalItems items in the list." -ForegroundColor White
Write-Host "Field to update: Ticket Number (field_2)" -ForegroundColor White
Write-Host "New value: '$newTicketNumber'" -ForegroundColor White
Write-Host ""
Write-Host "This operation cannot be easily undone!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Type 'YES' to continue, or anything else to cancel"

if ($confirm -ne "YES") {
    Write-Host ""
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    Disconnect-PnPOnline
    exit
}

Write-Host ""
Write-Host "Starting bulk update..." -ForegroundColor Cyan
Write-Host ""

# Get all items and update them
$processed = 0
$updated = 0
$errors = 0

try {
    # Get all items - this might take a while with 2,218 items
    Write-Host "Retrieving all items (this may take a moment)..." -ForegroundColor Yellow
    $allItems = Get-PnPListItem -List $listName -PageSize 500
    
    Write-Host "Found $($allItems.Count) items. Starting updates..." -ForegroundColor Green
    Write-Host ""
    
    foreach ($item in $allItems) {
        $processed++
        
        # Update the ticket number
        try {
            Set-PnPListItem -List $listName -Identity $item.Id -Values @{field_2=$newTicketNumber} -ErrorAction Stop
            $updated++
            
            # Show progress every 100 items
            if ($processed % 100 -eq 0) {
                $percent = [math]::Round(($processed / $totalItems) * 100, 1)
                Write-Host "  Progress: $processed / $totalItems ($percent%) | Updated: $updated | Errors: $errors" -ForegroundColor Gray
            }
        } catch {
            $errors++
            Write-Host "  [ERROR] Failed to update Item ID $($item.Id): $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "BULK UPDATE COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total items processed: $processed" -ForegroundColor White
    Write-Host "Successfully updated: $updated" -ForegroundColor Green
    Write-Host "Errors: $errors" -ForegroundColor $(if($errors -gt 0){"Red"}else{"Green"})
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Bulk update failed: $_" -ForegroundColor Red
    Write-Host "Items processed before error: $processed" -ForegroundColor Yellow
}

Disconnect-PnPOnline

