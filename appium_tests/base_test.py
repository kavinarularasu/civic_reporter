"""
Base Test Class — Shared driver setup, helpers, screenshot capture.
NOTE: No __init__ — pytest requires test classes have no constructor.
All state is initialised inside setup_driver().
"""
import os
import time
import logging
from datetime import datetime
from typing import Optional, List

from appium import webdriver
from appium.options.android import UiAutomator2Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import (
    TimeoutException, WebDriverException
)

import config


class BaseTest:
    """Base class for all Civic Reporter Appium tests.
    Attributes are assigned inside setup_driver() — no __init__ needed.
    """

    # ─────────────────────────────────────────
    # Logger (module-level, not per-instance)
    # ─────────────────────────────────────────
    @staticmethod
    def _make_logger(name: str) -> logging.Logger:
        log_path = os.path.join(config.REPORT_DIR, "test_execution.log")
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        logger = logging.getLogger(name)
        if not logger.handlers:
            fh  = logging.FileHandler(log_path, encoding="utf-8")
            ch  = logging.StreamHandler()
            fmt = logging.Formatter(
                "%(asctime)s [%(levelname)s] %(name)s — %(message)s"
            )
            fh.setFormatter(fmt)
            ch.setFormatter(fmt)
            logger.addHandler(fh)
            logger.addHandler(ch)
            logger.setLevel(logging.INFO)
        return logger

    # ─────────────────────────────────────────
    # Driver lifecycle
    # ─────────────────────────────────────────
    def setup_driver(self, no_reset: bool = False) -> bool:
        """Initialise Appium WebDriver. Call from pytest fixture."""
        # Initialise per-test instance state here (not in __init__)
        self.driver       = None
        self.wait         = None
        self.test_results = []
        self.logger       = self._make_logger(self.__class__.__name__)

        os.makedirs(config.SCREENSHOT_DIR, exist_ok=True)
        os.makedirs(config.REPORT_DIR,     exist_ok=True)

        try:
            opts = UiAutomator2Options()
            opts.platform_name           = "Android"
            opts.automation_name         = "UiAutomator2"
            opts.device_name             = config.ANDROID_DEVICE_NAME
            opts.platform_version        = config.ANDROID_PLATFORM_VERSION
            opts.app_package             = config.APP_PACKAGE
            opts.app_activity            = config.APP_ACTIVITY
            opts.auto_grant_permissions  = True
            opts.no_reset                = no_reset
            opts.new_command_timeout     = 120
            opts.set_capability("settings[ignoreUnimportantViews]", True)

            if os.path.exists(config.APK_PATH):
                opts.app = config.APK_PATH
                self.logger.info(f"Installing APK: {config.APK_PATH}")
            else:
                self.logger.warning(
                    f"APK not found at {config.APK_PATH} — assuming already installed."
                )

            self.driver = webdriver.Remote(config.APPIUM_URL, options=opts)
            self.wait   = WebDriverWait(self.driver, config.EXPLICIT_WAIT)
            self.driver.implicitly_wait(config.IMPLICIT_WAIT)
            self.logger.info("Appium WebDriver initialised successfully.")
            return True

        except Exception as e:
            self.logger.error(f"Failed to initialise WebDriver: {e}")
            return False

    def teardown_driver(self):
        """Quit the Appium driver gracefully."""
        if getattr(self, "driver", None):
            try:
                self.driver.quit()
                self.logger.info("WebDriver closed.")
            except Exception:
                pass

    # ─────────────────────────────────────────
    # Element helpers
    # ─────────────────────────────────────────
    def find_element(self, locator: tuple, timeout: int = None):
        """Return element or None (never raises)."""
        try:
            t  = timeout or config.EXPLICIT_WAIT
            el = WebDriverWait(self.driver, t).until(
                EC.presence_of_element_located(locator)
            )
            return el
        except (TimeoutException, WebDriverException) as e:
            self.logger.debug(f"find_element failed {locator}: {e}")
            return None

    def find_elements(self, locator: tuple) -> List:
        """Return list of matching elements (may be empty)."""
        try:
            return self.driver.find_elements(*locator)
        except Exception:
            return []

    def click_element(self, locator: tuple, timeout: int = None) -> bool:
        try:
            t  = timeout or config.EXPLICIT_WAIT
            el = WebDriverWait(self.driver, t).until(
                EC.element_to_be_clickable(locator)
            )
            el.click()
            self.logger.info(f"Clicked: {locator}")
            return True
        except Exception as e:
            self.logger.warning(f"click_element failed {locator}: {e}")
            return False

    def send_text(self, locator: tuple, text: str, clear: bool = True) -> bool:
        try:
            el = self.find_element(locator)
            if el:
                if clear:
                    el.clear()
                el.send_keys(text)
                self.logger.info(f"Sent text '{text[:20]}' to {locator}")
                return True
            return False
        except Exception as e:
            self.logger.warning(f"send_text failed {locator}: {e}")
            return False

    def get_element_text(self, locator: tuple) -> Optional[str]:
        el = self.find_element(locator)
        return el.text if el else None

    def is_element_visible(self, locator: tuple, timeout: int = 5) -> bool:
        try:
            WebDriverWait(self.driver, timeout).until(
                EC.visibility_of_element_located(locator)
            )
            return True
        except Exception:
            return False

    def is_element_present(self, locator: tuple, timeout: int = 5) -> bool:
        try:
            WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located(locator)
            )
            return True
        except Exception:
            return False

    def tap_by_text(self, text: str, timeout: int = 10) -> bool:
        locator = ("xpath", f'//*[contains(@text,"{text}")]')
        return self.click_element(locator, timeout)

    # ─────────────────────────────────────────
    # Scroll / Swipe
    # ─────────────────────────────────────────
    def swipe_up(self, times: int = 1):
        """Swipe up (scrolls down the page)."""
        size = self.driver.get_window_size()
        w, h = size["width"], size["height"]
        for _ in range(times):
            self.driver.swipe(w // 2, int(h * 0.7), w // 2, int(h * 0.3), 600)
            time.sleep(0.4)

    def swipe_down(self, times: int = 1):
        """Swipe down (scrolls up the page)."""
        size = self.driver.get_window_size()
        w, h = size["width"], size["height"]
        for _ in range(times):
            self.driver.swipe(w // 2, int(h * 0.3), w // 2, int(h * 0.7), 600)
            time.sleep(0.4)

    # ─────────────────────────────────────────
    # Screenshot
    # ─────────────────────────────────────────
    def take_screenshot(self, name: str) -> Optional[str]:
        try:
            ts   = datetime.now().strftime("%Y%m%d_%H%M%S")
            path = os.path.join(config.SCREENSHOT_DIR, f"{name}_{ts}.png")
            self.driver.save_screenshot(path)
            self.logger.info(f"Screenshot saved: {path}")
            return path
        except Exception as e:
            self.logger.warning(f"Screenshot failed: {e}")
            return None

    # ─────────────────────────────────────────
    # Login flow helper
    # ─────────────────────────────────────────
    def wait_for_splash_and_login(self):
        """Wait past the Splash screen to the Login screen."""
        self.logger.info("Waiting for Splash → Login transition…")
        time.sleep(config.SPLASH_WAIT)

    def login_with_phone_otp(self, phone: str = None, otp: str = None):
        """Complete phone → OTP → Dashboard login flow."""
        phone = phone or config.TEST_PHONE
        otp   = otp   or config.TEST_OTP

        self.wait_for_splash_and_login()

        # Enter phone number
        self.send_text(config.LOCATORS["phone_input"], phone)
        time.sleep(0.5)
        self.click_element(config.LOCATORS["send_otp_btn"])
        time.sleep(config.OTP_WAIT)

        # Fill OTP boxes
        otp_fields = self.find_elements(("xpath", "//android.widget.EditText"))
        if otp_fields and len(otp_fields) >= 6:
            for i, digit in enumerate(otp[:6]):
                otp_fields[i].send_keys(digit)
                time.sleep(0.2)
        elif otp_fields:
            otp_fields[0].send_keys(otp)

        self.click_element(config.LOCATORS["verify_btn"])
        time.sleep(config.LOGIN_WAIT)

    # ─────────────────────────────────────────
    # Result recording
    # ─────────────────────────────────────────
    def record_test_result(
        self,
        test_name: str,
        status: str,
        details: str = "",
        screenshot: str = ""
    ):
        result = {
            "test_name":  test_name,
            "status":     status,
            "timestamp":  datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "details":    details,
            "screenshot": screenshot or "",
        }
        self.test_results.append(result)
        level = logging.INFO if status == "PASSED" else logging.WARNING
        self.logger.log(level, f"[{status}] {test_name} — {details}")

    # ─────────────────────────────────────────
    # Safe test wrapper
    # ─────────────────────────────────────────
    def run_test(self, test_name: str, fn) -> bool:
        """
        Wrap a test function so exceptions are caught, screenshots taken
        on failure, and the result always recorded.
        Returns True on PASS, False on FAIL.
        """
        try:
            fn()
            self.record_test_result(test_name, "PASSED", "Test completed successfully.")
            return True
        except AssertionError as ae:
            shot = self.take_screenshot(f"FAIL_{test_name}")
            self.record_test_result(test_name, "FAILED", str(ae), shot or "")
            self.logger.error(f"ASSERTION FAILED — {test_name}: {ae}")
            return False
        except Exception as e:
            shot = self.take_screenshot(f"ERROR_{test_name}")
            self.record_test_result(test_name, "FAILED", f"Exception: {e}", shot or "")
            self.logger.error(f"EXCEPTION — {test_name}: {e}", exc_info=True)
            return False
