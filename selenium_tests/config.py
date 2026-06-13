"""
Selenium Test Configuration for Civic Reporter Web App (Flutter Web)
"""
import os

# ─────────────────────────────────────────────────────────────
# Web App URL
# Change BASE_URL to your Firebase hosted URL if deployed
# For local: run  firebase serve  or  flutter run -d chrome
# ─────────────────────────────────────────────────────────────
BASE_URL = "http://localhost:5000"   # Firebase local serve
# BASE_URL = "https://civic-reporter.web.app"  # Live URL

# ─────────────────────────────────────────────────────────────
# Browser Configuration
# ─────────────────────────────────────────────────────────────
BROWSER            = "chrome"          # chrome | firefox | edge
HEADLESS           = False             # True = no browser window
WINDOW_WIDTH       = 1280
WINDOW_HEIGHT      = 900
IMPLICIT_WAIT      = 5
EXPLICIT_WAIT      = 15
PAGE_LOAD_TIMEOUT  = 30

# ─────────────────────────────────────────────────────────────
# Test Credentials
# ─────────────────────────────────────────────────────────────
TEST_PHONE    = "9876543210"
TEST_OTP      = "123456"
INVALID_PHONE = "12345"
OFFICER_ID    = "CMC-WD42-001"
OFFICER_PASS  = "admin1234"

# ─────────────────────────────────────────────────────────────
# Wait Times (seconds)
# ─────────────────────────────────────────────────────────────
SPLASH_WAIT  = 4
OTP_WAIT     = 3
LOGIN_WAIT   = 3
SHORT_WAIT   = 2
SUBMIT_WAIT  = 3

# ─────────────────────────────────────────────────────────────
# Report Configuration
# ─────────────────────────────────────────────────────────────
REPORT_DIR        = os.path.join(os.path.dirname(__file__), "reports")
SCREENSHOT_DIR    = os.path.join(REPORT_DIR, "screenshots")
EXCEL_REPORT_NAME = "Civic_Reporter_Selenium_Complete_Report.xlsx"

# ─────────────────────────────────────────────────────────────
# Flutter Web Locators
# Flutter web exposes elements via flt-semantics with aria attrs.
# We use CSS for flt-semantics and XPath as fallback.
# Call  enable_accessibility()  in base_test before finding elements.
# ─────────────────────────────────────────────────────────────
def by_label(text):
    """CSS selector for Flutter flt-semantics aria-label."""
    return ("css selector", f'flt-semantics[aria-label="{text}"]')

def by_label_contains(text):
    """XPath — aria-label contains text."""
    return ("xpath", f'//*[contains(@aria-label,"{text}")]')

def by_text(text):
    """XPath — visible text content."""
    return ("xpath", f'//*[normalize-space(text())="{text}"]')

def by_text_contains(text):
    """XPath — text contains substring."""
    return ("xpath", f'//*[contains(text(),"{text}") or contains(@aria-label,"{text}")]')

def by_role_button(label):
    """flt-semantics button with aria-label."""
    return ("css selector", f'flt-semantics[role="button"][aria-label="{label}"]')

def by_role_textbox():
    """First available textbox."""
    return ("css selector", 'flt-semantics[role="textbox"], input[type="text"], input:not([type])')

