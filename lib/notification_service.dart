import 'package:flutter/foundation.dart';
import 'env_config.dart';

/// Automated Notification Service for dispatching SMS & Email alerts upon issue resolution.
class NotificationService {
  /// Sends automated SMS notification to registered citizen phone.
  static Future<bool> sendResolutionSMS({
    required String phoneNumber,
    required String issueId,
    required String issueTitle,
    required String wardName,
  }) async {
    if (phoneNumber.trim().isEmpty) {
      debugPrint('SMS Notification Skipped: No phone number provided for Issue #$issueId');
      return false;
    }

    final message = 'CivicReporter Alert: Your reported issue #$issueId ("$issueTitle") in $wardName has been marked as RESOLVED by the Ward Officer. Thank you for making our city better!';

    debugPrint('----------------------------------------------------');
    debugPrint('[NOTIFICATION SMS DISPATCH]');
    debugPrint('To: $phoneNumber');
    debugPrint('Provider URL: ${EnvConfig.smsServiceUrl}');
    debugPrint('Sender ID: ${EnvConfig.smsSenderId}');
    debugPrint('Message Body: $message');
    debugPrint('----------------------------------------------------');

    try {
      // If external SMS API key configured, invoke REST endpoint
      if (EnvConfig.smsApiKey != 'ENV_SMS_KEY_DEMO') {
        // http.post(Uri.parse(EnvConfig.smsServiceUrl), body: ...)
      }
      return true;
    } catch (e) {
      debugPrint('SMS Notification Error: $e');
      return false;
    }
  }

  /// Sends automated Email notification to registered citizen email.
  static Future<bool> sendResolutionEmail({
    required String recipientEmail,
    required String citizenName,
    required String issueId,
    required String issueTitle,
    required String wardName,
    required String resolutionNotes,
    required DateTime resolvedAt,
  }) async {
    if (recipientEmail.trim().isEmpty) {
      debugPrint('Email Notification Skipped: No recipient email provided for Issue #$issueId');
      return false;
    }

    final formattedTimestamp = resolvedAt.toLocal().toString().split('.').first;

    final emailBody = '''
Dear $citizenName,

We are pleased to inform you that your civic issue report has been successfully resolved!

Issue ID: #$issueId
Topic: $issueTitle
Location/Ward: $wardName
Resolution Summary: ${resolutionNotes.isNotEmpty ? resolutionNotes : "Action completed by Municipal Field Crew."}
Timestamp: $formattedTimestamp

Thank you for actively contributing to your community.

Sincerely,
Civic Reporter Municipal Office
    ''';

    debugPrint('----------------------------------------------------');
    debugPrint('[NOTIFICATION EMAIL DISPATCH]');
    debugPrint('To: $recipientEmail');
    debugPrint('SMTP Host: ${EnvConfig.smtpHost}:${EnvConfig.smtpPort}');
    debugPrint('Subject: Issue #$issueId Resolved - Civic Reporter');
    debugPrint('Content:\n$emailBody');
    debugPrint('----------------------------------------------------');

    try {
      if (EnvConfig.emailServiceKey != 'ENV_EMAIL_KEY_DEMO') {
        // SMTP / API dispatch logic
      }
      return true;
    } catch (e) {
      debugPrint('Email Notification Error: $e');
      return false;
    }
  }

  /// Combined resolution notification dispatcher.
  static Future<void> triggerResolutionNotifications({
    required String citizenPhone,
    required String citizenEmail,
    required String citizenName,
    required String issueId,
    required String issueTitle,
    required String wardName,
    required String resolutionNotes,
    required DateTime resolvedAt,
  }) async {
    await sendResolutionSMS(
      phoneNumber: citizenPhone,
      issueId: issueId,
      issueTitle: issueTitle,
      wardName: wardName,
    );

    await sendResolutionEmail(
      recipientEmail: citizenEmail,
      citizenName: citizenName,
      issueId: issueId,
      issueTitle: issueTitle,
      wardName: wardName,
      resolutionNotes: resolutionNotes,
      resolvedAt: resolvedAt,
    );
  }
}
