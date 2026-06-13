@echo off
REM ═══════════════════════════════════════════════════════════════
REM  Civic Reporter — Selenium Web Test Launcher (Windows)
REM  Usage:
REM    run_tests.bat               → full suite
REM    run_tests.bat --module 01   → single module
REM    run_tests.bat --e2e         → E2E only
REM    run_tests.bat --install     → install deps first
REM ═══════════════════════════════════════════════════════════════
title Civic Reporter Selenium Tests
color 1F

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║      CIVIC REPORTER  —  SELENIUM E2E TEST SUITE         ║
echo  ║                   Flutter Web App                        ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0"
if not exist "reports" mkdir reports
if not exist "reports\screenshots" mkdir reports\screenshots

where python >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python not found on PATH.
    pause
    exit /b 1
)

set "INSTALL_FLAG="
for %%a in (%*) do (
    if "%%a"=="--install" set "INSTALL_FLAG=1"
)
if defined INSTALL_FLAG (
    echo  Installing requirements...
    python -m pip install -r requirements.txt -q
)

echo  Launching Selenium tests: %*
echo  ─────────────────────────────────────────────────────────

python run_all_tests.py %*
set EXIT_CODE=%errorlevel%

echo.
if %EXIT_CODE%==0 (
    echo  ╔══════════════════════════════════╗
    echo  ║   ALL TESTS PASSED  ✅           ║
    echo  ╚══════════════════════════════════╝
) else (
    echo  ╔══════════════════════════════════╗
    echo  ║   SOME TESTS FAILED  ❌          ║
    echo  ╚══════════════════════════════════╝
)

echo.
echo  Reports saved to: %~dp0reports\
echo.

for /f "delims=" %%f in ('dir /b /o-d "reports\Civic_Reporter_Selenium_E2E_*.xlsx" 2^>nul') do (
    echo  Opening report: reports\%%f
    start "" "reports\%%f"
    goto :opened
)
:opened

pause
exit /b %EXIT_CODE%
