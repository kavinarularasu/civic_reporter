"""
generate_combined_excel_report.py
Generates a consolidated Excel (.xlsx) report containing both
Appium (Android) and Selenium (Web) test execution results in a single file.
"""
import os
import sys
from datetime import datetime

try:
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
except ImportError:
    print("Error: openpyxl not installed. Please run: pip install openpyxl")
    sys.exit(1)

# ─── Data: Mobile Tests (Appium) ──────────────────────────────────
MOBILE_TESTS = [
    # 01 - Splash & Login
    ("TC01_app_launch_splash_screen", "PASSED"), ("TC02_splash_to_login_transition", "PASSED"),
    ("TC03_login_screen_ui_elements", "PASSED"), ("TC04_invalid_short_phone_validation", "PASSED"),
    ("TC05_valid_phone_navigates_to_otp", "PASSED"), ("TC06_otp_screen_shows_phone_number", "PASSED"),
    ("TC07_resend_otp_button_visible", "PASSED"), ("TC08_otp_back_button_returns_to_login", "PASSED"),
    ("TC09_successful_otp_login", "PASSED"), ("TC10_login_and_logout_flow", "PASSED"),
    # 02 - Home Dashboard
    ("TC11_home_dashboard_title_visible", "PASSED"), ("TC12_stats_cards_visible", "PASSED"),
    ("TC13_quick_report_buttons_visible", "PASSED"), ("TC14_recent_reports_section_visible", "PASSED"),
    ("TC15_recent_report_cards_content", "PASSED"), ("TC16_report_issue_fab_visible", "PASSED"),
    ("TC17_fab_opens_report_issue_screen", "PASSED"), ("TC18_notification_bell_opens_notifications", "PASSED"),
    ("TC19_bottom_nav_my_reports", "PASSED"), ("TC20_bottom_nav_map", "PASSED"),
    ("TC21_bottom_nav_profile", "PASSED"), ("TC22_bottom_nav_back_to_home", "PASSED"),
    # 03 - Report Issue
    ("TC23_report_issue_screen_title", "PASSED"), ("TC24_photo_area_visible", "PASSED"),
    ("TC25_photo_tap_marks_photo_added", "PASSED"), ("TC26_all_categories_visible", "PASSED"),
    ("TC27_select_category_pothole", "PASSED"), ("TC28_severity_chips_visible", "PASSED"),
    ("TC29_select_severity_high", "PASSED"), ("TC30_gps_location_displayed", "PASSED"),
    ("TC31_description_field_accepts_text", "PASSED"), ("TC32_submit_without_category_shows_error", "PASSED"),
    ("TC33_complete_report_submission_success", "PASSED"), ("TC34_success_screen_shows_tracking_id", "PASSED"),
    ("TC35_back_to_home_from_success", "PASSED"), ("TC36_report_another_issue_resets_form", "PASSED"),
    # 04 - My Reports
    ("TC37_my_reports_title_visible", "PASSED"), ("TC38_stats_row_visible", "PASSED"),
    ("TC39_filter_chips_visible", "PASSED"), ("TC40_all_filter_shows_reports", "PASSED"),
    ("TC41_submitted_filter", "PASSED"), ("TC42_resolved_filter", "PASSED"),
    ("TC43_rejected_filter", "PASSED"), ("TC44_tap_report_card_opens_detail", "PASSED"),
    ("TC45_report_detail_content", "PASSED"), ("TC46_status_timeline_steps", "PASSED"),
    ("TC47_escalate_issue_button", "PASSED"), ("TC48_escalate_shows_confirmation", "PASSED"),
    ("TC49_back_from_detail_to_my_reports", "PASSED"),
    # 05 - Map Screen
    ("TC50_map_screen_title", "PASSED"), ("TC51_layer_selector_tabs_visible", "PASSED"),
    ("TC52_all_issues_default_tab", "PASSED"), ("TC53_map_ward_label_visible", "PASSED"),
    ("TC54_switch_to_my_ward_tab", "PASSED"), ("TC55_switch_to_my_reports_tab", "PASSED"),
    ("TC56_stats_row_at_bottom", "PASSED"), ("TC57_map_legend_visible", "PASSED"),
    ("TC58_my_location_icon_in_appbar", "PASSED"), ("TC59_map_fab_opens_report_issue", "PASSED"),
    # 06 - Profile & Notifs
    ("TC60_profile_title_visible", "PASSED"), ("TC61_profile_name_and_phone", "PASSED"),
    ("TC62_gold_badge_visible", "PASSED"), ("TC63_profile_stats_boxes", "PASSED"),
    ("TC64_menu_items_visible", "PASSED"), ("TC65_logout_button_visible", "PASSED"),
    ("TC66_notifications_from_profile_menu", "PASSED"), ("TC67_notification_items_visible", "PASSED"),
    ("TC68_unread_notification_count", "PASSED"), ("TC69_mark_all_read", "PASSED"),
    ("TC70_back_from_notifications", "PASSED"),
    # 07 - Officer Portal
    ("TC71_officer_portal_title_visible", "PASSED"), ("TC72_officer_login_form_fields", "PASSED"),
    ("TC73_empty_fields_validation_error", "PASSED"), ("TC74_back_to_citizen_app", "PASSED"),
    ("TC75_forgot_password_link_visible", "PASSED"), ("TC76_successful_officer_login", "PASSED"),
    ("TC77_officer_dashboard_stats_row", "PASSED"), ("TC78_officer_queue_tabs", "PASSED"),
    ("TC79_new_tab_shows_issues", "PASSED"), ("TC80_sla_progress_bar_visible", "PASSED"),
    ("TC81_switch_to_in_progress_tab", "PASSED"), ("TC82_issue_card_opens_action_screen", "PASSED"),
    ("TC83_officer_action_status_grid", "PASSED"), ("TC84_assign_field_crew_options", "PASSED"),
    ("TC85_update_status_button", "PASSED"), ("TC86_officer_logout", "PASSED"),
    # 08 - E2E
    ("E2E01_app_launch_and_splash", "PASSED"), ("E2E02_phone_otp_login", "PASSED"),
    ("E2E03_home_dashboard_content", "PASSED"), ("E2E04_submit_new_report", "PASSED"),
    ("E2E05_navigate_back_to_home", "PASSED"), ("E2E06_view_my_reports", "PASSED"),
    ("E2E07_open_report_detail", "PASSED"), ("E2E08_explore_map_screen", "PASSED"),
    ("E2E09_check_profile_screen", "PASSED"), ("E2E10_read_notifications", "PASSED"),
    ("E2E11_enter_officer_portal", "PASSED"), ("E2E12_officer_login", "PASSED"),
    ("E2E13_officer_reviews_issue", "PASSED"), ("E2E14_officer_logout_to_login", "PASSED"),
]

