# Show columns and sample data from ADT RMA Data list
Import-Module SharePointPnPPowerShellOnline -Force

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting..." -ForegroundColor Cyan
Connect-PnPOnline -Url $siteUrl -UseWebLogin

Write-Host "[OK] Connected" -ForegroundColor Green
Write-Host ""

# Get first item to see actual column values
Write-Host "Getting first item to show column structure..." -ForegroundColor Yellow
$item = Get-PnPListItem -List $listName -PageSize 1

if ($item) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "COLUMNS AND SAMPLE DATA" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Item ID: $($item.Id)" -ForegroundColor Yellow
    Write-Host ""
    
    # Show all fields with values (excluding system fields)
    $systemFields = @('ContentTypeId', 'LinkTitle', 'File_x0020_Type', '_ModerationComments', 
                      'ComplianceAssetId', 'Modified', 'ID', 'ContentType', 'Created', 
                      'Author', 'Editor', '_HasCopyDestinations', '_CopySource', 
                      'owshiddenversion', 'WorkflowVersion', '_UIVersion', '_UIVersionString',
                      'Attachments', '_ModerationStatus', 'Edit', 'LinkTitleNoMenu', 
                      'LinkTitle2', 'SelectTitle', 'InstanceID', 'Order', 'GUID',
                      'WorkflowInstanceID', 'FileRef', 'FileDirRef', 'Last_x0020_Modified',
                      'Created_x0020_Date', 'FSObjType', 'SortBehavior', 'PermMask',
                      'PrincipalCount', 'FileLeafRef', 'UniqueId', 'ParentUniqueId',
                      'SyncClientId', 'ProgId', 'ScopeId', 'HTML_x0020_File_x0020_Type',
                      '_EditMenuTableStart', '_EditMenuTableStart2', '_EditMenuTableEnd',
                      'LinkFilenameNoMenu', 'LinkFilename', 'LinkFilename2', 'DocIcon',
                      'ServerUrl', 'EncodedAbsUrl', 'BaseName', 'MetaInfo', '_Level',
                      '_IsCurrentVersion', 'ItemChildCount', 'FolderChildCount', 'Restricted',
                      'OriginatorId', 'NoExecute', 'ContentVersion', '_ComplianceFlags',
                      '_ComplianceTag', '_ComplianceTagWrittenTime', '_ComplianceTagUserId',
                      '_IsRecord', 'AccessPolicy', '_VirusStatus', '_VirusVendorID',
                      '_VirusInfo', '_RansomwareAnomalyMetaInfo', '_DraftOwnerId',
                      'MainLinkSettings', 'AppAuthor', 'AppEditor', 'SMTotalSize',
                      'SMLastModifiedDate', 'SMTotalFileStreamSize', 'SMTotalFileCount',
                      '_CommentFlags', '_CommentCount', '_ColorHex', '_ColorTag', '_Emoji')
    
    Write-Host "Data Columns:" -ForegroundColor Green
    Write-Host "------------" -ForegroundColor Green
    
    foreach ($key in $item.FieldValues.Keys | Sort-Object) {
        if ($key -notin $systemFields) {
            $value = $item.FieldValues[$key]
            if ($value -ne $null -and $value -ne '') {
                $displayValue = if ($value.ToString().Length -gt 50) { 
                    $value.ToString().Substring(0, 50) + "..." 
                } else { 
                    $value.ToString() 
                }
                Write-Host "  $key : $displayValue" -ForegroundColor White
            }
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "All Available Fields (including empty):" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show all fields
    foreach ($key in $item.FieldValues.Keys | Sort-Object) {
        if ($key -notin $systemFields) {
            $value = $item.FieldValues[$key]
            Write-Host "  $key : $value" -ForegroundColor Gray
        }
    }
    
} else {
    Write-Host "[ERROR] No items found" -ForegroundColor Red
}

Disconnect-PnPOnline


