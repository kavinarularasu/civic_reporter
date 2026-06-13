"""
Example: Page Object Model Pattern for Appium Tests
Demonstrates best practices for test organization
"""
from selenium.webdriver.common.by import By
from base_test import BaseTest
import config


class LoginPage(BaseTest):
    """Page Object for Login Screen"""
    
    EMAIL_INPUT = ("xpath", "//android.widget.EditText[1]")
    PASSWORD_INPUT = ("xpath", "//android.widget.EditText[2]")
    LOGIN_BUTTON = ("xpath", "//android.widget.Button[@content-desc='LOGIN']")
    SIGNUP_BUTTON = ("xpath", "//android.widget.Button[@content-desc='SIGN UP']")
    ERROR_MESSAGE = ("xpath", "//*[contains(@text, 'Error')]")
    
    def __init__(self, driver):
        self.driver = driver
    
    def enter_email(self, email):
        """Enter email"""
        return self.send_text(self.EMAIL_INPUT, email)
    
    def enter_password(self, password):
        """Enter password"""
        return self.send_text(self.PASSWORD_INPUT, password)
    
    def click_login(self):
        """Click login button"""
        return self.wait_and_click(self.LOGIN_BUTTON)
    
    def click_signup(self):
        """Click signup button"""
        return self.wait_and_click(self.SIGNUP_BUTTON)
    
    def get_error_message(self):
        """Get error message text"""
        return self.get_element_text(self.ERROR_MESSAGE)
    
    def is_error_displayed(self):
        """Check if error is displayed"""
        return self.is_element_visible(self.ERROR_MESSAGE)
    
    def login(self, email, password):
        """Login with email and password"""
        self.enter_email(email)
        self.enter_password(password)
        return self.click_login()


class DashboardPage(BaseTest):
    """Page Object for Dashboard Screen"""
    
    CREATE_REPORT_BUTTON = ("xpath", "//android.widget.Button[@content-desc='CREATE REPORT']")
    LOGOUT_BUTTON = ("xpath", "//android.widget.Button[@content-desc='LOGOUT']")
    REPORTS_LIST = ("xpath", "//android.widget.ListView[@content-desc='REPORTS']")
    USER_PROFILE = ("xpath", "//android.widget.ImageButton[@content-desc='PROFILE']")
    
    def __init__(self, driver):
        self.driver = driver
    
    def click_create_report(self):
        """Click create report button"""
        return self.wait_and_click(self.CREATE_REPORT_BUTTON)
    
    def click_logout(self):
        """Click logout button"""
        return self.wait_and_click(self.LOGOUT_BUTTON)
    
    def is_dashboard_loaded(self):
        """Check if dashboard is loaded"""
        return self.is_element_visible(self.CREATE_REPORT_BUTTON)
    
    def open_user_profile(self):
        """Open user profile"""
        return self.wait_and_click(self.USER_PROFILE)


class ReportCreationPage(BaseTest):
    """Page Object for Report Creation"""
    
    TITLE_INPUT = ("xpath", "//android.widget.EditText[@content-desc='Title']")
    DESCRIPTION_INPUT = ("xpath", "//android.widget.EditText[@content-desc='Description']")
    PHOTO_BUTTON = ("xpath", "//android.widget.Button[@content-desc='ADD PHOTO']")
    LOCATION_BUTTON = ("xpath", "//android.widget.Button[@content-desc='USE LOCATION']")
    SUBMIT_BUTTON = ("xpath", "//android.widget.Button[@content-desc='SUBMIT']")
    CANCEL_BUTTON = ("xpath", "//android.widget.Button[@content-desc='CANCEL']")
    SUCCESS_MESSAGE = ("xpath", "//*[contains(@text, 'submitted')]")
    
    def __init__(self, driver):
        self.driver = driver
    
    def enter_title(self, title):
        """Enter report title"""
        return self.send_text(self.TITLE_INPUT, title)
    
    def enter_description(self, description):
        """Enter report description"""
        return self.send_text(self.DESCRIPTION_INPUT, description)
    
    def click_add_photo(self):
        """Click add photo button"""
        return self.wait_and_click(self.PHOTO_BUTTON)
    
    def click_use_location(self):
        """Click use location button"""
        return self.wait_and_click(self.LOCATION_BUTTON)
    
    def click_submit(self):
        """Click submit button"""
        return self.wait_and_click(self.SUBMIT_BUTTON)
    
    def click_cancel(self):
        """Click cancel button"""
        return self.wait_and_click(self.CANCEL_BUTTON)
    
    def is_success_displayed(self):
        """Check if success message is displayed"""
        return self.is_element_visible(self.SUCCESS_MESSAGE)
    
    def create_report(self, title, description):
        """Create report with title and description"""
        self.enter_title(title)
        self.enter_description(description)
        return self.click_submit()


# Example usage in test:
"""
def test_login_using_pom():
    driver = setup_driver()
    
    login_page = LoginPage(driver)
    login_page.login("test@example.com", "password123")
    
    dashboard_page = DashboardPage(driver)
    assert dashboard_page.is_dashboard_loaded()
    
    dashboard_page.click_create_report()
    
    report_page = ReportCreationPage(driver)
    report_page.create_report("Test Title", "Test Description")
    assert report_page.is_success_displayed()
"""
