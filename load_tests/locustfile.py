"""
Civic Reporter — Baseline / Load Test
======================================
100 virtual users  |  1 minute  |  Locust
Simulates realistic user navigation through the Flutter Web app.
"""
from locust import HttpUser, task, between, events
import time
import json
import os

# ──────────────────────────────────────────────
#  Pages that the Flutter web app serves
#  (all return the same index.html with different route params)
# ──────────────────────────────────────────────
ROUTES = [
    "/",            # Splash / Home
    "/#/login",     # Login screen
    "/#/home",      # Home dashboard
    "/#/report",    # Report Issue
    "/#/my-reports",# My Reports
    "/#/map",       # Map screen
    "/#/profile",   # Profile
]

STATIC_ASSETS = [
    "/flutter.js",
    "/flutter_bootstrap.js",
    "/main.dart.js",
    "/manifest.json",
    "/favicon.png",
    "/index.html",
]


class CivicReporterUser(HttpUser):
    """
    Simulates a single concurrent user navigating the Civic Reporter web app.
    Each user waits 0.5-2 seconds between page loads (realistic pacing).
    """
    wait_time = between(0.5, 2)

    # ──────────────────────────────────────────
    #  Page-load tasks  (weighted by frequency)
    # ──────────────────────────────────────────
    @task(5)
    def visit_home(self):
        """Most-visited page — highest weight."""
        self.client.get("/", name="[PAGE] Home / Splash")

    @task(3)
    def visit_report_issue(self):
        self.client.get("/#/report", name="[PAGE] Report Issue")

    @task(3)
    def visit_my_reports(self):
        self.client.get("/#/my-reports", name="[PAGE] My Reports")

    @task(2)
    def visit_map(self):
        self.client.get("/#/map", name="[PAGE] Map Screen")

    @task(2)
    def visit_profile(self):
        self.client.get("/#/profile", name="[PAGE] Profile")

    @task(1)
    def visit_login(self):
        self.client.get("/#/login", name="[PAGE] Login")

    # ──────────────────────────────────────────
    #  Static asset requests
    # ──────────────────────────────────────────
    @task(2)
    def load_main_dart_js(self):
        """Simulate browser fetching the compiled Flutter bundle."""
        self.client.get("/main.dart.js", name="[ASSET] main.dart.js")

    @task(1)
    def load_manifest(self):
        self.client.get("/manifest.json", name="[ASSET] manifest.json")

    @task(1)
    def load_flutter_js(self):
        self.client.get("/flutter.js", name="[ASSET] flutter.js")

    @task(1)
    def load_favicon(self):
        self.client.get("/favicon.png", name="[ASSET] favicon.png")

    def on_start(self):
        """Called once per user when they start — load the app entry point."""
        self.client.get("/index.html", name="[ASSET] index.html (on_start)")
