"""
conftest.py — Pytest hooks for result collection and Excel report generation
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import pytest
from datetime import datetime
try:
    from report_generator import ExcelReportGenerator
except ImportError:
    from appium_tests.report_generator import ExcelReportGenerator
import config


# ─────────────────────────────────────────────
# Session-level storage for results
# ─────────────────────────────────────────────
_session_results: list = []
_session_start:   str  = ""


def pytest_configure(config):
    """Called before test collection — record start time."""
    global _session_start
    _session_start = datetime.now().strftime("%Y-%m-%d %H:%M:%S")


# ─────────────────────────────────────────────
# Hook: capture per-test result
# ─────────────────────────────────────────────
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep     = outcome.get_result()

    if rep.when == "call":
        status = "PASSED" if rep.passed else ("FAILED" if rep.failed else "SKIPPED")

        # Safely extract error details
        details = ""
        if rep.longrepr:
            try:
                details = str(rep.longrepr.reprcrash.message)
            except AttributeError:
                details = str(rep.longrepr)[:500]

        # Pull screenshot path if test instance stored one
        screenshot = ""
        instance   = getattr(item, "_testcase", None) or getattr(item, "instance", None)
        if instance and hasattr(instance, "test_results"):
            for r in reversed(instance.test_results):
                if r.get("test_name", "") in item.nodeid:
                    screenshot = r.get("screenshot", "")
                    break

        _session_results.append({
            "test_name":  item.nodeid.split("::")[-1],
            "status":     status,
            "timestamp":  datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "details":    details,
            "screenshot": screenshot,
        })


# ─────────────────────────────────────────────
# Hook: generate report after all tests finish
# ─────────────────────────────────────────────
def pytest_sessionfinish(session, exitstatus):
    if not _session_results:
        return

    os.makedirs(config.REPORT_DIR, exist_ok=True)
    ts       = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"Civic_Reporter_E2E_{ts}.xlsx"

    try:
        gen  = ExcelReportGenerator(output_dir=config.REPORT_DIR)
        path = gen.generate_report(
            test_results=_session_results,
            filename=filename,
            device_info={
                "device":  config.ANDROID_DEVICE_NAME,
                "version": config.ANDROID_PLATFORM_VERSION,
            }
        )
        print(f"\n\n{'='*60}")
        print(f"  Excel Report Generated:")
        print(f"     {path}")
        print(f"  Total Tests: {len(_session_results)}")
        passed  = sum(1 for r in _session_results if r["status"] == "PASSED")
        failed  = sum(1 for r in _session_results if r["status"] == "FAILED")
        skipped = sum(1 for r in _session_results if r["status"] == "SKIPPED")
        rate    = round(passed / len(_session_results) * 100, 2) if _session_results else 0
        print(f"  Passed  : {passed}")
        print(f"  Failed  : {failed}")
        print(f"  Skipped : {skipped}")
        print(f"  Pass Rate: {rate}%")
        print(f"{'='*60}\n")
    except Exception as e:
        print(f"\n[WARN] Could not generate Excel report: {e}")


# ─────────────────────────────────────────────
# Shared fixtures
# ─────────────────────────────────────────────
@pytest.fixture(scope="session")
def device_info():
    """Return device info dict for tests that need it."""
    return {
        "device":  config.ANDROID_DEVICE_NAME,
        "version": config.ANDROID_PLATFORM_VERSION,
    }

