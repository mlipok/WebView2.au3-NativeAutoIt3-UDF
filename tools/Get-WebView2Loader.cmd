@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Get-WebView2Loader.ps1"
if errorlevel 1 (
    echo.
    echo WebView2Loader setup FAILED.
    exit /b 1
)
echo.
echo WebView2Loader setup completed.
endlocal
