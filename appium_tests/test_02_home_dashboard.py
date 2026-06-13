"""
TEST MODULE 02 — Home Dashboard
Covers: Stats cards, Quick Report buttons, Recent Reports list,
        Notification bell, Bottom Navigation Bar
"""
import time
import pytest
from base_test import BaseTest
import config


class TestHomeDashboard(BaseTest):
    """Tests for the main Home Dashboard screen."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        self.login_with_phone_otp()   # Pre-condition: logged in
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-11: Dashboard title and ward text visible
    # ──────────────────────────────────────────
    def test_TC11_home_dashboard_title_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["home_title"], timeout=8
            ), "'Civic Reporter' title not visible on Home"
            assert self.is_element_visible(
                config.LOCATORS["home_ward_text"], timeout=6
            ), "Ward text not visible on Home AppBar"
            self.take_screenshot("TC11_home_title")

        assert self.run_test("TC11_home_dashboard_title_visible", _run)

    # ──────────────────────────────────────────
    # TC-12: Stats cards visible (Total/In Progress/Resolved)
    # ──────────────────────────────────────────
    def test_TC12_stats_cards_visible(self):
        def _run():
            for label in ["Total", "In", "Resolved"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{label}")]'), timeout=6
                ), f"Stat card '{label}' not visible"
            self.take_screenshot("TC12_stats_cards")

        assert self.run_test("TC12_stats_cards_visible", _run)

    # ──────────────────────────────────────────
    # TC-13: Quick Report section and all 4 buttons visible
    # ──────────────────────────────────────────
    def test_TC13_quick_report_buttons_visible(self):
        def _run():
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Quick Report")]'), timeout=6
            ), "Quick Report section title missing"
            for cat in ["Pothole", "Streetlight", "Drain", "Garbage"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{cat}")]'), timeout=5
                ), f"Quick Report button '{cat}' missing"
            self.take_screenshot("TC13_quick_report_btns")

        assert self.run_test("TC13_quick_report_buttons_visible", _run)

    # ──────────────────────────────────────────
    # TC-14: Recent Reports section visible
    # ──────────────────────────────────────────
    def test_TC14_recent_reports_section_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["recent_reports_title"], timeout=6
            ), "Recent Reports section not visible"
            assert self.is_element_visible(
                config.LOCATORS["see_all_btn"], timeout=6
            ), "See All button not visible"
            self.take_screenshot("TC14_recent_reports")

        assert self.run_test("TC14_recent_reports_section_visible", _run)

    # ──────────────────────────────────────────
    # TC-15: Existing report cards visible in list
    # ──────────────────────────────────────────
    def test_TC15_recent_report_cards_content(self):
        def _run():
            for report_type in ["Pothole", "Broken Streetlight", "Open Drain"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{report_type}")]'), timeout=6
                ), f"Report card '{report_type}' not visible"
            self.take_screenshot("TC15_report_cards")

        assert self.run_test("TC15_recent_report_cards_content", _run)

    # ──────────────────────────────────────────
    # TC-16: Report Issue FAB is visible and clickable
    # ──────────────────────────────────────────
    def test_TC16_report_issue_fab_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["report_issue_fab"], timeout=6
            ), "Report Issue FAB not visible"
            self.take_screenshot("TC16_fab_visible")

        assert self.run_test("TC16_report_issue_fab_visible", _run)

    # ──────────────────────────────────────────
    # TC-17: FAB click opens Report Issue screen
    # ──────────────────────────────────────────
    def test_TC17_fab_opens_report_issue_screen(self):
        def _run():
            self.click_element(config.LOCATORS["report_issue_fab"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["report_title"], timeout=8
            ), "Report Issue screen did not open"
            self.driver.press_keycode(4)  # Back
            time.sleep(1)

        assert self.run_test("TC17_fab_opens_report_issue_screen", _run)

    # ──────────────────────────────────────────
    # TC-18: Notification bell navigates to Notifications
    # ──────────────────────────────────────────
    def test_TC18_notification_bell_opens_notifications(self):
        def _run():
            # AppBar notification icon
            bell = self.find_element(
                ("xpath", '//*[@content-desc="notifications_outlined" '
                           'or @content-desc="Notifications"]'),
                timeout=6
            )
            if not bell:
                # Fallback — tap area top-right via coordinates
                size = self.driver.get_window_size()
                self.driver.tap([(int(size["width"] * 0.87), 70)])
            else:
                bell.click()
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["notif_title"], timeout=8
            ), "Notifications screen did not open"
            self.driver.press_keycode(4)
            time.sleep(1)
            self.take_screenshot("TC18_notifications_opened")

        assert self.run_test("TC18_notification_bell_opens_notifications", _run)

    # ──────────────────────────────────────────
    # TC-19: Bottom Nav — My Reports tab
    # ──────────────────────────────────────────
    def test_TC19_bottom_nav_my_reports(self):
        def _run():
            self.click_element(config.LOCATORS["nav_my_reports"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["my_reports_title"], timeout=8
            ), "My Reports screen did not appear"
            self.take_screenshot("TC19_my_reports_tab")

        assert self.run_test("TC19_bottom_nav_my_reports", _run)

    # ──────────────────────────────────────────
    # TC-20: Bottom Nav — Map tab
    # ──────────────────────────────────────────
    def test_TC20_bottom_nav_map(self):
        def _run():
            self.click_element(config.LOCATORS["nav_map"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["map_title"], timeout=8
            ), "Map screen did not appear"
            self.take_screenshot("TC20_map_tab")

        assert self.run_test("TC20_bottom_nav_map", _run)

    # ──────────────────────────────────────────
    # TC-21: Bottom Nav — Profile tab
    # ──────────────────────────────────────────
    def test_TC21_bottom_nav_profile(self):
        def _run():
            self.click_element(config.LOCATORS["nav_profile"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["profile_title"], timeout=8
            ), "Profile screen did not appear"
            self.take_screenshot("TC21_profile_tab")

        assert self.run_test("TC21_bottom_nav_profile", _run)

    # ──────────────────────────────────────────
    # TC-22: Bottom Nav — return to Home
    # ──────────────────────────────────────────
    def test_TC22_bottom_nav_back_to_home(self):
        def _run():
            self.click_element(config.LOCATORS["nav_map"])
            time.sleep(1)
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["home_title"], timeout=8
            ), "Home screen not restored via bottom nav"
            self.take_screenshot("TC22_back_to_home")

        assert self.run_test("TC22_bottom_nav_back_to_home", _run)
