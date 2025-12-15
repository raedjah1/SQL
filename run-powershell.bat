@echo off
REM Batch file to run PowerShell scripts with execution policy bypass
REM Usage: run-powershell.bat your-script.ps1 [arguments]

if "%~1"=="" (
    echo Usage: run-powershell.bat script.ps1 [arguments]
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -File "%~1" %*


