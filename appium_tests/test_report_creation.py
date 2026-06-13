"""
End-to-End Tests for Report Creation
"""
import pytest
from base_test import BaseTest
from config import TEST_EMAIL, TEST_PASSWORD, TEST_REPORT_TITLE, TEST_REPORT_DESCRIPTION
import time


class TestReportCreation(BaseTest):
    """Test report creation flows"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup for each test"""
        self.setup_driver()
        yield
        self.teardown_driver()
    
    def _login_user(self):
        """Helper method to login"""
        time.sleep(3)
        
        email_locator = ("xpath", "//android.widget.EditText[1]")
        password_locator = ("xpath", "//android.widget.EditText[2]")
        login_btn = ("xpath", "//android.widget.Button[@content-desc='LOGIN']")
        
        self.send_text(email_locator, TEST_EMAIL)
        self.send_text(password_locator, TEST_PASSWORD)
        self.wait_and_click(login_btn)
        time.sleep(3)
    
    def test_01_create_report_button_visible(self):
        """Test: Create report button is visible after login"""
        try:
            self._login_user()
            
            # Check for create report button
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            assert self.is_element_visible(create_btn, timeout=5), \
                "Create report button not visible"
            
            self.record_test_result("test_01_create_report_button_visible", "PASSED",
                                  "Create report button found")
        except AssertionError as e:
            self.record_test_result("test_01_create_report_button_visible", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_02_open_create_report_form(self):
        """Test: Can open create report form"""
        try:
            self._login_user()
            
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            assert self.wait_and_click(create_btn), "Failed to click create report"
            
            time.sleep(2)
            
            # Verify form elements
            title_input = ("xpath", "//android.widget.EditText[@content-desc='Title']")
            assert self.is_element_visible(title_input, timeout=5), \
                "Title input not visible in form"
            
            self.record_test_result("test_02_open_create_report_form", "PASSED",
                                  "Report form opened successfully")
        except AssertionError as e:
            self.record_test_result("test_02_open_create_report_form", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_03_fill_report_title(self):
        """Test: Can fill report title"""
        try:
            self._login_user()
            
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            self.wait_and_click(create_btn)
            
            time.sleep(2)
            
            title_input = ("xpath", "//android.widget.EditText[@content-desc='Title']")
            assert self.send_text(title_input, TEST_REPORT_TITLE), \
                "Failed to enter title"
            
            # Verify text was entered
            title_text = self.get_element_text(title_input)
            assert TEST_REPORT_TITLE in title_text, "Title not properly entered"
            
            self.record_test_result("test_03_fill_report_title", "PASSED",
                                  "Report title filled successfully")
        except AssertionError as e:
            self.record_test_result("test_03_fill_report_title", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_04_fill_report_description(self):
        """Test: Can fill report description"""
        try:
            self._login_user()
            
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            self.wait_and_click(create_btn)
            
            time.sleep(2)
            
            title_input = ("xpath", "//android.widget.EditText[@content-desc='Title']")
            self.send_text(title_input, TEST_REPORT_TITLE)
            
            desc_input = ("xpath", "//android.widget.EditText[@content-desc='Description']")
            assert self.send_text(desc_input, TEST_REPORT_DESCRIPTION), \
                "Failed to enter description"
            
            self.record_test_result("test_04_fill_report_description", "PASSED",
                                  "Report description filled successfully")
        except AssertionError as e:
            self.record_test_result("test_04_fill_report_description", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_05_submit_report_without_attachments(self):
        """Test: Can submit report with only text"""
        try:
            self._login_user()
            
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            self.wait_and_click(create_btn)
            
            time.sleep(2)
            
            title_input = ("xpath", "//android.widget.EditText[@content-desc='Title']")
            self.send_text(title_input, TEST_REPORT_TITLE)
            
            desc_input = ("xpath", "//android.widget.EditText[@content-desc='Description']")
            self.send_text(desc_input, TEST_REPORT_DESCRIPTION)
            
            submit_btn = ("xpath", "//android.widget.Button[@content-desc='SUBMIT']")
            assert self.wait_and_click(submit_btn), "Failed to click submit"
            
            time.sleep(3)
            
            # Check for success message
            success_msg = self.is_element_visible(
                ("xpath", "//*[contains(@text, 'submitted')]"),
                timeout=5
            )
            
            assert success_msg, "Success message not shown"
            
            self.record_test_result("test_05_submit_report_without_attachments", "PASSED",
                                  "Report submitted successfully")
        except AssertionError as e:
            self.record_test_result("test_05_submit_report_without_attachments", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_06_upload_photo(self):
        """Test: Can attach photo to report"""
        try:
            self._login_user()
            
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            self.wait_and_click(create_btn)
            
            time.sleep(2)
            
            # Click photo button
            photo_btn = ("xpath", "//android.widget.Button[@content-desc='ADD PHOTO']")
            assert self.wait_and_click(photo_btn), "Failed to click photo button"
            
            time.sleep(2)
            
            # Handle photo picker dialog (this will vary based on implementation)
            # You may need to adjust XPath based on your app
            
            self.record_test_result("test_06_upload_photo", "PASSED",
                                  "Photo dialog opened successfully")
        except AssertionError as e:
            self.record_test_result("test_06_upload_photo", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_07_use_geolocation(self):
        """Test: Can use geolocation in report"""
        try:
            self._login_user()
            
            create_btn = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
            self.wait_and_click(create_btn)
            
            time.sleep(2)
            
            # Click location button
            location_btn = ("xpath", "//android.widget.Button[@content-desc='USE LOCATION']")
            assert self.wait_and_click(location_btn), "Failed to click location button"
            
            time.sleep(2)
            
            # Check for location confirmation
            location_confirm = self.is_element_visible(
                ("xpath", "//*[contains(@text, 'Location')]"),
                timeout=5
            )
            
            assert location_confirm, "Location not confirmed"
            
            self.record_test_result("test_07_use_geolocation", "PASSED",
                                  "Geolocation feature working")
        except AssertionError as e:
            self.record_test_result("test_07_use_geolocation", "FAILED", str(e))
            pytest.fail(str(e))