# Pre-built locator map
LOCATORS = {
    # ── Splash ──────────────────────────────────────────
    "splash_title":        by_label_contains("Civic Reporter"),
    "splash_subtitle":     by_label_contains("Fix Your City"),

    # ── Login ────────────────────────────────────────────
    "welcome_back":        by_label_contains("Welcome Back"),
    "phone_input":         by_role_textbox(),
    "send_otp_btn":        by_label_contains("Send OTP"),
    "support_btn":         by_label_contains("Contact Support"),

    # ── OTP ──────────────────────────────────────────────
    "verify_otp_title":    by_label_contains("Verify OTP"),
    "verify_btn":          by_label_contains("Verify OTP"),
    "resend_otp_btn":      by_label_contains("Resend OTP"),

    # ── Home ─────────────────────────────────────────────
    "home_title":          by_label_contains("Civic Reporter"),
    "home_ward_text":      by_label_contains("Ward 42"),
    "quick_report_title":  by_label_contains("Quick Report"),
    "recent_reports_title":by_label_contains("Recent Reports"),
    "see_all_btn":         by_label_contains("See All"),
    "report_issue_fab":    by_label_contains("Report Issue"),
    "notification_btn":    by_label_contains("Notifications"),

    # ── Bottom Nav ───────────────────────────────────────
    "nav_home":            by_label_contains("Home"),
    "nav_my_reports":      by_label_contains("My Reports"),
    "nav_map":             by_label_contains("Map"),
    "nav_profile":         by_label_contains("Profile"),

    # ── Report Issue ─────────────────────────────────────
    "report_title":        by_label_contains("Report an Issue"),
    "photo_area":          by_label_contains("Tap to take a photo"),
    "photo_added":         by_label_contains("Photo Added"),
    "cat_pothole":         by_label_contains("Pothole"),
    "cat_streetlight":     by_label_contains("Streetlight"),
    "cat_open_drain":      by_label_contains("Open Drain"),
    "cat_garbage":         by_label_contains("Garbage"),
    "cat_road_damage":     by_label_contains("Road Damage"),
    "cat_water_leak":      by_label_contains("Water Leak"),
    "sev_low":             by_label_contains("Low"),
    "sev_medium":          by_label_contains("Medium"),
    "sev_high":            by_label_contains("High"),
    "sev_critical":        by_label_contains("Critical"),
    "location_detected":   by_label_contains("GPS Location Detected"),
    "desc_field":          by_role_textbox(),
    "submit_report_btn":   by_label_contains("Submit Report"),

    # ── Success ──────────────────────────────────────────
    "report_submitted":    by_label_contains("Report Submitted"),
    "tracking_id":         by_label_contains("#WD24"),
    "back_to_home_btn":    by_label_contains("Back to Home"),
    "report_another_btn":  by_label_contains("Report Another Issue"),

    # ── My Reports ───────────────────────────────────────
    "my_reports_title":    by_label_contains("My Reports"),
    "filter_all":          by_label_contains("All"),
    "filter_submitted":    by_label_contains("Submitted"),
    "filter_resolved":     by_label_contains("Resolved"),
    "filter_rejected":     by_label_contains("Rejected"),

    # ── Report Detail ────────────────────────────────────
    "status_timeline":     by_label_contains("Status Timeline"),
    "escalate_btn":        by_label_contains("Escalate Issue"),

    # ── Map ──────────────────────────────────────────────
    "map_title":           by_label_contains("Area Map"),
    "map_all_issues":      by_label_contains("All Issues"),
    "map_my_ward":         by_label_contains("My Ward"),
    "map_my_reports_tab":  by_label_contains("My Reports"),
    "map_ward_text":       by_label_contains("Ward 42"),

    # ── Profile ──────────────────────────────────────────
    "profile_title":       by_label_contains("My Profile"),
    "profile_name":        by_label_contains("Kavin"),
    "profile_phone":       by_label_contains("+91"),
    "gold_badge":          by_label_contains("Gold Civic Reporter"),
    "officer_portal_btn":  by_label_contains("Officer Portal"),
    "logout_btn":          by_label_contains("Logout"),

    # ── Notifications ────────────────────────────────────
    "notif_title":         by_label_contains("Notifications"),
    "mark_all_read_btn":   by_label_contains("Mark all read"),

    # ── Officer Portal ───────────────────────────────────
    "officer_portal_title":by_label_contains("Ward Officer Portal"),
    "officer_id_input":    by_role_textbox(),
    "officer_login_btn":   by_label_contains("Login as Officer"),
    "back_citizen_btn":    by_label_contains("Back to Citizen App"),

    # ── Officer Dashboard ────────────────────────────────
    "officer_dashboard_title": by_label_contains("Officer Dashboard"),
}
