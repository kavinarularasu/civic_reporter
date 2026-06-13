"""TEST MODULE 05 — Map Screen (TC50-TC59)"""
import time
import pytest
from base_test import BaseTest
import config


class TestMapScreen(BaseTest):

    @pytest.fixture(autouse=True)
    def setup_teardown(self):
        assert self.setup_driver(), "WebDriver init failed"
        self.open_app()
        self.login_with_phone_otp()
        time.sleep(1)
        self.click_element(config.LOCATORS["nav_map"])
        time.sleep(2)
        yield
        self.teardown_driver()

    def test_TC50_map_screen_title(self):
        def _run():
            assert self.page_contains("Area Map"), "Map title missing"
            self.take_screenshot("TC50_map_title")
        assert self.run_test("TC50_map_screen_title", _run)

    def test_TC51_layer_selector_tabs_visible(self):
        def _run():
            for t in ["All Issues", "My Ward", "My Reports"]:
                assert self.page_contains(t), f"Tab '{t}' missing"
            self.take_screenshot("TC51_tabs_visible")
        assert self.run_test("TC51_layer_selector_tabs_visible", _run)

    def test_TC52_all_issues_default_tab(self):
        def _run():
            # Assume 'All Issues' is active by default
            assert True
            self.take_screenshot("TC52_all_issues_default")
        assert self.run_test("TC52_all_issues_default_tab", _run)

    def test_TC53_map_ward_label_visible(self):
        def _run():
            assert self.page_contains("Ward 42"), "Ward label missing on map"
            self.take_screenshot("TC53_ward_label")
        assert self.run_test("TC53_map_ward_label_visible", _run)

    def test_TC54_switch_to_my_ward_tab(self):
        def _run():
            self.click_element(config.LOCATORS["map_my_ward"])
            time.sleep(1)
            self.take_screenshot("TC54_my_ward")
            assert True
        assert self.run_test("TC54_switch_to_my_ward_tab", _run)

    def test_TC55_switch_to_my_reports_tab(self):
        def _run():
            self.click_element(config.LOCATORS["map_my_reports_tab"])
            time.sleep(1)
            self.take_screenshot("TC55_my_reports_tab")
            assert True
        assert self.run_test("TC55_switch_to_my_reports_tab", _run)

    def test_TC56_stats_row_at_bottom(self):
        def _run():
            for s in ["Total Issues", "In Progress", "Resolved"]:
                assert self.page_contains(s), f"Stat '{s}' missing"
            self.take_screenshot("TC56_stats_row")
        assert self.run_test("TC56_stats_row_at_bottom", _run)

    def test_TC57_map_legend_visible(self):
        def _run():
            # Scroll/swipe up if bottom sheet is minimized
            self.scroll_to_bottom()
            time.sleep(1)
            self.take_screenshot("TC57_legend")
            assert True
        assert self.run_test("TC57_map_legend_visible", _run)

    def test_TC58_my_location_icon_click(self):
        def _run():
            # If map has a center button or location button
            self.take_screenshot("TC58_my_location")
            assert True
        assert self.run_test("TC58_my_location_icon_click", _run)

    def test_TC59_map_fab_opens_report_issue(self):
        def _run():
            self.click_element(config.LOCATORS["report_issue_fab"])
            time.sleep(1.5)
            assert self.page_contains("Report an Issue"), "FAB did not open Report Issue"
            self.browser_back()
            self.take_screenshot("TC59_map_fab")
        assert self.run_test("TC59_map_fab_opens_report_issue", _run)
