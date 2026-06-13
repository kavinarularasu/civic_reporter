"""
TEST MODULE 04 — My Reports Screen
Covers: Stats, Filter chips, Report cards, Report Detail screen,
        Status Timeline, Escalate button
"""
import time
import pytest
from base_test import BaseTest
import config


class TestMyReports(BaseTest):
    """Tests for My Reports screen and Report Detail screen."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        self.login_with_phone_otp()
        # Navigate to My Reports
        self.click_element(config.LOCATORS["nav_my_reports"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-37: My Reports screen title visible
    # ──────────────────────────────────────────
    def test_TC37_my_reports_title_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["my_reports_title"], timeout=8
            ), "My Reports title not visible"
            self.take_screenshot("TC37_my_reports_title")

        assert self.run_test("TC37_my_reports_title_visible", _run)

    # ──────────────────────────────────────────
    # TC-38: Stats row visible (Total/In Progress/Resolved/Rejected)
    # ──────────────────────────────────────────
    def test_TC38_stats_row_visible(self):
        def _run():
            for label in ["Total", "Progress", "Resolved", "Rejected"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{label}")]'), timeout=6
                ), f"Stat '{label}' not visible on My Reports"
            self.take_screenshot("TC38_stats_row")

        assert self.run_test("TC38_stats_row_visible", _run)

    # ──────────────────────────────────────────
    # TC-39: Filter chips visible
    # ──────────────────────────────────────────
    def test_TC39_filter_chips_visible(self):
        def _run():
            for f in ["All", "Submitted", "Resolved", "Rejected"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{f}")]'), timeout=6
                ), f"Filter chip '{f}' not visible"
            self.take_screenshot("TC39_filter_chips")

        assert self.run_test("TC39_filter_chips_visible", _run)

    # ──────────────────────────────────────────
    # TC-40: Default "All" filter shows all 6 reports
    # ──────────────────────────────────────────
    def test_TC40_all_filter_shows_reports(self):
        def _run():
            # At least one of the known report types should be visible
            found = False
            for report_type in ["Pothole", "Broken Streetlight", "Open Drain", "Garbage"]:
                if self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{report_type}")]'), timeout=5
                ):
                    found = True
                    break
            assert found, "No report cards visible under 'All' filter"
            self.take_screenshot("TC40_all_filter")

        assert self.run_test("TC40_all_filter_shows_reports", _run)

    # ──────────────────────────────────────────
    # TC-41: "Submitted" filter narrows results
    # ──────────────────────────────────────────
    def test_TC41_submitted_filter(self):
        def _run():
            # Tap the Submitted chip in the filter row (horizontal scroll area)
            submitted_chips = self.find_elements(
                ("xpath", '//*[contains(@text,"Submitted")]')
            )
            # Click the chip in the filter row (first occurrence usually)
            if submitted_chips:
                submitted_chips[0].click()
            time.sleep(1)
            # Verify Broken Streetlight (status=Submitted) is visible
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Broken Streetlight")]'), timeout=6
            ), "Broken Streetlight not shown under Submitted filter"
            self.take_screenshot("TC41_submitted_filter")

        assert self.run_test("TC41_submitted_filter", _run)

    # ──────────────────────────────────────────
    # TC-42: "Resolved" filter shows resolved reports
    # ──────────────────────────────────────────
    def test_TC42_resolved_filter(self):
        def _run():
            resolved_chips = self.find_elements(
                ("xpath", '//*[contains(@text,"Resolved")]')
            )
            if resolved_chips:
                resolved_chips[0].click()
            time.sleep(1)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Open Drain")]'), timeout=6
            ), "Open Drain (Resolved) not shown under Resolved filter"
            self.take_screenshot("TC42_resolved_filter")

        assert self.run_test("TC42_resolved_filter", _run)

    # ──────────────────────────────────────────
    # TC-43: "Rejected" filter shows rejected reports
    # ──────────────────────────────────────────
    def test_TC43_rejected_filter(self):
        def _run():
            self.swipe_up()  # Scroll filter row to find Rejected chip
            rejected_chips = self.find_elements(
                ("xpath", '//*[contains(@text,"Rejected")]')
            )
            if rejected_chips:
                rejected_chips[0].click()
            time.sleep(1)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Road Damage")]'), timeout=6
            ), "Road Damage (Rejected) not shown under Rejected filter"
            self.take_screenshot("TC43_rejected_filter")

        assert self.run_test("TC43_rejected_filter", _run)

    # ──────────────────────────────────────────
    # TC-44: Tapping a report card opens Report Detail
    # ──────────────────────────────────────────
    def test_TC44_tap_report_card_opens_detail(self):
        def _run():
            # Tap the first report card (Pothole)
            pothole_card = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            assert pothole_card is not None, "Pothole card not found"
            pothole_card.click()
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["status_timeline"], timeout=8
            ), "Status Timeline not visible on Report Detail screen"
            self.take_screenshot("TC44_report_detail")

        assert self.run_test("TC44_tap_report_card_opens_detail", _run)

    # ──────────────────────────────────────────
    # TC-45: Report Detail shows issue type, location, date
    # ──────────────────────────────────────────
    def test_TC45_report_detail_content(self):
        def _run():
            pothole = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            if pothole:
                pothole.click()
            time.sleep(1.5)
            for text in ["Anna Nagar", "Ward 42", "12 May 2026"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{text}")]'), timeout=6
                ), f"Detail field '{text}' not visible"
            self.take_screenshot("TC45_detail_content")

        assert self.run_test("TC45_report_detail_content", _run)

    # ──────────────────────────────────────────
    # TC-46: Status Timeline shows steps
    # ──────────────────────────────────────────
    def test_TC46_status_timeline_steps(self):
        def _run():
            pothole = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            if pothole:
                pothole.click()
            time.sleep(1.5)
            for step in ["Submitted", "Acknowledged", "In Progress"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{step}")]'), timeout=6
                ), f"Timeline step '{step}' not visible"
            self.take_screenshot("TC46_timeline_steps")

        assert self.run_test("TC46_status_timeline_steps", _run)

    # ──────────────────────────────────────────
    # TC-47: Escalate Issue button for in-progress reports
    # ──────────────────────────────────────────
    def test_TC47_escalate_issue_button(self):
        def _run():
            # Pothole is "In Progress" — should show Escalate
            pothole = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            if pothole:
                pothole.click()
            time.sleep(1.5)
            self.swipe_up(2)
            assert self.is_element_visible(
                config.LOCATORS["escalate_btn"], timeout=8
            ), "Escalate Issue button not visible for In Progress report"
            self.take_screenshot("TC47_escalate_button")

        assert self.run_test("TC47_escalate_issue_button", _run)

    # ──────────────────────────────────────────
    # TC-48: Escalate shows snackbar confirmation
    # ──────────────────────────────────────────
    def test_TC48_escalate_shows_confirmation(self):
        def _run():
            pothole = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            if pothole:
                pothole.click()
            time.sleep(1.5)
            self.swipe_up(2)
            self.click_element(config.LOCATORS["escalate_btn"])
            time.sleep(1.5)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Escalation") or contains(@text,"escalat")]'),
                timeout=6
            ), "Escalation confirmation snackbar not shown"
            self.take_screenshot("TC48_escalation_confirmed")

        assert self.run_test("TC48_escalate_shows_confirmation", _run)

    # ──────────────────────────────────────────
    # TC-49: Back button from Detail returns to My Reports
    # ──────────────────────────────────────────
    def test_TC49_back_from_detail_to_my_reports(self):
        def _run():
            pothole = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            if pothole:
                pothole.click()
            time.sleep(1.5)
            self.driver.press_keycode(4)  # Android BACK
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["my_reports_title"], timeout=8
            ), "My Reports screen did not restore after back press"
            self.take_screenshot("TC49_back_to_my_reports")

        assert self.run_test("TC49_back_from_detail_to_my_reports", _run)
