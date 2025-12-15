# Check for all fields and identify any missing ones
Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

Write-Host "Getting all fields..." -ForegroundColor Yellow
$allFields = Get-PnPField -List $listName
$dataFields = $allFields | Where-Object { 
    $_.InternalName -like "field_*" -or 
    $_.InternalName -eq "Title" -or
    $_.InternalName -eq "ComplianceAssetId"
}

Write-Host ""
Write-Host "Total fields in list: $($allFields.Count)" -ForegroundColor Cyan
Write-Host "Data fields (editable): $($dataFields.Count)" -ForegroundColor Cyan
Write-Host ""

# Check for missing field numbers
Write-Host "Checking for missing field numbers..." -ForegroundColor Yellow
$fieldNumbers = $dataFields | Where-Object {$_.InternalName -like "field_*"} | ForEach-Object {
    $num = [int]($_.InternalName -replace '[^0-9]','')
    $num
} | Sort-Object

Write-Host ""
Write-Host "Field numbers found: $($fieldNumbers -join ', ')" -ForegroundColor White

# Check for gaps
$missing = @()
for($i=0; $i -le 26; $i++) {
    if($i -notin $fieldNumbers) {
        $missing += $i
    }
}

if($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing field numbers: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host "(These field numbers don't exist in the list)" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "[OK] No missing field numbers (0-26 all present or accounted for)" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALL DATA FIELDS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($field in $dataFields | Sort-Object @{Expression={[int]($_.InternalName -replace '[^0-9]','')}; Ascending=$true}, InternalName) {
    $displayName = if ($field.Title) { $field.Title } else { $field.InternalName }
    Write-Host "  $displayName ($($field.InternalName)) - $($field.TypeAsString)" -ForegroundColor White
}

Disconnect-PnPOnline
Write-Host ""
Write-Host "Done!" -ForegroundColor Green


