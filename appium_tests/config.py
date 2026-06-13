"""
Appium Test Configuration for Civic Reporter App
Auto-detects APK path and device configuration
"""
import os
import subprocess
import sys

# ─────────────────────────────────────────────
# Appium Server Configuration
# ─────────────────────────────────────────────
APPIUM_HOST = "127.0.0.1"
APPIUM_PORT = 4723
APPIUM_URL = f"http://{APPIUM_HOST}:{APPIUM_PORT}"

# ─────────────────────────────────────────────
# Android Device Configuration
# ─────────────────────────────────────────────
ANDROID_PLATFORM_VERSION = "12"
ANDROID_DEVICE_NAME = "emulator-5554"   # Change to your real device serial if needed

# ─────────────────────────────────────────────
# App Package Configuration
# ─────────────────────────────────────────────
APP_PACKAGE  = "com.civicreporter.civic_reporter"
APP_ACTIVITY = ".MainActivity"

# APK path — tries release first, then debug
def _find_apk() -> str:
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    candidates = [
        os.path.join(base, "build", "app", "outputs", "flutter-apk", "app-release.apk"),
        os.path.join(base, "build", "app", "outputs", "flutter-apk", "app-debug.apk"),
        os.path.join(base, "build", "app", "outputs", "apk",         "release", "app-release.apk"),
        os.path.join(base, "build", "app", "outputs", "apk",         "debug",   "app-debug.apk"),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    # fallback — let the test surface a clear error
    return candidates[0]

APK_PATH = _find_apk()

# ─────────────────────────────────────────────
# Test Credentials (Phone-OTP based)
# ─────────────────────────────────────────────
TEST_PHONE    = "9876543210"    # 10-digit number accepted by the app
TEST_OTP      = "123456"        # Any 6-digit OTP (app skips real Firebase in test)
OFFICER_ID    = "CMC-WD42-001"
OFFICER_PASS  = "admin1234"
INVALID_PHONE = "12345"         # Only 5 digits — should fail validation

# ─────────────────────────────────────────────
# Wait Times (seconds)
# ─────────────────────────────────────────────
SPLASH_WAIT    = 5   # Splash → Login transition
OTP_WAIT       = 3   # OTP send transition
LOGIN_WAIT     = 3   # Login → Dashboard transition
EXPLICIT_WAIT  = 15
IMPLICIT_WAIT  = 5
SHORT_WAIT     = 3
SUBMIT_WAIT    = 4

# ─────────────────────────────────────────────
# Test Report Configuration
# ─────────────────────────────────────────────
REPORT_DIR        = os.path.join(os.path.dirname(__file__), "reports")
EXCEL_REPORT_NAME = "Civic_Reporter_E2E_Test_Results.xlsx"
SCREENSHOT_DIR    = os.path.join(REPORT_DIR, "screenshots")

# ─────────────────────────────────────────────
# XPath Locators (Flutter uses UiAutomator2 content-desc / text)
# ─────────────────────────────────────────────
LOCATORS = {
    # ── Splash Screen ──────────────────────────
    "splash_title":       ("xpath", '//*[contains(@text,"Civic Reporter")]'),
    "splash_subtitle":    ("xpath", '//*[contains(@text,"Fix Your City")]'),

    # ── Login Screen ───────────────────────────
    "phone_input":        ("xpath", '//android.widget.EditText'),
    "send_otp_btn":       ("xpath", '//*[contains(@text,"Send OTP")]'),
    "support_btn":        ("xpath", '//*[contains(@text,"Contact Support")]'),
    "welcome_back":       ("xpath", '//*[contains(@text,"Welcome Back")]'),

    # ── OTP Screen ─────────────────────────────
    "verify_otp_title":   ("xpath", '//*[contains(@text,"Verify OTP")]'),
    "verify_btn":         ("xpath", '//*[contains(@text,"Verify OTP")]'),
    "resend_otp_btn":     ("xpath", '//*[contains(@text,"Resend OTP")]'),
    "otp_box":            ("xpath", '//android.widget.EditText'),

    # ── Home Dashboard ──────────────────────────
    "home_title":         ("xpath", '//*[contains(@text,"Civic Reporter")]'),
    "home_ward_text":     ("xpath", '//*[contains(@text,"Ward 42")]'),
    "notification_btn":   ("xpath", '//*[@content-desc="notifications_outlined"]'),
    "quick_report_pothole":   ("xpath", '//*[contains(@text,"Pothole")]'),
    "quick_report_street":    ("xpath", '//*[contains(@text,"Streetlight")]'),
    "quick_report_drain":     ("xpath", '//*[contains(@text,"Drain")]'),
    "quick_report_garbage":   ("xpath", '//*[contains(@text,"Garbage")]'),
    "recent_reports_title":   ("xpath", '//*[contains(@text,"Recent Reports")]'),
    "see_all_btn":            ("xpath", '//*[contains(@text,"See All")]'),
    "report_issue_fab":       ("xpath", '//*[contains(@text,"Report Issue")]'),
    "stat_total_reported":    ("xpath", '//*[contains(@text,"Total")]'),

    # ── Bottom Navigation ───────────────────────
    "nav_home":        ("xpath", '//*[@content-desc="Home"]'),
    "nav_my_reports":  ("xpath", '//*[@content-desc="My Reports"]'),
    "nav_map":         ("xpath", '//*[@content-desc="Map"]'),
    "nav_profile":     ("xpath", '//*[@content-desc="Profile"]'),

    # ── Report Issue Screen ─────────────────────
    "report_title":       ("xpath", '//*[contains(@text,"Report an Issue")]'),
    "photo_area":         ("xpath", '//*[contains(@text,"Tap to take a photo")]'),
    "photo_added":        ("xpath", '//*[contains(@text,"Photo Added")]'),
    "cat_pothole":        ("xpath", '//*[contains(@text,"Pothole")]'),
    "cat_streetlight":    ("xpath", '//*[contains(@text,"Streetlight")]'),
    "cat_open_drain":     ("xpath", '//*[contains(@text,"Open Drain")]'),
    "cat_garbage":        ("xpath", '//*[contains(@text,"Garbage")]'),
    "cat_road_damage":    ("xpath", '//*[contains(@text,"Road Damage")]'),
    "cat_water_leak":     ("xpath", '//*[contains(@text,"Water Leak")]'),
    "sev_low":            ("xpath", '//*[contains(@text,"Low")]'),
    "sev_medium":         ("xpath", '//*[contains(@text,"Medium")]'),
    "sev_high":           ("xpath", '//*[contains(@text,"High")]'),
    "sev_critical":       ("xpath", '//*[contains(@text,"Critical")]'),
    "location_detected":  ("xpath", '//*[contains(@text,"GPS Location Detected")]'),
    "desc_field":         ("xpath", '//android.widget.EditText'),
    "submit_report_btn":  ("xpath", '//*[contains(@text,"Submit Report")]'),

    # ── Submission Success ──────────────────────
    "report_submitted":   ("xpath", '//*[contains(@text,"Report Submitted")]'),
    "tracking_id":        ("xpath", '//*[contains(@text,"#WD24")]'),
    "back_to_home_btn":   ("xpath", '//*[contains(@text,"Back to Home")]'),
    "report_another_btn": ("xpath", '//*[contains(@text,"Report Another Issue")]'),

    # ── My Reports Screen ──────────────────────
    "my_reports_title":   ("xpath", '//*[contains(@text,"My Reports")]'),
    "filter_all":         ("xpath", '//*[contains(@text,"All")]'),
    "filter_submitted":   ("xpath", '//*[contains(@text,"Submitted")]'),
    "filter_inprogress":  ("xpath", '//*[contains(@text,"In Progress")]'),
    "filter_resolved":    ("xpath", '//*[contains(@text,"Resolved")]'),
    "filter_rejected":    ("xpath", '//*[contains(@text,"Rejected")]'),

    # ── Report Detail Screen ────────────────────
    "status_timeline":    ("xpath", '//*[contains(@text,"Status Timeline")]'),
    "escalate_btn":       ("xpath", '//*[contains(@text,"Escalate Issue")]'),

    # ── Map Screen ─────────────────────────────
    "map_title":          ("xpath", '//*[contains(@text,"Area Map")]'),
    "map_all_issues":     ("xpath", '//*[contains(@text,"All Issues")]'),
    "map_my_ward":        ("xpath", '//*[contains(@text,"My Ward")]'),
    "map_my_reports":     ("xpath", '//*[contains(@text,"My Reports")]'),
    "map_ward_text":      ("xpath", '//*[contains(@text,"Ward 42")]'),

    # ── Profile Screen ─────────────────────────
    "profile_title":      ("xpath", '//*[contains(@text,"My Profile")]'),
    "profile_name":       ("xpath", '//*[contains(@text,"Kavin")]'),
    "profile_phone":      ("xpath", '//*[contains(@text,"+91")]'),
    "gold_badge":         ("xpath", '//*[contains(@text,"Gold Civic Reporter")]'),
    "officer_portal_btn": ("xpath", '//*[contains(@text,"Officer Portal")]'),
    "logout_btn":         ("xpath", '//*[contains(@text,"Logout")]'),

    # ── Notification Screen ─────────────────────
    "notif_title":        ("xpath", '//*[contains(@text,"Notifications")]'),
    "mark_all_read_btn":  ("xpath", '//*[contains(@text,"Mark all read")]'),
    "notif_issue_inprog": ("xpath", '//*[contains(@text,"Issue In Progress")]'),

    # ── Officer Login ───────────────────────────
    "officer_portal_title": ("xpath", '//*[contains(@text,"Ward Officer Portal")]'),
    "officer_id_input":     ("xpath", '//android.widget.EditText[1]'),
    "officer_pass_input":   ("xpath", '//android.widget.EditText[2]'),
    "officer_login_btn":    ("xpath", '//*[contains(@text,"Login as Officer")]'),
    "back_citizen_btn":     ("xpath", '//*[contains(@text,"Back to Citizen App")]'),

    # ── Officer Dashboard ───────────────────────
    "officer_dashboard_title": ("xpath", '//*[contains(@text,"Officer Dashboard")]'),
    "officer_tab_new":         ("xpath", '//*[contains(@text,"New")]'),
    "officer_tab_inprog":      ("xpath", '//*[contains(@text,"In Progress")]'),
    "officer_tab_resolved":    ("xpath", '//*[contains(@text,"Resolved")]'),
    "officer_tab_escalated":   ("xpath", '//*[contains(@text,"Escalated")]'),
    "officer_logout_btn":      ("xpath", '//*[@content-desc="logout"]'),
    "ward_stats_btn":          ("xpath", '//*[@content-desc="bar_chart"]'),
}
