import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:alacarte_suggestion/presentation/ui/screens/voice_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: deprecated_member_use
import 'dart:js' as js;
import 'dart:async';

class AuthController extends GetxController {
  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;
  final bool firebaseInitialized;

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  // コンストラクタでFirebase初期化状態を受け取る
  AuthController({required this.firebaseInitialized})
    : _auth = firebaseInitialized ? FirebaseAuth.instance : null,
      _googleSignIn = firebaseInitialized ? GoogleSignIn() : null {
    print(
      'AuthController created with firebaseInitialized: $firebaseInitialized',
    );
  }

  @override
  void onInit() {
    super.onInit();
    print('AuthController initialized');

    if (firebaseInitialized && !kIsWeb) {
      // モバイル環境でのみFirebase Auth SDKを使用
      firebaseUser.bindStream(_auth!.authStateChanges());

      // 認証状態の変化を監視して画面遷移
      ever(firebaseUser, (User? user) {
        print(
          'Auth state changed: ${user != null ? 'Logged in' : 'Logged out'}',
        );
        if (user != null) {
          // ログイン成功時にメイン画面へ
          print('User is logged in, navigating to home screen');
          Get.offAll(() => const VoiceInputScreen());
        }
      });
    } else if (firebaseInitialized && kIsWeb) {
      // Web環境ではJavaScriptのFirebaseを使用
      print('Web環境: JavaScriptのFirebase Authを使用します');

      // JavaScript側の認証状態変化を監視する処理をここで設定
      _setupWebAuthListener();
    } else {
      print('Firebase not initialized, authentication features disabled');
    }
  }

  // Web環境でJavaScriptのFirebase認証状態変化を監視
  void _setupWebAuthListener() {
    if (kIsWeb && firebaseInitialized) {
      try {
        // JavaScriptの関数をDartから呼び出して、認証状態の変化をリッスン
        js.context.callMethod('eval', [
          '''
          if (typeof firebase !== 'undefined' && firebase.auth) {
            firebase.auth().onAuthStateChanged(function(user) {
              console.log('JS: Firebase Auth state changed', user);
              
              // Dart側に認証状態の変化を通知
              if (user) {
                window.dispatchEvent(new CustomEvent('flutterFirebaseAuthStateChanged', {
                  detail: { isLoggedIn: true }
                }));
              } else {
                window.dispatchEvent(new CustomEvent('flutterFirebaseAuthStateChanged', {
                  detail: { isLoggedIn: false }
                }));
              }
            });
            console.log('JS: Firebase Auth listener set up');
          } else {
            console.error('JS: Firebase Auth not available');
          }
        ''',
        ]);

        // JavaScriptからのイベントをリッスン
        js.context['window'].callMethod('addEventListener', [
          'flutterFirebaseAuthStateChanged',
          js.allowInterop((event) {
            final detail = js.JsObject.fromBrowserObject(event)['detail'];
            final isLoggedIn = detail['isLoggedIn'] as bool;
            print('Received auth state change from JS: $isLoggedIn');

            if (isLoggedIn) {
              // ログイン成功時にメイン画面へ
              Get.offAll(() => const VoiceInputScreen());
            }
          }),
        ]);

        print('Web auth listener setup complete');
      } catch (e) {
        print('Error setting up web auth listener: $e');
      }
    }
  }

