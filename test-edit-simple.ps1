# Simple test to edit a SharePoint item
# This will update a test field and then restore it

param(
    [Parameter(Mandatory=$true)]
    [int]$ItemId
)

Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

# Get current values
Write-Host "Getting current values for Item ID: $ItemId" -ForegroundColor Yellow
$item = Get-PnPListItem -List $listName -Identity $ItemId -Fields "Title", "field_2", "field_15"

if (-not $item) {
    Write-Host "[ERROR] Item ID $ItemId not found!" -ForegroundColor Red
    Disconnect-PnPOnline
    exit
}

$originalTitle = $item.FieldValues.Title
$originalTicket = $item.FieldValues.field_2
$originalStatus = $item.FieldValues.field_15

Write-Host "Current values:" -ForegroundColor Cyan
Write-Host "  Title: $originalTitle" -ForegroundColor White
Write-Host "  Ticket Number (field_2): $originalTicket" -ForegroundColor White
Write-Host "  Status (field_15): $originalStatus" -ForegroundColor White
Write-Host ""

# Test edit - update Title with a test suffix
$testTitle = "$originalTitle [TEST EDIT $(Get-Date -Format 'HH:mm:ss')]"
Write-Host "Updating Title to: $testTitle" -ForegroundColor Yellow

try {
    Set-PnPListItem -List $listName -Identity $ItemId -Values @{Title=$testTitle}
    Write-Host "[OK] Item updated successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify the update
    Write-Host "Verifying update..." -ForegroundColor Yellow
    $updatedItem = Get-PnPListItem -List $listName -Identity $ItemId -Fields "Title"
    Write-Host "Updated Title: $($updatedItem.FieldValues.Title)" -ForegroundColor Green
    
    if ($updatedItem.FieldValues.Title -eq $testTitle) {
        Write-Host "[OK] Edit verified - it works!" -ForegroundColor Green
    }
    
    # Restore original title
    Write-Host ""
    Write-Host "Restoring original title..." -ForegroundColor Yellow
    Set-PnPListItem -List $listName -Identity $ItemId -Values @{Title=$originalTitle}
    Write-Host "[OK] Original title restored" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "TEST COMPLETE - EDITING WORKS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "[ERROR] Failed to update item: $_" -ForegroundColor Red
}

Disconnect-PnPOnline


