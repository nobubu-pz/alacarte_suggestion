import 'package:http/http.dart' as http;

class VoiceInputDataSource {
  Future<void> sendText(String text) async {
    // GCPのAPI Gatewayのエンドポイントを指定
    var url = Uri.parse('YOUR_API_GATEWAY_ENDPOINT');
    var response = await http.post(url, body: {'text': text});
    if (response.statusCode != 200) {
      throw Exception('API request failed with status: ${response.statusCode}');
    }
  }
}
