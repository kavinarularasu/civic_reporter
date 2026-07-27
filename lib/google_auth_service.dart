import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'env_config.dart';

/// User authentication result model for Google OAuth.
class GoogleAuthResult {
  final bool isSuccess;
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? errorMessage;

  GoogleAuthResult({
    required this.isSuccess,
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.errorMessage,
  });

  factory GoogleAuthResult.success({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return GoogleAuthResult(
      isSuccess: true,
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  factory GoogleAuthResult.failure(String message) {
    return GoogleAuthResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Service managing Official Google OAuth 2.0 Authentication via Firebase & Google Identity.
class GoogleAuthService {
  /// Triggers official Google account picker modal and authenticates user session.
  static Future<GoogleAuthResult> signInWithGoogle({required String role}) async {
    UserCredential? userCredential;
    String? errorReason;
    final String? configuredClientId = EnvConfig.googleClientId.isNotEmpty ? EnvConfig.googleClientId : null;

    try {
      debugPrint('Triggering Official Google OAuth 2.0 Sign-In...');

      if (kIsWeb) {
        // Firebase Web OAuth Popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        try {
          userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        } catch (e) {
          debugPrint('Firebase Web OAuth Popup Exception: $e');
          errorReason = e.toString();
          // Try GoogleSignIn Web SDK
          try {
            final GoogleSignIn googleSignIn = GoogleSignIn(
              clientId: configuredClientId,
              scopes: ['email', 'profile'],
            );
            final googleUser = await googleSignIn.signIn();
            if (googleUser != null) {
              final googleAuth = await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            }
          } catch (gErr) {
            debugPrint('GoogleSignIn SDK error: $gErr');
            errorReason = gErr.toString();
          }
        }
      } else {
        // Native Mobile Google Sign-In
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: configuredClientId,
          scopes: ['email', 'profile'],
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        }
      }
    } catch (e) {
      debugPrint('Google OAuth outer exception caught: $e');
      errorReason = e.toString();
    }

    final firebaseUser = userCredential?.user;
    if (firebaseUser == null) {
      String msg = 'Google Sign-In was not completed.';
      if (errorReason != null && errorReason.contains('origin_mismatch')) {
        msg = 'Error 400: origin_mismatch.\n\nYour current app URL is not authorized in Google Cloud Console.\n\nPlease add your URL (e.g. https://civic-reporter-a8807.web.app or http://localhost:PORT) to Authorized JavaScript Origins in Google Cloud Console.';
      } else if (errorReason != null && (errorReason.contains('popup_closed') || errorReason.contains('closed'))) {
        msg = 'Google Sign-In popup was closed before completing sign in.';
      } else if (errorReason != null && errorReason.isNotEmpty) {
        msg = 'Google Sign-In error: $errorReason';
      }
      return GoogleAuthResult.failure(msg);
    }

    final uid = firebaseUser.uid;
    final email = firebaseUser.email ?? 'google_user@gmail.com';
    final displayName = firebaseUser.displayName ?? (email.isNotEmpty ? email.split('@').first : 'Google User');
    final photoUrl = firebaseUser.photoURL;

    // Sync user profile in Cloud Firestore
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': displayName,
        'email': email,
        'photo_url': photoUrl,
        'role': role,
        'provider': 'google.com',
        'is_verified': true,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore User Sync Error: $e');
    }

    return GoogleAuthResult.success(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// Sign out Google account.
  static Future<void> signOut() async {
    try {
      final String? configuredClientId = EnvConfig.googleClientId.isNotEmpty ? EnvConfig.googleClientId : null;
      if (!kIsWeb) {
        await GoogleSignIn(clientId: configuredClientId).signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Google SignOut Error: $e');
    }
  }
}
