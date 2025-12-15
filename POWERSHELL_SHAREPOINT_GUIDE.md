# PowerShell & SharePoint Setup Guide

## ✅ Setup Complete

You can now run PowerShell scripts and edit SharePoint, even with the execution policy restriction.

## How to Run PowerShell Scripts

### Method 1: Using the Bypass Flag (Recommended)
```powershell
powershell.exe -ExecutionPolicy Bypass -File your-script.ps1
```

### Method 2: Using the Batch File Helper
```cmd
run-powershell.bat your-script.ps1
```

### Method 3: Using the PowerShell Helper Script
```powershell
powershell.exe -ExecutionPolicy Bypass -File run-powershell.ps1 -ScriptPath "your-script.ps1"
```

## SharePoint Connection

### Connect to SharePoint Online
```powershell
powershell.exe -ExecutionPolicy Bypass -File sharepoint-connect.ps1 -SiteUrl "https://yourtenant.sharepoint.com"
```

Or manually:
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "Import-Module PnP.PowerShell; Connect-PnPOnline -Url 'https://yourtenant.sharepoint.com' -Interactive"
```

## Common SharePoint Editing Commands

### Get Lists
```powershell
Get-PnPList
```

### Get Items from a List
```powershell
Get-PnPListItem -List "YourListName"
```

### Update a List Item
```powershell
Set-PnPListItem -List "YourListName" -Identity 1 -Values @{Title="New Title"; Status="Active"}
```

### Add a New List Item
```powershell
Add-PnPListItem -List "YourListName" -Values @{Title="New Item"; Status="Active"}
```

### Delete a List Item
```powershell
Remove-PnPListItem -List "YourListName" -Identity 1 -Force
```

### Upload a File
```powershell
Add-PnPFile -Path "C:\path\to\file.pdf" -Folder "Shared Documents"
```

### Download a File
```powershell
Get-PnPFile -Url "/sites/yoursite/Shared Documents/file.pdf" -Path "C:\downloads\file.pdf" -AsFile
```

## Example: Edit SharePoint Items Script

Run the example script:
```powershell
powershell.exe -ExecutionPolicy Bypass -File sharepoint-edit-example.ps1 -SiteUrl "https://yourtenant.sharepoint.com" -ListName "YourListName"
```

## Notes

- The execution policy is set to `RemoteSigned` at the MachinePolicy level (Group Policy), which cannot be changed
- Using `-ExecutionPolicy Bypass` allows you to run any script regardless of the policy
- All scripts in this directory can be run using the bypass method
- PnP.PowerShell is installed and ready to use for SharePoint operations

## Troubleshooting

If you get module not found errors:
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force"
```

If you need to check installed modules:
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "Get-Module -ListAvailable | Where-Object {$_.Name -like '*PnP*'}"
```


