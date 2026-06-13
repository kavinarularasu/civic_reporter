"""TEST MODULE 02 — Home Dashboard (TC11-TC22)"""
import time
import pytest
from base_test import BaseTest
import config


class TestHomeDashboard(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        self.login_with_phone_otp()
        yield
        self.teardown_driver()

    def test_TC11_home_title_and_ward_visible(self):
        def _run():
            assert self.page_contains("Civic Reporter"), "Home title missing"
            assert self.page_contains("Ward 42"), "Ward text missing"
            self.take_screenshot("TC11_home_title")
        assert self.run_test("TC11_home_title_and_ward_visible", _run)

    def test_TC12_stats_cards_visible(self):
        def _run():
            for label in ["Total", "Resolved"]:
                assert self.page_contains(label), f"Stat '{label}' missing"
            self.take_screenshot("TC12_stats_cards")
        assert self.run_test("TC12_stats_cards_visible", _run)

    def test_TC13_quick_report_section_visible(self):
        def _run():
            assert self.page_contains("Quick Report"), "Quick Report section missing"
            for cat in ["Pothole", "Streetlight", "Drain", "Garbage"]:
                assert self.page_contains(cat), f"Quick Report '{cat}' missing"
            self.take_screenshot("TC13_quick_report")
        assert self.run_test("TC13_quick_report_section_visible", _run)

    def test_TC14_recent_reports_section_visible(self):
        def _run():
            assert self.page_contains("Recent Reports"), "Recent Reports missing"
            assert self.page_contains("See All"), "See All button missing"
            self.take_screenshot("TC14_recent_reports")
        assert self.run_test("TC14_recent_reports_section_visible", _run)

    def test_TC15_recent_report_cards_content(self):
        def _run():
            found = any(self.page_contains(t) for t in ["Pothole", "Broken Streetlight", "Open Drain"])
            assert found, "No report cards visible in Recent Reports"
            self.take_screenshot("TC15_report_cards")
        assert self.run_test("TC15_recent_report_cards_content", _run)

    def test_TC16_report_issue_fab_visible(self):
        def _run():
            assert self.page_contains("Report Issue"), "Report Issue FAB missing"
            self.take_screenshot("TC16_fab_visible")
        assert self.run_test("TC16_report_issue_fab_visible", _run)

    def test_TC17_fab_opens_report_issue_screen(self):
        def _run():
            self.click_element(config.LOCATORS["report_issue_fab"])
            time.sleep(1.5)
            assert self.page_contains("Report an Issue"), "Report Issue screen not opened"
            self.browser_back()
            self.take_screenshot("TC17_fab_click")
        assert self.run_test("TC17_fab_opens_report_issue_screen", _run)

    def test_TC18_notification_bell_opens_notifications(self):
        def _run():
            self.click_element(config.LOCATORS["notification_btn"])
            time.sleep(1.5)
            assert self.page_contains("Notifications"), "Notifications screen not opened"
            self.browser_back()
            self.take_screenshot("TC18_notifications")
        assert self.run_test("TC18_notification_bell_opens_notifications", _run)

    def test_TC19_bottom_nav_my_reports(self):
        def _run():
            self.click_element(config.LOCATORS["nav_my_reports"])
            time.sleep(1.5)
            assert self.page_contains("My Reports"), "My Reports screen not opened"
            self.take_screenshot("TC19_nav_my_reports")
        assert self.run_test("TC19_bottom_nav_my_reports", _run)

    def test_TC20_bottom_nav_map(self):
        def _run():
            self.click_element(config.LOCATORS["nav_map"])
            time.sleep(1.5)
            assert self.page_contains("Area Map") or self.page_contains("Ward 42"), \
                "Map screen not opened"
            self.take_screenshot("TC20_nav_map")
        assert self.run_test("TC20_bottom_nav_map", _run)

    def test_TC21_bottom_nav_profile(self):
        def _run():
            self.click_element(config.LOCATORS["nav_profile"])
            time.sleep(1.5)
            assert self.page_contains("My Profile"), "Profile screen not opened"
            self.take_screenshot("TC21_nav_profile")
        assert self.run_test("TC21_bottom_nav_profile", _run)

    def test_TC22_bottom_nav_home_returns(self):
        def _run():
            self.click_element(config.LOCATORS["nav_map"])
            time.sleep(1)
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1.5)
            assert self.page_contains("Quick Report") or self.page_contains("Recent Reports"), \
                "Home not restored"
            self.take_screenshot("TC22_nav_home")
        assert self.run_test("TC22_bottom_nav_home_returns", _run)
