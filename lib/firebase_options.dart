// Generated from google-services.json — project: examensw1
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase web no configurado. Agrega las credenciales web en firebase_options.dart.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase iOS no configurado. Agrega el GoogleService-Info.plist.',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcjHsvrIP67Y3hv8fb0KgmFXHGuZ5NA5U',
    appId: '1:1063803389682:android:5004fae3c561e8c3f6726b',
    messagingSenderId: '1063803389682',
    projectId: 'examensw1',
    storageBucket: 'examensw1.firebasestorage.app',
  );
}
