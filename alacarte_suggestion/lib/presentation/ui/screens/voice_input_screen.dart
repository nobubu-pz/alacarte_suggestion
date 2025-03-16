import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alacarte_suggestion/presentation/controllers/voice_input_controller.dart';

class VoiceInputScreen extends GetView<VoiceInputController> {
  const VoiceInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('音声入力'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 冷蔵庫アイコン
                  const Icon(Icons.kitchen, size: 120, color: Colors.blue),
                  const SizedBox(height: 40),
                  // 音声認識テキスト
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Obx(
                      () => Text(
                        controller.recognizedText.value.isEmpty
                            ? 'マイクボタンを押して話してください'
                            : controller.recognizedText.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              controller.recognizedText.value.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // マイクボタン
          Container(
            padding: const EdgeInsets.only(bottom: 40),
            child: GestureDetector(
              onTapDown: (_) => controller.startListening(),
              onTapUp: (_) => controller.stopListening(),
              onTapCancel: () => controller.stopListening(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Obx(
                  () => Icon(
                    Icons.mic,
                    size: 40,
                    color:
                        controller.isListening.value
                            ? Colors.red
                            : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
