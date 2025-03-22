// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebaseの設定オプションを提供するデフォルトクラス
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web向けのFirebase設定
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1pmgMI2_h5MXFnOtJQk1XrYLIrgMO7pQ',
    appId: '1:227096630545:web:ff45a25f2596a8d75e28b0',
    messagingSenderId: '227096630545',
    projectId: 'a-la-carte-suggestions',
    authDomain: 'a-la-carte-suggestions.firebaseapp.com',
    databaseURL:
        'https://a-la-carte-suggestions-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'a-la-carte-suggestions.firebasestorage.app',
    measurementId: 'G-X3BZEZ4DMH',
  );

  // Android向けのFirebase設定
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBu-2y4lN1HBJH0-fJFm-MwTMB_OwqUWHk',
    appId: '1:227096630545:android:1d452ac9e3c1e86d5e28b0',
    messagingSenderId: '227096630545',
    projectId: 'a-la-carte-suggestions',
    databaseURL:
        'https://a-la-carte-suggestions-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'a-la-carte-suggestions.firebasestorage.app',
  );

  // iOS向けのFirebase設定
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDBnlYl_RQPXxlh5BQw0zXrK1Qp7XPTC14',
    appId: '1:227096630545:ios:dc6f0e2fcac6f6a15e28b0',
    messagingSenderId: '227096630545',
    projectId: 'a-la-carte-suggestions',
    databaseURL:
        'https://a-la-carte-suggestions-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'a-la-carte-suggestions.firebasestorage.app',
    iosClientId:
        '227096630545-dqe34j69s0nntmipnc28p9sf4ogdjur0.apps.googleusercontent.com',
    iosBundleId: 'com.example.alacarteSuggestion',
  );
}
