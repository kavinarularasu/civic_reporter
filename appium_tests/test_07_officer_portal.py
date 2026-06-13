"""
TEST MODULE 07 — Officer Portal
Covers: Officer Login screen, validation, login success,
        Officer Dashboard (tabs, queue cards, SLA bar),
        Officer Action screen, Ward Stats screen
"""
import time
import pytest
from base_test import BaseTest
import config


class TestOfficerPortal(BaseTest):
    """Tests for the Officer Portal (login, dashboard, actions)."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        self.login_with_phone_otp()
        # Navigate to Officer Portal via Profile > Officer Portal
        self.click_element(config.LOCATORS["nav_profile"])
        time.sleep(1.5)
        self.click_element(config.LOCATORS["officer_portal_btn"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-71: Officer Portal title visible
    # ──────────────────────────────────────────
    def test_TC71_officer_portal_title_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["officer_portal_title"], timeout=8
            ), "'Ward Officer Portal' title not visible"
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Chennai Municipal")]'), timeout=6
            ), "Municipality sub-title not visible"
            self.take_screenshot("TC71_officer_portal_title")

        assert self.run_test("TC71_officer_portal_title_visible", _run)

    # ──────────────────────────────────────────
    # TC-72: Officer login form fields visible
    # ──────────────────────────────────────────
    def test_TC72_officer_login_form_fields(self):
        def _run():
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Employee ID")]'), timeout=6
            ), "Employee ID label not visible"
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Password")]'), timeout=6
            ), "Password label not visible"
            assert self.is_element_visible(
                config.LOCATORS["officer_login_btn"], timeout=6
            ), "Login as Officer button not visible"
            self.take_screenshot("TC72_officer_login_form")

        assert self.run_test("TC72_officer_login_form_fields", _run)

    # ──────────────────────────────────────────
    # TC-73: Empty fields show validation error
    # ──────────────────────────────────────────
    def test_TC73_empty_fields_validation_error(self):
        def _run():
            self.click_element(config.LOCATORS["officer_login_btn"])
            time.sleep(1.5)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Employee ID") or contains(@text,"Password")]'),
                timeout=6
            ), "Validation error not shown for empty fields"
            self.take_screenshot("TC73_officer_empty_validation")

        assert self.run_test("TC73_empty_fields_validation_error", _run)

    # ──────────────────────────────────────────
    # TC-74: "Back to Citizen App" returns to Profile
    # ──────────────────────────────────────────
    def test_TC74_back_to_citizen_app(self):
        def _run():
            self.click_element(config.LOCATORS["back_citizen_btn"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["profile_title"], timeout=8
            ), "Did not return to Profile screen"
            self.take_screenshot("TC74_back_to_citizen")

        assert self.run_test("TC74_back_to_citizen_app", _run)

    # ──────────────────────────────────────────
    # TC-75: Forgot Password link visible
    # ──────────────────────────────────────────
    def test_TC75_forgot_password_link_visible(self):
        def _run():
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Forgot Password")]'), timeout=6
            ), "Forgot Password link not visible on Officer Login"
            self.take_screenshot("TC75_forgot_password")

        assert self.run_test("TC75_forgot_password_link_visible", _run)

    # ──────────────────────────────────────────
    # TC-76: Successful Officer Login → Officer Dashboard
    # ──────────────────────────────────────────
    def test_TC76_successful_officer_login(self):
        def _run():
            self._do_officer_login()
            assert self.is_element_visible(
                config.LOCATORS["officer_dashboard_title"], timeout=10
            ), "Officer Dashboard did not appear after login"
            self.take_screenshot("TC76_officer_dashboard")

        assert self.run_test("TC76_successful_officer_login", _run)

    # ──────────────────────────────────────────
    # TC-77: Officer Dashboard stats row visible
    # ──────────────────────────────────────────
    def test_TC77_officer_dashboard_stats_row(self):
        def _run():
            self._do_officer_login()
            for label in ["New", "In Progress", "Resolved", "Escalated"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{label}")]'), timeout=6
                ), f"Dashboard stat '{label}' not visible"
            self.take_screenshot("TC77_officer_stats")

        assert self.run_test("TC77_officer_dashboard_stats_row", _run)

    # ──────────────────────────────────────────
    # TC-78: Officer queue tabs visible
    # ──────────────────────────────────────────
    def test_TC78_officer_queue_tabs(self):
        def _run():
            self._do_officer_login()
            for tab in ["New", "In Progress", "Resolved", "Escalated"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{tab}")]'), timeout=6
                ), f"Queue tab '{tab}' not visible"
            self.take_screenshot("TC78_officer_queue_tabs")

        assert self.run_test("TC78_officer_queue_tabs", _run)

    # ──────────────────────────────────────────
    # TC-79: "New" tab shows queued issues
    # ──────────────────────────────────────────
    def test_TC79_new_tab_shows_issues(self):
        def _run():
            self._do_officer_login()
            time.sleep(1)
            # Click "New" tab explicitly
            new_tabs = self.find_elements(
                ("xpath", '//*[contains(@text,"New")]')
            )
            if new_tabs:
                new_tabs[0].click()
            time.sleep(1)
            # Pothole #WD24-007 is a "New" issue
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=8
            ), "No issues visible under 'New' tab"
            self.take_screenshot("TC79_new_tab_issues")

        assert self.run_test("TC79_new_tab_shows_issues", _run)

    # ──────────────────────────────────────────
    # TC-80: SLA progress bar visible on queue card
    # ──────────────────────────────────────────
    def test_TC80_sla_progress_bar_visible(self):
        def _run():
            self._do_officer_login()
            time.sleep(1)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"SLA")]'), timeout=8
            ), "SLA text not visible on queue cards"
            self.take_screenshot("TC80_sla_bar")

        assert self.run_test("TC80_sla_progress_bar_visible", _run)

    # ──────────────────────────────────────────
    # TC-81: Switch to "In Progress" tab
    # ──────────────────────────────────────────
    def test_TC81_switch_to_in_progress_tab(self):
        def _run():
            self._do_officer_login()
            in_prog_tabs = self.find_elements(
                ("xpath", '//*[contains(@text,"In Progress")]')
            )
            if in_prog_tabs:
                in_prog_tabs[0].click()
            time.sleep(1)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Pothole") or contains(@text,"Water Leak")]'),
                timeout=6
            ), "No In Progress issues visible"
            self.take_screenshot("TC81_in_progress_tab")

        assert self.run_test("TC81_switch_to_in_progress_tab", _run)

    # ──────────────────────────────────────────
    # TC-82: Tap issue card opens Officer Action screen
    # ──────────────────────────────────────────
    def test_TC82_issue_card_opens_action_screen(self):
        def _run():
            self._do_officer_login()
            time.sleep(1)
            issue = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=8
            )
            assert issue is not None, "No Pothole card found to tap"
            issue.click()
            time.sleep(1.5)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Update Status")]'), timeout=8
            ), "Officer Action screen 'Update Status' not visible"
            self.take_screenshot("TC82_officer_action_screen")

        assert self.run_test("TC82_issue_card_opens_action_screen", _run)

    # ──────────────────────────────────────────
    # TC-83: Officer Action screen — status grid visible
    # ──────────────────────────────────────────
    def test_TC83_officer_action_status_grid(self):
        def _run():
            self._do_officer_login()
            issue = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=8
            )
            if issue:
                issue.click()
            time.sleep(1.5)
            for s in ["Acknowledged", "In Progress", "Resolved", "Rejected"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{s}")]'), timeout=6
                ), f"Status option '{s}' not visible in action screen"
            self.take_screenshot("TC83_status_grid")

        assert self.run_test("TC83_officer_action_status_grid", _run)

    # ──────────────────────────────────────────
    # TC-84: Officer Action — Assign Field Crew options
    # ──────────────────────────────────────────
    def test_TC84_assign_field_crew_options(self):
        def _run():
            self._do_officer_login()
            issue = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=8
            )
            if issue:
                issue.click()
            time.sleep(1.5)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Assign Field Crew")]'), timeout=6
            ), "Assign Field Crew section not visible"
            self.swipe_up()
            for crew in ["Crew A", "Crew B"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{crew}")]'), timeout=6
                ), f"Crew option '{crew}' not visible"
            self.take_screenshot("TC84_crew_options")

        assert self.run_test("TC84_assign_field_crew_options", _run)

    # ──────────────────────────────────────────
    # TC-85: Officer Action — Update Status button works
    # ──────────────────────────────────────────
    def test_TC85_update_status_button(self):
        def _run():
            self._do_officer_login()
            issue = self.find_element(
                ("xpath", '//*[contains(@text,"Pothole")]'), timeout=8
            )
            if issue:
                issue.click()
            time.sleep(1.5)
            # Select "In Progress" status
            self.click_element(
                ("xpath", '//*[contains(@text,"In Progress")]')
            )
            time.sleep(0.5)
            # Scroll to Update button and click
            self.swipe_up(3)
            update_btn = self.find_element(
                ("xpath", '//*[contains(@text,"Update Status") or contains(@text,"Update")]'),
                timeout=6
            )
            assert update_btn is not None, "Update Status button not found"
            update_btn.click()
            time.sleep(config.SUBMIT_WAIT)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"updated") or contains(@text,"notified")]'),
                timeout=6
            ), "Status update confirmation not shown"
            self.take_screenshot("TC85_status_updated")

        assert self.run_test("TC85_update_status_button", _run)

    # ──────────────────────────────────────────
    # TC-86: Officer Logout returns to Login screen
    # ──────────────────────────────────────────
    def test_TC86_officer_logout(self):
        def _run():
            self._do_officer_login()
            # Logout icon in AppBar
            logout_icon = self.find_element(
                ("xpath", '//*[@content-desc="logout"]'), timeout=6
            )
            if logout_icon:
                logout_icon.click()
            else:
                # Fallback text-based
                self.tap_by_text("Logout")
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["welcome_back"], timeout=8
            ), "Login screen did not appear after officer logout"
            self.take_screenshot("TC86_officer_logged_out")

        assert self.run_test("TC86_officer_logout", _run)

    # ──────────────────────────────────────────
    # Helper
    # ──────────────────────────────────────────
    def _do_officer_login(self):
        """Fill in Officer ID + Password and tap Login."""
        id_field = self.find_element(
            config.LOCATORS["officer_id_input"], timeout=8
        )
        if id_field:
            id_field.clear()
            id_field.send_keys(config.OFFICER_ID)
        time.sleep(0.3)
        pass_field = self.find_element(
            config.LOCATORS["officer_pass_input"], timeout=6
        )
        if pass_field:
            pass_field.clear()
            pass_field.send_keys(config.OFFICER_PASS)
        time.sleep(0.3)
        self.click_element(config.LOCATORS["officer_login_btn"])
        time.sleep(config.LOGIN_WAIT)
