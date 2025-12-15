# Export SharePoint list to Excel for easy data entry
# After filling in Excel, use import-from-excel.ps1 to import it back

Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"
$exportPath = "$PSScriptRoot\ADT_RMA_Data_Export.xlsx"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

Write-Host "Exporting list to Excel..." -ForegroundColor Yellow
Write-Host "This will create an Excel file with all current data." -ForegroundColor White
Write-Host ""

try {
    # Get all items
    Write-Host "Retrieving all items..." -ForegroundColor Yellow
    $items = Get-PnPListItem -List $listName -PageSize 500
    
    Write-Host "Found $($items.Count) items" -ForegroundColor Green
    Write-Host ""
    
    # Create Excel COM object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Add()
    $worksheet = $workbook.Worksheets.Item(1)
    $worksheet.Name = "ADT RMA Data"
    
    # Get field names (headers)
    $fields = Get-PnPField -List $listName | Where-Object { 
        $_.InternalName -like "field_*" -or 
        $_.InternalName -eq "Title" -or
        $_.InternalName -eq "ComplianceAssetId"
    } | Sort-Object @{Expression={[int]($_.InternalName -replace '[^0-9]','')}; Ascending=$true}, InternalName
    
    # Write headers
    $col = 1
    $worksheet.Cells.Item(1, $col) = "ID"
    $col++
    foreach ($field in $fields) {
        $displayName = if ($field.Title) { $field.Title } else { $field.InternalName }
        $worksheet.Cells.Item(1, $col) = "$displayName ($($field.InternalName))"
        $col++
    }
    
    # Format header row
    $headerRange = $worksheet.Range($worksheet.Cells.Item(1, 1), $worksheet.Cells.Item(1, $col-1))
    $headerRange.Font.Bold = $true
    $headerRange.Interior.ColorIndex = 15  # Gray background
    
    # Write data
    $row = 2
    foreach ($item in $items) {
        $col = 1
        $worksheet.Cells.Item($row, $col) = $item.Id
        $col++
        
        foreach ($field in $fields) {
            $value = $item.FieldValues[$field.InternalName]
            if ($value -ne $null) {
                $worksheet.Cells.Item($row, $col) = $value.ToString()
            }
            $col++
        }
        $row++
        
        if ($row % 100 -eq 0) {
            Write-Host "  Exported $row rows..." -ForegroundColor Gray
        }
    }
    
    # Auto-fit columns
    $usedRange = $worksheet.UsedRange
    $usedRange.Columns.AutoFit() | Out-Null
    
    # Save file
    Write-Host ""
    Write-Host "Saving Excel file..." -ForegroundColor Yellow
    $workbook.SaveAs($exportPath)
    $workbook.Close()
    $excel.Quit()
    
    Write-Host ""
    Write-Host "[OK] Export complete!" -ForegroundColor Green
    Write-Host "File saved to: $exportPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Open the Excel file and fill in your data" -ForegroundColor White
    Write-Host "2. Save the Excel file" -ForegroundColor White
    Write-Host "3. Run import-from-excel.ps1 to import the data back to SharePoint" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] Export failed: $_" -ForegroundColor Red
    if ($excel) {
        $excel.Quit()
    }
}

Disconnect-PnPOnline


