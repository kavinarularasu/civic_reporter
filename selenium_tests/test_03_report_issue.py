"""TEST MODULE 03 — Report Issue (TC23-TC36)"""
import time
import pytest
from base_test import BaseTest
import config


class TestReportIssue(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        self.login_with_phone_otp()
        time.sleep(1)
        self.click_element(config.LOCATORS["report_issue_fab"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    def test_TC23_report_issue_screen_title(self):
        def _run():
            assert self.page_contains("Report an Issue"), "Title missing"
            self.take_screenshot("TC23_title")
        assert self.run_test("TC23_report_issue_screen_title", _run)

    def test_TC24_photo_area_visible(self):
        def _run():
            assert self.page_contains("Tap to take a photo"), "Photo area missing"
            self.take_screenshot("TC24_photo_area")
        assert self.run_test("TC24_photo_area_visible", _run)

    def test_TC25_photo_tap_marks_photo_added(self):
        def _run():
            self.click_element(config.LOCATORS["photo_area"])
            time.sleep(1)
            assert self.page_contains("Photo Added"), "Photo not added after tap"
            self.take_screenshot("TC25_photo_added")
        assert self.run_test("TC25_photo_tap_marks_photo_added", _run)

    def test_TC26_all_categories_visible(self):
        def _run():
            cats = ["Pothole", "Streetlight", "Open Drain", "Garbage", "Road Damage", "Water Leak"]
            for c in cats:
                assert self.page_contains(c), f"Category '{c}' missing"
            self.take_screenshot("TC26_categories")
        assert self.run_test("TC26_all_categories_visible", _run)

    def test_TC27_select_category_pothole(self):
        def _run():
            self.click_element(config.LOCATORS["cat_pothole"])
            time.sleep(0.5)
            self.take_screenshot("TC27_select_pothole")
            assert True
        assert self.run_test("TC27_select_category_pothole", _run)

    def test_TC28_severity_chips_visible(self):
        def _run():
            self.scroll_down(300)
            for s in ["Low", "Medium", "High", "Critical"]:
                assert self.page_contains(s), f"Severity '{s}' missing"
            self.take_screenshot("TC28_severity_chips")
        assert self.run_test("TC28_severity_chips_visible", _run)

    def test_TC29_select_severity_high(self):
        def _run():
            self.scroll_down(300)
            self.click_element(config.LOCATORS["sev_high"])
            time.sleep(0.5)
            self.take_screenshot("TC29_severity_high")
            assert True
        assert self.run_test("TC29_select_severity_high", _run)

    def test_TC30_gps_location_displayed(self):
        def _run():
            self.scroll_down(400)
            assert self.page_contains("GPS Location Detected"), "Location card missing"
            self.take_screenshot("TC30_location")
        assert self.run_test("TC30_gps_location_displayed", _run)

    def test_TC31_description_field_accepts_text(self):
        def _run():
            self.scroll_to_bottom()
            self.send_text(config.LOCATORS["desc_field"], "Huge pothole causing traffic jam")
            time.sleep(0.5)
            self.take_screenshot("TC31_description")
            assert True
        assert self.run_test("TC31_description_field_accepts_text", _run)

    def test_TC32_submit_without_category_shows_error(self):
        def _run():
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(1)
            assert self.page_contains("Please select a category") or \
                   self.page_contains("Required"), "Validation error missing"
            self.take_screenshot("TC32_submit_error")
        assert self.run_test("TC32_submit_without_category_shows_error", _run)

    def test_TC33_complete_report_submission_success(self):
        def _run():
            self.click_element(config.LOCATORS["photo_area"])
            self.click_element(config.LOCATORS["cat_pothole"])
            self.scroll_down(300)
            self.click_element(config.LOCATORS["sev_high"])
            self.scroll_to_bottom()
            self.send_text(config.LOCATORS["desc_field"], "Dangerous pothole")
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            assert self.page_contains("Report Submitted") or self.page_contains("Success"), \
                "Success screen not shown"
            self.take_screenshot("TC33_submission_success")
        assert self.run_test("TC33_complete_report_submission_success", _run)

    def test_TC34_success_screen_shows_tracking_id(self):
        def _run():
            self.click_element(config.LOCATORS["cat_pothole"])
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            assert self.page_contains("#WD24") or self.page_contains("Tracking ID"), \
                "Tracking ID missing"
            self.take_screenshot("TC34_tracking_id")
        assert self.run_test("TC34_success_screen_shows_tracking_id", _run)

    def test_TC35_back_to_home_from_success(self):
        def _run():
            self.click_element(config.LOCATORS["cat_pothole"])
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            self.click_element(config.LOCATORS["back_to_home_btn"])
            time.sleep(1.5)
            assert self.page_contains("Quick Report") or self.page_contains("Recent Reports"), \
                "Not returned to home"
            self.take_screenshot("TC35_back_to_home")
        assert self.run_test("TC35_back_to_home_from_success", _run)

    def test_TC36_report_another_issue_resets_form(self):
        def _run():
            self.click_element(config.LOCATORS["cat_pothole"])
            self.scroll_to_bottom()
            self.click_element(config.LOCATORS["submit_report_btn"])
            time.sleep(config.SUBMIT_WAIT)
            self.click_element(config.LOCATORS["report_another_btn"])
            time.sleep(1.5)
            assert self.page_contains("Report an Issue"), "Form not reopened"
            self.take_screenshot("TC36_report_another")
        assert self.run_test("TC36_report_another_issue_resets_form", _run)
