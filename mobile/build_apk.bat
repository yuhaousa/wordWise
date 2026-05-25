@echo off
setlocal enabledelayedexpansion
title WordWise — Build Android APK

echo.
echo  ==========================================
echo   WordWise English Learning App
echo   Android APK Builder
echo  ==========================================
echo.

:: ── 1. Check Flutter ──────────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found in PATH.
    echo.
    echo  Please install Flutter first:
    echo    1. Go to https://docs.flutter.dev/get-started/install/windows
    echo    2. Download and extract the Flutter SDK
    echo    3. Add flutter\bin to your system PATH
    echo    4. Run: flutter doctor
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter found:
flutter --version
echo.

:: ── 2. Run flutter doctor ─────────────────────────────────
echo [INFO] Checking build environment...
flutter doctor -v 2>&1 | findstr /C:"Android" /C:"[!]" /C:"[X]" /C:"Flutter"
echo.

:: ── 3. Get dependencies ───────────────────────────────────
echo [INFO] Fetching dependencies (flutter pub get)...
flutter pub get
if errorlevel 1 (
    echo [ERROR] pub get failed. Check your internet connection.
    pause
    exit /b 1
)
echo [OK] Dependencies ready.
echo.

:: ── 4. Build release APK ─────────────────────────────────
echo [INFO] Building release APK (this takes 2-5 minutes)...
flutter build apk --release --no-tree-shake-icons
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed. Try:
    echo   flutter clean
    echo   flutter pub get
    echo   flutter build apk --release
    pause
    exit /b 1
)

:: ── 5. Copy APK to easy location ─────────────────────────
set APK_SRC=build\app\outputs\flutter-apk\app-release.apk
set APK_DST=%~dp0WordWise.apk

if exist "%APK_SRC%" (
    copy /Y "%APK_SRC%" "%APK_DST%" >nul
    echo.
    echo  ==========================================
    echo   BUILD SUCCESSFUL!
    echo  ==========================================
    echo.
    echo   APK saved to:
    echo   %APK_DST%
    echo.
    echo   Install on Android device:
    echo     adb install WordWise.apk
    echo.
    echo   Or just copy WordWise.apk to your phone
    echo   and open it to install (enable 'Install
    echo   from unknown sources' in phone settings).
    echo  ==========================================
    echo.
    :: Open the folder so user can find the APK
    explorer /select,"%APK_DST%"
) else (
    echo [WARN] APK not found at expected path. Check build\app\outputs\
)

pause
