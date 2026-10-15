import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Smart Canteen.
/// Replace placeholder values with your Firebase Project credentials from Firebase Console.
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

  // Web Firebase Configuration (from Firebase Console > Project Settings > Web App)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_FIREBASE_API_KEY',
    appId: 'REPLACE_WITH_YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'smart-canteen-app',
    authDomain: 'smart-canteen-app.firebaseapp.com',
    storageBucket: 'smart-canteen-app.appspot.com',
  );

  // Android Firebase Configuration (or place google-services.json in android/app/)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_FIREBASE_API_KEY',
    appId: '1:123456789:android:abcdef',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'smart-canteen-app',
    storageBucket: 'smart-canteen-app.appspot.com',
  );
}
