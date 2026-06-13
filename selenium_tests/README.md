# Civic Reporter — Selenium Web Test Suite

End-to-end web test automation for the **Civic Reporter** Flutter web application.

---

## 📁 Folder Structure

```
selenium_tests/
├── config.py                        # Web locators (flt-semantics), settings
├── base_test.py                     # Chrome setup, Flutter semantics enablement
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
├── test_07_officer_portal.py        # TC71–TC86   Officer Portal
├── test_08_end_to_end.py            # E2E01–E2E14 Full Journey
│
├── report_generator.py              # Excel report builder
├── run_all_tests.py                 # Master CLI runner
├── run_tests.bat                    # One-click Windows launcher
│
└── reports/                         # Auto-created at runtime
    ├── Civic_Reporter_Selenium_Complete_Report.xlsx # Excel report
    ├── pytest_report_<ts>.html      # HTML report
    └── screenshots/                 # PNG per test (on failure)
```

---

## ⚙️ Setup

### 1. Requirements
- Python 3.9+
- Google Chrome browser

### 2. Install Dependencies
```bash
cd selenium_tests
pip install -r requirements.txt
```

### 3. Run Web App Locally
In another terminal, serve the Flutter web build:
```bash
cd ../build/web
python -m http.server 5000
```

---

## 🚀 Running Tests

**One-Click Windows:**
```
Double-click run_tests.bat
```

**CLI Runners:**
```bash
python run_all_tests.py            # All 100 tests
python run_all_tests.py --e2e      # Only end-to-end flow
python run_all_tests.py --retry 1  # Auto-retry failures
```
