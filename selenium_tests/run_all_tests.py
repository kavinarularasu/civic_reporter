"""
run_all_tests.py — Master Test Runner for Civic Reporter Selenium Web Suite
"""
import os
import sys
import subprocess
import argparse
import time
from datetime import datetime

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
REPORTS_DIR  = os.path.join(SCRIPT_DIR, "reports")
SCREENS_DIR  = os.path.join(REPORTS_DIR, "screenshots")

MODULE_MAP = {
    "01": "test_01_splash_login.py",
    "02": "test_02_home_dashboard.py",
    "03": "test_03_report_issue.py",
    "04": "test_04_my_reports.py",
    "05": "test_05_map_screen.py",
    "06": "test_06_profile_notifications.py",
    "07": "test_07_officer_portal.py",
    "08": "test_08_end_to_end.py",
}
ALL_MODULES = ["01", "02", "03", "04", "05", "06", "07", "08"]

def _banner(title: str, char="═", width=62):
    line = char * width
    print(f"\n{line}")
    print(f"  {title}")
    print(f"{line}\n")

def run_tests(modules: list, retry: int = 0):
    os.makedirs(REPORTS_DIR, exist_ok=True)
    os.makedirs(SCREENS_DIR, exist_ok=True)

    test_files = [os.path.join(SCRIPT_DIR, MODULE_MAP[m]) for m in modules if m in MODULE_MAP]
    if not test_files:
        print("❌  No test files found for the requested modules.")
        return 1

    _banner(f"🚀  RUNNING SELENIUM MODULES: {', '.join(modules)}")
    
    ts      = datetime.now().strftime("%Y%m%d_%H%M%S")
    html_rp = os.path.join(REPORTS_DIR, f"pytest_report_{ts}.html")

    cmd = [
        sys.executable, "-m", "pytest",
        *test_files,
        "-v",
        "--tb=short",
        f"--html={html_rp}",
        "--self-contained-html",
        "-p", "no:warnings"
    ]
    if retry > 0:
        cmd += ["--reruns", str(retry), "--reruns-delay", "3"]

    start = time.time()
    result = subprocess.run(cmd, cwd=SCRIPT_DIR)
    elapsed = time.time() - start

    _banner(f"⏱   Finished in {elapsed:.1f}s — Exit code: {result.returncode}")
    return result.returncode

def main():
    parser = argparse.ArgumentParser(description="Civic Reporter Selenium Test Runner")
    parser.add_argument("--module", nargs="+", help="Run specific module(s)")
    parser.add_argument("--e2e", action="store_true", help="Run only the E2E test")
    parser.add_argument("--retry", type=int, default=0, help="Retry failed tests")
    args = parser.parse_args()

    if args.e2e:
        modules = ["08"]
    elif args.module:
        modules = [m.zfill(2) for m in args.module]
    else:
        modules = ALL_MODULES

    exit_code = run_tests(modules, retry=args.retry)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
