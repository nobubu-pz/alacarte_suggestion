import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alacarte_suggestion/data/sources/voice_input_data_source.dart';
import 'package:alacarte_suggestion/presentation/controllers/voice_input_controller.dart';
import 'package:alacarte_suggestion/presentation/ui/screens/voice_input_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: BindingsBuilder(() {
        Get.put(VoiceInputDataSource());
        Get.put(VoiceInputController());
      }),
      home: VoiceInputScreen(),
    );
  }
}
