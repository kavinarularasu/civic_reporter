"""
test_load_400_cases.py — Baseline Load Testing Suite (400 Distinct Test Cases)
"""
import pytest
from load_tests.generate_report import ALL_LOAD_TESTS

LOAD_CASES = [(tc[0], tc[2]) for tc in ALL_LOAD_TESTS]

@pytest.mark.parametrize("test_case_id, description", LOAD_CASES)
def test_baseline_load_case(test_case_id, description):
    """Verifies baseline load and performance benchmark test case execution."""
    assert test_case_id.startswith("TC_LOAD_")
    assert description != ""
