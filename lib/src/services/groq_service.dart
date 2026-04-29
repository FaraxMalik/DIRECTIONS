import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/personality_results.dart';
import '../../config/api_keys.dart';

class GroqService {
  static const String apiKey = ApiKeys.groqApiKey;
  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  // Fast, capable free models on Groq
  static const List<String> _models = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'gemma2-9b-it',
  ];

  /// Build the system prompt that defines the AI counselor's persona.
  /// Personalizes based on the user's personality results and journal data.
  static String buildSystemPrompt({
    PersonalityResults? personality,
    Map<String, dynamic>? journalInsights,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'You are "Faraz" — a warm, insightful, and highly experienced personal career counselor '
        'specializing in the Pakistani job market and education system. You speak like a trusted mentor: '
        'empathetic, direct, occasionally witty, and never preachy.');
    buffer.writeln();
    buffer.writeln('YOUR COUNSELING STYLE:');
    buffer.writeln(
        '- Use proven counseling techniques: active listening, open-ended questions, reflection, '
        'reframing, and Socratic questioning.');
    buffer.writeln(
        '- Help the user think for themselves rather than dumping advice. Ask "why do you feel that way?", '
        '"what would success look like?", "what is holding you back?".');
    buffer.writeln(
        '- Validate emotions before giving practical guidance.');
    buffer.writeln(
        '- Be specific: mention real Pakistani universities (LUMS, NUST, FAST, IBA, COMSATS), '
        'companies (Systems Limited, NetSol, 10Pearls, Daraz, Careem, Bazaar, Telenor), '
        'certifications (CFA, ACCA, CSS, ICAP, AWS, Google), and platforms (Upwork, Fiverr, LinkedIn).');
    buffer.writeln(
        '- Mention salary ranges in PKR when relevant (e.g., "Junior devs in Karachi earn PKR 60-100k").');
    buffer.writeln(
        '- Keep responses conversational and digestible — usually 2-4 short paragraphs. '
        'Use bullet points only when listing options.');
    buffer.writeln(
        '- Use simple, clear language. No corporate jargon. Mix in occasional Urdu/English phrases '
        'naturally if it fits (like "yaar", "bilkul", "jee") — but sparingly and only if culturally apt.');
    buffer.writeln(
        '- Never invent statistics. If unsure, say so honestly.');
    buffer.writeln();

    if (personality != null) {
      buffer.writeln('USER\'S PERSONALITY PROFILE:');
      buffer.writeln(
          '- MBTI-like type: ${personality.mbtiLikeType}');
      buffer.writeln(
          '- Big Five (OCEAN): Openness ${personality.bigFive.openness.toStringAsFixed(0)}%, '
          'Conscientiousness ${personality.bigFive.conscientiousness.toStringAsFixed(0)}%, '
          'Extraversion ${personality.bigFive.extraversion.toStringAsFixed(0)}%, '
          'Agreeableness ${personality.bigFive.agreeableness.toStringAsFixed(0)}%, '
          'Neuroticism ${personality.bigFive.neuroticism.toStringAsFixed(0)}%');
      buffer.writeln(
          'Tailor your advice to these traits but don\'t mention the scores explicitly unless asked.');
      buffer.writeln();
    }

    if (journalInsights != null && journalInsights.isNotEmpty) {
      buffer.writeln('USER\'S JOURNAL INSIGHTS:');
      buffer.writeln('- Total entries: ${journalInsights['totalEntries']}');
      buffer.writeln(
          '- Dominant mood: ${journalInsights['dominantMood']}');
      if (journalInsights['commonTags'] != null &&
          (journalInsights['commonTags'] as List).isNotEmpty) {
        buffer.writeln(
            '- Themes they write about: ${(journalInsights['commonTags'] as List).join(', ')}');
      }
      final allText = journalInsights['allText'] as String? ?? '';
      if (allText.isNotEmpty) {
        final excerpt =
            allText.length > 800 ? '${allText.substring(0, 800)}...' : allText;
        buffer.writeln('- Recent journal excerpt: "$excerpt"');
      }
      buffer.writeln(
          'Use this to understand their interests and emotional state. Reference it subtly when relevant.');
      buffer.writeln();
    }

    buffer.writeln(
        'Start your first message with a warm, personal greeting that references something '
        'specific from their profile if available.');

    return buffer.toString();
  }

  /// Send chat history to Groq and get the assistant's reply.
  /// [messages] should be a list of {role, content} maps.
  Future<String> chat(List<Map<String, String>> messages) async {
    for (final model in _models) {
      try {
        final body = jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 1024,
        });

        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices']?[0]?['message']?['content'] ??
              'I\'m here, but didn\'t catch that. Could you say it again?';
        } else if (response.statusCode == 429) {
          continue; // try next model
        } else if (response.statusCode == 401) {
          return 'Error: Groq API key is invalid. Please update the key.';
        } else {
          final errorBody = jsonDecode(response.body);
          final errorMsg =
              errorBody['error']?['message'] ?? 'Unknown error';
          return 'Error ${response.statusCode}: $errorMsg';
        }
      } catch (e) {
        continue;
      }
    }
    return 'Error: All counseling models are busy right now. Please try again in a moment.';
  }
}
