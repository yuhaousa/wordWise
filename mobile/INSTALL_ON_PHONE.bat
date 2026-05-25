@echo off
title WordWise — Build and Install to Android Phone
color 1F
echo.
echo  ============================================
echo   WordWise English Learning App
echo   One-Click Build + Install to Android Phone
echo  ============================================
echo.
echo  This script will:
echo    1. Install Flutter SDK if not found
echo    2. Download Android ADB tools if needed
echo    3. Build the WordWise APK
echo    4. Install it on your connected phone
echo.
echo  *** BEFORE CLICKING OK: ***
echo   - On your Android phone:
echo       Settings ^> About Phone ^> tap Build Number 7x
echo       Settings ^> Developer Options ^> USB Debugging ON
echo   - Plug your phone in via USB
echo   - Tap "Allow" when phone asks to trust this PC
echo.
pause

:: Clean up any partial Flutter folder left by a previous attempt
if exist "C:\development\workMaster\flutter\.git\config.lock" (
    echo.
    echo  Cleaning up partial Flutter folder from previous attempt...
    rd /s /q "C:\development\workMaster\flutter" 2>nul
    echo  Done.
)

:: Run the PowerShell script (no admin needed — installs to user folders)
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0build_and_install.ps1"
