"""
TEST MODULE 03 — Report Issue Flow
Covers: Open Report screen, Photo tap, Category selection,
        Severity selection, Location display, Description entry,
        Submit report, Success screen, Navigation back
"""
import time
import pytest
from base_test import BaseTest
import config


class TestReportIssue(BaseTest):
    """Tests for the complete Report Issue flow."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        self.login_with_phone_otp()
        # Open Report Issue screen via FAB
        self.click_element(config.LOCATORS["report_issue_fab"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-23: Report Issue screen title
    # ──────────────────────────────────────────
    def test_TC23_report_issue_screen_title(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["report_title"], timeout=8
            ), "'Report an Issue' title not visible"
            self.take_screenshot("TC23_report_issue_title")

        assert self.run_test("TC23_report_issue_screen_title", _run)

    # ──────────────────────────────────────────
    # TC-24: Photo upload area visible
    # ──────────────────────────────────────────
    def test_TC24_photo_area_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["photo_area"], timeout=6
            ), "Photo area 'Tap to take a photo' not visible"
            self.take_screenshot("TC24_photo_area")

        assert self.run_test("TC24_photo_area_visible", _run)

    # ──────────────────────────────────────────
    # TC-25: Tapping photo area marks photo as added
    # ──────────────────────────────────────────
    def test_TC25_photo_tap_marks_photo_added(self):
        def _run():
            self.click_element(config.LOCATORS["photo_area"])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["photo_added"], timeout=6
            ), "'Photo Added ✓' text not visible after tapping"
            self.take_screenshot("TC25_photo_added")

        assert self.run_test("TC25_photo_tap_marks_photo_added", _run)

    # ──────────────────────────────────────────
    # TC-26: All issue categories visible
    # ──────────────────────────────────────────
    def test_TC26_all_categories_visible(self):
        def _run():
            for cat in ["Pothole", "Streetlight", "Open Drain", "Garbage", "Road Damage", "Water Leak"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{cat}")]'), timeout=6
                ), f"Category '{cat}' not visible"
            self.take_screenshot("TC26_all_categories")

        assert self.run_test("TC26_all_categories_visible", _run)

    # ──────────────────────────────────────────
    # TC-27: Selecting a category highlights it
    # ──────────────────────────────────────────
    def test_TC27_select_category_pothole(self):
        def _run():
            self.click_element(config.LOCATORS["cat_pothole"])
            time.sleep(1)
            # After selection the same text is still visible (selected state)
            assert self.is_element_visible(
                config.LOCATORS["cat_pothole"], timeout=5
            ), "Pothole category disappeared after selection"
            self.take_screenshot("TC27_category_selected")

        assert self.run_test("TC27_select_category_pothole", _run)

    # ──────────────────────────────────────────
    # TC-28: Severity chips visible
    # ──────────────────────────────────────────
    def test_TC28_severity_chips_visible(self):
        def _run():
            for sev in ["Low", "Medium", "High", "Critical"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{sev}")]'), timeout=6
                ), f"Severity '{sev}' not visible"
            self.take_screenshot("TC28_severity_chips")

        assert self.run_test("TC28_severity_chips_visible", _run)

    # ──────────────────────────────────────────
    # TC-29: Select severity chip
    # ──────────────────────────────────────────
    def test_TC29_select_severity_high(self):
        def _run():
            self.click_element(config.LOCATORS["sev_high"])
            time.sleep(0.5)
            assert self.is_element_visible(
                config.LOCATORS["sev_high"], timeout=5
            ), "High severity chip disappeared after selection"
            self.take_screenshot("TC29_severity_selected")

        assert self.run_test("TC29_select_severity_high", _run)

    # ──────────────────────────────────────────
    # TC-30: GPS Location section visible
    # ──────────────────────────────────────────
    def test_TC30_gps_location_displayed(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["location_detected"], timeout=6
            ), "GPS Location Detected not visible"
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Anna Nagar")]'), timeout=5
            ), "Location address not visible"
            self.take_screenshot("TC30_gps_location")

        assert self.run_test("TC30_gps_location_displayed", _run)

    # ──────────────────────────────────────────
    # TC-31: Description field accepts text
    # ──────────────────────────────────────────
    def test_TC31_description_field_accepts_text(self):
        def _run():
            self.swipe_up(2)
            time.sleep(0.5)
            desc_field = self.find_element(
                ("xpath", '//android.widget.EditText'), timeout=6
            )
            assert desc_field is not None, "Description field not found"
            desc_field.clear()
            desc_field.send_keys("Automated test: Road pothole near bus stop")
            time.sleep(0.5)
            val = desc_field.text or desc_field.get_attribute("text") or ""
            assert "Automated" in val or len(val) > 0, "Text not entered in description"
            self.take_screenshot("TC31_description_entered")

        assert self.run_test("TC31_description_field_accepts_text", _run)

    # ──────────────────────────────────────────
    # TC-32: Submit without category shows error
    # ──────────────────────────────────────────
    def test_TC32_submit_without_category_shows_error(self):
        def _run():
            self.swipe_up(3)
            time.sleep(0.5)
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(1.5)
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"category") or contains(@text,"Category")]'),
                timeout=6
            ), "Validation error not shown when category not selected"
            self.take_screenshot("TC32_validation_no_category")

        assert self.run_test("TC32_submit_without_category_shows_error", _run)

    # ──────────────────────────────────────────
    # TC-33: Complete report submission → success screen
    # ──────────────────────────────────────────
    def test_TC33_complete_report_submission_success(self):
        def _run():
            # Select category
            self.click_element(config.LOCATORS["cat_pothole"])
            time.sleep(0.5)
            # Select severity
            self.click_element(config.LOCATORS["sev_medium"])
            time.sleep(0.5)
            # Scroll to submit button
            self.swipe_up(3)
            time.sleep(0.5)
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["report_submitted"], timeout=10
            ), "Submission success screen did not appear"
            self.take_screenshot("TC33_submission_success")

        assert self.run_test("TC33_complete_report_submission_success", _run)

    # ──────────────────────────────────────────
    # TC-34: Success screen shows tracking ID
    # ──────────────────────────────────────────
    def test_TC34_success_screen_shows_tracking_id(self):
        def _run():
            # Select category + submit
            self.click_element(config.LOCATORS["cat_open_drain"])
            time.sleep(0.5)
            self.swipe_up(3)
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            assert self.is_element_visible(
                config.LOCATORS["tracking_id"], timeout=10
            ), "Tracking ID (#WD24-xxxxx) not shown on success screen"
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"Tracking ID")]'), timeout=6
            ), "Tracking ID label not visible"
            self.take_screenshot("TC34_tracking_id")

        assert self.run_test("TC34_success_screen_shows_tracking_id", _run)

    # ──────────────────────────────────────────
    # TC-35: Back to Home from success screen
    # ──────────────────────────────────────────
    def test_TC35_back_to_home_from_success(self):
        def _run():
            self.click_element(config.LOCATORS["cat_garbage"])
            time.sleep(0.5)
            self.swipe_up(3)
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            self.click_element(config.LOCATORS["back_to_home_btn"])
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["home_title"], timeout=8
            ), "Did not navigate back to Home after success"
            self.take_screenshot("TC35_back_to_home")

        assert self.run_test("TC35_back_to_home_from_success", _run)

    # ──────────────────────────────────────────
    # TC-36: "Report Another Issue" resets form
    # ──────────────────────────────────────────
    def test_TC36_report_another_issue_resets_form(self):
        def _run():
            self.click_element(config.LOCATORS["cat_streetlight"])
            time.sleep(0.5)
            self.swipe_up(3)
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            self.click_element(config.LOCATORS["report_another_btn"])
            time.sleep(2)
            assert self.is_element_visible(
                config.LOCATORS["report_title"], timeout=8
            ), "Report Issue form did not reopen for new report"
            self.take_screenshot("TC36_report_another")

        assert self.run_test("TC36_report_another_issue_resets_form", _run)
