@echo off
REM ══════════════════════════════════════════════════════════
REM  Civic Reporter — Baseline / Load Test Runner (Windows)
REM  100 users | 1 minute | Results exported to Excel
REM ══════════════════════════════════════════════════════════
setlocal

echo.
echo ============================================================
echo   CIVIC REPORTER — BASELINE LOAD TEST
echo   100 Virtual Users ^| 1 Minute ^| Excel Report
echo ============================================================
echo.

REM ── Step 1: install dependencies ──────────────────────────
echo [1/3] Installing dependencies ...
pip install -r "%~dp0requirements.txt" -q
if errorlevel 1 (
    echo ERROR: pip install failed. Make sure Python is in PATH.
    pause & exit /b 1
)
echo       Done.
echo.

REM ── Step 2: Make sure Firebase is serving the app ─────────
echo [2/3] NOTE: Make sure your Flutter web app is running at
echo       http://localhost:5000 (firebase serve) or update
echo       BASE_URL environment variable before running.
echo.

REM ── Step 3: run the load test ─────────────────────────────
echo [3/3] Starting load test (this will take ~1 minute) ...
echo.
set BASE_URL=http://localhost:5000
python "%~dp0run_load_test.py"
if errorlevel 1 (
    echo.
    echo ERROR: Load test failed. Check output above for details.
    pause & exit /b 1
)

echo.
echo ============================================================
echo  DONE! Check load_tests\reports\ for your Excel report.
echo ============================================================
echo.
pause
