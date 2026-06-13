"""
TEST MODULE 01 — Splash Screen & Authentication (Phone + OTP)
Covers: Splash → Login screen → OTP screen → Home Dashboard
"""
import time
import pytest
from base_test import BaseTest
import config


class TestSplashAndLogin(BaseTest):
    """Tests for app launch, splash, phone login and OTP verification."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-01: App launches and shows splash
    # ──────────────────────────────────────────
    def test_TC01_app_launch_splash_screen(self):
        def _run():
            time.sleep(2)  # Give app time to start
            # Splash must show "Civic Reporter"
            assert self.is_element_visible(
                config.LOCATORS["splash_title"], timeout=8
            ), "Splash title 'Civic Reporter' not visible"
            self.take_screenshot("TC01_splash")

        result = self.run_test("TC01_app_launch_splash_screen", _run)
        assert result, "TC01 failed"

    # ──────────────────────────────────────────
    # TC-02: Splash transitions to Login screen
    # ──────────────────────────────────────────
    def test_TC02_splash_to_login_transition(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["welcome_back"], timeout=8
            ), "'Welcome Back!' not visible after splash"
            assert self.is_element_visible(
                config.LOCATORS["phone_input"], timeout=5
            ), "Phone input not visible on Login screen"
            self.take_screenshot("TC02_login_screen")

        result = self.run_test("TC02_splash_to_login_transition", _run)
        assert result, "TC02 failed"

    # ──────────────────────────────────────────
    # TC-03: Login screen UI elements present
    # ──────────────────────────────────────────
    def test_TC03_login_screen_ui_elements(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Phone Number")]'), timeout=6
            ), "Phone Number label not visible"
            assert self.is_element_visible(
                config.LOCATORS["send_otp_btn"], timeout=6
            ), "Send OTP button not visible"
            assert self.is_element_visible(
                config.LOCATORS["support_btn"], timeout=6
            ), "Contact Support button not visible"
            self.take_screenshot("TC03_login_elements")

        result = self.run_test("TC03_login_screen_ui_elements", _run)
        assert result, "TC03 failed"

    # ──────────────────────────────────────────
    # TC-04: Short phone number shows validation error
    # ──────────────────────────────────────────
    def test_TC04_invalid_short_phone_validation(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            self.send_text(config.LOCATORS["phone_input"], config.INVALID_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(1.5)
            # App shows snackbar with "valid 10-digit"
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"valid") or contains(@text,"10-digit")]'),
                timeout=5
            ), "Validation snackbar not shown for short phone"
            self.take_screenshot("TC04_phone_validation_error")

        result = self.run_test("TC04_invalid_short_phone_validation", _run)
        assert result, "TC04 failed"

    # ──────────────────────────────────────────
    # TC-05: Valid phone triggers OTP screen
    # ──────────────────────────────────────────
    def test_TC05_valid_phone_navigates_to_otp(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            self.send_text(config.LOCATORS["phone_input"], config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["verify_otp_title"], timeout=8
            ), "OTP screen did not appear"
            self.take_screenshot("TC05_otp_screen")

        result = self.run_test("TC05_valid_phone_navigates_to_otp", _run)
        assert result, "TC05 failed"

    # ──────────────────────────────────────────
    # TC-06: OTP screen shows correct phone number
    # ──────────────────────────────────────────
    def test_TC06_otp_screen_shows_phone_number(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            self.send_text(config.LOCATORS["phone_input"], config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            # App shows "+91 <phone>"
            assert self.is_element_visible(
                ("xpath", f'//*[contains(@text,"{config.TEST_PHONE}")]'), timeout=6
            ), f"Phone number {config.TEST_PHONE} not shown on OTP screen"
            self.take_screenshot("TC06_otp_phone_number")

        result = self.run_test("TC06_otp_screen_shows_phone_number", _run)
        assert result, "TC06 failed"

    # ──────────────────────────────────────────
    # TC-07: Resend OTP button is visible
    # ──────────────────────────────────────────
    def test_TC07_resend_otp_button_visible(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            self.send_text(config.LOCATORS["phone_input"], config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["resend_otp_btn"], timeout=6
            ), "Resend OTP button not visible"
            self.take_screenshot("TC07_resend_otp")

        result = self.run_test("TC07_resend_otp_button_visible", _run)
        assert result, "TC07 failed"

    # ──────────────────────────────────────────
    # TC-08: OTP back-button returns to Login
    # ──────────────────────────────────────────
    def test_TC08_otp_back_button_returns_to_login(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            self.send_text(config.LOCATORS["phone_input"], config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            self.driver.press_keycode(4)  # Android BACK key
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["welcome_back"], timeout=6
            ), "Did not navigate back to Login screen"
            self.take_screenshot("TC08_back_to_login")

        result = self.run_test("TC08_otp_back_button_returns_to_login", _run)
        assert result, "TC08 failed"

    # ──────────────────────────────────────────
    # TC-09: Successful OTP login → Home Dashboard
    # ──────────────────────────────────────────
    def test_TC09_successful_otp_login(self):
        def _run():
            self.login_with_phone_otp()
            assert self.is_element_visible(
                config.LOCATORS["home_title"], timeout=10
            ), "Home Dashboard did not appear after OTP login"
            self.take_screenshot("TC09_home_dashboard")

        result = self.run_test("TC09_successful_otp_login", _run)
        assert result, "TC09 failed"

    # ──────────────────────────────────────────
    # TC-10: Login → logout → back to Login screen
    # ──────────────────────────────────────────
    def test_TC10_login_and_logout_flow(self):
        def _run():
            self.login_with_phone_otp()
            # Navigate to Profile via bottom nav
            self.click_element(config.LOCATORS["nav_profile"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["logout_btn"], timeout=6
            ), "Logout button not found on Profile screen"
            self.click_element(config.LOCATORS["logout_btn"])
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["welcome_back"], timeout=8
            ), "Login screen did not appear after logout"
            self.take_screenshot("TC10_after_logout")

        result = self.run_test("TC10_login_and_logout_flow", _run)
        assert result, "TC10 failed"
