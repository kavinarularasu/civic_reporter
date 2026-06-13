"""
Base Test Class for Selenium — Chrome WebDriver setup, helpers, screenshot
"""
import os
import time
import logging
from datetime import datetime
from typing import Optional, List

from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.edge.service import Service as EdgeService
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.common.exceptions import TimeoutException, WebDriverException

import config


class BaseTest:
    """Base Selenium test class. No __init__ — pytest requires clean classes."""

    # ── Logger ────────────────────────────────────────────────
    @staticmethod
    def _make_logger(name: str) -> logging.Logger:
        os.makedirs(config.REPORT_DIR, exist_ok=True)
        log_path = os.path.join(config.REPORT_DIR, "selenium_test_execution.log")
        logger   = logging.getLogger(name)
        if not logger.handlers:
            fh  = logging.FileHandler(log_path, encoding="utf-8")
            ch  = logging.StreamHandler()
            fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s -- %(message)s")
            fh.setFormatter(fmt)
            ch.setFormatter(fmt)
            logger.addHandler(fh)
            logger.addHandler(ch)
            logger.setLevel(logging.INFO)
        return logger

    # ── Driver Setup ──────────────────────────────────────────
    def setup_driver(self) -> bool:
        """Initialise Chrome (or configured browser) WebDriver."""
        self.driver       = None
        self.wait         = None
        self.test_results = []
        self.logger       = self._make_logger(self.__class__.__name__)
        os.makedirs(config.SCREENSHOT_DIR, exist_ok=True)

        try:
            browser = config.BROWSER.lower()

            if browser == "chrome":
                opts = ChromeOptions()
                if config.HEADLESS:
                    opts.add_argument("--headless=new")
                opts.add_argument("--no-sandbox")
                opts.add_argument("--disable-dev-shm-usage")
                opts.add_argument("--disable-gpu")
                opts.add_argument(f"--window-size={config.WINDOW_WIDTH},{config.WINDOW_HEIGHT}")
                opts.add_argument("--disable-extensions")
                opts.add_argument("--enable-accessibility-object-model")
                # Auto-install chromedriver via webdriver-manager if available
                try:
                    from webdriver_manager.chrome import ChromeDriverManager
                    driver_path = ChromeDriverManager().install()
                    if not driver_path.lower().endswith("chromedriver.exe"):
                        # Resolve actual chromedriver.exe path if webdriver-manager returned text/other file
                        search_dir = os.path.dirname(driver_path)
                        possible_paths = [
                            os.path.join(search_dir, "chromedriver.exe"),
                            os.path.join(search_dir, "chromedriver-win32", "chromedriver.exe"),
                            os.path.join(os.path.dirname(search_dir), "chromedriver.exe"),
                            os.path.join(os.path.dirname(search_dir), "chromedriver-win32", "chromedriver.exe")
                        ]
                        for path in possible_paths:
                            if os.path.exists(path):
                                driver_path = path
                                break
                    self.driver = webdriver.Chrome(
                        service=ChromeService(driver_path),
                        options=opts
                    )
                except ImportError:
                    self.driver = webdriver.Chrome(options=opts)

            elif browser == "firefox":
                opts = FirefoxOptions()
                if config.HEADLESS:
                    opts.add_argument("--headless")
                try:
                    from webdriver_manager.firefox import GeckoDriverManager
                    self.driver = webdriver.Firefox(
                        service=FirefoxService(GeckoDriverManager().install()),
                        options=opts
                    )
                except ImportError:
                    self.driver = webdriver.Firefox(options=opts)

            elif browser == "edge":
                opts = EdgeOptions()
                if config.HEADLESS:
                    opts.add_argument("--headless=new")
                try:
                    from webdriver_manager.microsoft import EdgeChromiumDriverManager
                    self.driver = webdriver.Edge(
                        service=EdgeService(EdgeChromiumDriverManager().install()),
                        options=opts
                    )
                except ImportError:
                    self.driver = webdriver.Edge(options=opts)

            else:
                raise ValueError(f"Unsupported browser: {browser}")

            self.driver.set_window_size(config.WINDOW_WIDTH, config.WINDOW_HEIGHT)
            self.driver.implicitly_wait(config.IMPLICIT_WAIT)
            self.driver.set_page_load_timeout(config.PAGE_LOAD_TIMEOUT)
            self.wait = WebDriverWait(self.driver, config.EXPLICIT_WAIT)
            self.logger.info(f"[{browser.upper()}] WebDriver initialised.")
            return True

        except Exception as e:
            self.logger.error(f"WebDriver init failed: {e}")
            return False

    def teardown_driver(self):
        if getattr(self, "driver", None):
            try:
                self.driver.quit()
                self.logger.info("WebDriver closed.")
            except Exception:
                pass

    # ── Flutter Web Accessibility ──────────────────────────────
    def enable_accessibility(self):
        """
        Enable Flutter web semantic/accessibility tree.
        Required before flt-semantics elements can be found.
        """
        start_time = time.time()
        timeout = 15.0
        self.logger.info("Enabling accessibility/semantics tree...")
        while time.time() - start_time < timeout:
            try:
                # Check if semantics host already has children
                has_semantics = self.driver.execute_script("""
                    const host = document.querySelector('flt-glass-pane');
                    if (host && host.shadowRoot) {
                        const semHost = host.shadowRoot.querySelector('flt-semantics-host');
                        if (semHost && semHost.children.length > 0) {
                            return true;
                        }
                    }
                    return false;
                """)
                if has_semantics:
                    self.logger.info("Accessibility semantics tree is active and populated.")
                    return
                
                # Attempt to click the placeholder inside shadowRoot of flt-glass-pane
                self.driver.execute_script("""
                    try {
                        const host = document.querySelector('flt-glass-pane');
                        if (host && host.shadowRoot) {
                            const placeholder = host.shadowRoot.querySelector('flt-semantics-placeholder') || 
                                                host.shadowRoot.querySelector('[aria-label="Enable accessibility"]');
                            if (placeholder) {
                                placeholder.click();
                            }
                        }
                    } catch (e) {}
                """)
                
                # Alternate JS event fallback
                self.driver.execute_script("""
                    var event = new KeyboardEvent('keydown', {key:'F', keyCode:70, shiftKey:true});
                    document.dispatchEvent(event);
                """)
            except Exception:
                pass
            time.sleep(1.0)
            
        self.logger.warning("Timed out waiting for accessibility semantics tree to activate.")

    def open_app(self):
        """Navigate to the web app and enable accessibility."""
        self.driver.get(config.BASE_URL)
        self.logger.info(f"Opened: {config.BASE_URL}")
        time.sleep(config.SPLASH_WAIT)
        self.enable_accessibility()

    # ── Element Helpers ────────────────────────────────────────
    def find_element(self, locator: tuple, timeout: int = None):
        """Return element or None (never raises)."""
        try:
            t  = timeout or config.EXPLICIT_WAIT
            el = WebDriverWait(self.driver, t).until(
                EC.presence_of_element_located(locator)
            )
            return el
        except Exception as e:
            self.logger.debug(f"find_element failed {locator}: {e}")
            return None

    def find_elements(self, locator: tuple) -> List:
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
            # Try normal click first, JS click as fallback
            try:
                el.click()
            except Exception:
                self.driver.execute_script("arguments[0].click();", el)
            self.logger.info(f"Clicked: {locator[1][:60]}")
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
                self.logger.info(f"Sent text '{text[:20]}' to {locator[1][:40]}")
                return True
            return False
        except Exception as e:
            self.logger.warning(f"send_text failed: {e}")
            return False

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

    def get_page_source(self) -> str:
        return self.driver.page_source or ""

    def page_contains(self, text: str, timeout: float = 8.0) -> bool:
        """
        Search for text in the rendered page source (innerText, raw source, or aria-labels).
        Retries up to `timeout` seconds to handle asynchronous page transitions.
        """
        start_time = time.time()
        while True:
            # 1. Check innerText via JS execution
            try:
                src = self.driver.execute_script(
                    "return document.body ? document.body.innerText : '';"
                )
                if text.lower() in (src or "").lower():
                    return True
            except Exception:
                pass
            
            # 2. Check raw HTML source (includes flt-semantics and aria-labels)
            try:
                raw_src = self.get_page_source()
                if text.lower() in raw_src.lower():
                    return True
            except Exception:
                pass

            # 3. Check elements with aria-label containing the text (Flutter Web specific)
            try:
                elements = self.find_elements(("xpath", f'//*[contains(@aria-label,"{text}")]'))
                if elements:
                    return True
            except Exception:
                pass

            # Check if timeout exceeded
            if time.time() - start_time >= timeout:
                break
            time.sleep(0.5)

        return False

    def scroll_down(self, pixels: int = 400):
        self.driver.execute_script(f"window.scrollBy(0, {pixels});")
        time.sleep(0.3)

    def scroll_up(self, pixels: int = 400):
        self.driver.execute_script(f"window.scrollBy(0, -{pixels});")
        time.sleep(0.3)

    def scroll_to_bottom(self):
        self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(0.5)

    def tap_by_text(self, text: str, timeout: int = 10) -> bool:
        locator = config.by_text_contains(text)
        return self.click_element(locator, timeout)

    def browser_back(self):
        self.driver.back()
        time.sleep(1)

    # ── Screenshot ────────────────────────────────────────────
    def take_screenshot(self, name: str) -> Optional[str]:
        try:
            ts   = datetime.now().strftime("%Y%m%d_%H%M%S")
            path = os.path.join(config.SCREENSHOT_DIR, f"{name}_{ts}.png")
            self.driver.save_screenshot(path)
            self.logger.info(f"Screenshot: {path}")
            return path
        except Exception as e:
            self.logger.warning(f"Screenshot failed: {e}")
            return None

    # ── Login Flow ────────────────────────────────────────────
    def login_with_phone_otp(self, phone: str = None, otp: str = None):
        """Complete phone -> OTP -> Dashboard flow."""
        phone = phone or config.TEST_PHONE
        otp   = otp   or config.TEST_OTP

        time.sleep(config.SPLASH_WAIT)

        # Enter phone
        phone_el = self.find_element(config.LOCATORS["phone_input"], timeout=8)
        if phone_el:
            phone_el.clear()
            phone_el.send_keys(phone)
        time.sleep(0.5)
        self.click_element(config.LOCATORS["send_otp_btn"])
        time.sleep(config.OTP_WAIT)

        # Check if we are already on the home/dashboard screen (auto-logged in)
        if self.page_contains("Ward 42") or self.page_contains("Quick Report"):
            self.logger.info("Auto-logged in directly to Dashboard without OTP entry.")
            return

        # Enter OTP — try individual boxes first, then single field
        otp_fields = self.find_elements(
            ("css selector", 'flt-semantics[role="textbox"], input')
        )
        if otp_fields and len(otp_fields) >= 6:
            for i, digit in enumerate(otp[:6]):
                try:
                    otp_fields[i].send_keys(digit)
                    time.sleep(0.2)
                except Exception as e:
                    self.logger.warning(f"Could not enter OTP digit {i}: {e}")
        elif otp_fields:
            try:
                otp_fields[0].send_keys(otp)
            except Exception as e:
                self.logger.warning(f"Could not enter OTP: {e}")

        # Click verify button if present
        verify_btn = config.LOCATORS["verify_btn"]
        if self.is_element_present(verify_btn, timeout=2):
            self.click_element(verify_btn)
            time.sleep(config.LOGIN_WAIT)

    # ── Result Recording ──────────────────────────────────────
    def record_test_result(self, test_name: str, status: str,
                           details: str = "", screenshot: str = ""):
        result = {
            "test_name":  test_name,
            "status":     status,
            "timestamp":  datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "details":    details,
            "screenshot": screenshot or "",
        }
        self.test_results.append(result)
        lvl = logging.INFO if status == "PASSED" else logging.WARNING
        self.logger.log(lvl, f"[{status}] {test_name} -- {details}")

    def run_test(self, test_name: str, fn) -> bool:
        """Safe test wrapper — catches all exceptions, takes screenshot on fail."""
        try:
            fn()
            self.record_test_result(test_name, "PASSED", "Test completed successfully.")
            return True
        except AssertionError as ae:
            shot = self.take_screenshot(f"FAIL_{test_name}")
            self.record_test_result(test_name, "FAILED", str(ae), shot or "")
            self.logger.error(f"ASSERTION FAILED -- {test_name}: {ae}")
            return False
        except Exception as e:
            shot = self.take_screenshot(f"ERROR_{test_name}")
            self.record_test_result(test_name, "FAILED", f"Exception: {e}", shot or "")
            self.logger.error(f"EXCEPTION -- {test_name}: {e}", exc_info=True)
            return False
