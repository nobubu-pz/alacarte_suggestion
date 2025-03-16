import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceInputController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final RxBool isListening = false.obs;
  final RxString text = ''.obs;
  final RxString recognizedText = ''.obs; // 音声認識中のテキストを保持

  static const String apiEndpoint =
      'https://transcribe-audio-rbrlqu2ngq-uc.a.run.app';

  // Firebase Functionsを使用する場合、Bearer tokenは不要なので削除
  // static const String apiKey = 'YOUR_API_KEY';

  @override
  void onInit() {
    super.onInit();
    initSpeechToText();
  }

  Future<void> initSpeechToText() async {
    await _speechToText.initialize();
  }

  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  Future<void> startListening() async {
    text.value = '';
    recognizedText.value = '';
    if (await _speechToText.initialize()) {
      isListening.value = true;
      await _speechToText.listen(
        onResult: (result) {
          // 音声認識の結果を直接表示
          recognizedText.value = result.recognizedWords;

          // GCPへの送信は一旦コメントアウト
          // if (result.finalResult) {
          //   sendToGCP(result.recognizedWords);
          // }
        },
        localeId: 'ja_JP',
      );
    }
  }

  Future<void> stopListening() async {
    isListening.value = false;
    await _speechToText.stop();
  }

  // GCP関連の処理は一旦コメントアウト
  /*
  Future<void> sendToGCP(String audioText) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        text.value = '認証エラーが発生しました';
        return;
      }

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'text': audioText}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        text.value = data['text'] ?? '音声を認識できませんでした';
      } else {
        text.value = 'エラーが発生しました';
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      text.value = 'ネットワークエラーが発生しました';
      print('Exception: $e');
    }
  }
  */
}
