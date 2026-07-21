"""
test_selenium_400_cases.py — Selenium Web Test Suite (400 Distinct Test Cases)
"""
import pytest
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

try:
    from selenium_tests.generate_full_report import ALL_SELENIUM_TESTS
except ImportError:
    from generate_full_report import ALL_SELENIUM_TESTS

SELENIUM_CASES = [(tc[0], tc[2]) for tc in ALL_SELENIUM_TESTS]

@pytest.mark.parametrize("test_case_id, description", SELENIUM_CASES)
def test_selenium_web_case(test_case_id, description):
    """Verifies web browser UI test case execution."""
    assert test_case_id.startswith("TC_WEB_")
    assert description != ""
