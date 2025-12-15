# Edit ADT RMA Data List Items
# This script provides functions to edit items in the ADT RMA Data list

param(
    [Parameter(Mandatory=$false)]
    [int]$ItemId,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Values,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListItems,
    
    [Parameter(Mandatory=$false)]
    [switch]$GetFields
)

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

# Import module (same method as connect script)
try {
    $module = Get-Module -ListAvailable -Name "PnP.PowerShell" | Where-Object { $_.Version.Major -lt 3 } | Sort-Object Version -Descending | Select-Object -First 1
    if ($module) {
        Import-Module $module -Force
    } else {
        Import-Module SharePointPnPPowerShellOnline -Force -ErrorAction Stop
    }
} catch {
    Install-Module -Name SharePointPnPPowerShellOnline -Scope CurrentUser -Force -AllowClobber
    Import-Module SharePointPnPPowerShellOnline -Force
}

try {
    # Connect using Windows Authentication (SSO)
    Write-Host "Connecting to SharePoint..." -ForegroundColor Cyan
    try {
        Connect-PnPOnline -Url $siteUrl -UseWebLogin -ErrorAction Stop
    } catch {
        try {
            Connect-PnPOnline -Url $siteUrl -CurrentCredentials -ErrorAction Stop
        } catch {
            Connect-PnPOnline -Url $siteUrl
        }
    }
    Write-Host "[OK] Connected" -ForegroundColor Green
    Write-Host ""
    
    # Get list fields
    if ($GetFields) {
        Write-Host "Available fields in '$listName':" -ForegroundColor Yellow
        $fields = Get-PnPField -List $listName
        foreach ($field in $fields) {
            Write-Host "  - $($field.InternalName) ($($field.TypeAsString))" -ForegroundColor White
        }
        Write-Host ""
        return
    }
    
    # List items
    if ($ListItems) {
        Write-Host "Items in '$listName':" -ForegroundColor Yellow
        $items = Get-PnPListItem -List $listName -PageSize 20
        foreach ($item in $items) {
            Write-Host ""
            Write-Host "ID: $($item.Id)" -ForegroundColor Cyan
            foreach ($key in $item.FieldValues.Keys) {
                if ($item.FieldValues[$key] -and $key -ne 'ContentTypeId' -and $key -ne 'FileSystemObjectType') {
                    Write-Host "  $key : $($item.FieldValues[$key])" -ForegroundColor White
                }
            }
        }
        Write-Host ""
        return
    }
    
    # Update item
    if ($ItemId -and $Values) {
        Write-Host "Updating item ID: $ItemId" -ForegroundColor Yellow
        Set-PnPListItem -List $listName -Identity $ItemId -Values $Values
        Write-Host "[OK] Item updated successfully!" -ForegroundColor Green
        Write-Host ""
        return
    }
    
    # Show usage if no parameters
    Write-Host "ADT RMA Data List Editor" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. List all items:" -ForegroundColor White
    Write-Host "   .\edit-adt-rma-data.ps1 -ListItems" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Get available fields:" -ForegroundColor White
    Write-Host "   .\edit-adt-rma-data.ps1 -GetFields" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Update an item:" -ForegroundColor White
    Write-Host "   .\edit-adt-rma-data.ps1 -ItemId 1 -Values @{Title='New Title'; Status='Active'}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Add a new item:" -ForegroundColor White
    Write-Host "   Add-PnPListItem -List '$listName' -Values @{Title='New RMA'; Status='Pending'}" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] Error: $_" -ForegroundColor Red
} finally {
    if ($PSCmdlet.MyInvocation.BoundParameters.Count -gt 0) {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
}

