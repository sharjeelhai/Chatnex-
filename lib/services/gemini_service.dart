import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles communication with Google's Gemini API
class GeminiService {
  // ✅ Replace with your Gemini API key from https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBv_5A4i0KwVksOi4dsiwq64dqtTwD7irs';

  // ✅ Use latest stable endpoint
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Sends a message and gets AI response
  Future<String> sendMessage(String message) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'Missing API key. Get one from https://aistudio.google.com/app/apikey',
      );
    }

    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': message},
            ],
          },
        ],
        // ✅ Better generation settings
        'generationConfig': {
          'temperature': 0.8, // slightly more creative
          'maxOutputTokens': 4096, // allows longer responses
          'topP': 0.9,
          'topK': 40,
        },
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        final msg =
            errorData['error']?['message'] ?? 'Unknown API error occurred';
        throw Exception('API Error (${response.statusCode}): $msg');
      }

      final data = jsonDecode(response.body);

      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null && text.isNotEmpty) {
        return text.trim();
      } else {
        throw Exception('No response text found in API response.');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  bool isApiKeyConfigured() =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE';
}
