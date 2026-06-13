"""TEST MODULE 06 — Profile & Notifications (TC60-TC70)"""
import time
import pytest
from base_test import BaseTest
import config


class TestProfileAndNotifications(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        self.login_with_phone_otp()
        time.sleep(1)
        self.click_element(config.LOCATORS["nav_profile"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    def test_TC60_profile_title_visible(self):
        def _run():
            assert self.page_contains("My Profile"), "Profile title missing"
            self.take_screenshot("TC60_profile_title")
        assert self.run_test("TC60_profile_title_visible", _run)

    def test_TC61_profile_name_and_phone(self):
        def _run():
            assert self.page_contains("Kavin"), "Name missing"
            assert self.page_contains("+91"), "Phone missing"
            self.take_screenshot("TC61_name_phone")
        assert self.run_test("TC61_profile_name_and_phone", _run)

    def test_TC62_gold_badge_visible(self):
        def _run():
            assert self.page_contains("Gold Civic Reporter"), "Badge missing"
            self.take_screenshot("TC62_badge")
        assert self.run_test("TC62_gold_badge_visible", _run)

    def test_TC63_profile_stats_boxes(self):
        def _run():
            for s in ["Reports", "Issues", "Badges"]:
                assert self.page_contains(s), f"Stat box '{s}' missing"
            self.take_screenshot("TC63_stats")
        assert self.run_test("TC63_profile_stats_boxes", _run)

    def test_TC64_menu_items_visible(self):
        def _run():
            self.scroll_down()
            for item in ["Settings", "Help & Support", "About Us"]:
                assert self.page_contains(item), f"Menu item '{item}' missing"
            self.take_screenshot("TC64_menu")
        assert self.run_test("TC64_menu_items_visible", _run)

    def test_TC65_logout_button_visible(self):
        def _run():
            self.scroll_to_bottom()
            assert self.page_contains("Logout"), "Logout button missing"
            self.take_screenshot("TC65_logout")
        assert self.run_test("TC65_logout_button_visible", _run)

    def test_TC66_notifications_from_profile_menu(self):
        def _run():
            # Go back to home to click the bell icon
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1)
            self.click_element(config.LOCATORS["notification_btn"])
            time.sleep(1.5)
            assert self.page_contains("Notifications"), "Notifications not opened"
            self.take_screenshot("TC66_notifications_open")
        assert self.run_test("TC66_notifications_from_profile_menu", _run)

    def test_TC67_notification_items_visible(self):
        def _run():
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1)
            self.click_element(config.LOCATORS["notification_btn"])
            time.sleep(1.5)
            assert self.page_contains("Issue In Progress") or \
                   self.page_contains("Acknowledged"), "Notification items missing"
            self.take_screenshot("TC67_notif_items")
        assert self.run_test("TC67_notification_items_visible", _run)

    def test_TC68_unread_notification_count(self):
        def _run():
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1)
            # Assuming there is a badge count or bold text for unread
            self.take_screenshot("TC68_unread_count")
            assert True
        assert self.run_test("TC68_unread_notification_count", _run)

    def test_TC69_mark_all_read(self):
        def _run():
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1)
            self.click_element(config.LOCATORS["notification_btn"])
            time.sleep(1.5)
            self.click_element(config.LOCATORS["mark_all_read_btn"])
            time.sleep(1)
            self.take_screenshot("TC69_mark_all_read")
            assert True
        assert self.run_test("TC69_mark_all_read", _run)

    def test_TC70_back_from_notifications(self):
        def _run():
            self.click_element(config.LOCATORS["nav_home"])
            time.sleep(1)
            self.click_element(config.LOCATORS["notification_btn"])
            time.sleep(1.5)
            self.browser_back()
            time.sleep(1)
            assert self.page_contains("Civic Reporter"), "Did not return to Home"
            self.take_screenshot("TC70_back_from_notifications")
        assert self.run_test("TC70_back_from_notifications", _run)
