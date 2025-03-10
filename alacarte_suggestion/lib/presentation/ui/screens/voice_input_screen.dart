import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alacarte_suggestion/presentation/controllers/voice_input_controller.dart';
import 'package:alacarte_suggestion/presentation/ui/widgets/voice_input_button.dart';

class VoiceInputScreen extends StatelessWidget {
  final VoiceInputController _controller = Get.put(VoiceInputController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('音声入力')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Obx(
              () =>
                  Text(_controller.text.value, style: TextStyle(fontSize: 24)),
            ),
            SizedBox(height: 20),
            VoiceInputButton(
              onPressed: _controller.toggleListening,
              isListening: _controller.isListening.value,
            ),
          ],
        ),
      ),
    );
  }
}
