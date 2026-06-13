import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLVWdXRZDHMupCjaIexKVc1kxge73GSXY',
    appId: '1:764357521579:android:c37c86a4d2517426d207ee',
    messagingSenderId: '764357521579',
    projectId: 'civic-reporter-a8807',
    storageBucket: 'civic-reporter-a8807.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLVWdXRZDHMupCjaIexKVc1kxge73GSXY',
    appId: '1:764357521579:web:3e2db4e78c419c81086791', // TODO: Update with your Firebase Web App ID if different
    messagingSenderId: '764357521579',
    projectId: 'civic-reporter-a8807',
    authDomain: 'civic-reporter-a8807.firebaseapp.com',
    storageBucket: 'civic-reporter-a8807.firebasestorage.app',
  );
}