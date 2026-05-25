<#
.SYNOPSIS
  WordWise — One-click: install Flutter if needed, build APK, install to phone.

.DESCRIPTION
  Run this script once. It handles everything:
    1. Removes any partial Flutter folder left by a previous attempt
    2. Downloads & extracts Flutter SDK 3.24.5 for Windows (if not found)
    3. Accepts Android SDK licences
    4. Runs flutter pub get + flutter build apk --release
    5. Detects your USB-connected Android device
    6. Installs WordWise on the device and launches it

  BEFORE RUNNING on your phone:
    Settings → About Phone → tap Build Number 7 times
    Settings → Developer Options → turn on USB Debugging
    Plug in via USB → tap "Allow" when the phone asks to trust this PC

  HOW TO RUN:
    Right-click this file → "Run with PowerShell"
    (or in PowerShell:  .\build_and_install.ps1 )
#>

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # makes Invoke-WebRequest fast

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FlutterRoot = "C:\development\workMaster\flutter"
$FlutterBin  = "$FlutterRoot\bin\flutter.bat"
$AdbDir      = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
$AdbExe      = "$AdbDir\adb.exe"
$ApkSrc      = "$ScriptDir\build\app\outputs\flutter-apk\app-release.apk"
$ApkDest     = "$ScriptDir\WordWise.apk"

function Info  ($m) { Write-Host "  [....] $m" -ForegroundColor Cyan }
function OK    ($m) { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn  ($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Err   ($m) { Write-Host "  [FAIL] $m`n" -ForegroundColor Red; Read-Host "Press Enter to exit"; exit 1 }
function Step  ($n, $t) { Write-Host "`n  ── Step $n : $t" -ForegroundColor Magenta }

Clear-Host
Write-Host @"

  ╔══════════════════════════════════════════╗
  ║   WordWise English Learning App          ║
  ║   Build + Install to Android Phone       ║
  ╚══════════════════════════════════════════╝

"@ -ForegroundColor Blue

# ═══════════════════════════════════════════════════
#  STEP 1 — Flutter SDK
# ═══════════════════════════════════════════════════
Step 1 "Flutter SDK"

# Check system PATH first
$sysFlutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($sysFlutter) {
    $FlutterBin = $sysFlutter.Source
    OK "Flutter already in PATH: $FlutterBin"
} elseif (Test-Path $FlutterBin) {
    OK "Flutter found at $FlutterRoot"
} else {
    # Clean up any partial/broken folder from a previous attempt
    if (Test-Path $FlutterRoot) {
        Info "Removing broken partial Flutter folder..."
        Remove-Item -Recurse -Force $FlutterRoot -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $ZipUrl  = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
    $ZipFile = "$env:TEMP\flutter_windows.zip"
    $ExtractTo = "C:\development\workMaster"

    Info "Downloading Flutter 3.24.5 for Windows (~700 MB)..."
    Info "URL: $ZipUrl"
    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -UseBasicParsing
    } catch {
        Err "Download failed: $_`n`nPlease download manually from https://docs.flutter.dev/get-started/install/windows and extract to C:\development\workMaster\flutter"
    }
    OK "Download complete. Extracting..."

    Expand-Archive -Path $ZipFile -DestinationPath $ExtractTo -Force
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path $FlutterBin)) {
        Err "Extraction failed — flutter.bat not found at $FlutterBin"
    }
    OK "Flutter extracted to $FlutterRoot"
}

# Add Flutter bin to this session's PATH
$env:PATH = (Split-Path $FlutterBin) + ";$env:PATH"

# Run flutter doctor once to download Dart SDK + engine (first-run setup)
Info "Running first-time Flutter setup (downloads Dart SDK ~100 MB)..."
& $FlutterBin doctor --no-color 2>&1 | Select-String -Pattern "Flutter|Dart|Android|✓|✗|!" | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

# ═══════════════════════════════════════════════════
#  STEP 2 — Android platform-tools (ADB)
# ═══════════════════════════════════════════════════
Step 2 "Android platform-tools (ADB)"

