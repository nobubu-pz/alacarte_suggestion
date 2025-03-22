import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:alacarte_suggestion/presentation/ui/screens/voice_input_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:alacarte_suggestion/presentation/controllers/auth_controller.dart';
import 'dart:js' as js;
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 入力したメールアドレス・パスワード
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _isWebEnvironment = false;

  @override
  void initState() {
    super.initState();
    _isWebEnvironment = kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('食材管理アシスタント')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // アプリロゴまたはアイコン
              Icon(
                Icons.kitchen,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // アプリ名
              const Text(
                '食材管理アシスタント',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Web環境の場合は注意メッセージを表示
              if (_isWebEnvironment)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(height: 8),
                      Text(
                        'メール/パスワードでログインするか、ゲストとして続けることができます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

              // メールアドレス入力用テキストフィールド
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: !_isLoading, // Web環境でも有効化
                keyboardType: TextInputType.emailAddress,
                onChanged: (String value) {
                  setState(() {
                    _email = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // パスワード入力用テキストフィールド
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                enabled: !_isLoading, // Web環境でも有効化
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    _password = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // ログインボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('ログイン', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              // ユーザー登録ボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: const Text('新規ユーザー登録', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              // パスワードリセットのテキストボタン
              TextButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: const Text('パスワードをお忘れですか？'),
              ),
              const SizedBox(height: 24),

              // ゲストログインボタン
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        _isWebEnvironment ? Colors.blue.shade50 : null,
                  ),
                  onPressed: _isLoading ? null : _signInAnonymously,
                  child: Text(
                    _isWebEnvironment ? 'アプリを開始する' : 'ゲストとして続ける',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isWebEnvironment ? Colors.blue : null,
                      fontWeight: _isWebEnvironment ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ログイン処理
  Future<void> _signIn() async {
    if (_email.isEmpty || _password.isEmpty) {
      _showErrorDialog('メールアドレスとパスワードを入力してください');
      return;
    }

    // EmailAddressの形式チェック
    if (!_email.contains('@') || !_email.contains('.')) {
      _showErrorDialog('メールアドレスの形式が正しくありません');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting user login...');

      if (_isWebEnvironment) {
        // Web環境ではJavaScriptのFirebaseを使用（極めてシンプルな方法）
        print('Using JavaScript Firebase Auth for login');

        // 最もシンプルな方法でJavaScriptを実行
        js.context.callMethod('eval', [
          '''
          if (typeof firebase === 'undefined' || !firebase.auth) {
            alert('Firebaseが利用できません。ページを再読み込みしてください。');
          } else {
            // ログイン前にフラグをリセット
            window.flutterLoginSuccess = false;
            window.flutterLoginErrorCode = null;
            window.flutterLoginErrorMessage = null;
            
            firebase.auth().signInWithEmailAndPassword("${_email}", "${_password}")
              .then(function(userCredential) {
                console.log('Login successful');
                // Flutterに成功を伝えるために簡単なグローバル変数を設定
                window.flutterLoginSuccess = true;
              })
              .catch(function(error) {
                console.error('Login error:', error.code, error.message);
                // エラーメッセージを設定
                window.flutterLoginErrorCode = error.code;
                window.flutterLoginErrorMessage = error.message;
                
                if (error.code === 'auth/user-not-found') {
                  alert('メールアドレスが登録されていません');
                } else if (error.code === 'auth/wrong-password') {
                  alert('パスワードが間違っています');
                } else {
                  alert('ログインエラー: ' + error.message);
                }
              });
          }
          ''',
        ]);

        // 処理が完了するまで少し待機
        await Future.delayed(const Duration(seconds: 2));

        // 成功したかどうかを確認
        final success = js.context['flutterLoginSuccess'] == true;

        if (success) {
          print('Login successful based on global variable');
          // メイン画面に遷移
          Get.offAll(() => const VoiceInputScreen());
          return;
        }

        // エラーコードを取得
        final errorCode = js.context['flutterLoginErrorCode'];
        if (errorCode != null) {
          print('Login error detected: $errorCode');

          if (errorCode == 'auth/user-not-found') {
            _showErrorDialog('メールアドレスが登録されていません');
          } else if (errorCode == 'auth/wrong-password') {
            _showErrorDialog('パスワードが間違っています');
          } else {
            final errorMessage = js.context['flutterLoginErrorMessage'];
            _showErrorDialog('ログインに失敗しました: $errorMessage');
          }

          setState(() {
            _isLoading = false;
          });
          return;
        }

        // タイムアウトか不明なエラー
        print('Login timed out or unknown error');
        _showErrorDialog('ログイン処理がタイムアウトしました。再度お試しください。');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // モバイル環境の場合はFlutterのFirebase認証を使用
      print('Using Flutter Firebase Auth for login');
      // メール/パスワードでログイン
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);

      print('ログインしました: ${userCredential.user?.email}');

      // メイン画面に遷移
      Get.offAll(() => const VoiceInputScreen());
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'user-not-found') {
        message = 'メールアドレスが登録されていません';
      } else if (e.code == 'wrong-password') {
        message = 'パスワードが間違っています';
      } else if (e.code == 'invalid-email') {
        message = 'メールアドレスの形式が正しくありません';
      } else {
        message = 'ログインに失敗しました: ${e.message}';
      }

      _showErrorDialog(message);
    } catch (e) {
      print('Unexpected error during login: $e');
      _showErrorDialog('ログインに失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ユーザー登録処理
  Future<void> _signUp() async {
    if (_email.isEmpty || _password.isEmpty) {
      _showErrorDialog('メールアドレスとパスワードを入力してください');
      return;
    }

    if (_password.length < 6) {
      _showErrorDialog('パスワードは6文字以上にしてください');
      return;
    }

    // EmailAddressの形式チェック
    if (!_email.contains('@') || !_email.contains('.')) {
      _showErrorDialog('メールアドレスの形式が正しくありません');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting user registration...');

      if (_isWebEnvironment) {
        // Web環境ではJavaScriptのFirebaseを使用（極めてシンプルな方法）
        print('Using JavaScript Firebase Auth for registration');

        // 最もシンプルな方法でJavaScriptを実行
        js.context.callMethod('eval', [
          '''
          if (typeof firebase === 'undefined' || !firebase.auth) {
            alert('Firebaseが利用できません。ページを再読み込みしてください。');
          } else {
            firebase.auth().createUserWithEmailAndPassword("${_email}", "${_password}")
              .then(function(userCredential) {
                console.log('Registration successful');
                // Flutterに成功を伝えるために簡単なグローバル変数を設定
                window.flutterAuthSuccess = true;
              })
              .catch(function(error) {
                console.error('Registration error:', error.code, error.message);
                // エラーメッセージを設定
                window.flutterAuthErrorCode = error.code;
                window.flutterAuthErrorMessage = error.message;
                
                if (error.code === 'auth/email-already-in-use') {
                  alert('このメールアドレスは既に使用されています');
                } else {
                  alert('登録エラー: ' + error.message);
                }
              });
          }
          ''',
        ]);

        // 処理が完了するまで少し待機
        await Future.delayed(const Duration(seconds: 2));

        // 成功したかどうかを確認
        final success = js.context['flutterAuthSuccess'] == true;

        if (success) {
          print('Registration successful based on global variable');
          // メイン画面に遷移
          Get.offAll(() => const VoiceInputScreen());
          return;
        }

        // エラーコードを取得
        final errorCode = js.context['flutterAuthErrorCode'];
        if (errorCode != null) {
          print('Registration error detected: $errorCode');

          if (errorCode == 'auth/email-already-in-use') {
            _showErrorDialog('このメールアドレスは既に使用されています');
          } else {
            final errorMessage = js.context['flutterAuthErrorMessage'];
            _showErrorDialog('ユーザー登録に失敗しました: $errorMessage');
          }

          setState(() {
            _isLoading = false;
          });
          return;
        }

        // タイムアウトか不明なエラー
        print('Registration timed out or unknown error');
        _showErrorDialog('登録処理がタイムアウトしました。再度お試しください。');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // モバイル環境の場合はFlutterのFirebase認証を使用
      print('Using Flutter Firebase Auth');
      final auth = FirebaseAuth.instance;
      print('Firebase Auth instance available: ${auth != null}');

      // ユーザー登録
      print('Attempting to create user with email: $_email');
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(email: _email, password: _password);

      print('User registration successful: ${userCredential.user?.email}');

      // メイン画面に遷移
      Get.offAll(() => const VoiceInputScreen());
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during registration:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      String message = '';

      if (e.code == 'email-already-in-use') {
        message = 'このメールアドレスは既に使用されています';
      } else if (e.code == 'invalid-email') {
        message = 'メールアドレスの形式が正しくありません';
      } else if (e.code == 'weak-password') {
        message = 'パスワードが弱すぎます';
      } else {
        message = 'ユーザー登録に失敗しました: ${e.message}';
      }

      _showErrorDialog(message);
    } catch (e) {
      print('Unexpected error during registration:');
      print('Error: $e');
      _showErrorDialog('ユーザー登録に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // パスワードリセット処理
  Future<void> _resetPassword() async {
    if (_email.isEmpty) {
      _showErrorDialog('パスワードをリセットするメールアドレスを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // パスワードリセットメールを送信
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);

      _showSuccessDialog('パスワードリセット用のメールを送信しました。メールをご確認ください。');
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'user-not-found') {
        message = 'このメールアドレスは登録されていません';
      } else if (e.code == 'invalid-email') {
        message = 'メールアドレスの形式が正しくありません';
      } else {
        message = 'パスワードリセットに失敗しました: ${e.message}';
      }

      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('パスワードリセットに失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ゲストログイン（匿名ログイン）処理
  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting anonymous login...');

      if (!_isWebEnvironment) {
        // モバイル環境ではFirebaseの匿名ログインを使用
        print('Mobile environment, using Firebase anonymous login');
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInAnonymously();
        print('匿名ログインしました: ${userCredential.user?.uid}');

        // メイン画面に遷移
        Get.offAll(() => const VoiceInputScreen());
        return;
      }

      // Web環境では簡略化（匿名ログインを試みるが成功・失敗に関わらずメイン画面へ遷移）
      print('Web environment, using JavaScript Firebase anonymous login');

      // AuthControllerがすでに登録されているか確認
      if (!Get.isRegistered<AuthController>()) {
        print('Registering AuthController before navigating');
        try {
          Get.put(AuthController(firebaseInitialized: true));
          print('AuthController registered successfully');
        } catch (e) {
          print('Error registering AuthController: $e');
          // エラーが発生しても継続
        }
      } else {
        print('AuthController already registered');
      }

      // 最もシンプルな方法でJavaScriptを実行
      js.context.callMethod('eval', [
        '''
        if (typeof firebase === 'undefined' || !firebase.auth) {
          console.error('Firebase Auth not available in JavaScript');
          // エラーを無視して続行
        } else {
          // 匿名ログインを試みる
          window.flutterAnonymousLoginSuccess = false;
          
          firebase.auth().signInAnonymously()
            .then(function(userCredential) {
              console.log('Anonymous login successful');
              window.flutterAnonymousLoginSuccess = true;
            })
            .catch(function(error) {
              console.error('Anonymous login error:', error.code, error.message);
              // エラーを無視して続行
            });
        }
        ''',
      ]);

      // 短い待機後、結果に関わらずメイン画面へ遷移
      await Future.delayed(const Duration(milliseconds: 1000));
      print('Moving to main screen after anonymous login attempt');

      // メイン画面に遷移
      Get.offAll(() => const VoiceInputScreen());
    } catch (e) {
      print('Unexpected error during anonymous login: $e');
      // エラーが発生してもメイン画面へ遷移
      Get.offAll(() => const VoiceInputScreen());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // エラーダイアログ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('エラー'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // 成功ダイアログ
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('成功'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
