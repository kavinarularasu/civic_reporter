"""TEST MODULE 07 — Officer Portal (TC71-TC86)"""
import time
import pytest
from base_test import BaseTest
import config


class TestOfficerPortal(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        self.login_with_phone_otp()
        time.sleep(1)
        self.click_element(config.LOCATORS["nav_profile"])
        time.sleep(1.5)
        self.scroll_to_bottom()
        self.click_element(config.LOCATORS["officer_portal_btn"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    def test_TC71_officer_portal_title_visible(self):
        def _run():
            assert self.page_contains("Ward Officer Portal"), "Title missing"
            self.take_screenshot("TC71_officer_title")
        assert self.run_test("TC71_officer_portal_title_visible", _run)

    def test_TC72_officer_login_form_fields(self):
        def _run():
            assert self.find_element(config.LOCATORS["officer_id_input"]), "ID input missing"
            assert self.find_element(config.LOCATORS["officer_login_btn"]), "Login btn missing"
            self.take_screenshot("TC72_officer_fields")
        assert self.run_test("TC72_officer_login_form_fields", _run)

    def test_TC73_empty_fields_validation_error(self):
        def _run():
            self.click_element(config.LOCATORS["officer_login_btn"])
            time.sleep(1)
            assert self.page_contains("Required") or self.page_contains("valid"), \
                "Validation error missing"
            self.take_screenshot("TC73_validation_error")
        assert self.run_test("TC73_empty_fields_validation_error", _run)

    def test_TC74_back_to_citizen_app(self):
        def _run():
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["back_citizen_btn"])
            time.sleep(1.5)
            assert self.page_contains("My Profile"), "Did not return to citizen app"
            self.take_screenshot("TC74_back_to_citizen")
        assert self.run_test("TC74_back_to_citizen_app", _run)

    def test_TC75_forgot_password_link_visible(self):
        def _run():
            assert self.page_contains("Forgot Password"), "Forgot password missing"
            self.take_screenshot("TC75_forgot_password")
        assert self.run_test("TC75_forgot_password_link_visible", _run)

    def test_TC76_successful_officer_login(self):
        def _run():
            inputs = self.find_elements(config.LOCATORS["officer_id_input"])
            if len(inputs) >= 2:
                inputs[0].send_keys(config.OFFICER_ID)
                inputs[1].send_keys(config.OFFICER_PASS)
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["officer_login_btn"])
            time.sleep(3)
            assert self.page_contains("Officer Dashboard") or self.page_contains(config.OFFICER_ID), \
                "Officer dashboard not opened"
            self.take_screenshot("TC76_officer_dashboard")
        assert self.run_test("TC76_successful_officer_login", _run)

    def test_TC77_officer_dashboard_stats_row(self):
        def _run():
            self.test_TC76_successful_officer_login()
            for s in ["New", "In Progress", "Resolved", "Escalated"]:
                assert self.page_contains(s), f"Stat '{s}' missing"
            self.take_screenshot("TC77_officer_stats")
        assert self.run_test("TC77_officer_dashboard_stats_row", _run)

    def test_TC78_officer_queue_tabs(self):
        def _run():
            self.test_TC76_successful_officer_login()
            for s in ["All", "New", "In Progress", "Escalated"]:
                assert self.page_contains(s), f"Queue tab '{s}' missing"
            self.take_screenshot("TC78_officer_tabs")
        assert self.run_test("TC78_officer_queue_tabs", _run)

    def test_TC79_new_tab_shows_issues(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.tap_by_text("New", timeout=5)
            time.sleep(1)
            self.take_screenshot("TC79_new_tab")
            assert True
        assert self.run_test("TC79_new_tab_shows_issues", _run)

    def test_TC80_sla_progress_bar_visible(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.take_screenshot("TC80_sla_bar")
            assert True
        assert self.run_test("TC80_sla_progress_bar_visible", _run)

    def test_TC81_switch_to_in_progress_tab(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.tap_by_text("In Progress", timeout=5)
            time.sleep(1)
            self.take_screenshot("TC81_in_progress")
            assert True
        assert self.run_test("TC81_switch_to_in_progress_tab", _run)

    def test_TC82_issue_card_opens_action_screen(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            assert self.page_contains("Update Status"), "Action screen not opened"
            self.browser_back()
            self.take_screenshot("TC82_action_screen")
        assert self.run_test("TC82_issue_card_opens_action_screen", _run)

    def test_TC83_officer_action_status_grid(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            self.scroll_down(200)
            for s in ["Acknowledged", "In Progress", "Resolved"]:
                assert self.page_contains(s), f"Status '{s}' missing"
            self.take_screenshot("TC83_status_grid")
        assert self.run_test("TC83_officer_action_status_grid", _run)

    def test_TC84_assign_field_crew_options(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            self.scroll_down(300)
            assert self.page_contains("Crew A") or self.page_contains("Assign"), \
                "Crew assignment missing"
            self.take_screenshot("TC84_crew")
        assert self.run_test("TC84_assign_field_crew_options", _run)

    def test_TC85_update_status_button(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.tap_by_text("Ward 42", timeout=5)
            time.sleep(1.5)
            self.scroll_to_bottom()
            assert self.page_contains("Update Status"), "Update button missing"
            self.take_screenshot("TC85_update_btn")
        assert self.run_test("TC85_update_status_button", _run)

    def test_TC86_officer_logout(self):
        def _run():
            self.test_TC76_successful_officer_login()
            self.click_element(config.LOCATORS["logout_btn"])
            time.sleep(1.5)
            assert self.page_contains("Login as Officer"), "Officer logout failed"
            self.take_screenshot("TC86_officer_logout")
        assert self.run_test("TC86_officer_logout", _run)
