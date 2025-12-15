# Clear all data values from all items in ADT RMA Data list
# This will keep the list structure and columns, but clear all field values

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
Write-Host "WARNING: CLEAR ALL DATA OPERATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will CLEAR ALL DATA from ALL $totalItems items in the list." -ForegroundColor White
Write-Host ""
Write-Host "What will happen:" -ForegroundColor Cyan
Write-Host "  - All items (rows) will be kept" -ForegroundColor White
Write-Host "  - All columns will be kept" -ForegroundColor White
Write-Host "  - ALL field values will be cleared (set to empty/null)" -ForegroundColor White
Write-Host ""
Write-Host "This operation cannot be easily undone!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Type 'CLEAR ALL DATA' to continue, or anything else to cancel"

if ($confirm -ne "CLEAR ALL DATA") {
    Write-Host ""
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    Disconnect-PnPOnline
    exit
}

Write-Host ""
Write-Host "Starting data clearing operation..." -ForegroundColor Cyan
Write-Host ""

# Get all items
$processed = 0
$cleared = 0
$errors = 0

try {
    Write-Host "Retrieving all items (this may take a moment)..." -ForegroundColor Yellow
    $allItems = Get-PnPListItem -List $listName -PageSize 500
    
    Write-Host "Found $($allItems.Count) items. Starting to clear data..." -ForegroundColor Green
    Write-Host ""
    
    # Define all data fields to clear (from our earlier discovery)
    $fieldsToClear = @{
        'Title' = ''
        'ComplianceAssetId' = ''
        'field_0' = $null  # DateTime - set to null
        'field_2' = ''
        'field_3' = ''
        'field_4' = ''
        'field_5' = $null  # Number - set to null
        'field_6' = $null  # DateTime - set to null
        'field_7' = $null  # DateTime - set to null
        'field_8' = $null  # Number - set to null
        'field_9' = $null  # DateTime - set to null
        'field_10' = $null  # DateTime - set to null
        'field_11' = $null  # Number - set to null
        'field_12' = ''
        'field_13' = ''
        'field_14' = ''
        'field_15' = ''
        'field_16' = ''
        'field_17' = ''
        'field_18' = ''
        'field_19' = ''
        'field_20' = $null  # Number - set to null
        'field_21' = $null  # Number - set to null
        'field_22' = $null  # Number - set to null
        'field_23' = ''
        'field_24' = $null  # Number - set to null
        'field_25' = ''
        'field_26' = ''
    }
    
    foreach ($item in $allItems) {
        $processed++
        
        try {
            # Clear all data fields for this item
            Set-PnPListItem -List $listName -Identity $item.Id -Values $fieldsToClear -ErrorAction Stop
            $cleared++
            
            # Show progress every 100 items
            if ($processed % 100 -eq 0) {
                $percent = [math]::Round(($processed / $totalItems) * 100, 1)
                Write-Host "  Progress: $processed / $totalItems ($percent%) | Cleared: $cleared | Errors: $errors" -ForegroundColor Gray
            }
        } catch {
            $errors++
            Write-Host "  [ERROR] Failed to clear Item ID $($item.Id): $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "DATA CLEARING COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total items processed: $processed" -ForegroundColor White
    Write-Host "Successfully cleared: $cleared" -ForegroundColor Green
    Write-Host "Errors: $errors" -ForegroundColor $(if($errors -gt 0){"Red"}else{"Green"})
    Write-Host ""
    Write-Host "All data values have been cleared from all items." -ForegroundColor Green
    Write-Host "List structure and columns remain intact." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Data clearing failed: $_" -ForegroundColor Red
    Write-Host "Items processed before error: $processed" -ForegroundColor Yellow
}

Disconnect-PnPOnline


