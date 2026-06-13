# Civic Reporter — Appium E2E Test Suite

Complete end-to-end mobile test automation for the **Civic Reporter** Android application.

---

## 📁 Folder Structure

```
appium_tests/
├── config.py                        # All settings, locators, credentials
├── base_test.py                     # Shared driver setup, helpers, screenshot
├── conftest.py                      # Pytest hooks → auto Excel report
├── pytest.ini                       # Pytest configuration
├── requirements.txt                 # Python dependencies
│
├── test_01_splash_login.py          # TC01–TC10   Splash + Phone/OTP Auth
├── test_02_home_dashboard.py        # TC11–TC22   Home Dashboard
├── test_03_report_issue.py          # TC23–TC36   Report Issue flow
├── test_04_my_reports.py            # TC37–TC49   My Reports + Detail
├── test_05_map_screen.py            # TC50–TC59   Map Screen
├── test_06_profile_notifications.py # TC60–TC70   Profile + Notifications
├── test_07_officer_portal.py        # TC71–TC86   Officer Portal & Dashboard
├── test_08_end_to_end.py            # E2E01–E2E14 Full E2E Journey
│
├── report_generator.py              # Excel report builder (6 sheets + charts)
├── run_all_tests.py                 # Master CLI runner
├── run_tests.bat                    # One-click Windows launcher
│
└── reports/                         # Auto-created at runtime
    ├── Civic_Reporter_E2E_<ts>.xlsx # Rich Excel report
    ├── pytest_report_<ts>.html      # HTML report
    ├── test_execution.log           # Full log
    ├── appium_server.log            # Appium server log
    └── screenshots/                 # PNG per test (on failure)
```

---

## 🧪 Test Coverage — 86 Test Cases

| Module | Tests | Covers |
|--------|-------|--------|
| 01 — Splash & Login | TC01–TC10 | App launch, splash, phone input, OTP flow, logout |
| 02 — Home Dashboard | TC11–TC22 | Stats, Quick Report, Recent Reports, FAB, bottom nav |
| 03 — Report Issue | TC23–TC36 | Photo, category, severity, GPS, description, submit, success |
| 04 — My Reports | TC37–TC49 | Filter chips, report cards, detail screen, timeline, escalate |
| 05 — Map Screen | TC50–TC59 | Layers, legend, stats, FAB, my-location |
| 06 — Profile & Notifs | TC60–TC70 | Profile info, menu, notifications, mark-all-read |
| 07 — Officer Portal | TC71–TC86 | Login, dashboard tabs, queue, action, crew, update, logout |
| 08 — Full E2E | E2E01–E2E14 | Complete citizen + officer user journey in one session |

---

## ⚙️ Prerequisites

### 1. Android SDK / ADB
```
winget install --id Google.AndroidStudio -e   (or download Android Studio)
```
Add `%LOCALAPPDATA%\Android\Sdk\platform-tools` to your PATH.

### 2. Java 11+
```
winget install --id Microsoft.OpenJDK.11
```

### 3. Node.js + Appium
```
winget install OpenJS.NodeJS
npm install -g appium
appium driver install uiautomator2
```

### 4. Python 3.9+
```
winget install Python.Python.3.11
```

### 5. Install Python dependencies
```bash
cd appium_tests
pip install -r requirements.txt
```

---

## 🚀 Running Tests

### Option A — One-Click (Windows)
```
Double-click run_tests.bat
```
Starts Appium automatically, runs all 86 tests, opens Excel report.

### Option B — Python runner (CLI)
```bash
cd appium_tests

# All tests
python run_all_tests.py

# Only E2E journey
python run_all_tests.py --e2e

# Specific modules
python run_all_tests.py --module 01 03 07

# With auto-retry on failure (up to 2 retries)
python run_all_tests.py --retry 2

# Install deps + run all
python run_all_tests.py --install
```

### Option C — Direct pytest
```bash
cd appium_tests

# All tests
pytest -v

# Single module
pytest test_03_report_issue.py -v

# Single test
pytest test_01_splash_login.py::TestSplashAndLogin::test_TC09_successful_otp_login -v
```

---

## 📊 Excel Report (Auto-Generated)

Each test run creates `reports/Civic_Reporter_E2E_<timestamp>.xlsx` with **6 sheets**:

| Sheet | Contents |
|-------|----------|
| 📋 Cover Page | Run metadata, device info, pass-rate summary |
| 📊 Summary | Stats table + Bar chart + Pie chart |
| 📝 Test Results | All 86 results with PASS/FAIL colour coding |
| 📦 Module Analysis | Per-module breakdown + pass-rate bar chart |
| ❌ Failures | Failure-only deep-dive with error details |
| 📸 Screenshots | Index of all captured screenshots with paths |

---

## 🔧 Configuration

Edit `config.py` to match your setup:

```python
ANDROID_DEVICE_NAME   = "emulator-5554"    # adb devices output
ANDROID_PLATFORM_VERSION = "12"            # your Android version
APP_PACKAGE           = "com.civicreporter.civic_reporter"
TEST_PHONE            = "9876543210"       # 10-digit test phone
TEST_OTP              = "123456"           # any 6-digit OTP
OFFICER_ID            = "CMC-WD42-001"
OFFICER_PASS          = "admin1234"
```

---

## 📱 Building the APK

```bash
# From the project root (c:\projects\civic_reporter)
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

The test suite auto-detects the APK path. If the APK is missing, it will assume the app is already installed on the device.

---

## 🐛 Troubleshooting

| Problem | Fix |
|---------|-----|
| `Connection refused 4723` | Run `appium` in a separate terminal |
| `No devices attached` | Run `adb devices` — start emulator or plug in device |
| `App not installed` | Build APK first: `flutter build apk` |
| `Element not found` | Increase `EXPLICIT_WAIT` in `config.py` |
| `SessionNotCreatedException` | Check `APP_PACKAGE` matches installed app |
| Excel file locked | Close any open Excel before re-running |
