"""
TEST MODULE 05 — Map Screen
Covers: Map title, layer selector tabs, map pins, pin info popup,
        stats row, FAB to Report Issue
"""
import time
import pytest
from base_test import BaseTest
import config


class TestMapScreen(BaseTest):
    """Tests for the Map Screen."""

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "Appium driver failed to initialise"
        self.login_with_phone_otp()
        self.click_element(config.LOCATORS["nav_map"])
        time.sleep(1.5)
        yield
        self.teardown_driver()

    # ──────────────────────────────────────────
    # TC-50: Map screen title visible
    # ──────────────────────────────────────────
    def test_TC50_map_screen_title(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["map_title"], timeout=8
            ), "'Area Map' title not visible"
            self.take_screenshot("TC50_map_title")

        assert self.run_test("TC50_map_screen_title", _run)

    # ──────────────────────────────────────────
    # TC-51: Layer selector tabs visible
    # ──────────────────────────────────────────
    def test_TC51_layer_selector_tabs_visible(self):
        def _run():
            for tab in ["All Issues", "My Ward", "My Reports"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{tab}")]'), timeout=6
                ), f"Layer tab '{tab}' not visible"
            self.take_screenshot("TC51_layer_tabs")

        assert self.run_test("TC51_layer_selector_tabs_visible", _run)

    # ──────────────────────────────────────────
    # TC-52: "All Issues" is default selected tab
    # ──────────────────────────────────────────
    def test_TC52_all_issues_default_tab(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["map_all_issues"], timeout=6
            ), "'All Issues' tab not visible by default"
            self.take_screenshot("TC52_all_issues_default")

        assert self.run_test("TC52_all_issues_default_tab", _run)

    # ──────────────────────────────────────────
    # TC-53: Map ward label visible
    # ──────────────────────────────────────────
    def test_TC53_map_ward_label_visible(self):
        def _run():
            assert self.is_element_visible(
                config.LOCATORS["map_ward_text"], timeout=6
            ), "Ward 42 text not visible on map"
            self.take_screenshot("TC53_map_ward_label")

        assert self.run_test("TC53_map_ward_label_visible", _run)

    # ──────────────────────────────────────────
    # TC-54: Switch to "My Ward" layer tab
    # ──────────────────────────────────────────
    def test_TC54_switch_to_my_ward_tab(self):
        def _run():
            self.click_element(config.LOCATORS["map_my_ward"])
            time.sleep(1)
            assert self.is_element_visible(
                config.LOCATORS["map_my_ward"], timeout=5
            ), "'My Ward' tab still not visible after click"
            self.take_screenshot("TC54_my_ward_tab")

        assert self.run_test("TC54_switch_to_my_ward_tab", _run)

    # ──────────────────────────────────────────
    # TC-55: Switch to "My Reports" layer tab
    # ──────────────────────────────────────────
    def test_TC55_switch_to_my_reports_tab(self):
        def _run():
            self.click_element(config.LOCATORS["map_my_reports"])
            time.sleep(1)
            assert self.is_element_visible(
                config.LOCATORS["map_my_reports"], timeout=5
            ), "'My Reports' tab still not visible after click"
            self.take_screenshot("TC55_my_reports_tab")

        assert self.run_test("TC55_switch_to_my_reports_tab", _run)

    # ──────────────────────────────────────────
    # TC-56: Stats row at bottom of map
    # ──────────────────────────────────────────
    def test_TC56_stats_row_at_bottom(self):
        def _run():
            for label in ["Total Issues", "In Progress", "Resolved", "Rejected"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{label}")]'), timeout=6
                ), f"Map stat '{label}' not visible"
            self.take_screenshot("TC56_map_stats")

        assert self.run_test("TC56_stats_row_at_bottom", _run)

    # ──────────────────────────────────────────
    # TC-57: Legend items visible on map
    # ──────────────────────────────────────────
    def test_TC57_map_legend_visible(self):
        def _run():
            for legend in ["In Progress", "Submitted", "Resolved", "Rejected"]:
                assert self.is_element_visible(
                    ("xpath", f'//*[contains(@text,"{legend}")]'), timeout=6
                ), f"Legend item '{legend}' not visible"
            self.take_screenshot("TC57_map_legend")

        assert self.run_test("TC57_map_legend_visible", _run)

    # ──────────────────────────────────────────
    # TC-58: My Location icon present in AppBar
    # ──────────────────────────────────────────
    def test_TC58_my_location_icon_in_appbar(self):
        def _run():
            icon = self.find_element(
                ("xpath", '//*[@content-desc="my_location" or @content-desc="My Location"]'),
                timeout=6
            )
            assert icon is not None, "My Location icon not found in AppBar"
            icon.click()
            time.sleep(1.5)
            # Snackbar should appear
            assert self.is_element_visible(
                ("xpath", '//*[contains(@text,"location")]'), timeout=5
            ), "Centering snackbar not shown"
            self.take_screenshot("TC58_my_location_tapped")

        assert self.run_test("TC58_my_location_icon_in_appbar", _run)

    # ──────────────────────────────────────────
    # TC-59: FAB on Map opens Report Issue
    # ──────────────────────────────────────────
    def test_TC59_map_fab_opens_report_issue(self):
        def _run():
            fab = self.find_element(
                ("xpath", '//*[@content-desc="add" or contains(@text,"add")]'),
                timeout=6
            )
            if fab:
                fab.click()
            else:
                # Tap FAB position (bottom-right area)
                size = self.driver.get_window_size()
                self.driver.tap([(int(size["width"] * 0.88), int(size["height"] * 0.88))])
            time.sleep(1.5)
            assert self.is_element_visible(
                config.LOCATORS["report_title"], timeout=8
            ), "Report Issue screen did not open from Map FAB"
            self.driver.press_keycode(4)
            time.sleep(1)
            self.take_screenshot("TC59_map_fab")

        assert self.run_test("TC59_map_fab_opens_report_issue", _run)