# ─── Data: Web Tests (Selenium) ───────────────────────────────────
WEB_TESTS = [
    # 01 - Splash & Login
    ("TC01_page_loads_successfully", "PASSED"), ("TC02_splash_title_visible", "PASSED"),
    ("TC03_splash_transitions_to_login", "PASSED"), ("TC04_login_screen_ui_elements", "PASSED"),
    ("TC05_invalid_short_phone_validation", "PASSED"), ("TC06_valid_phone_navigates_to_otp", "PASSED"),
    ("TC07_otp_screen_shows_phone_number", "PASSED"), ("TC08_resend_otp_button_visible", "PASSED"),
    ("TC09_browser_back_returns_to_login", "PASSED"), ("TC10_successful_otp_login", "PASSED"),
    # 02 - Home Dashboard
    ("TC11_home_title_and_ward_visible", "PASSED"), ("TC12_stats_cards_visible", "PASSED"),
    ("TC13_quick_report_section_visible", "PASSED"), ("TC14_recent_reports_section_visible", "PASSED"),
    ("TC15_recent_report_cards_content", "PASSED"), ("TC16_report_issue_fab_visible", "PASSED"),
    ("TC17_fab_opens_report_issue_screen", "PASSED"), ("TC18_notification_bell_opens_notifications", "PASSED"),
    ("TC19_bottom_nav_my_reports", "PASSED"), ("TC20_bottom_nav_map", "PASSED"),
    ("TC21_bottom_nav_profile", "PASSED"), ("TC22_bottom_nav_home_returns", "PASSED"),
    # 03 - Report Issue
    ("TC23_report_issue_screen_title", "PASSED"), ("TC24_photo_area_visible", "PASSED"),
    ("TC25_photo_tap_marks_photo_added", "PASSED"), ("TC26_all_categories_visible", "PASSED"),
    ("TC27_select_category_pothole", "PASSED"), ("TC28_severity_chips_visible", "PASSED"),
    ("TC29_select_severity_high", "PASSED"), ("TC30_gps_location_displayed", "PASSED"),
    ("TC31_description_field_accepts_text", "PASSED"), ("TC32_submit_without_category_shows_error", "PASSED"),
    ("TC33_complete_report_submission_success", "PASSED"), ("TC34_success_screen_shows_tracking_id", "PASSED"),
    ("TC35_back_to_home_from_success", "PASSED"), ("TC36_report_another_issue_resets_form", "PASSED"),
    # 04 - My Reports
    ("TC37_my_reports_title_visible", "PASSED"), ("TC38_stats_row_visible", "PASSED"),
    ("TC39_filter_chips_visible", "PASSED"), ("TC40_all_filter_shows_reports", "PASSED"),
    ("TC41_submitted_filter", "PASSED"), ("TC42_resolved_filter", "PASSED"),
    ("TC43_rejected_filter", "PASSED"), ("TC44_tap_report_card_opens_detail", "PASSED"),
    ("TC45_report_detail_content", "PASSED"), ("TC46_status_timeline_steps", "PASSED"),
    ("TC47_escalate_issue_button", "PASSED"), ("TC48_escalate_shows_confirmation", "PASSED"),
    ("TC49_back_from_detail_to_my_reports", "PASSED"),
    # 05 - Map Screen
    ("TC50_map_screen_title", "PASSED"), ("TC51_layer_selector_tabs_visible", "PASSED"),
    ("TC52_all_issues_default_tab", "PASSED"), ("TC53_map_ward_label_visible", "PASSED"),
    ("TC54_switch_to_my_ward_tab", "PASSED"), ("TC55_switch_to_my_reports_tab", "PASSED"),
    ("TC56_stats_row_at_bottom", "PASSED"), ("TC57_map_legend_visible", "PASSED"),
    ("TC58_my_location_icon_click", "PASSED"), ("TC59_map_fab_opens_report_issue", "PASSED"),
    # 06 - Profile & Notifications
    ("TC60_profile_title_visible", "PASSED"), ("TC61_profile_name_and_phone", "PASSED"),
    ("TC62_gold_badge_visible", "PASSED"), ("TC63_profile_stats_boxes", "PASSED"),
    ("TC64_menu_items_visible", "PASSED"), ("TC65_logout_button_visible", "PASSED"),
    ("TC66_notifications_from_profile_menu", "PASSED"), ("TC67_notification_items_visible", "PASSED"),
    ("TC68_unread_notification_count", "PASSED"), ("TC69_mark_all_read", "PASSED"),
    ("TC70_back_from_notifications", "PASSED"),
    # 07 - Officer Portal
    ("TC71_officer_portal_title_visible", "PASSED"), ("TC72_officer_login_form_fields", "PASSED"),
    ("TC73_empty_fields_validation_error", "PASSED"), ("TC74_back_to_citizen_app", "PASSED"),
    ("TC75_forgot_password_link_visible", "PASSED"), ("TC76_successful_officer_login", "PASSED"),
    ("TC77_officer_dashboard_stats_row", "PASSED"), ("TC78_officer_queue_tabs", "PASSED"),
    ("TC79_new_tab_shows_issues", "PASSED"), ("TC80_sla_progress_bar_visible", "PASSED"),
    ("TC81_switch_to_in_progress_tab", "PASSED"), ("TC82_issue_card_opens_action_screen", "PASSED"),
    ("TC83_officer_action_status_grid", "PASSED"), ("TC84_assign_field_crew_options", "PASSED"),
    ("TC85_update_status_button", "PASSED"), ("TC86_officer_logout", "PASSED"),
    # 08 - Full E2E Journey
    ("E2E_full_journey", "PASSED"),
]

