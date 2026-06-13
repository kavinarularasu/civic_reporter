"""
run_all_tests.py — Master Test Runner for Civic Reporter Appium Suite
Usage:
    python run_all_tests.py                     # run all modules
    python run_all_tests.py --module 01         # run only module 01
    python run_all_tests.py --e2e               # run only E2E test
    python run_all_tests.py --module 03 04 07   # run multiple modules
    python run_all_tests.py --retry 2           # retry failed tests up to 2 times
"""

import os
import sys
import subprocess
import argparse
import shutil
import time
from datetime import datetime

# ─── Resolve paths relative to this file ─────────────────────
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
REPORTS_DIR  = os.path.join(SCRIPT_DIR, "reports")
SCREENS_DIR  = os.path.join(REPORTS_DIR, "screenshots")
LOG_FILE     = os.path.join(REPORTS_DIR, "test_execution.log")

# Module map: key → filename
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
ALL_MODULES_ORDER = ["01", "02", "03", "04", "05", "06", "07", "08"]


# ─── Banner ───────────────────────────────────────────────────
def _banner(title: str, char="═", width=62):
    line = char * width
    print(f"\n{line}")
    print(f"  {title}")
    print(f"{line}\n")


# ─── Pre-flight checks ────────────────────────────────────────
def preflight():
    """Verify dependencies, Appium, device connectivity."""
    _banner("🔍  PRE-FLIGHT CHECKS")
    ok = True

    # Python packages
    required = ["appium", "selenium", "pytest", "openpyxl"]
    for pkg in required:
        try:
            __import__(pkg.replace("-", "_"))
            print(f"  ✅  {pkg}")
        except ImportError:
            print(f"  ❌  {pkg} — NOT INSTALLED  → pip install {pkg}")
            ok = False

    # ADB reachable
    try:
        result = subprocess.run(
            ["adb", "devices"],
            capture_output=True, text=True, timeout=8
        )
        lines  = [l for l in result.stdout.splitlines() if "device" in l and "List" not in l]
        if lines:
            print(f"  ✅  ADB device: {lines[0].split()[0]}")
        else:
            print("  ⚠️   No ADB device detected — tests will fail if no device/emulator connected")
    except FileNotFoundError:
        print("  ⚠️   adb not found — ensure Android SDK platform-tools is on PATH")
    except subprocess.TimeoutExpired:
        print("  ⚠️   ADB timed out")

    # Appium server (HTTP ping)
    try:
        import urllib.request
        sys.path.insert(0, SCRIPT_DIR)
        import config as cfg
        url  = f"http://{cfg.APPIUM_HOST}:{cfg.APPIUM_PORT}/status"
        resp = urllib.request.urlopen(url, timeout=4)
        if resp.status == 200:
            print(f"  ✅  Appium server reachable at {cfg.APPIUM_URL}")
        else:
            print(f"  ❌  Appium server returned HTTP {resp.status}")
            ok = False
    except Exception as e:
        print(f"  ❌  Appium server NOT reachable — start it with: appium  ({e})")
        ok = False

    return ok


# ─── Install requirements ─────────────────────────────────────
def install_deps():
    req = os.path.join(SCRIPT_DIR, "requirements.txt")
    if not os.path.exists(req):
        print("requirements.txt not found, skipping install.")
        return
    _banner("📦  INSTALLING REQUIREMENTS")
    subprocess.run(
        [sys.executable, "-m", "pip", "install", "-r", req, "--quiet"],
        check=False
    )
    print("  Done.\n")


# ─── Build pytest command ─────────────────────────────────────
def _build_cmd(test_files: list[str], extra_args: list[str]) -> list[str]:
    ts      = datetime.now().strftime("%Y%m%d_%H%M%S")
    html_rp = os.path.join(REPORTS_DIR, f"pytest_report_{ts}.html")

    cmd = [
        sys.executable, "-m", "pytest",
        *test_files,
        "-v",
        "--tb=short",
        f"--html={html_rp}",
        "--self-contained-html",
        "-p", "no:warnings",
        *extra_args,
    ]
    return cmd


