"""TEST MODULE 08 — Full End to End (E2E01-E2E14)"""
import time
import pytest
from base_test import BaseTest
import config


class TestFullEndToEnd(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        yield
        self.teardown_driver()

    def test_E2E_full_journey(self):
        def _run():
            # 1. Launch & Splash
            assert self.page_contains("Civic Reporter"), "Splash failed"
            time.sleep(config.SPLASH_WAIT)

            # 2. Login
            self.login_with_phone_otp()
            assert self.page_contains("Ward 42"), "Login failed"

            # 3. Dashboard
            assert self.page_contains("Quick Report"), "Dashboard missing"

            # 4. Report Issue
            self.click_element(config.LOCATORS["report_issue_fab"])
            time.sleep(1.5)
            self.click_element(config.LOCATORS["photo_area"])
            self.click_element(config.LOCATORS["cat_pothole"])
            self.scroll_down(300)
            self.click_element(config.LOCATORS["sev_high"])
            self.scroll_to_bottom()
            self.send_text(config.LOCATORS["desc_field"], "Dangerous pothole E2E")
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            assert self.page_contains("Report Submitted") or self.page_contains("Success")

            # 5. Back to Home
            self.click_element(config.LOCATORS["back_to_home_btn"])
            time.sleep(1.5)

            # 6. My Reports
            self.click_element(config.LOCATORS["nav_my_reports"])
            time.sleep(1.5)
            assert self.page_contains("My Reports")

            # 7. Map
            self.click_element(config.LOCATORS["nav_map"])
            time.sleep(1.5)
            assert self.page_contains("Area Map")

            # 8. Profile
            self.click_element(config.LOCATORS["nav_profile"])
            time.sleep(1.5)
            assert self.page_contains("My Profile")

            # 9. Enter Officer Portal
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["officer_portal_btn"])
            time.sleep(1.5)
            assert self.page_contains("Ward Officer Portal")

            # 10. Officer Login
            inputs = self.find_elements(config.LOCATORS["officer_id_input"])
            if len(inputs) >= 2:
                inputs[0].send_keys(config.OFFICER_ID)
                inputs[1].send_keys(config.OFFICER_PASS)
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["officer_login_btn"])
            time.sleep(3)
            assert self.page_contains("Officer Dashboard")

            # 11. Officer Logout
            self.click_element(config.LOCATORS["logout_btn"])
            time.sleep(1.5)
            assert self.page_contains("Login as Officer")

            self.take_screenshot("E2E_Success")

        assert self.run_test("test_E2E_full_journey", _run)
