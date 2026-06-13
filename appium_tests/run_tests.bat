@echo off
REM ═══════════════════════════════════════════════════════════════
REM  Civic Reporter — Appium E2E Test Launcher (Windows)
REM  Usage:
REM    run_tests.bat               → full suite
REM    run_tests.bat --module 01   → single module
REM    run_tests.bat --e2e         → E2E only
REM    run_tests.bat --install     → install deps first
REM ═══════════════════════════════════════════════════════════════
title Civic Reporter Appium Tests
color 1F

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║       CIVIC REPORTER  —  APPIUM E2E TEST SUITE          ║
echo  ║              Android Mobile Automation                   ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

REM ── Move to the directory containing this script ─────────────
cd /d "%~dp0"

REM ── Create reports folder ────────────────────────────────────
if not exist "reports" mkdir reports
if not exist "reports\screenshots" mkdir reports\screenshots

REM ── Check Python availability ────────────────────────────────
where python >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python not found on PATH. Please install Python 3.9+
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  Python: %%v

REM ── Activate virtual environment if present ──────────────────
if exist "..\venv\Scripts\activate.bat" (
    echo  Activating venv...
    call "..\venv\Scripts\activate.bat"
) else if exist "..\..\.venv\Scripts\activate.bat" (
    call "..\..\.venv\Scripts\activate.bat"
) else (
    echo  [INFO] No venv found — using system Python
)

REM ── Install requirements (if --install flag passed) ──────────
set "INSTALL_FLAG="
for %%a in (%*) do (
    if "%%a"=="--install" set "INSTALL_FLAG=1"
)
if defined INSTALL_FLAG (
    echo.
    echo  Installing requirements...
    python -m pip install -r requirements.txt -q
)

REM ── Start Appium Server in background (if not already running) 
echo.
echo  Checking Appium server...
curl -s http://127.0.0.1:4723/status >nul 2>&1
if errorlevel 1 (
    echo  Starting Appium server in background...
    start /min "Appium Server" cmd /c "appium --log reports\appium_server.log --log-level info"
    echo  Waiting 6 seconds for Appium to start...
    timeout /t 6 /nobreak >nul
) else (
    echo  Appium server already running.
)

REM ── Run the tests ─────────────────────────────────────────────
echo.
echo  Launching tests: %*
echo  ─────────────────────────────────────────────────────────
echo.

python run_all_tests.py --skip-preflight %*
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

REM ── Open the latest Excel report automatically ───────────────
for /f "delims=" %%f in ('dir /b /o-d "reports\Civic_Reporter_E2E_*.xlsx" 2^>nul') do (
    echo  Opening report: reports\%%f
    start "" "reports\%%f"
    goto :opened
)
:opened

pause
exit /b %EXIT_CODE%