# ─── Run tests ────────────────────────────────────────────────
def run_tests(modules: list[str], retry: int = 0, extra: list[str] = None):
    os.makedirs(REPORTS_DIR, exist_ok=True)
    os.makedirs(SCREENS_DIR, exist_ok=True)

    test_files = [
        os.path.join(SCRIPT_DIR, MODULE_MAP[m])
        for m in modules
        if m in MODULE_MAP and os.path.exists(os.path.join(SCRIPT_DIR, MODULE_MAP[m]))
    ]

    if not test_files:
        print("❌  No test files found for the requested modules.")
        return 1

    _banner(f"🚀  RUNNING MODULES: {', '.join(modules)}")
    for f in test_files:
        print(f"   📄  {os.path.basename(f)}")
    print()

    extra_args = list(extra or [])
    if retry > 0:
        # pytest-rerunfailures syntax
        extra_args += ["--reruns", str(retry), "--reruns-delay", "3"]

    cmd       = _build_cmd(test_files, extra_args)
    start     = time.time()
    result    = subprocess.run(cmd, cwd=SCRIPT_DIR)
    elapsed   = time.time() - start

    _banner(f"⏱   Finished in {elapsed:.1f}s — Exit code: {result.returncode}")
    return result.returncode


# ─── Pretty summary from log ──────────────────────────────────
def _print_summary():
    _banner("📊  LATEST EXCEL REPORT")
    try:
        reports = [
            f for f in os.listdir(REPORTS_DIR)
            if f.endswith(".xlsx") and "Civic_Reporter" in f
        ]
        if reports:
            latest = sorted(reports)[-1]
            print(f"  📂  {os.path.join(REPORTS_DIR, latest)}\n")
        else:
            print("  (no Excel report found yet)\n")
    except Exception:
        pass


# ─── Main ─────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Civic Reporter Appium Test Runner",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "--module", nargs="+", metavar="N",
        help="Run specific module(s), e.g. --module 01 03 07"
    )
    parser.add_argument(
        "--e2e", action="store_true",
        help="Run only the full E2E test (module 08)"
    )
    parser.add_argument(
        "--all", action="store_true", default=True,
        help="Run all modules (default)"
    )
    parser.add_argument(
        "--retry", type=int, default=0, metavar="N",
        help="Retry failed tests N times (requires pytest-rerunfailures)"
    )
    parser.add_argument(
        "--skip-preflight", action="store_true",
        help="Skip pre-flight environment checks"
    )
    parser.add_argument(
        "--install", action="store_true",
        help="Install requirements before running"
    )
    parser.add_argument(
        "--no-e2e", action="store_true",
        help="Run all modules EXCEPT the E2E test (08)"
    )
    args = parser.parse_args()

    _banner("🏙️   CIVIC REPORTER — APPIUM E2E TEST SUITE", "═", 62)
    print(f"  Started : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  Python  : {sys.executable}")
    print(f"  Reports : {REPORTS_DIR}\n")

    if args.install:
        install_deps()

    if not args.skip_preflight:
        if not preflight():
            print("\n❌  Pre-flight failed. Fix the issues above and retry.")
            print("    To skip checks: python run_all_tests.py --skip-preflight\n")
            sys.exit(1)
    else:
        print("⚠️   Pre-flight checks SKIPPED.\n")

    # Decide which modules to run
    if args.e2e:
        modules = ["08"]
    elif args.module:
        modules = [m.zfill(2) for m in args.module]
    elif args.no_e2e:
        modules = [m for m in ALL_MODULES_ORDER if m != "08"]
    else:
        modules = ALL_MODULES_ORDER

    exit_code = run_tests(modules, retry=args.retry)
    _print_summary()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
