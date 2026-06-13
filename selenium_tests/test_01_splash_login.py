"""TEST MODULE 01 — Splash & Login (TC01-TC10)"""
import time
import pytest
from base_test import BaseTest
import config


class TestSplashAndLogin(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        yield
        self.teardown_driver()

    def test_TC01_page_loads_successfully(self):
        def _run():
            assert self.driver.title is not None or self.page_contains("Civic")
            self.take_screenshot("TC01_page_loaded")
        assert self.run_test("TC01_page_loads_successfully", _run)

    def test_TC02_splash_title_visible(self):
        def _run():
            assert self.page_contains("Civic Reporter"), "Splash title not in page"
            self.take_screenshot("TC02_splash_title")
        assert self.run_test("TC02_splash_title_visible", _run)

    def test_TC03_splash_transitions_to_login(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            assert self.page_contains("Welcome Back") or self.page_contains("Phone Number"), \
                "Login screen not shown after splash"
            self.take_screenshot("TC03_login_screen")
        assert self.run_test("TC03_splash_transitions_to_login", _run)

    def test_TC04_login_screen_ui_elements(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            assert self.page_contains("Phone Number"), "Phone label missing"
            assert self.page_contains("Send OTP"), "Send OTP button missing"
            assert self.page_contains("Contact Support"), "Contact Support missing"
            self.take_screenshot("TC04_login_elements")
        assert self.run_test("TC04_login_screen_ui_elements", _run)

    def test_TC05_invalid_short_phone_validation(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            phone_el = self.find_element(config.LOCATORS["phone_input"], timeout=8)
            assert phone_el, "Phone input not found"
            phone_el.send_keys(config.INVALID_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(1.5)
            assert self.page_contains("valid") or self.page_contains("10-digit") \
                or self.page_contains("Invalid"), "Validation error not shown"
            self.take_screenshot("TC05_phone_validation")
        assert self.run_test("TC05_invalid_short_phone_validation", _run)

    def test_TC06_valid_phone_navigates_to_otp(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            phone_el = self.find_element(config.LOCATORS["phone_input"], timeout=8)
            assert phone_el, "Phone input not found"
            phone_el.send_keys(config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            assert self.page_contains("Verify OTP") or self.page_contains("OTP"), \
                "OTP screen did not appear"
            self.take_screenshot("TC06_otp_screen")
        assert self.run_test("TC06_valid_phone_navigates_to_otp", _run)

    def test_TC07_otp_screen_shows_phone_number(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            phone_el = self.find_element(config.LOCATORS["phone_input"], timeout=8)
            if phone_el:
                phone_el.send_keys(config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            assert self.page_contains(config.TEST_PHONE), \
                f"Phone {config.TEST_PHONE} not shown on OTP screen"
            self.take_screenshot("TC07_otp_phone")
        assert self.run_test("TC07_otp_screen_shows_phone_number", _run)

    def test_TC08_resend_otp_button_visible(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            phone_el = self.find_element(config.LOCATORS["phone_input"], timeout=8)
            if phone_el:
                phone_el.send_keys(config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            assert self.page_contains("Resend OTP"), "Resend OTP button not visible"
            self.take_screenshot("TC08_resend_otp")
        assert self.run_test("TC08_resend_otp_button_visible", _run)

    def test_TC09_browser_back_returns_to_login(self):
        def _run():
            time.sleep(config.SPLASH_WAIT)
            phone_el = self.find_element(config.LOCATORS["phone_input"], timeout=8)
            if phone_el:
                phone_el.send_keys(config.TEST_PHONE)
            self.click_element(config.LOCATORS["send_otp_btn"])
            time.sleep(config.OTP_WAIT)
            self.browser_back()
            time.sleep(1.5)
            assert self.page_contains("Welcome Back") or self.page_contains("Phone Number"), \
                "Login screen not restored after back"
            self.take_screenshot("TC09_back_to_login")
        assert self.run_test("TC09_browser_back_returns_to_login", _run)

    def test_TC10_successful_otp_login(self):
        def _run():
            self.login_with_phone_otp()
            assert self.page_contains("Civic Reporter") or self.page_contains("Ward 42"), \
                "Home not visible after login"
            self.take_screenshot("TC10_home_after_login")
        assert self.run_test("TC10_successful_otp_login", _run)
