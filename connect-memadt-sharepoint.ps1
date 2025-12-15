# Connect to MEMADT SharePoint Site
# Site: https://topcogroup.sharepoint.com/sites/MEMADT
# List: ADT RMA Data
#
# AUTHENTICATION: You will be prompted to enter your SharePoint/Office 365 credentials
# Use your work email (e.g., yourname@topcogroup.com) and password

param(
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseCredentials
)

$siteUrl = "https://topcogroup.sharepoint.com/sites/MEMADT"
$listName = "ADT RMA Data"

Write-Host "Connecting to MEMADT SharePoint..." -ForegroundColor Cyan
Write-Host "Site URL: $siteUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "WINDOWS AUTHENTICATION (SSO)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Using your Windows login credentials for SharePoint authentication." -ForegroundColor Cyan
Write-Host "This will use the same credentials you use to log into SharePoint in your browser." -ForegroundColor White
Write-Host ""

# Import PnP PowerShell module (try newer first, fallback to older)
try {
    # Try to import a compatible version
    $module = Get-Module -ListAvailable -Name "PnP.PowerShell" | Where-Object { $_.Version.Major -lt 3 } | Sort-Object Version -Descending | Select-Object -First 1
    if ($module) {
        Import-Module $module -Force
        Write-Host "Using PnP.PowerShell version $($module.Version)" -ForegroundColor Gray
    } else {
        # Fallback to legacy module
        Import-Module SharePointPnPPowerShellOnline -Force -ErrorAction Stop
        Write-Host "Using SharePointPnPPowerShellOnline (legacy)" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARNING] Could not load PnP module. Attempting to install compatible version..." -ForegroundColor Yellow
    Install-Module -Name SharePointPnPPowerShellOnline -Scope CurrentUser -Force -AllowClobber
    Import-Module SharePointPnPPowerShellOnline -Force
}

try {
    # Connect to SharePoint Online using Windows Authentication/SSO
    Write-Host "Using Windows Authentication (SSO)..." -ForegroundColor Cyan
    Write-Host "This will use your current Windows login credentials." -ForegroundColor Gray
    Write-Host ""
    
    if ($UseCredentials -and $Username) {
        # Use provided credentials
        Write-Host "Using provided username: $Username" -ForegroundColor Gray
        $securePassword = Read-Host "Enter your password" -AsSecureString
        $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
        Connect-PnPOnline -Url $siteUrl -Credentials $credential
    } else {
        # Try to use Windows authentication/SSO
        # Method 1: UseWebLogin - opens browser for SSO authentication
        Write-Host "Opening browser for Windows authentication..." -ForegroundColor Yellow
        Write-Host "If a browser window opens, complete the login there." -ForegroundColor White
        Write-Host ""
        
        try {
            # Try UseWebLogin first (opens browser for SSO)
            Connect-PnPOnline -Url $siteUrl -UseWebLogin -ErrorAction Stop
        } catch {
            # Fallback: Try with current Windows credentials
            Write-Host "Trying with current Windows credentials..." -ForegroundColor Yellow
            try {
                Connect-PnPOnline -Url $siteUrl -CurrentCredentials -ErrorAction Stop
            } catch {
                # Last resort: Interactive (may prompt)
                Write-Host "Using interactive authentication..." -ForegroundColor Yellow
                Connect-PnPOnline -Url $siteUrl
            }
        }
    }
    
    Write-Host "[OK] Successfully connected to SharePoint!" -ForegroundColor Green
    Write-Host ""
    
    # Get the list
    Write-Host "Accessing list: $listName" -ForegroundColor Yellow
    $list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue
    
    if ($list) {
        Write-Host "[OK] Found list: $listName" -ForegroundColor Green
        Write-Host "  Item Count: $($list.ItemCount)" -ForegroundColor Gray
        Write-Host ""
        
        # Get list items (first 10)
        Write-Host "Getting items from list..." -ForegroundColor Yellow
        $items = Get-PnPListItem -List $listName -PageSize 10
        
        Write-Host "[OK] Retrieved $($items.Count) items (showing first 10)" -ForegroundColor Green
        Write-Host ""
        
        # Display items
        foreach ($item in $items) {
            $title = if ($item.FieldValues.Title) { $item.FieldValues.Title } else { "N/A" }
            Write-Host "  ID: $($item.Id) - Title: $title" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "You're now connected and can run SharePoint commands!" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Example commands:" -ForegroundColor Yellow
        Write-Host "  Get-PnPListItem -List '$listName' | Select-Object Id, FieldValues" -ForegroundColor White
        Write-Host "  Set-PnPListItem -List '$listName' -Identity 1 -Values @{Title='Updated'}" -ForegroundColor White
        Write-Host "  Add-PnPListItem -List '$listName' -Values @{Title='New Item'}" -ForegroundColor White
        Write-Host ""
        Write-Host "To disconnect, run: Disconnect-PnPOnline" -ForegroundColor Yellow
        
    } else {
        Write-Host "[ERROR] List '$listName' not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available lists:" -ForegroundColor Yellow
        Get-PnPList | Select-Object Title, ItemCount | Format-Table
    }
    
} catch {
    Write-Host "[ERROR] Error connecting to SharePoint: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have the correct permissions and are authenticated." -ForegroundColor Yellow
}