if (-not (Test-Path $AdbExe)) {
    Info "Downloading Android platform-tools..."
    $PtZip = "$env:TEMP\platform-tools.zip"
    try {
        Invoke-WebRequest -Uri "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" `
            -OutFile $PtZip -UseBasicParsing
        New-Item -ItemType Directory -Path (Split-Path $AdbDir) -Force | Out-Null
        Expand-Archive -Path $PtZip -DestinationPath (Split-Path $AdbDir) -Force
        Remove-Item $PtZip -Force
        OK "ADB installed to $AdbDir"
    } catch {
        Warn "Could not auto-download ADB: $_"
        Warn "Download manually: https://developer.android.com/studio/releases/platform-tools"
    }
} else {
    OK "ADB found: $AdbExe"
}

$env:PATH = "$AdbDir;$env:PATH"

# ═══════════════════════════════════════════════════
#  STEP 3 — Accept Android SDK licences
# ═══════════════════════════════════════════════════
Step 3 "Android SDK licences"
Info "Accepting SDK licences (requires Android Studio or SDK to be installed)..."
try {
    echo "y`ny`ny`ny`ny`ny`n" | & $FlutterBin doctor --android-licenses 2>&1 | Out-Null
    OK "Licences accepted"
} catch {
    Warn "Could not accept licences automatically (Android Studio may not be installed — that's OK for sideloading)"
}

# ═══════════════════════════════════════════════════
#  STEP 4 — Build the APK
# ═══════════════════════════════════════════════════
Step 4 "Building APK"
Set-Location $ScriptDir

Info "flutter pub get..."
& $FlutterBin pub get
if ($LASTEXITCODE -ne 0) { Err "flutter pub get failed. Check your internet connection." }
OK "Dependencies ready"

Info "flutter build apk --release  (this takes 3–6 minutes, please wait)..."
& $FlutterBin build apk --release --no-tree-shake-icons
if ($LASTEXITCODE -ne 0) { Err "Build failed. Run 'flutter doctor' for details." }

if (Test-Path $ApkSrc) {
    Copy-Item $ApkSrc $ApkDest -Force
    $sizeMB = [math]::Round((Get-Item $ApkDest).Length / 1MB, 1)
    OK "APK built → $ApkDest  ($sizeMB MB)"
} else {
    Err "APK not found after build at: $ApkSrc"
}

# ═══════════════════════════════════════════════════
#  STEP 5 — Detect phone & install
# ═══════════════════════════════════════════════════
Step 5 "Installing on Android device"

& $AdbExe start-server 2>&1 | Out-Null
Start-Sleep -Seconds 2

function Get-Device {
    $lines = & $AdbExe devices 2>&1 | Where-Object { $_ -match "\t(device|unauthorized|offline)" }
    return $lines
}

$deviceLines = Get-Device
if (-not $deviceLines) {
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "  │  No Android device detected.            │" -ForegroundColor Yellow
    Write-Host "  │                                         │" -ForegroundColor Yellow
    Write-Host "  │  Please:                                │" -ForegroundColor Yellow
    Write-Host "  │  1. Connect phone via USB               │" -ForegroundColor Yellow
    Write-Host "  │  2. Enable USB Debugging (Dev Options)  │" -ForegroundColor Yellow
    Write-Host "  │  3. Tap 'Allow' on your phone screen    │" -ForegroundColor Yellow
    Write-Host "  └─────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter when phone is connected to retry"
    $deviceLines = Get-Device
}

if ($deviceLines | Where-Object { $_ -match "unauthorized" }) {
    Err "Device found but not authorized. Tap 'Allow USB Debugging' on your phone, then re-run."
}

if (-not $deviceLines) {
    Write-Host ""
    Warn "No device found. APK is ready at:"
    Write-Host "    $ApkDest" -ForegroundColor White
    Write-Host ""
    Write-Host "  Copy it to your phone and open it to install manually." -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 0
}

$serial = ($deviceLines | Select-Object -First 1) -split "\t" | Select-Object -First 1
$model  = (& $AdbExe -s $serial shell getprop ro.product.model 2>&1).Trim()
OK "Connected: $model  [$serial]"

Info "Installing WordWise.apk..."
$out = & $AdbExe -s $serial install -r $ApkDest 2>&1
if ($LASTEXITCODE -eq 0 -or ($out -join " ") -match "Success") {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║   ✅  INSTALL SUCCESSFUL!                 ║" -ForegroundColor Green
    Write-Host "  ║                                          ║" -ForegroundColor Green
    Write-Host "  ║   WordWise is now on $($model.PadRight(18))║" -ForegroundColor Green
    Write-Host "  ║   Look for the 📚 icon in your apps.     ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Info "Launching WordWise..."
    & $AdbExe -s $serial shell am start -n "com.wordwise.app/.MainActivity" 2>&1 | Out-Null
} else {
    Warn "ADB output: $out"
    Write-Host ""
    Write-Host "  Manual option: copy $ApkDest to your phone and tap it." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "  Press Enter to exit"
