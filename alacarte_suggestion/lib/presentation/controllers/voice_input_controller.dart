import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alacarte_suggestion/data/sources/voice_input_data_source.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputController extends GetxController {
  final _speechToText = SpeechToText();
  final isListening = false.obs;
  final text = '音声入力待ち'.obs;
  final _dataSource = Get.find<VoiceInputDataSource>();

  @override
  void onInit() {
    super.onInit();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  void toggleListening() async {
    if (isListening.value) {
      await _speechToText.stop();
      isListening.value = false;
    } else {
      await _speechToText.listen(
        onResult: (result) {
          text.value = result.recognizedWords;
        },
      );
      isListening.value = true;
    }
  }

  Future<void> sendTextToApi() async {
    if (text.value.isNotEmpty) {
      try {
        await _dataSource.sendText(text.value);
      } catch (e) {
        // エラー処理
        Get.snackbar('エラー', 'APIリクエストに失敗しました');
      }
    }
  }
}
