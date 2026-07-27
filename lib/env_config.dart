import 'package:flutter/foundation.dart';

/// Environment Configuration Manager for Civic Reporter Application.
/// Exposes production API keys and live endpoints for Google OAuth, SMS Gateways (Firebase/Twilio/Fast2SMS), Maps, Vision AI, and Email.
class EnvConfig {
  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'civic-reporter-app.firebaseapp.com');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'civic-reporter-app');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');

  // Google OAuth Credentials (set via --dart-define or .env)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '',
  );

  // Twilio Live SMS Gateway
  static const String twilioAccountSid = String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static const String twilioAuthToken = String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static const String twilioPhoneNumber = String.fromEnvironment('TWILIO_PHONE_NUMBER', defaultValue: '');

  // Fast2SMS Live SMS Gateway
  static const String fast2smsApiKey = String.fromEnvironment('FAST2SMS_API_KEY', defaultValue: '');

  // Generic SMS Config
  static const String smsApiKey = String.fromEnvironment('SMS_API_KEY', defaultValue: '');
  static const String smsSenderId = String.fromEnvironment('SMS_SENDER_ID', defaultValue: 'CIVIC_ALERT');
  static const String smsServiceUrl = String.fromEnvironment('SMS_SERVICE_URL', defaultValue: 'https://api.sms-provider.com/v1/send');

  // Maps & Vision Credentials
  static const String mapApiKey = String.fromEnvironment('MAP_API_KEY', defaultValue: '');
  static const String mapGeocodeUrl = String.fromEnvironment('MAP_GEOCODE_URL', defaultValue: 'https://maps.googleapis.com/maps/api/geocode/json');
  static const String visionApiKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');
  static const String visionApiUrl = String.fromEnvironment('VISION_API_URL', defaultValue: 'https://vision.googleapis.com/v1/images:annotate');

  // Email SMTP Credentials
  static const String emailServiceKey = String.fromEnvironment('EMAIL_SERVICE_KEY', defaultValue: '');
  static const String smtpHost = String.fromEnvironment('SMTP_HOST', defaultValue: 'smtp.civicreporter.org');
  static const int smtpPort = int.fromEnvironment('SMTP_PORT', defaultValue: 587);
  static const String smtpUser = String.fromEnvironment('SMTP_USER', defaultValue: 'notifications@civicreporter.org');

  static bool get isTwilioLive => twilioAccountSid.isNotEmpty && twilioAuthToken.isNotEmpty;
  static bool get isFast2SMSLive => fast2smsApiKey.isNotEmpty;
  static bool get isGoogleOAuthLive => googleClientId.isNotEmpty;

  static void printConfigSummary() {
    debugPrint('=== Civic Reporter Production Environment Status ===');
    debugPrint('Google OAuth Configured: ${isGoogleOAuthLive ? "YES" : "NO (Console Keys Required)"}');
    debugPrint('Twilio SMS Live: ${isTwilioLive ? "YES" : "NO (Twilio SID Required)"}');
    debugPrint('Fast2SMS Live: ${isFast2SMSLive ? "YES" : "NO (Fast2SMS Key Required)"}');
    debugPrint('Vision API Key Configured: ${visionApiKey.isNotEmpty}');
    debugPrint('Email Notification Host: $smtpHost');
  }
}
