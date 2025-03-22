import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class FoodItem {
  final String name;
  final String quantity;
  final String expiryDate;

  FoodItem({
    required this.name,
    required this.quantity,
    required this.expiryDate,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    print('Creating FoodItem from JSON: $json'); // デバッグ出力
    return FoodItem(
      name: json['食材'] ?? '',
      quantity: json['個数'] ?? '',
      expiryDate: json['消費/賞味期限'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FoodItem{name: $name, quantity: $quantity, expiryDate: $expiryDate}';
  }
}

class VoiceInputController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final RxBool isListening = false.obs;
  final RxString recognizedText = ''.obs;
  final RxList<FoodItem> processedItems = <FoodItem>[].obs;
  final RxBool isProcessing = false.obs; // API処理中フラグ
  final RxBool showConfirmation = false.obs; // 確認ダイアログ表示フラグ
  final RxBool showCompletion = false.obs; // 完了メッセージ表示フラグ

  static const String transcribeEndpoint =
      'https://transcribe-audio-rbrlqu2ngq-uc.a.run.app';
  static const String processEndpoint =
      'https://process-text-and-organize-rbrlqu2ngq-uc.a.run.app';

  @override
  void onInit() {
    super.onInit();
    initSpeechToText();
  }

  Future<void> initSpeechToText() async {
    bool available = false;

    if (kIsWeb) {
      print('Initializing Web Speech API');
      try {
        available = await _speechToText.initialize(
          onStatus: (status) {
            print('Web Speech recognition status: $status');
            // Webブラウザでマイクの権限リクエストに関するステータス処理
            if (status == 'notListening') {
              isListening.value = false;
            }
          },
          onError: (errorNotification) {
            print('Web Speech recognition error: $errorNotification');
            isListening.value = false;
            _handleWebSpeechError(errorNotification.errorMsg);
          },
          debugLogging: true,
        );
        print('Web Speech to text initialized: $available');
      } catch (e) {
        print('Web Speech initialization error: $e');
        Get.snackbar(
          '音声認識初期化エラー',
          'ブラウザの音声認識機能を初期化できませんでした。最新のChrome、Edge、Safariなどのブラウザをお使いください。',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } else {
      // モバイルアプリ用の初期化
      available = await _speechToText.initialize();
      print('Mobile Speech to text initialized: $available');
    }
  }

  // Webでのエラー処理
  void _handleWebSpeechError(String errorMsg) {
    if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
      // マイク許可に関するエラー
      Get.snackbar(
        'マイク許可が必要です',
        'ブラウザの設定からマイクの使用を許可してください',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } else if (errorMsg.contains('network')) {
      // ネットワークエラー
      Get.snackbar(
        'ネットワークエラー',
        '通信状態を確認してください',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      // その他のエラー
      Get.snackbar(
        '音声認識エラー',
        'エラーが発生しました: $errorMsg',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleListening() async {
    if (isListening.value) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    try {
      // Web環境での特別な処理
      if (kIsWeb) {
        print('Web environment detected, initializing speech recognition...');
        bool hasPermission = await _speechToText.hasPermission;

        if (!hasPermission) {
          print('Requesting permission for Web speech recognition');
          await _speechToText.initialize(
            onStatus: (status) => print('Web Speech status: $status'),
            onError: (error) => print('Web Speech error: $error'),
          );
          hasPermission = await _speechToText.hasPermission;
        }

        if (!hasPermission) {
          print('Web speech permission denied');
          Get.snackbar(
            'マイク許可が必要です',
            'ブラウザの設定からマイクの使用を許可してください',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }

      if (await _speechToText.initialize()) {
        isListening.value = true;
        // 音声入力開始時は新しい認識テキストを表示するためにクリア
        recognizedText.value = '';

        // 初回の場合のみprocessedItemsをクリア（追加入力の場合はクリアしない）
        if (!showConfirmation.value && processedItems.isEmpty) {
          processedItems.clear();
        }

        await _speechToText.listen(
          onResult: (result) {
            recognizedText.value = result.recognizedWords;
            print('Recognized text: ${result.recognizedWords}');
          },
          localeId: 'ja_JP',
          listenMode: ListenMode.dictation,
        );
      } else {
        print('Speech recognition initialization failed');
        Get.snackbar(
          '音声認識の初期化に失敗しました',
          'ブラウザの設定を確認してください',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Exception during speech recognition start: $e');
      Get.snackbar(
        '音声認識エラー',
        'エラーが発生しました: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      isListening.value = false;
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    isListening.value = false;
    if (recognizedText.value.isNotEmpty) {
      await processText(recognizedText.value);
    }
  }

  Future<void> processText(String text) async {
    try {
      isProcessing.value = true;
      print('Sending text to API: $text');

      // CORS対策としてヘッダーを追加
      Map<String, String> headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      };

      // Web特有の追加ヘッダー
      if (kIsWeb) {
        headers['X-Requested-With'] = 'XMLHttpRequest'; // CORSヘッダー
      }

      final response = await http.post(
        Uri.parse(processEndpoint),
        headers: headers,
        body: json.encode({'text': text}),
      );

      print('Response status code: ${response.statusCode}');
      print('Response raw body: ${response.body}');

      if (response.statusCode == 200) {
        // レスポンスをUTF-8としてデコード
        final decodedBody = utf8.decode(response.bodyBytes);
        print('Decoded body: $decodedBody');

        final responseData = json.decode(decodedBody);
        print('Parsed response type: ${responseData.runtimeType}');
        print('Parsed response content: $responseData');

        // 現在の食材リストを保存
        final List<FoodItem> currentItems = List<FoodItem>.from(processedItems);

        // レスポンスがリストの場合（現在のレスポンス形式）
        if (responseData is List) {
          print('Processing list response: $responseData');
          final foodItems =
              responseData
                  .map((item) {
                    print('Processing item: $item');
                    if (item is Map<String, dynamic>) {
                      final foodItem = FoodItem(
                        name: item['食材']?.toString() ?? '',
                        quantity: item['個数']?.toString() ?? '',
                        expiryDate: item['消費/賞味期限']?.toString() ?? '',
                      );
                      print('Created FoodItem: $foodItem');
                      return foodItem;
                    }
                    return null;
                  })
                  .whereType<FoodItem>()
                  .toList();

          print('Created food items: $foodItems');

          // 同じ食材名の場合は個数を合計する
          final Map<String, FoodItem> mergedItems = {};

          // 既存のアイテムを処理
          for (final item in currentItems) {
            if (!mergedItems.containsKey(item.name)) {
              mergedItems[item.name] = item;
            } else {
              // 個数を合計
              final currentQuantity = _parseQuantity(
                mergedItems[item.name]!.quantity,
              );
              final newQuantity = _parseQuantity(item.quantity);
              final totalQuantity = currentQuantity + newQuantity;

              // 合計した新しいFoodItemを作成（より新しい期限を優先）
              mergedItems[item.name] = FoodItem(
                name: item.name,
                quantity: _formatQuantity(totalQuantity),
                expiryDate: _compareExpiryDates(
                  mergedItems[item.name]!.expiryDate,
                  item.expiryDate,
                ),
              );
            }
          }

          // 新しいアイテムを処理
          for (final item in foodItems) {
            if (!mergedItems.containsKey(item.name)) {
              mergedItems[item.name] = item;
            } else {
              // 個数を合計
              final currentQuantity = _parseQuantity(
                mergedItems[item.name]!.quantity,
              );
              final newQuantity = _parseQuantity(item.quantity);
              final totalQuantity = currentQuantity + newQuantity;

              // 合計した新しいFoodItemを作成（より新しい期限を優先）
              mergedItems[item.name] = FoodItem(
                name: item.name,
                quantity: _formatQuantity(totalQuantity),
                expiryDate: _compareExpiryDates(
                  mergedItems[item.name]!.expiryDate,
                  item.expiryDate,
                ),
              );
            }
          }

          // リストを一度クリアして、マージしたリストを追加
          processedItems.clear();
          processedItems.addAll(mergedItems.values.toList());

          print('Merged items count: ${processedItems.length}');
        }
        showConfirmation.value = true;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Exception during processing: $e');
      print('Stack trace: $stackTrace');
    } finally {
      isProcessing.value = false;
    }
  }

  // 個数をパースして数値に変換する補助メソッド
  int _parseQuantity(String quantityText) {
    // 数字のみを抽出
    final numberMatch = RegExp(r'\d+').firstMatch(quantityText);
    if (numberMatch != null) {
      return int.tryParse(numberMatch.group(0) ?? '0') ?? 0;
    }
    return 0;
  }

  // 数値を個数形式に変換する補助メソッド
  String _formatQuantity(int quantity) {
    return '$quantity個';
  }

  // 二つの消費/賞味期限を比較して、より新しい（または意味のある）方を返す
  String _compareExpiryDates(String date1, String date2) {
    // 日付形式がない場合は最初の値を返す
    if (date1.isEmpty) return date2;
    if (date2.isEmpty) return date1;

    // 簡易的な比較：より長い（詳細な）情報を優先
    if (date1.length > date2.length) return date1;
    if (date2.length > date1.length) return date2;

    // 同じ長さならより最近の日付（数値が大きい）を優先
    // ただし、簡易実装のため、文字列比較で代用
    return date1.compareTo(date2) > 0 ? date1 : date2;
  }

  void confirmCompletion() {
    showConfirmation.value = false;
    showCompletion.value = true;
  }

  void continueInput() {
    showConfirmation.value = false;
    // 続けて入力する場合は認識テキストのみクリア（processedItemsはクリアしない）
    recognizedText.value = '';
    // 入力を開始
    startListening();
  }

  void reset() {
    showConfirmation.value = false;
    showCompletion.value = false;
    recognizedText.value = '';
    processedItems.clear();
  }

  @override
  void onClose() {
    _speechToText.stop();
    super.onClose();
  }
}
