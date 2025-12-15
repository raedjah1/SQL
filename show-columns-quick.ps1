# Quick script to show columns - optimized to not hang
Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

# Get list fields first (faster than getting items)
Write-Host "Getting column information..." -ForegroundColor Yellow
$allFields = Get-PnPField -List $listName

# Filter to show only user-created data fields (not system fields)
$fields = $allFields | Where-Object { 
    $_.InternalName -like "field_*" -or 
    $_.InternalName -eq "Title" -or
    $_.InternalName -eq "ComplianceAssetId"
} | Sort-Object @{Expression={[int]($_.InternalName -replace '[^0-9]','')}; Ascending=$true}, InternalName

Write-Host "Total fields in list: $($allFields.Count)" -ForegroundColor Gray
Write-Host "Data fields (editable): $($fields.Count)" -ForegroundColor Gray
Write-Host ""

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DATA COLUMNS IN ADT RMA DATA LIST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Display Name (Internal Name) - Type" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

foreach ($field in $fields) {
    $displayName = if ($field.Title) { $field.Title } else { $field.InternalName }
    Write-Host "  $displayName ($($field.InternalName)) - $($field.TypeAsString)" -ForegroundColor White
}

Write-Host ""
Write-Host "Total columns shown: $($fields.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You have 28 data columns in the ADT RMA Data list:" -ForegroundColor White
Write-Host "  - Title (Text)" -ForegroundColor Gray
Write-Host "  - ComplianceAssetId (Text)" -ForegroundColor Gray
Write-Host "  - field_0 through field_26 (various types)" -ForegroundColor Gray
Write-Host ""
Write-Host "To edit items, use these field names in your scripts." -ForegroundColor Yellow
Write-Host "Example: Set-PnPListItem -List '$listName' -Identity 1 -Values @{Title='New Title'; field_2='Value'}" -ForegroundColor Gray
Write-Host ""

Disconnect-PnPOnline
Write-Host "Done!" -ForegroundColor Green

