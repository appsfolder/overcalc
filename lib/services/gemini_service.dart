import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('user_gemini_api_key');

    if (userKey != null && userKey.isNotEmpty) {
      return userKey;
    }

    return dotenv.env['GEMINI_API_KEY'];
  }

  Future<String> getResponse(
    String systemPrompt,
    List<Content> history,
    String userMessage,
  ) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API ключ не найден. Добавьте свой ключ в настройках.');
    }

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    final systemInstruction = Content.text(systemPrompt);
    final userRequest = Content.text(userMessage);

    final fullPrompt = [systemInstruction, ...history, userRequest];

    final response = await model.generateContent(fullPrompt);
    final result = response.text?.trim();

    if (result == null || result.isEmpty) {
      throw Exception('Получен пустой ответ от модели.');
    }

    return result;
  }
}
