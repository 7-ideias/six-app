import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static bool get isConfigured {
    final FirebaseOptions options = currentPlatform;
    return options.apiKey.trim().isNotEmpty &&
        options.appId.trim().isNotEmpty &&
        options.messagingSenderId.trim().isNotEmpty &&
        options.projectId.trim().isNotEmpty;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8Hq0Livcf2DyDzbM-mzauwxxQRmkzVB0',
    appId: '1:841074493827:android:15e3b2e7d7b5c18cb98eb6',
    messagingSenderId: '841074493827',
    projectId: 'sixpos-cd87e',
    storageBucket: 'sixpos-cd87e.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAeeAVUUO0xOOKw7ifDf0hGKumrnooBGiU',
    appId: '1:841074493827:ios:9fbc8a60d3d7e6aeb98eb6',
    messagingSenderId: '841074493827',
    projectId: 'sixpos-cd87e',
    storageBucket: 'sixpos-cd87e.firebasestorage.app',
    iosBundleId: 'br.com.seteideias.appplanilha',
  );
}
