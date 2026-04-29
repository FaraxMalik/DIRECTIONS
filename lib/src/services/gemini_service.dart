import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/personality_question.dart';
import '../models/personality_results.dart';
import '../../config/api_keys.dart';

class GeminiService {
  static const String apiKey = ApiKeys.geminiApiKey;

  // Fallback model list — tries each in order if quota is exceeded.
  // gemini-2.5-flash-lite is the most generous free-tier model (1500 req/day, 15 RPM).
  // The others are fallbacks if rate-limited.
  static const List<String> _models = [
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemma-3-27b-it',
  ];

  static String _endpointFor(String model) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  Future<String> getCareerSuggestionFull({
    required List<Map<String, dynamic>> answers,
    Map<String, dynamic>? journalInsights,
    PersonalityResults? personalityResults,
  }) async {
    final prompt = _buildFullPrompt(
      answers: answers,
      journalInsights: journalInsights,
      personalityResults: personalityResults,
    );
    return await _callGemini(prompt);
  }

  /// Asks Gemini to infer the user's MBTI-like type and Big Five scores
  /// from their raw question/response data. Returns null if Gemini fails
  /// or gives an unparseable response, so callers can fall back to local
  /// scoring.
  Future<PersonalityResults?> inferPersonalityFromAnswers({
    required List<PersonalityQuestion> bigFiveQuestions,
    required Map<int, int> bigFiveResponses,
    required List<PersonalityQuestion> jungianQuestions,
    required Map<int, int> jungianResponses,
  }) async {
    try {
      final buffer = StringBuffer()
        ..writeln(
            'You are an expert personality psychologist. Given the user\'s '
            'raw responses to the IPIP-50 (Big Five) and Jungian 16-type '
            'questionnaires below (1=Strongly Disagree, 5=Strongly Agree), '
            'infer their results. Respond ONLY with strict JSON in this exact shape, '
            'no prose, no markdown:')
        ..writeln('{')
        ..writeln('  "mbtiLikeType": "XXXX",')
        ..writeln('  "bigFive": {')
        ..writeln('    "openness": 0-100,')
        ..writeln('    "conscientiousness": 0-100,')
        ..writeln('    "extraversion": 0-100,')
        ..writeln('    "agreeableness": 0-100,')
        ..writeln('    "neuroticism": 0-100')
        ..writeln('  }')
        ..writeln('}')
        ..writeln()
        ..writeln('=== BIG FIVE RESPONSES ===');
      for (final q in bigFiveQuestions) {
        final r = bigFiveResponses[q.id];
        if (r == null) continue;
        buffer.writeln(
            'Q${q.id} [${q.dimension}${q.reverse ? '-rev' : ''}]: ${q.text} → $r');
      }
      buffer
        ..writeln()
        ..writeln('=== JUNGIAN 16-TYPE RESPONSES ===');
      for (final q in jungianQuestions) {
        final r = jungianResponses[q.id];
        if (r == null) continue;
        buffer.writeln(
            'Q${q.id} [${q.dimension}${q.reverse ? '-rev' : ''}]: ${q.text} → $r');
      }

      final raw = await _callGemini(buffer.toString());
      if (raw.startsWith('Error')) return null;

      // Extract JSON between first { and last }
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final jsonStr = raw.substring(start, end + 1);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      final type = parsed['mbtiLikeType'];
      final big = parsed['bigFive'];
      if (type is! String || big is! Map) return null;

      return PersonalityResults(
        mbtiLikeType: type,
        bigFive: BigFiveScores.fromMap(Map<String, dynamic>.from(big)),
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> testApiKey() async {
    try {
      final response =
          await _callGemini('Say "API is working" in exactly those 3 words.');
      if (response.startsWith('Error:')) return response;
      return 'OK';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _callGemini(String prompt) async {
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    // Try each model in order, falling back if quota exceeded
    for (final model in _models) {
      try {
        final response = await http
            .post(
              Uri.parse(_endpointFor(model)),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
              'No response from AI.';
        } else if (response.statusCode == 429) {
          // Quota exceeded — try next model
          continue;
        } else if (response.statusCode == 403) {
          return 'Error: API key is invalid or suspended (403). Please provide a new API key.';
        } else {
          final errorBody = jsonDecode(response.body);
          final errorMsg =
              errorBody['error']?['message'] ?? 'Unknown error';
          return 'Error ${response.statusCode}: $errorMsg';
        }
      } catch (e) {
        // Network error on this model — try next
        continue;
      }
    }

    return 'Error: All models quota exceeded for today. The free tier resets at midnight (Pacific Time). '
        'Please try again tomorrow or create a new API key from a fresh Google Cloud project at '
        'https://aistudio.google.com/apikey';
  }

  String _buildFullPrompt({
    required List<Map<String, dynamic>> answers,
    Map<String, dynamic>? journalInsights,
    PersonalityResults? personalityResults,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'You are an expert Career Counselor specializing in the Pakistani job market and education system. '
        'You have deep knowledge of career opportunities in Pakistan including government jobs (CSS, PMS, armed forces), '
        'private sector (IT, banking, telecom, FMCG, textiles), freelancing, entrepreneurship, and emerging fields. '
        'You understand Pakistani universities, professional certifications, and the local employment landscape.');
    buffer.writeln();
    buffer.writeln(
        'The user is a Pakistani student/professional seeking career guidance. '
        'You are given their quiz answers, personality test results, and journal entries. '
        'Your task: suggest the TOP 3 best-suited careers that are realistic and achievable in Pakistan, '
        'and explain why each fits based on ALL the data provided.');
    buffer.writeln();

    // ── PERSONALITY RESULTS ──
    if (personalityResults != null) {
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('PERSONALITY TEST RESULTS:');
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln();
      buffer.writeln(
          '📋 Jungian 16-Type (MBTI-like): ${personalityResults.mbtiLikeType}');
      buffer.writeln();
      buffer.writeln('📊 Big Five (OCEAN) Personality Scores (0-100%):');
      buffer.writeln(
          '  • Openness to Experience: ${personalityResults.bigFive.openness.toStringAsFixed(1)}%');
      buffer.writeln(
          '  • Conscientiousness: ${personalityResults.bigFive.conscientiousness.toStringAsFixed(1)}%');
      buffer.writeln(
          '  • Extraversion: ${personalityResults.bigFive.extraversion.toStringAsFixed(1)}%');
      buffer.writeln(
          '  • Agreeableness: ${personalityResults.bigFive.agreeableness.toStringAsFixed(1)}%');
      buffer.writeln(
          '  • Neuroticism: ${personalityResults.bigFive.neuroticism.toStringAsFixed(1)}%');
      buffer.writeln();
      buffer.writeln(
          'USE THESE PERSONALITY RESULTS HEAVILY in your career recommendation. '
          'The MBTI type and Big Five scores reveal the user\'s core personality traits, work style, '
          'leadership potential, stress tolerance, and interpersonal dynamics.');
      buffer.writeln();
    }

    // ── JOURNAL INSIGHTS ──
    if (journalInsights != null && journalInsights.isNotEmpty) {
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('JOURNAL INSIGHTS:');
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln();
      buffer.writeln('Total entries: ${journalInsights['totalEntries']}');
      if (journalInsights['writingFrequency'] != null) {
        buffer.writeln(
            'Writing frequency: ${(journalInsights['writingFrequency'] as num).toStringAsFixed(2)} entries/day');
      }
      buffer.writeln('Dominant mood: ${journalInsights['dominantMood']}');
      buffer.writeln(
          'Average words per entry: ${journalInsights['averageWordsPerEntry']}');
      if (journalInsights['commonTags'] != null &&
          (journalInsights['commonTags'] as List).isNotEmpty) {
        buffer.writeln(
            'Common themes/tags: ${(journalInsights['commonTags'] as List).join(', ')}');
      }
      buffer.writeln();
      buffer.writeln(
          'JOURNAL TEXT (analyze thinking patterns, communication style, interests, passions):');
      final allText = journalInsights['allText'] as String? ?? '';
      final truncatedText = allText.length > 2000
          ? '${allText.substring(0, 2000)}...'
          : allText;
      buffer.writeln(truncatedText);
      buffer.writeln();
      buffer.writeln(
          'USE THE JOURNAL to understand what the user is passionate about, '
          'how they think, their communication style, emotional patterns, and hidden interests.');
      buffer.writeln();
    }

    // ── QUIZ ANSWERS ──
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('CAREER QUIZ ANSWERS:');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    for (int i = 0; i < answers.length; i++) {
      final answer = answers[i];
      buffer.writeln('${i + 1}. Q: ${answer['question']}');
      buffer.writeln('   A: ${answer['answer']}');
    }
    buffer.writeln();

    // ── OUTPUT REQUIREMENTS ──
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('OUTPUT REQUIREMENTS:');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln(
        '- Recommend TOP 3 careers that are realistic and in-demand in PAKISTAN.');
    buffer.writeln(
        '- Consider Pakistani job market realities: government sector, private sector, freelancing, startups.');
    buffer.writeln(
        '- Include specific Pakistani context: relevant universities/certifications, salary ranges in PKR, growth potential in Pakistan.');
    buffer.writeln(
        '- Use ALL three data sources: personality results + journal insights + quiz answers.');
    buffer.writeln(
        '- If personality data is missing, still give recommendations based on available data.');
    buffer.writeln(
        '- Be specific (e.g., "Software Engineer at a Pakistani IT company or freelancing on Upwork/Fiverr", '
        '"CSS Officer", "Chartered Accountant (ICAP)", "Digital Marketing Specialist", not just generic titles).');
    buffer.writeln(
        '- Mention relevant Pakistani platforms, companies, or institutions where applicable.');
    buffer.writeln();
    buffer.writeln('OUTPUT FORMAT (follow this exactly):');
    buffer.writeln();
    buffer.writeln('Career 1: <career title>');
    buffer.writeln(
        'Why it fits: <3-4 sentences explaining the fit based on personality, journal, and quiz>');
    buffer.writeln('Pakistan context: <1-2 sentences about this career in Pakistan>');
    buffer.writeln();
    buffer.writeln('Career 2: <career title>');
    buffer.writeln(
        'Why it fits: <3-4 sentences explaining the fit based on personality, journal, and quiz>');
    buffer.writeln('Pakistan context: <1-2 sentences about this career in Pakistan>');
    buffer.writeln();
    buffer.writeln('Career 3: <career title>');
    buffer.writeln(
        'Why it fits: <3-4 sentences explaining the fit based on personality, journal, and quiz>');
    buffer.writeln('Pakistan context: <1-2 sentences about this career in Pakistan>');

    return buffer.toString();
  }
}
