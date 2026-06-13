"""
Quick setup and validation script for Appium testing
"""
import os
import subprocess
import sys
import platform


def check_python_version():
    """Check Python version"""
    version = sys.version_info
    print(f"✓ Python Version: {version.major}.{version.minor}.{version.micro}")
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("✗ Python 3.8+ required")
        return False
    return True


def check_java():
    """Check Java installation"""
    try:
        result = subprocess.run(["java", "-version"], capture_output=True, text=True)
        print("✓ Java is installed")
        return True
    except:
        print("✗ Java not found. Install Java SDK first")
        return False


def check_adb():
    """Check Android Debug Bridge"""
    try:
        result = subprocess.run(["adb", "version"], capture_output=True, text=True)
        print("✓ ADB is installed")
        return True
    except:
        print("✗ ADB not found. Install Android SDK")
        return False


def list_devices():
    """List connected Android devices"""
    try:
        result = subprocess.run(["adb", "devices"], capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')[1:]
        if lines:
            print("\n📱 Connected Devices:")
            for line in lines:
                if line.strip():
                    print(f"   {line}")
            return True
        else:
            print("⚠ No devices connected")
            return False
    except Exception as e:
        print(f"✗ Error listing devices: {str(e)}")
        return False


def check_appium():
    """Check Appium installation"""
    try:
        result = subprocess.run(["appium", "--version"], capture_output=True, text=True)
        print(f"✓ Appium is installed")
        return True
    except:
        print("✗ Appium not found. Install with: npm install -g appium")
        return False


def check_dependencies():
    """Check Python dependencies"""
    try:
        import appium
        import pytest
        import openpyxl
        from selenium import webdriver
        print("✓ Python dependencies installed")
        return True
    except ImportError as e:
        print(f"✗ Missing dependency: {str(e)}")
        print("   Run: pip install -r requirements.txt")
        return False


def install_dependencies():
    """Install Python dependencies"""
    print("\n📦 Installing Python dependencies...")
    try:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "-r", "requirements.txt"],
            check=True
        )
        print("✓ Dependencies installed successfully")
        return True
    except:
        print("✗ Failed to install dependencies")
        return False


def main():
    """Run all checks"""
    print("=" * 60)
    print("CIVIC REPORTER - APPIUM SETUP VERIFICATION")
    print("=" * 60)
    print()
    
    checks = [
        ("Python Version", check_python_version),
        ("Java", check_java),
        ("ADB (Android Tools)", check_adb),
        ("Appium Server", check_appium),
        ("Python Dependencies", check_dependencies),
    ]
    
    results = {}
    for check_name, check_func in checks:
        print(f"\n🔍 Checking {check_name}...")
        try:
            results[check_name] = check_func()
        except Exception as e:
            print(f"✗ Error: {str(e)}")
            results[check_name] = False
    
    # List devices
    print(f"\n🔍 Checking Connected Devices...")
    list_devices()
    
    # Summary
    print("\n" + "=" * 60)
    print("SETUP SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for check_name, result in results.items():
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status}: {check_name}")
    
    print(f"\n{passed}/{total} checks passed")
    
    if passed < total:
        print("\n⚠️  Some prerequisites are missing. Please install them first.")
        print("\nNext Steps:")
        print("1. Install missing dependencies above")
        print("2. Ensure Android device is connected and adb is detected")
        print("3. Start Appium server: appium")
        print("4. Run tests: python run_tests.py")
    else:
        print("\n✅ All prerequisites satisfied!")
        print("\nNext Steps:")
        print("1. Ensure Android device is connected")
        print("2. Start Appium server: appium")
        print("3. Run tests: python run_tests.py")


if __name__ == "__main__":
    main()
