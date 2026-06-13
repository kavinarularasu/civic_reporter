@echo off
REM Appium Testing Quick Start Script for Windows

echo ==========================================
echo CIVIC REPORTER - APPIUM QUICK START
echo ==========================================
echo.

REM Check prerequisites
echo 🔍 Checking prerequisites...
python setup_verification.py

echo.
echo ==========================================
echo STARTING APPIUM SERVER...
echo ==========================================
echo Server will run on: http://localhost:4723
echo.
echo ⏳ Appium will start in new window...
echo Press Ctrl+C to stop the server
echo.

REM Start Appium server
appium

pause
