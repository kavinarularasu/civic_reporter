# Civic Reporter E2E Testing - Step-by-Step Guide

## 📋 Complete Installation & Execution Guide

### Prerequisites Check
- Windows 10/11, Mac, or Linux
- Internet connection
- Admin access for installations

---

## PART 1: System Setup (30 mins)

### Step 1.1: Install Java SDK
**Required for Android development tools**

1. Download Java SDK 11 or 17 from: https://www.oracle.com/java/technologies/downloads/
2. Run installer with admin rights
3. Verify: Open Command Prompt/Terminal and run:
   ```bash
   java -version
   ```
   Expected output: Java version information

### Step 1.2: Install Android SDK
**Required for ADB and Android development**

**Option A: Android Studio (Recommended)**
1. Download from: https://developer.android.com/studio
2. Run installer
3. Install Android SDK (API 28+)
4. Add to PATH if not automatic

**Option B: Command Line Tools**
1. Download from Android website
2. Extract and add to PATH

**Verify:**
```bash
adb --version
```

### Step 1.3: Install Node.js & npm
**Required for Appium**

1. Download from: https://nodejs.org/ (LTS recommended)
2. Run installer
3. Verify:
   ```bash
   node --version
   npm --version
   ```

### Step 1.4: Install Python 3.9+
**Required for test scripts**

1. Download from: https://www.python.org/downloads/
2. **IMPORTANT**: Check "Add Python to PATH" during installation
3. Verify:
   ```bash
   python --version
   ```

---

## PART 2: Android Device/Emulator Setup (15 mins)

### Option A: Physical Device (Recommended for Testing)
1. Enable USB Debugging:
   - Settings → Developer Options → USB Debugging
2. Connect via USB
3. Allow USB debugging access when prompted
4. Verify:
   ```bash
   adb devices
   ```
   You should see your device listed

### Option B: Android Emulator
1. Open Android Studio
2. Click AVD Manager
3. Create new Virtual Device (Pixel 4, Android 12+)
4. Launch emulator:
   ```bash
   emulator -avd <device_name>
   ```
5. Wait for boot (2-3 minutes)
6. Verify:
   ```bash
   adb devices
   ```

---

## PART 3: Appium Installation (10 mins)

### Step 3.1: Install Appium Server
```bash
npm install -g appium
npm install -g appium-doctor
```

### Step 3.2: Verify Installation
```bash
appium --version
```

### Step 3.3: Check Android Setup
```bash
appium-doctor --android
```
Fix any issues shown ✓

---

## PART 4: Flutter App Build (20 mins)

### Step 4.1: Build APK
```bash
cd c:\projects\civic_reporter

# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release
```

**Output location**: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4.2: Verify APK
```bash
# Check if file exists
dir build\app\outputs\flutter-apk\app-release.apk

# Install on device (optional - Appium does this automatically)
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## PART 5: Appium Test Setup (10 mins)

### Step 5.1: Navigate to Test Directory
```bash
cd c:\projects\civic_reporter\appium_tests
```

### Step 5.2: Install Python Dependencies
```bash
pip install -r requirements.txt
```

Expected packages:
- appium-python-client
- selenium
- pytest
- openpyxl
- pytest-html

### Step 5.3: Verify Setup
```bash
python setup_verification.py
```

Expected output:
```
✓ Python Version: 3.x.x
✓ Java is installed
✓ ADB is installed
✓ Appium is installed
✓ Python dependencies installed
```

---

## PART 6: Configure Tests (5 mins)

### Step 6.1: Update Configuration
Edit `config.py`:

```python
# Line 22-25: Update with your credentials
TEST_EMAIL = "your_test_email@example.com"
TEST_PASSWORD = "your_test_password"

# Line 10-11: Verify app package (if different)
APP_PACKAGE = "com.civicreporter.civic_reporter"
APP_ACTIVITY = ".MainActivity"
```

### Step 6.2: Find Locators
If tests fail to find elements:

1. Run utility:
   ```bash
   python appium_utils.py
   ```
2. Select option 2: "Dump UI Hierarchy"
3. Open generated XML file
4. Update XPath in `config.py` LOCATORS

---

## PART 7: First Test Run

### 📌 Step 7.1: Start Appium Server (Terminal 1)
```bash
cd c:\projects\civic_reporter\appium_tests

# Windows:
start_appium.bat

