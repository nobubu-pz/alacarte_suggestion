import 'package:flutter/material.dart';

class VoiceInputButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isListening;

  const VoiceInputButton({required this.onPressed, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: isListening ? Text('停止') : Text('開始'),
    );
  }
}
