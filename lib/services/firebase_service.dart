import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isFirebaseReady = false;
  static bool get isFirebaseReady => _isFirebaseReady;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        bool hasPlaceholderApiKey = false;
        try {
          final options = DefaultFirebaseOptions.currentPlatform;
          if (options.apiKey.startsWith('REPLACE_') || options.apiKey.length < 20) {
            hasPlaceholderApiKey = true;
          }
        } catch (_) {
          hasPlaceholderApiKey = true;
        }

        if (hasPlaceholderApiKey) {
          _isFirebaseReady = false;
          debugPrint('ℹ️ Running in local persistent database mode (No custom Firebase Cloud API key configured).');
          return;
        }

        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (_) {
          await Firebase.initializeApp();
        }
      }
      _isFirebaseReady = true;
      debugPrint('🔥 Firebase initialized successfully.');
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('⚠️ Firebase initialization note: $e');
      debugPrint(
        'ℹ️ Firebase will activate automatically when google-services.json is added to android/app/.',
      );
    }
  }
}