  // Googleでサインイン
  Future<void> signInWithGoogle() async {
    if (!firebaseInitialized) {
      print('Firebase not initialized, cannot sign in with Google');
      Get.snackbar(
        'ログインエラー',
        'Firebaseが初期化されていないため、ログインできません。アプリを再起動してください。',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      // メイン画面に直接移動
      Get.offAll(() => const VoiceInputScreen());
      return;
    }

    try {
      isLoading.value = true;

      if (kIsWeb) {
        // Web環境ではJavaScriptのFirebaseを直接使用
        print('Web環境: JavaScriptのGoogle認証を使用します');

        final success = await _signInWithGoogleJS();
        if (success) {
          // 認証成功時はJavaScriptのリスナーが画面遷移を処理
          print('JavaScriptのGoogle認証が成功しました');
        } else {
          // 認証失敗
          throw Exception('JavaScriptのGoogle認証に失敗しました');
        }
      } else {
        // モバイル環境でのGoogle認証
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          print('Google sign in cancelled by user');
          isLoading.value = false;
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth!.signInWithCredential(credential);
      }
    } catch (e) {
      print('Google Sign In Error: $e');
      Get.snackbar(
        'ログインエラー',
        'ログインに失敗しました: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // エラーの場合は直接メイン画面に移動（ゲストとして）
      Get.offAll(() => const VoiceInputScreen());
    } finally {
      isLoading.value = false;
    }
  }

  // JavaScriptを使用してGoogleサインインを実行
  Future<bool> _signInWithGoogleJS() async {
    final completer = Completer<bool>();

    try {
      // JavaScriptの関数を実行
      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            if (typeof firebase === 'undefined' || !firebase.auth) {
              console.error('Firebase Auth not available');
              window.dispatchEvent(new CustomEvent('flutterGoogleSignInResult', {
                detail: { success: false, error: 'Firebase Auth not available' }
              }));
              return;
            }
            
            var provider = new firebase.auth.GoogleAuthProvider();
            provider.addScope('https://www.googleapis.com/auth/userinfo.email');
            provider.addScope('https://www.googleapis.com/auth/userinfo.profile');
            
            firebase.auth().signInWithPopup(provider).then(function(result) {
              console.log('Google sign in successful', result.user.uid);
              window.dispatchEvent(new CustomEvent('flutterGoogleSignInResult', {
                detail: { success: true }
              }));
            }).catch(function(error) {
              console.error('Google sign in error', error);
              window.dispatchEvent(new CustomEvent('flutterGoogleSignInResult', {
                detail: { success: false, error: error.message }
              }));
            });
          } catch (e) {
            console.error('Exception during Google sign in', e);
            window.dispatchEvent(new CustomEvent('flutterGoogleSignInResult', {
              detail: { success: false, error: e.toString() }
            }));
          }
        })();
      ''',
      ]);

      // 結果をリッスン
      js.context['window'].callMethod('addEventListener', [
        'flutterGoogleSignInResult',
        js.allowInterop((event) {
          final detail = js.JsObject.fromBrowserObject(event)['detail'];
          final success = detail['success'] as bool;

          if (success) {
            print('JavaScript Google sign in successful');
            completer.complete(true);
          } else {
            final error = detail['error'];
            print('JavaScript Google sign in failed: $error');
            completer.complete(false);
          }

          // イベントリスナーを削除
          js.context['window'].callMethod('removeEventListener', [
            'flutterGoogleSignInResult',
            js.allowInterop((event) {}),
          ]);
        }),
        {'once': true}, // リスナーを一度だけ実行
      ]);

      // タイムアウト設定
      Future.delayed(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          print('Google sign in timed out');
          completer.complete(false);
        }
      });
    } catch (e) {
      print('Error during JavaScript Google sign in: $e');
      completer.complete(false);
    }

    return completer.future;
  }

  // ゲストとしてサインイン - Firebase認証を使わずに直接画面遷移
  Future<void> signInAnonymously() async {
    try {
      isLoading.value = true;
      print('ゲストモード: メイン画面に直接移動します');

      // 直接メイン画面に移動
      Get.offAll(() => const VoiceInputScreen());
    } catch (e) {
      print('Navigation Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      print('Signing out');

      // Firebaseからサインアウト
      await _auth!.signOut();

      // Googleからサインアウト（Googleでログインしていた場合）
      if (await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
      }

      print('Sign out successful');

      // ログイン画面に戻る（リダイレクト処理はever()リスナーが行う）
    } catch (e) {
      print('Sign Out Error: $e');
      Get.snackbar(
        'エラー',
        'ログアウトに失敗しました: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ユーザーがログインしているか確認
  bool get isLoggedIn => _auth!.currentUser != null;
}
