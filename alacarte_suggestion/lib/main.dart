import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alacarte_suggestion/firebase_options.dart';
import 'package:alacarte_suggestion/presentation/controllers/voice_input_controller.dart';
import 'package:alacarte_suggestion/presentation/controllers/auth_controller.dart';
import 'package:alacarte_suggestion/presentation/ui/screens/login_screen.dart';
import 'package:alacarte_suggestion/presentation/ui/screens/voice_input_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:js' as js;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized');

  // Web用のURLストラテジーを設定
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  bool firebaseInitialized = false;

  try {
    if (kIsWeb) {
      // Web環境ではJavaScriptのFirebaseが初期化されているか確認
      print('Checking JavaScript Firebase initialization...');

      // JavaScriptでFirebaseが初期化されているか確認
      final bool jsFirebaseInitialized = js.context.hasProperty('firebase');
      print('JavaScript Firebase available: $jsFirebaseInitialized');

      if (jsFirebaseInitialized) {
        // JavaScriptのFirebaseが利用可能な場合はFirebase初期化済みとマーク
        print('Using JavaScript initialized Firebase');
        firebaseInitialized = true;

        // JavaScript側でのFirebase初期化状況を確認 (追加)
        final bool isJsInitialized = js.context.callMethod('eval', [
          '''
          (function() {
            if (typeof firebase === 'undefined') return false;
            console.log('Firebase initialized in JavaScript');
            return true;
          })();
          ''',
        ]);
        print('JavaScript Firebase initialization confirmed: $isJsInitialized');
      } else {
        // バックアップとしてFlutterのFirebaseを初期化
        print('JavaScript Firebase not available, initializing from Flutter');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized from Flutter');
        firebaseInitialized = true;
      }
    } else {
      // モバイル環境では通常通りFirebaseを初期化
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully on mobile');
      firebaseInitialized = true;
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    if (kIsWeb) {
      // Web環境ではエラーがあってもJavaScriptのFirebaseが使えるかもしれない
      final bool jsFirebaseInitialized = js.context.hasProperty('firebase');
      if (jsFirebaseInitialized) {
        print('Using JavaScript Firebase despite Flutter initialization error');
        firebaseInitialized = true;
      }
    }
  }

  // コントローラーを登録
  try {
    // まずVoiceInputControllerを登録
    Get.put(VoiceInputController());
    print('Voice controller registered');

    if (kIsWeb) {
      try {
        // Web環境ではLoginScreenに登録を任せる
        print(
          'Web environment: AuthController registration deferred to LoginScreen',
        );
      } catch (e) {
        print('Error during web Auth controller setup: $e');
      }
    } else {
      try {
        // モバイル環境ではfirebaseInitializedの値でAuthControllerを登録
        Get.put(AuthController(firebaseInitialized: firebaseInitialized));
        print(
          'Auth controller registered for mobile with $firebaseInitialized',
        );
      } catch (e) {
        print('Error during mobile Auth controller setup: $e');
      }
    }
  } catch (e) {
    print('Failed to register controllers: $e');
    // エラーが発生してもアプリが起動できるようにする
  }

  // アプリを開始
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

// アプリケーションクラス
class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '食材管理アシスタント',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
