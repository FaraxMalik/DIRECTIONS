import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyDgMBzEsKUwSEqG6nTirkvvAafWC3spqo4';
  static const String model = 'gemini-1.5-flash';
  static const String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  Future<String> getCareerSuggestion(List<Map<String, dynamic>> answers) async {
    final prompt = _buildPrompt(answers);
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No career found.';
    } else {
      return 'Error: ${response.statusCode}';
    }
  }

  String _buildPrompt(List<Map<String, dynamic>> answers) {
    String prompt = 'Based on the following answers, suggest a suitable career and provide a short description.\n';
    for (int i = 0; i < answers.length; i++) {
      prompt += 'Q${i + 1}: ${answers[i]['question']}\nA: ${answers[i]['answer']}\n';
    }
    return prompt;
  }
}
