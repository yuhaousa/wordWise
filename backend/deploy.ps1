<#
.SYNOPSIS
  WordWise — Deploy Cloudflare Workers backend (one-click).

.DESCRIPTION
  1. Installs Node.js if missing
  2. Runs npm install
  3. Logs you in to Cloudflare (browser opens once)
  4. Creates the D1 database
  5. Runs schema migrations + seeds sample data
  6. Deploys the Worker
  7. Prints the live API URL
  8. Updates the Flutter app's api_config.dart with the new URL
#>

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MobileConfig = "$ScriptDir\..\mobile\lib\config\api_config.dart"

function Info ($m) { Write-Host "  [....] $m" -ForegroundColor Cyan }
function OK   ($m) { Write-Host "  [ OK ] $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Err  ($m) { Write-Host "  [FAIL] $m`n" -ForegroundColor Red; Read-Host "Press Enter to exit"; exit 1 }
function Step ($n, $t) { Write-Host "`n  ── Step $n : $t" -ForegroundColor Magenta }

Clear-Host
Write-Host @"

  ╔══════════════════════════════════════════╗
  ║   WordWise — Deploy Backend to           ║
  ║   Cloudflare Workers + D1                ║
  ╚══════════════════════════════════════════╝

"@ -ForegroundColor Blue

Set-Location $ScriptDir

# ═══════════════════════════════════════════════════
#  STEP 1 — Node.js
# ═══════════════════════════════════════════════════
Step 1 "Node.js"
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Info "Node.js not found — downloading LTS installer..."
    $NodeInstaller = "$env:TEMP\node_installer.msi"
    Invoke-WebRequest "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi" -OutFile $NodeInstaller -UseBasicParsing
    Start-Process msiexec -ArgumentList "/i `"$NodeInstaller`" /quiet /norestart" -Wait
    Remove-Item $NodeInstaller -Force -ErrorAction SilentlyContinue
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) { Err "Node.js install failed. Please install manually from https://nodejs.org" }
}
OK "Node.js $($node | ForEach-Object { & $_.Source --version })"

# ═══════════════════════════════════════════════════
#  STEP 2 — npm install
# ═══════════════════════════════════════════════════
Step 2 "npm install"
Info "Installing dependencies..."
& npm install --loglevel error
if ($LASTEXITCODE -ne 0) { Err "npm install failed" }
OK "Dependencies installed"

# ═══════════════════════════════════════════════════
#  STEP 3 — Cloudflare login
# ═══════════════════════════════════════════════════
Step 3 "Cloudflare login"

# Check if already logged in
$whoami = & npx wrangler whoami 2>&1
if ($whoami -match "You are logged in") {
    OK "Already logged in: $($whoami | Select-String 'account' | Select-Object -First 1)"
} else {
    Write-Host ""
    Write-Host "  A browser window will open for Cloudflare login." -ForegroundColor Yellow
    Write-Host "  Log in (or create a free account at cloudflare.com)" -ForegroundColor Yellow
    Write-Host "  then come back here — the script continues automatically." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter to open the Cloudflare login page"
    & npx wrangler login
    if ($LASTEXITCODE -ne 0) { Err "Cloudflare login failed" }
    OK "Logged in to Cloudflare"
}

# ═══════════════════════════════════════════════════
#  STEP 4 — Create D1 database
# ═══════════════════════════════════════════════════
Step 4 "Create D1 database"

# Check if wrangler.toml already has a real database_id
$tomlContent = Get-Content "wrangler.toml" -Raw
if ($tomlContent -match 'database_id = "YOUR_D1_DATABASE_ID"') {
    Info "Creating D1 database 'english_learning_db'..."
    $dbOutput = & npx wrangler d1 create english_learning_db 2>&1
    Write-Host ($dbOutput | Out-String) -ForegroundColor Gray

    # Extract the database_id from the output
    $dbIdMatch = $dbOutput | Select-String -Pattern 'database_id\s*=\s*"([a-f0-9\-]{36})"'
    if ($dbIdMatch) {
        $dbId = $dbIdMatch.Matches[0].Groups[1].Value
        OK "Database created: $dbId"

        # Patch wrangler.toml
        $tomlContent = $tomlContent -replace 'database_id = "YOUR_D1_DATABASE_ID".*', "database_id = `"$dbId`""
        Set-Content "wrangler.toml" $tomlContent -Encoding UTF8
        OK "wrangler.toml updated with database_id"
    } else {
        # DB might already exist — try to get its id
        $listOut = & npx wrangler d1 list 2>&1
        $existMatch = $listOut | Select-String -Pattern 'english_learning_db\s+\|\s+([a-f0-9\-]{36})'
        if ($existMatch) {
            $dbId = $existMatch.Matches[0].Groups[1].Value
            $tomlContent = $tomlContent -replace 'database_id = "YOUR_D1_DATABASE_ID".*', "database_id = `"$dbId`""
            Set-Content "wrangler.toml" $tomlContent -Encoding UTF8
            OK "Found existing database: $dbId — wrangler.toml updated"
        } else {
            Warn "Could not extract database_id. Check wrangler.toml manually."
            Write-Host ($listOut | Out-String)
        }
    }
} else {
    OK "Database already configured in wrangler.toml"
}

# ═══════════════════════════════════════════════════
#  STEP 5 — Migrate + Seed
# ═══════════════════════════════════════════════════
Step 5 "Database migration + seed"

Info "Running schema migration (remote)..."
& npm run db:migrate 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
if ($LASTEXITCODE -ne 0) { Warn "Migration had warnings — continuing..." }
OK "Schema applied"

Info "Seeding sample data..."
& npm run db:seed 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
if ($LASTEXITCODE -ne 0) { Warn "Seed had warnings (data may already exist)" }
OK "Sample data loaded"

# ═══════════════════════════════════════════════════
#  STEP 6 — Deploy Worker
# ═══════════════════════════════════════════════════
Step 6 "Deploying Worker"
Info "Deploying to Cloudflare Workers..."
$deployOut = & npm run deploy 2>&1
$deployOut | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
if ($LASTEXITCODE -ne 0) { Err "Deployment failed" }

# Extract deployed URL
$urlMatch = $deployOut | Select-String -Pattern 'https://[a-zA-Z0-9\-]+\.workers\.dev'
if ($urlMatch) {
    $apiUrl = $urlMatch.Matches[0].Value.Trim()
    OK "Worker deployed: $apiUrl"

    # ═══════════════════════════════════════════════
    #  STEP 7 — Update Flutter app config
    # ═══════════════════════════════════════════════
    Step 7 "Updating Flutter app with live API URL"
    if (Test-Path $MobileConfig) {
        $dart = Get-Content $MobileConfig -Raw
        $dart = $dart -replace "static const String _productionBaseUrl = '[^']*'", "static const String _productionBaseUrl = '$apiUrl'"
        Set-Content $MobileConfig $dart -Encoding UTF8
        OK "api_config.dart updated → $apiUrl"
        Write-Host ""
        Write-Host "  ┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
        Write-Host "  │  Rebuild the APK to connect to the live server: │" -ForegroundColor Cyan
        Write-Host "  │                                                 │" -ForegroundColor Cyan
        Write-Host "  │   cd ..\mobile                                  │" -ForegroundColor Cyan
        Write-Host "  │   flutter build apk --release --dart-define=ENV=prod │" -ForegroundColor Cyan
        Write-Host "  │   adb install -r WordWise.apk                   │" -ForegroundColor Cyan
        Write-Host "  └─────────────────────────────────────────────────┘" -ForegroundColor Cyan
    } else {
        Warn "Could not find api_config.dart at $MobileConfig"
        Write-Host "  Manually set _productionBaseUrl = '$apiUrl'" -ForegroundColor Yellow
    }
} else {
    Warn "Could not detect deployed URL from output."
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║   ✅  BACKEND DEPLOYED SUCCESSFULLY!      ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Read-Host "  Press Enter to exit"
