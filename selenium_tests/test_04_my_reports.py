"""TEST MODULE 04 — My Reports (TC37-TC49)"""
import time
import pytest
from base_test import BaseTest
import config


class TestMyReports(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        self.login_with_phone_otp()
        time.sleep(1)
        self.click_element(config.LOCATORS["nav_my_reports"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    def test_TC37_my_reports_title_visible(self):
        def _run():
            assert self.page_contains("My Reports"), "Title missing"
            self.take_screenshot("TC37_my_reports_title")
        assert self.run_test("TC37_my_reports_title_visible", _run)

    def test_TC38_stats_row_visible(self):
        def _run():
            for s in ["Total", "Progress", "Resolved", "Rejected"]:
                assert self.page_contains(s), f"Stat '{s}' missing"
            self.take_screenshot("TC38_stats_row")
        assert self.run_test("TC38_stats_row_visible", _run)

    def test_TC39_filter_chips_visible(self):
        def _run():
            for f in ["All", "Submitted", "Resolved", "Rejected"]:
                assert self.page_contains(f), f"Filter '{f}' missing"
            self.take_screenshot("TC39_filter_chips")
        assert self.run_test("TC39_filter_chips_visible", _run)

    def test_TC40_all_filter_shows_reports(self):
        def _run():
            self.click_element(config.LOCATORS["filter_all"])
            time.sleep(1)
            assert self.page_contains("Pothole") or self.page_contains("Drain"), \
                "No reports visible under All"
            self.take_screenshot("TC40_all_filter")
        assert self.run_test("TC40_all_filter_shows_reports", _run)

    def test_TC41_submitted_filter(self):
        def _run():
            self.click_element(config.LOCATORS["filter_submitted"])
            time.sleep(1)
            self.take_screenshot("TC41_submitted_filter")
            assert True
        assert self.run_test("TC41_submitted_filter", _run)

    def test_TC42_resolved_filter(self):
        def _run():
            self.click_element(config.LOCATORS["filter_resolved"])
            time.sleep(1)
            self.take_screenshot("TC42_resolved_filter")
            assert True
        assert self.run_test("TC42_resolved_filter", _run)

    def test_TC43_rejected_filter(self):
        def _run():
            self.click_element(config.LOCATORS["filter_rejected"])
            time.sleep(1)
            self.take_screenshot("TC43_rejected_filter")
            assert True
        assert self.run_test("TC43_rejected_filter", _run)

    def test_TC44_tap_report_card_opens_detail(self):
        def _run():
            self.click_element(config.LOCATORS["filter_all"])
            time.sleep(1)
            # Find and click the first report card (by its ward or text)
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            assert self.page_contains("Status Timeline"), "Detail screen not opened"
            self.browser_back()
            self.take_screenshot("TC44_open_detail")
        assert self.run_test("TC44_tap_report_card_opens_detail", _run)

    def test_TC45_report_detail_content(self):
        def _run():
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            assert self.page_contains("Ward 42"), "Ward missing on detail"
            self.take_screenshot("TC45_detail_content")
        assert self.run_test("TC45_report_detail_content", _run)

    def test_TC46_status_timeline_steps(self):
        def _run():
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            for step in ["Submitted", "Acknowledged", "In Progress"]:
                assert self.page_contains(step), f"Timeline step '{step}' missing"
            self.take_screenshot("TC46_timeline")
        assert self.run_test("TC46_status_timeline_steps", _run)

    def test_TC47_escalate_issue_button(self):
        def _run():
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            self.scroll_to_bottom()
            assert self.page_contains("Escalate Issue"), "Escalate button missing"
            self.take_screenshot("TC47_escalate_btn")
        assert self.run_test("TC47_escalate_issue_button", _run)

    def test_TC48_escalate_shows_confirmation(self):
        def _run():
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["escalate_btn"])
            time.sleep(1)
            assert self.page_contains("escalated") or self.page_contains("Success"), \
                "Escalation confirmation missing"
            self.take_screenshot("TC48_escalate_confirm")
        assert self.run_test("TC48_escalate_shows_confirmation", _run)

    def test_TC49_back_from_detail_to_my_reports(self):
        def _run():
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            self.browser_back()
            time.sleep(1)
            assert self.page_contains("My Reports") and self.page_contains("All"), \
                "Did not return to list"
            self.take_screenshot("TC49_back_to_list")
        assert self.run_test("TC49_back_from_detail_to_my_reports", _run)
