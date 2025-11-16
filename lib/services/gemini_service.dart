import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Content {
  final String role;
  final String text;

  Content(this.role, this.text);
}

class GeminiService {
  final String _proxyUrl =
      dotenv.env['PROXY_SERVER_URL'] ?? 'https://default.url/error';
  final String _modelName =
      dotenv.env['DEFAULT_MODEL_NAME'] ?? 'gemini-2.5-flash';

  Future<String?> _getUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_gemini_api_key');
  }

  Future<String> getResponse(
    String systemPrompt,
    List<Content> history,
    String userMessage,
  ) async {
    final userApiKey = await _getUserApiKey();
    final headers = {'Content-Type': 'application/json'};
    if (userApiKey != null && userApiKey.isNotEmpty) {
      headers['X-API-Key'] = userApiKey;
    }

    final chatHistoryForProxy = history.map((content) {
      return {
        "role": content.role,
        "parts": [
          {"text": content.text},
        ],
      };
    }).toList();

    final body = {
      "model": _modelName,
      "prompt": userMessage,
      "chat_history": chatHistoryForProxy,
      "system_instruction": systemPrompt,
    };

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Ответ пришел успешно
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final modelResponse = responseData['response_text'];

        if (modelResponse == null || modelResponse.isEmpty) {
          throw Exception('Прокси-сервер вернул пустой ответ.');
        }

        return modelResponse;
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          'Ошибка сервера: ${response.statusCode}. ${errorData['error'] ?? ''}',
        );
      }
    } catch (e) {
      print(e);
      throw Exception(
        'Не удалось подключиться к серверу. Проверьте соединение.',
      );
    }
  }
}
