import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyDgMBzEsKUwSEqG6nTirkvvAafWC3spqo4';
  static const String model = 'gemini-1.5-flash';
  static const String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  Future<String> getCareerSuggestionWithJournal(
    List<Map<String, dynamic>> answers, 
    Map<String, dynamic>? journalInsights
  ) async {
    final prompt = _buildPromptWithJournal(answers, journalInsights);
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

  String _buildPromptWithJournal(List<Map<String, dynamic>> answers, Map<String, dynamic>? journalInsights) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are an expert Career Counselor with years of experience helping students choose the right, realistic career paths and succeed. '
      'You are given questionnaire answers AND personal journal entries from the user. '
      'The journal entries contain the user\'s RANDOM THOUGHTS - these are extremely valuable for understanding HOW THE USER THINKS and PROCESSES information. '
      'Your task: suggest ONE best-suited career from today\'s job market and explain why it fits based on BOTH quiz answers AND journal analysis.'
    );
    buffer.writeln();
    
    if (journalInsights != null && journalInsights.isNotEmpty) {
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('📊 JOURNAL STATISTICS:');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('Total entries: ${journalInsights['totalEntries']}');
      buffer.writeln('Writing frequency: ${journalInsights['writingFrequency']?.toStringAsFixed(2)} entries/day');
      buffer.writeln('Dominant mood: ${journalInsights['dominantMood']}');
      buffer.writeln('Average words per entry: ${journalInsights['averageWordsPerEntry']?.toStringAsFixed(0)}');
      if (journalInsights['commonTags'] != null && (journalInsights['commonTags'] as List).isNotEmpty) {
        buffer.writeln('Common themes: ${(journalInsights['commonTags'] as List).join(', ')}');
      }
      buffer.writeln();
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('💭 USER\'S JOURNAL ENTRIES (Random Thoughts & Observations):');
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('IMPORTANT: These are the user\'s PERSONAL THOUGHTS. Analyze them carefully to understand:');
      buffer.writeln('- HOW they think and process information');
      buffer.writeln('- WHAT topics genuinely interest them');
      buffer.writeln('- Their communication style and depth of thinking');
      buffer.writeln('- Their natural inclinations, passions, and problem-solving approach');
      buffer.writeln('- Patterns in their concerns, aspirations, and decision-making');
      buffer.writeln();
      final allText = journalInsights['allText'] as String? ?? '';
      // Limit to 3000 characters for more context
      final truncatedText = allText.length > 3000 ? '${allText.substring(0, 3000)}...' : allText;
      buffer.writeln(truncatedText);
      buffer.writeln();
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln();
    }
    
    buffer.writeln('📝 OUTPUT REQUIREMENTS:');
    buffer.writeln('- CRITICALLY IMPORTANT: Give HEAVY WEIGHT to the journal entries - they reveal the user\'s true thinking patterns');
    buffer.writeln('- Use BOTH quiz answers AND journal content to make your recommendation');
    buffer.writeln('- The journal shows authentic personality, thinking patterns, interests, and decision-making style');
    buffer.writeln('- Be realistic and specific (e.g., Data Analyst, UX Designer, Fashion Designer, Lawyer, Entrepreneur, Mechanical Engineer; not generic)');
    buffer.writeln('- Align the rationale directly to BOTH the quiz answers AND observable patterns from the journal');
    buffer.writeln('- Keep it concise and professional; no fluff or disclaimers');
    buffer.writeln('- Limit explanation to 3–5 sentences');
    buffer.writeln();
    buffer.writeln('📋 OUTPUT FORMAT:');
    buffer.writeln('Title: <career>');
    buffer.writeln('Reason: <3–5 sentences explaining the fit based on quiz AND journal thinking patterns>');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('📊 QUIZ ANSWERS:');
    buffer.writeln('═══════════════════════════════════════════════════════════');
    
    for (int i = 0; i < answers.length; i++) {
      final answer = answers[i];
      buffer.writeln('${i + 1}. Q: ${answer['question']}');
      buffer.writeln('   A: ${answer['answer']}');
    }
    
    return buffer.toString();
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
