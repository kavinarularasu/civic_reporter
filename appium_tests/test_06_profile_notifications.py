"""
TEST MODULE 06 — Profile Screen & Notifications
Covers: Profile info, stats, menu items, Notifications screen,
        mark-all-read, notification items
"""
import time
import pytest
from base_test import BaseTest
import config


class TestProfileAndNotifications(BaseTest):
    """Tests for Profile and Notification screens."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        self.login_with_phone_otp()
        self.click_element(config.LOCATORS["nav_profile"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-60: Profile screen title visible
    # ──────────────────────────────────────────
    def test_TC60_profile_title_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["profile_title"], timeout=8
            ), "'My Profile' title not visible"
            self.take_screenshot("TC60_profile_title")

        assert self.run_test("TC60_profile_title_visible", _run)

    # ──────────────────────────────────────────
    # TC-61: Profile name and phone visible
    # ──────────────────────────────────────────
    def test_TC61_profile_name_and_phone(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["profile_name"], timeout=6
            ), "Profile name 'Kavin' not visible"
            assert self.is_element_visible(
                config.LOCATORS["profile_phone"], timeout=6
            ), "Profile phone '+91' not visible"
            self.take_screenshot("TC61_profile_name_phone")

        assert self.run_test("TC61_profile_name_and_phone", _run)

    # ──────────────────────────────────────────
    # TC-62: Gold Civic Reporter badge visible
    # ──────────────────────────────────────────
    def test_TC62_gold_badge_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["gold_badge"], timeout=6
            ), "Gold Civic Reporter badge not visible"
            self.take_screenshot("TC62_gold_badge")

        assert self.run_test("TC62_gold_badge_visible", _run)

    # ──────────────────────────────────────────
    # TC-63: Profile stats (Reports Filed / Issues Resolved / Badges)
    # ──────────────────────────────────────────
    def test_TC63_profile_stats_boxes(self):
        def _run():
            for label in ["Reports", "Issues", "Badges"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{label}")]'), timeout=6
                ), f"Profile stat '{label}' not visible"
            self.take_screenshot("TC63_profile_stats")

        assert self.run_test("TC63_profile_stats_boxes", _run)

    # ──────────────────────────────────────────
    # TC-64: Menu items visible
    # ──────────────────────────────────────────
    def test_TC64_menu_items_visible(self):
        def _run():
            for item in ["My Reports", "Notifications", "Officer Portal",
                         "Privacy Policy", "Rate the App"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{item}")]'), timeout=6
                ), f"Menu item '{item}' not visible"
            self.take_screenshot("TC64_menu_items")

        assert self.run_test("TC64_menu_items_visible", _run)

    # ──────────────────────────────────────────
    # TC-65: Logout button visible and functional
    # ──────────────────────────────────────────
    def test_TC65_logout_button_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["logout_btn"], timeout=6
            ), "Logout button not visible on Profile"
            self.take_screenshot("TC65_logout_button")

        assert self.run_test("TC65_logout_button_visible", _run)

    # ──────────────────────────────────────────
    # TC-66: Notifications screen opens from profile menu
    # ──────────────────────────────────────────
    def test_TC66_notifications_from_profile_menu(self):
        def _run():
            self.click_element(
                ("xpath", '//*[contains(@text,"Notifications")]')
            )
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["notif_title"], timeout=8
            ), "Notifications screen did not open"
            self.take_screenshot("TC66_notif_from_profile")

        assert self.run_test("TC66_notifications_from_profile_menu", _run)

    # ──────────────────────────────────────────
    # TC-67: Notification items visible
    # ──────────────────────────────────────────
    def test_TC67_notification_items_visible(self):
        def _run():
            # Open Notifications
            self.click_element(
                ("xpath", '//*[contains(@text,"Notifications")]')
            )
            time.sleep(1.5)
            for notif in ["Issue In Progress", "Report Acknowledged", "Issue Resolved"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{notif}")]'), timeout=6
                ), f"Notification '{notif}' not visible"
            self.take_screenshot("TC67_notification_items")

        assert self.run_test("TC67_notification_items_visible", _run)

    # ──────────────────────────────────────────
    # TC-68: Unread notification badge indicator
    # ──────────────────────────────────────────
    def test_TC68_unread_notification_count(self):
        def _run():
            self.click_element(
                ("xpath", '//*[contains(@text,"Notifications")]')
            )
            time.sleep(1.5)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"unread")]'), timeout=6
            ), "Unread notification count not visible"
            self.take_screenshot("TC68_unread_count")

        assert self.run_test("TC68_unread_notification_count", _run)

    # ──────────────────────────────────────────
    # TC-69: Mark all read clears unread count
    # ──────────────────────────────────────────
    def test_TC69_mark_all_read(self):
        def _run():
            self.click_element(
                ("xpath", '//*[contains(@text,"Notifications")]')
            )
            time.sleep(1.5)
            self.click_element(config.LOCATORS["mark_all_read_btn"])
            time.sleep(1.5)
            # Unread banner should disappear
            assert not self.is_element_visible(
                ("xpath", '//*[contains(@text,"unread")]'), timeout=3
            ), "Unread count still visible after Mark All Read"
            self.take_screenshot("TC69_mark_all_read")

        assert self.run_test("TC69_mark_all_read", _run)

    # ──────────────────────────────────────────
    # TC-70: Back from Notifications returns to Profile
    # ──────────────────────────────────────────
    def test_TC70_back_from_notifications(self):
        def _run():
            self.click_element(
                ("xpath", '//*[contains(@text,"Notifications")]')
            )
            time.sleep(1.5)
            self.driver.press_keycode(4)
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["profile_title"], timeout=8
            ), "Profile screen not restored after back from Notifications"
            self.take_screenshot("TC70_back_to_profile")

        assert self.run_test("TC70_back_from_notifications", _run)
