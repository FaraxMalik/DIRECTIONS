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
    final buffer = StringBuffer();
    buffer.writeln(
      'You are an expert Career Counselor with years of experience helping students choose the right, realistic career paths and succeed. '
      'You are given the following questionnaire answers. Your task: suggest ONE best-suited career from today\'s job market and briefly explain why it fits.'
    );
    buffer.writeln();
    buffer.writeln('Output requirements:');
    buffer.writeln('- Be realistic and specific (e.g., Data Analyst, UX Designer, Fashion Designer, Lawyer, Entrepreneur, Mechanical Engineer; not generic).');
    buffer.writeln('- Align the rationale directly to the answers provided.');
    buffer.writeln('- Keep it concise and professional; no fluff or disclaimers.');
    buffer.writeln('- Limit explanation to 2–4 sentences.');
    buffer.writeln();
    buffer.writeln('Output format:');
    buffer.writeln('Title: <career>');
    buffer.writeln('Reason: <2–4 sentences explaining the fit>');
    buffer.writeln();
    buffer.writeln('Answers:');
    for (int i = 0; i < answers.length; i++) {
      buffer.writeln('Q${i + 1}: ${answers[i]['question']}');
      buffer.writeln('A: ${answers[i]['answer']}');
    }
    return buffer.toString();
  }
}
