"""
TEST MODULE 08 — Full End-to-End User Journey
Single session that walks through the ENTIRE application:
  Splash → Login → Home → Report Issue → My Reports → Map → Profile
  → Notifications → Officer Portal → Officer Dashboard → Logout
"""
import time
import pytest
from base_test import BaseTest
import config


class TestFullEndToEnd(BaseTest):
    """
    One continuous session E2E test.
    The driver is started ONCE and shared across all steps
    (class-scoped fixture).
    """

    @pytest.fixture(scope="class", autouse=True)
    def class_driver(self):
        """Class-scoped driver — single session for the whole E2E journey."""
        self.setup_driver()
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # STEP E2E-01: App launch & splash
    # ──────────────────────────────────────────
    def test_E2E01_app_launch_and_splash(self):
        def _run():
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["splash_title"], timeout=8
            ), "Splash screen not visible"
            self.take_screenshot("E2E01_splash")

        assert self.run_test("E2E01_app_launch_and_splash", _run)

    # ──────────────────────────────────────────
    # STEP E2E-02: Login with phone + OTP
    # ──────────────────────────────────────────
    def test_E2E02_phone_otp_login(self):
        def _run():
            self.login_with_phone_otp()
            assert self.is_element_visible(
                config.LOCATORS["home_title"], timeout=10
            ), "Home not visible after login"
            self.take_screenshot("E2E02_logged_in")

        assert self.run_test("E2E02_phone_otp_login", _run)

    # ──────────────────────────────────────────
    # STEP E2E-03: Home Dashboard content
    # ──────────────────────────────────────────
    def test_E2E03_home_dashboard_content(self):
        def _run():
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Quick Report")]'), timeout=6
            ), "Quick Report section missing"
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Recent Reports")]'), timeout=6
            ), "Recent Reports section missing"
            self.take_screenshot("E2E03_home_content")

        assert self.run_test("E2E03_home_dashboard_content", _run)

    # ──────────────────────────────────────────
    # STEP E2E-04: Submit a new report
    # ──────────────────────────────────────────
    def test_E2E04_submit_new_report(self):
        def _run():
            self.click_element(config.LOCATORS["report_issue_fab"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["report_title"], timeout=8
            ), "Report Issue screen not open"
            # Select category
            self.click_element(config.LOCATORS["cat_pothole"])
            time.sleep(0.5)
            # Select severity
            self.click_element(config.LOCATORS["sev_high"])
            time.sleep(0.5)
            # Scroll and submit
            self.swipe_up(3)
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["report_submitted"], timeout=10
            ), "Report submission did not succeed"
            self.take_screenshot("E2E04_report_submitted")

        assert self.run_test("E2E04_submit_new_report", _run)

    # ──────────────────────────────────────────
    # STEP E2E-05: Navigate back to Home
    # ──────────────────────────────────────────
    def test_E2E05_navigate_back_to_home(self):
        def _run():
            self.click_element(config.LOCATORS["back_to_home_btn"])
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["home_title"], timeout=8
            ), "Home not visible after submission"
            self.take_screenshot("E2E05_back_home")

        assert self.run_test("E2E05_navigate_back_to_home", _run)

    # ──────────────────────────────────────────
    # STEP E2E-06: View My Reports
    # ──────────────────────────────────────────
    def test_E2E06_view_my_reports(self):
        def _run():
            self.click_element(config.LOCATORS["nav_my_reports"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["my_reports_title"], timeout=8
            ), "My Reports not visible"
            # Verify report cards present
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            ), "Pothole report not in My Reports"
            self.take_screenshot("E2E06_my_reports")

        assert self.run_test("E2E06_view_my_reports", _run)

    # ──────────────────────────────────────────
    # STEP E2E-07: Open a report detail
    # ──────────────────────────────────────────
    def test_E2E07_open_report_detail(self):
        def _run():
            pothole = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=6
            )
            assert pothole, "Pothole card not found"
            pothole.click()
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["status_timeline"], timeout=8
            ), "Status Timeline not visible"
            self.driver.press_keycode(4)
            time.sleep(1)
            self.take_screenshot("E2E07_report_detail")

        assert self.run_test("E2E07_open_report_detail", _run)

    # ──────────────────────────────────────────
    # STEP E2E-08: Explore Map screen
    # ──────────────────────────────────────────
    def test_E2E08_explore_map_screen(self):
        def _run():
            self.click_element(config.LOCATORS["nav_map"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["map_title"], timeout=8
            ), "Map screen not visible"
            # Switch layers
            self.click_element(config.LOCATORS["map_my_ward"])
            time.sleep(0.8)
            self.click_element(config.LOCATORS["map_all_issues"])
            time.sleep(0.8)
            self.take_screenshot("E2E08_map_explored")

        assert self.run_test("E2E08_explore_map_screen", _run)

    # ──────────────────────────────────────────
    # STEP E2E-09: Check Profile screen
    # ──────────────────────────────────────────
    def test_E2E09_check_profile_screen(self):
        def _run():
            self.click_element(config.LOCATORS["nav_profile"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["profile_name"], timeout=8
            ), "Profile name not visible"
            assert self.is_element_visible(
                config.LOCATORS["gold_badge"], timeout=6
            ), "Gold badge not visible"
            self.take_screenshot("E2E09_profile")

        assert self.run_test("E2E09_check_profile_screen", _run)

    # ──────────────────────────────────────────
    # STEP E2E-10: Read notifications
    # ──────────────────────────────────────────
    def test_E2E10_read_notifications(self):
        def _run():
            self.click_element(
                ("xpath", '//*[contains(@text,"Notifications")]')
            )
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["notif_title"], timeout=8
            ), "Notifications screen not visible"
            self.click_element(config.LOCATORS["mark_all_read_btn"])
            time.sleep(1)
            self.driver.press_keycode(4)
            time.sleep(1)
            self.take_screenshot("E2E10_notifications_read")

        assert self.run_test("E2E10_read_notifications", _run)

    # ──────────────────────────────────────────
    # STEP E2E-11: Enter Officer Portal
    # ──────────────────────────────────────────
    def test_E2E11_enter_officer_portal(self):
        def _run():
            self.click_element(config.LOCATORS["officer_portal_btn"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["officer_portal_title"], timeout=8
            ), "Officer Portal not visible"
            self.take_screenshot("E2E11_officer_portal")

        assert self.run_test("E2E11_enter_officer_portal", _run)

    # ──────────────────────────────────────────
    # STEP E2E-12: Officer login
    # ──────────────────────────────────────────
    def test_E2E12_officer_login(self):
        def _run():
            id_field = self.find_element(
                config.LOCATORS["officer_id_input"], timeout=8
            )
            if id_field:
                id_field.clear()
                id_field.send_keys(config.OFFICER_ID)
            pass_field = self.find_element(
                config.LOCATORS["officer_pass_input"], timeout=6
            )
            if pass_field:
                pass_field.clear()
                pass_field.send_keys(config.OFFICER_PASS)
            self.click_element(config.LOCATORS["officer_login_btn"])
            time.sleep(config.LOGIN_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["officer_dashboard_title"], timeout=10
            ), "Officer Dashboard not visible after login"
            self.take_screenshot("E2E12_officer_dashboard")

        assert self.run_test("E2E12_officer_login", _run)

    # ──────────────────────────────────────────
    # STEP E2E-13: Officer reviews and updates an issue
    # ──────────────────────────────────────────
    def test_E2E13_officer_reviews_issue(self):
        def _run():
            issue = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=8
            )
            assert issue, "No Pothole in officer queue"
            issue.click()
            time.sleep(1.5)
            # Select In Progress
            self.click_element(
                ("xpath", '//*[contains(@text,"In Progress")]')
            )
            time.sleep(0.5)
            # Assign crew
            self.swipe_up()
            crew_a = self.find_element(
                ("xpath", '//*[contains(@text,"Crew A")]'), timeout=6
            )
            if crew_a:
                crew_a.click()
            time.sleep(0.5)
            # Submit update
            self.swipe_up(2)
            update_btn = self.find_element(
                ("xpath", '//*[contains(@text,"Update")]'), timeout=6
            )
            if update_btn:
                update_btn.click()
            time.sleep(config.SUBMIT_WAIT)
            self.take_screenshot("E2E13_officer_updated")

        assert self.run_test("E2E13_officer_reviews_issue", _run)

    # ──────────────────────────────────────────
    # STEP E2E-14: Officer logout back to citizen Login
    # ──────────────────────────────────────────
    def test_E2E14_officer_logout_to_login(self):
        def _run():
            logout_icon = self.find_element(
                ("xpath", '//*[@content-desc="logout"]'), timeout=6
            )
            if logout_icon:
                logout_icon.click()
            else:
                self.tap_by_text("Logout")
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["welcome_back"], timeout=10
            ), "Login screen not shown after complete E2E journey"
            self.take_screenshot("E2E14_journey_complete")

        assert self.run_test("E2E14_officer_logout_to_login", _run)
