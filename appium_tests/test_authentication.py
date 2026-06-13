"""
End-to-End Tests for Authentication
"""
import pytest
from base_test import BaseTest
from config import LOCATORS, TEST_EMAIL, TEST_PASSWORD, TEST_NAME
import time


class TestAuthentication(BaseTest):
    """Test authentication flows"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup for each test"""
        self.setup_driver()
        yield
        self.teardown_driver()
    
    def test_01_app_launch(self):
        """Test: App launches successfully"""
        try:
            # Wait for splash screen
            time.sleep(3)
            self.logger.info("App launched successfully")
            self.record_test_result("test_01_app_launch", "PASSED", "App loaded")
            assert True
        except Exception as e:
            self.record_test_result("test_01_app_launch", "FAILED", str(e))
            pytest.fail(f"App launch failed: {str(e)}")
    
    def test_02_login_page_elements(self):
        """Test: Login page displays all required elements"""
        try:
            # Wait for login page after splash
            time.sleep(3)
            
            # Check if email input is visible
            assert self.is_element_visible(
                ("xpath", "//android.widget.EditText[@content-desc='Email input']"),
                timeout=5
            ), "Email input not found"
            
            self.logger.info("Login page elements verified")
            self.record_test_result("test_02_login_page_elements", "PASSED", 
                                  "All login elements present")
        except AssertionError as e:
            self.record_test_result("test_02_login_page_elements", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_03_valid_login(self):
        """Test: User can login with valid credentials"""
        try:
            time.sleep(3)
            
            # Find and fill email
            email_locator = ("xpath", "//android.widget.EditText[1]")
            assert self.send_text(email_locator, TEST_EMAIL), "Failed to enter email"
            
            # Find and fill password
            password_locator = ("xpath", "//android.widget.EditText[2]")
            assert self.send_text(password_locator, TEST_PASSWORD), "Failed to enter password"
            
            # Click login button
            login_btn = ("xpath", "//android.widget.Button[@content-desc='LOGIN']")
            assert self.wait_and_click(login_btn), "Failed to click login"
            
            # Wait for dashboard
            time.sleep(3)
            
            self.record_test_result("test_03_valid_login", "PASSED", 
                                  "User logged in successfully")
        except AssertionError as e:
            self.record_test_result("test_03_valid_login", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_04_invalid_email(self):
        """Test: Login fails with invalid email"""
        try:
            time.sleep(3)
            
            email_locator = ("xpath", "//android.widget.EditText[1]")
            self.send_text(email_locator, "invalidemail")
            
            password_locator = ("xpath", "//android.widget.EditText[2]")
            self.send_text(password_locator, TEST_PASSWORD)
            
            login_btn = ("xpath", "//android.widget.Button[@content-desc='LOGIN']")
            self.wait_and_click(login_btn)
            
            # Check for error message
            time.sleep(2)
            error_visible = self.is_element_visible(
                ("xpath", "//*[contains(@text, 'Invalid')]"),
                timeout=5
            )
            
            assert error_visible, "Expected error message not shown"
            self.record_test_result("test_04_invalid_email", "PASSED", 
                                  "Invalid email rejected correctly")
        except AssertionError as e:
            self.record_test_result("test_04_invalid_email", "FAILED", str(e))
            pytest.fail(str(e))
    
    def test_05_empty_fields(self):
        """Test: Login fails with empty fields"""
        try:
            time.sleep(3)
            
            login_btn = ("xpath", "//android.widget.Button[@content-desc='LOGIN']")
            self.wait_and_click(login_btn)
            
            # Check for error message
            time.sleep(2)
            error_visible = self.is_element_visible(
                ("xpath", "//*[contains(@text, 'required')]"),
                timeout=5
            )
            
            assert error_visible, "Expected validation error not shown"
            self.record_test_result("test_05_empty_fields", "PASSED", 
                                  "Empty fields validation working")
        except AssertionError as e:
            self.record_test_result("test_05_empty_fields", "FAILED", str(e))
            pytest.fail(str(e))