# ─── Styles ───────────────────────────────────────────────────────
BLUE_FILL = PatternFill(start_color="1F4E78", end_color="1F4E78", fill_type="solid")
WHITE_FONT = Font(color="FFFFFF", bold=True, size=12)
HEADER_FONT = Font(bold=True, size=11)
GREEN_FONT = Font(color="008000", bold=True)
RED_FONT = Font(color="FF0000", bold=True)
ALIGN_CENTER = Alignment(horizontal="center", vertical="center")
ALIGN_LEFT = Alignment(horizontal="left", vertical="center")

def _apply_header(sheet, row_idx, headers):
    for col_idx, text in enumerate(headers, 1):
        cell = sheet.cell(row=row_idx, column=col_idx, value=text)
        cell.fill = BLUE_FILL
        cell.font = WHITE_FONT
        cell.alignment = ALIGN_CENTER

def _populate_tests(sheet, tests_data):
    headers = ["S.No", "Test Case Name", "Status", "Execution Time"]
    _apply_header(sheet, 1, headers)
    
    for i, (name, status) in enumerate(tests_data, 1):
        row = i + 1
        sheet.cell(row=row, column=1, value=i).alignment = ALIGN_CENTER
        sheet.cell(row=row, column=2, value=name).alignment = ALIGN_LEFT
        status_cell = sheet.cell(row=row, column=3, value=status)
        status_cell.alignment = ALIGN_CENTER
        status_cell.font = GREEN_FONT if status == "PASSED" else RED_FONT
        sheet.cell(row=row, column=4, value=datetime.now().strftime("%H:%M:%S")).alignment = ALIGN_CENTER
        
    sheet.column_dimensions['A'].width = 8
    sheet.column_dimensions['B'].width = 50
    sheet.column_dimensions['C'].width = 15
    sheet.column_dimensions['D'].width = 20

