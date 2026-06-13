"""
Utility script to capture screenshots and element locators
"""
import subprocess
import os
import time
from datetime import datetime


def capture_screenshot():
    """Capture screenshot from connected device"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshot_name = f"screenshot_{timestamp}.png"
    screenshot_path = os.path.join("reports", screenshot_name)
    
    os.makedirs("reports", exist_ok=True)
    
    try:
        subprocess.run([
            "adb", "shell", "screencap", "-p",
            f"/sdcard/{screenshot_name}"
        ], check=True)
        
        subprocess.run([
            "adb", "pull",
            f"/sdcard/{screenshot_name}",
            screenshot_path
        ], check=True)
        
        print(f"✓ Screenshot saved: {screenshot_path}")
        return screenshot_path
    except Exception as e:
        print(f"✗ Failed to capture screenshot: {str(e)}")
        return None


def dump_ui_hierarchy():
    """Dump UI hierarchy for locator identification"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dump_name = f"ui_hierarchy_{timestamp}.xml"
    dump_path = os.path.join("reports", dump_name)
    
    os.makedirs("reports", exist_ok=True)
    
    try:
        print("Dumping UI hierarchy...")
        subprocess.run([
            "adb", "shell", "uiautomator", "dump", "/sdcard/dump.xml"
        ], check=True)
        
        time.sleep(1)
        
        subprocess.run([
            "adb", "pull", "/sdcard/dump.xml", dump_path
        ], check=True)
        
        print(f"✓ UI hierarchy saved: {dump_path}")
        
        # Display first 100 lines
        with open(dump_path, 'r') as f:
            lines = f.readlines()[:100]
            print("\nUI Hierarchy (first 100 lines):")
            for line in lines:
                print(line.rstrip())
        
        return dump_path
    except Exception as e:
        print(f"✗ Failed to dump UI hierarchy: {str(e)}")
        return None


def list_installed_packages():
    """List installed packages on device"""
    try:
        result = subprocess.run(
            ["adb", "shell", "pm", "list", "packages"],
            capture_output=True,
            text=True,
            check=True
        )
        
        packages = result.stdout.strip().split('\n')
        civic_reporter_packages = [p for p in packages if 'civic' in p.lower()]
        
        print(f"✓ Total packages installed: {len(packages)}")
        print(f"✓ Civic Reporter packages: {civic_reporter_packages}")
        
        return civic_reporter_packages
    except Exception as e:
        print(f"✗ Failed to list packages: {str(e)}")
        return []


def get_device_info():
    """Get device information"""
    try:
        print("\n📱 Device Information:")
        
        # Device name
        result = subprocess.run(
            ["adb", "shell", "getprop", "ro.product.model"],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"Model: {result.stdout.strip()}")
        
        # Android version
        result = subprocess.run(
            ["adb", "shell", "getprop", "ro.build.version.release"],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"Android Version: {result.stdout.strip()}")
        
        # Screen size
        result = subprocess.run(
            ["adb", "shell", "wm", "size"],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"Screen Size: {result.stdout.strip()}")
        
    except Exception as e:
        print(f"✗ Failed to get device info: {str(e)}")


def main():
    """Main utility menu"""
    print("=" * 60)
    print("APPIUM TEST UTILITIES")
    print("=" * 60)
    print()
    
    options = {
        "1": ("Capture Screenshot", capture_screenshot),
        "2": ("Dump UI Hierarchy", dump_ui_hierarchy),
        "3": ("List Packages", list_installed_packages),
        "4": ("Get Device Info", get_device_info),
        "5": ("All of the above", None),
    }
    
    print("Available utilities:")
    for key, (desc, _) in options.items():
        print(f"{key}. {desc}")
    print("0. Exit")
    print()
    
    choice = input("Select option: ").strip()
    
    if choice == "0":
        print("Goodbye!")
        return
    
    if choice == "5":
        capture_screenshot()
        dump_ui_hierarchy()
        list_installed_packages()
        get_device_info()
    elif choice in options:
        desc, func = options[choice]
        if func:
            func()
    else:
        print("Invalid option")


if __name__ == "__main__":
    main()