# Or manual:
appium
```

**Expected output:**
```
Appium Server listening on 127.0.0.1:4723
```

### 📌 Step 7.2: Run Tests (Terminal 2)
```bash
cd c:\projects\civic_reporter\appium_tests

# Run all tests
python run_tests.py

# Or individual test
pytest test_authentication.py -v
```

### 📌 Step 7.3: Monitor Execution
You should see on device:
1. App installs
2. App launches
3. Tests execute (watch login, report creation, etc.)
4. Reports generated

---

## PART 8: View Results

### Check Generated Reports
```bash
# Windows - Open directly
start reports\Test_Results_*.xlsx

# Or check files
dir reports\
```

### Reports Include:
- ✅ Summary sheet (Total, Passed, Failed, Pass Rate)
- ✅ Detailed results (Timestamp, Status, Details)
- ✅ Color-coded results (Green=Pass, Red=Fail)
- ✅ HTML reports with screenshots
- ✅ Execution logs

---

## PART 9: Troubleshooting

### Issue: "Appium not found"
```bash
# Reinstall
npm uninstall -g appium
npm install -g appium
```

### Issue: "No devices found"
```bash
# Check connection
adb devices

# Restart adb
adb kill-server
adb start-server
adb devices
```

### Issue: "App package not found"
```bash
# List installed packages
adb shell pm list packages | grep civic

# Update APP_PACKAGE in config.py
```

### Issue: "Element not found errors"
```bash
# Dump UI hierarchy to find correct XPath
python appium_utils.py
# Select option 2

# Update LOCATORS in config.py with new XPath
```

### Issue: "Test timeout"
In `config.py`, increase `EXPLICIT_WAIT`:
```python
EXPLICIT_WAIT = 20  # Increase from 10
```

---

## PART 10: Continuous Integration (Optional)

### Setup CI/CD Pipeline
Add GitHub Actions workflow: `.github/workflows/e2e-tests.yml`

```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: cd appium_tests && pip install -r requirements.txt
      - run: appium &
      - run: python run_tests.py
      - uses: actions/upload-artifact@v2
        with:
          name: test-reports
          path: appium_tests/reports/
```

---

## 📊 Understanding Excel Report

### Summary Sheet
| Metric | Meaning |
|--------|---------|
| Total Tests | Number of tests executed |
| Passed | Number of successful tests ✓ |
| Failed | Number of failed tests ✗ |
| Skipped | Number of skipped tests |
| Pass Rate (%) | Percentage of passed tests |

### Test Results Sheet
| Column | Information |
|--------|-------------|
| Test # | Test sequence number |
| Test Name | Name of the test |
| Status | PASSED/FAILED/SKIPPED |
| Timestamp | When test ran |
| Details | Error details if failed |

---

## 🔄 Daily Usage Pattern

```bash
# Terminal 1: Start Appium
cd c:\projects\civic_reporter\appium_tests
start_appium.bat

# Wait for "listening on..." message

# Terminal 2: Run Tests
cd c:\projects\civic_reporter\appium_tests
python run_tests.py

# Wait for completion (~5-10 minutes)

# Check Reports
start reports\Test_Results_*.xlsx
```

---

## 📝 Adding New Tests

### Create New Test File
```python
# new_feature_test.py
import pytest
from base_test import BaseTest

class TestNewFeature(BaseTest):
    @pytest.fixture(autouse=True)
    def setup(self):
        self.setup_driver()
        yield
        self.teardown_driver()
    
    def test_new_feature(self):
        # Your test here
        pass
```

### Run New Test
```bash
pytest new_feature_test.py -v
```

---

## ✅ Verification Checklist

Before claiming success:
- [ ] All prerequisites installed
- [ ] Device detected by adb
- [ ] Appium server starts without errors
- [ ] APK built successfully
- [ ] First test runs (test_authentication.py)
- [ ] Excel report generated
- [ ] No errors in test_execution.log

---

## 🎓 Next Steps

1. ✅ Complete all parts above
2. ✅ Run test suite weekly
3. ✅ Add tests for new features
4. ✅ Review failures and fix
5. ✅ Integrate into CI/CD pipeline

---

## 📞 Support Resources

- **Appium Docs**: https://appium.io/docs/
- **Selenium Python**: https://www.selenium.dev/documentation/webdriver/
- **Flutter Testing**: https://flutter.dev/docs/testing
- **Android Testing**: https://developer.android.com/training/testing

---

**Status: Ready for Testing! 🚀**