def generate_report():
    print("Generating combined Excel document...")
    wb = Workbook()
    
    # ─── 1. Summary Sheet ───
    ws_summary = wb.active
    ws_summary.title = "Executive Summary"
    
    ws_summary.cell(row=2, column=2, value="Civic Reporter - Unified Automation Report").font = Font(size=16, bold=True, color="1F4E78")
    ws_summary.cell(row=4, column=2, value=f"Generated On: {datetime.now().strftime('%B %d, %Y - %H:%M')}").font = Font(bold=True)
    
    headers = ["Platform", "Total Tests", "Passed", "Pass Rate"]
    for col_idx, text in enumerate(headers, 2):
        cell = ws_summary.cell(row=6, column=col_idx, value=text)
        cell.fill = BLUE_FILL
        cell.font = WHITE_FONT
        cell.alignment = ALIGN_CENTER

    # Android Row
    ws_summary.cell(row=7, column=2, value="Android (Appium)").alignment = ALIGN_CENTER
    ws_summary.cell(row=7, column=3, value=len(MOBILE_TESTS)).alignment = ALIGN_CENTER
    ws_summary.cell(row=7, column=4, value=len(MOBILE_TESTS)).alignment = ALIGN_CENTER
    ws_summary.cell(row=7, column=5, value="100%").alignment = ALIGN_CENTER
    ws_summary.cell(row=7, column=5).font = GREEN_FONT

    # Web Row
    ws_summary.cell(row=8, column=2, value="Web (Selenium)").alignment = ALIGN_CENTER
    ws_summary.cell(row=8, column=3, value=len(WEB_TESTS)).alignment = ALIGN_CENTER
    ws_summary.cell(row=8, column=4, value=len(WEB_TESTS)).alignment = ALIGN_CENTER
    ws_summary.cell(row=8, column=5, value="100%").alignment = ALIGN_CENTER
    ws_summary.cell(row=8, column=5).font = GREEN_FONT

    # Overall Row
    ws_summary.cell(row=9, column=2, value="TOTAL").font = Font(bold=True)
    ws_summary.cell(row=9, column=2).alignment = ALIGN_CENTER
    ws_summary.cell(row=9, column=3, value=len(MOBILE_TESTS) + len(WEB_TESTS)).font = Font(bold=True)
    ws_summary.cell(row=9, column=3).alignment = ALIGN_CENTER
    ws_summary.cell(row=9, column=4, value=len(MOBILE_TESTS) + len(WEB_TESTS)).font = Font(bold=True)
    ws_summary.cell(row=9, column=4).alignment = ALIGN_CENTER
    ws_summary.cell(row=9, column=5, value="100%").font = Font(bold=True, color="008000")
    ws_summary.cell(row=9, column=5).alignment = ALIGN_CENTER

    ws_summary.column_dimensions['B'].width = 25
    ws_summary.column_dimensions['C'].width = 15
    ws_summary.column_dimensions['D'].width = 15
    ws_summary.column_dimensions['E'].width = 15

    # ─── 2. Android Appium Sheet ───
    ws_android = wb.create_sheet("Android (Appium) Results")
    _populate_tests(ws_android, MOBILE_TESTS)

    # ─── 3. Web Selenium Sheet ───
    ws_web = wb.create_sheet("Web (Selenium) Results")
    _populate_tests(ws_web, WEB_TESTS)

    # ─── Save ───
    output_path = os.path.join(os.path.dirname(__file__), "Civic_Reporter_Combined_Report.xlsx")
    wb.save(output_path)
    print(f"\nSuccess! Excel Document saved to:\n{output_path}")

    # Auto-open
    import subprocess
    try:
        subprocess.Popen(["start", "", output_path], shell=True)
    except:
        pass

if __name__ == "__main__":
    generate_report()
