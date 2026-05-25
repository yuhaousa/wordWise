@echo off
title WordWise — Deploy Backend to Cloudflare
color 1F
echo.
echo  ============================================
echo   WordWise — Deploy Backend to Cloudflare
echo  ============================================
echo.
echo  This will:
echo    1. Install Node.js if needed
echo    2. Log you in to Cloudflare (browser opens)
echo    3. Create the D1 database
echo    4. Run migrations and seed data
echo    5. Deploy the API to Cloudflare Workers
echo    6. Update the Flutter app with the live URL
echo.
echo  You need a FREE Cloudflare account.
echo  Sign up at: https://cloudflare.com (takes 1 min)
echo.
pause

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0deploy.ps1"
