import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/personality_question.dart';
import '../models/personality_results.dart';

class PersonalityScoringService {
  // Load questions from JSON assets
  static Future<List<PersonalityQuestion>> loadIPIP50Questions() async {
    final String jsonString = await rootBundle.loadString('assets/ipip50_questions.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PersonalityQuestion.fromJson(json)).toList();
  }

  static Future<List<PersonalityQuestion>> loadJungianQuestions() async {
    final String jsonString = await rootBundle.loadString('assets/jungian_questions.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PersonalityQuestion.fromJson(json)).toList();
  }

  // Calculate Big Five scores from IPIP-50 responses
  static BigFiveScores calculateBigFiveScores(
    List<PersonalityQuestion> questions,
    Map<int, int> responses, // questionId -> answer (1-5)
  ) {
    // Initialize dimension scores
    final Map<String, List<double>> dimensionScores = {
      'openness': [],
      'conscientiousness': [],
      'extraversion': [],
      'agreeableness': [],
      'neuroticism': [],
    };

    // Process each question
    for (var question in questions) {
      final response = responses[question.id];
      if (response == null) continue;

      // Reverse score if needed
      double score = question.reverse 
          ? (6 - response).toDouble() 
          : response.toDouble();

      dimensionScores[question.dimension]?.add(score);
    }

    // Calculate average and convert to percentage (0-100)
    double calculatePercentage(List<double> scores) {
      if (scores.isEmpty) return 0;
      final average = scores.reduce((a, b) => a + b) / scores.length;
      // Convert from 1-5 scale to 0-100 percentage
      return ((average - 1) / 4) * 100;
    }

    return BigFiveScores(
      openness: calculatePercentage(dimensionScores['openness']!),
      conscientiousness: calculatePercentage(dimensionScores['conscientiousness']!),
      extraversion: calculatePercentage(dimensionScores['extraversion']!),
      agreeableness: calculatePercentage(dimensionScores['agreeableness']!),
      neuroticism: calculatePercentage(dimensionScores['neuroticism']!),
    );
  }

  // Calculate Jungian 16-type from OEJTS responses
  static String calculateJungianType(
    List<PersonalityQuestion> questions,
    Map<int, int> responses, // questionId -> answer (1-5)
  ) {
    // Initialize dimension scores
    final Map<String, double> dimensionScores = {
      'E': 0, 'I': 0,
      'S': 0, 'N': 0,
      'T': 0, 'F': 0,
      'J': 0, 'P': 0,
    };

    // Process each question
    for (var question in questions) {
      final response = responses[question.id];
      if (response == null) continue;

      // Calculate score contribution (1-5 scale)
      double score = question.reverse 
          ? (6 - response).toDouble() 
          : response.toDouble();

      // Add to the appropriate dimension
      dimensionScores[question.dimension] = 
          (dimensionScores[question.dimension] ?? 0) + score;
    }

    // Determine type by comparing dichotomies
    String getType(String dim1, String dim2) {
      return (dimensionScores[dim1]! > dimensionScores[dim2]!) ? dim1 : dim2;
    }

    final type1 = getType('E', 'I');
    final type2 = getType('S', 'N');
    final type3 = getType('T', 'F');
    final type4 = getType('J', 'P');

    return '$type1$type2$type3$type4';
  }

  // Get personality type description
  static String getTypeDescription(String type) {
    const descriptions = {
      'INTJ': 'The Architect - Strategic, independent, and analytical thinkers.',
      'INTP': 'The Logician - Innovative, curious, and love theoretical concepts.',
      'ENTJ': 'The Commander - Bold, imaginative, and strong-willed leaders.',
      'ENTP': 'The Debater - Smart, curious, and love intellectual challenges.',
      'INFJ': 'The Advocate - Quiet, mystical, and inspiring idealists.',
      'INFP': 'The Mediator - Poetic, kind, and altruistic people.',
      'ENFJ': 'The Protagonist - Charismatic, inspiring, and natural leaders.',
      'ENFP': 'The Campaigner - Enthusiastic, creative, and sociable free spirits.',
      'ISTJ': 'The Logistician - Practical, fact-minded, and reliable.',
      'ISFJ': 'The Defender - Dedicated, warm protectors.',
      'ESTJ': 'The Executive - Excellent administrators, managing things.',
      'ESFJ': 'The Consul - Caring, social, and popular people.',
      'ISTP': 'The Virtuoso - Bold and practical experimenters.',
      'ISFP': 'The Adventurer - Flexible, charming artists.',
      'ESTP': 'The Entrepreneur - Smart, energetic, and perceptive.',
      'ESFP': 'The Entertainer - Spontaneous, energetic, and enthusiastic.',
    };
    return descriptions[type] ?? 'Unknown Type';
  }

  // Get Big Five trait description
  static String getTraitDescription(String trait, double score) {
    if (score >= 70) {
      return _getHighDescription(trait);
    } else if (score <= 30) {
      return _getLowDescription(trait);
    } else {
      return _getModerateDescription(trait);
    }
  }

  static String _getHighDescription(String trait) {
    const descriptions = {
      'openness': 'Highly creative, curious, and open to new experiences.',
      'conscientiousness': 'Very organized, disciplined, and goal-oriented.',
      'extraversion': 'Outgoing, energetic, and enjoys social interactions.',
      'agreeableness': 'Compassionate, cooperative, and values harmony.',
      'neuroticism': 'Tends to experience stress, worry, and emotional fluctuations.',
    };
    return descriptions[trait.toLowerCase()] ?? '';
  }

  static String _getLowDescription(String trait) {
    const descriptions = {
      'openness': 'Prefers routine, practical, and conventional approaches.',
      'conscientiousness': 'More spontaneous, flexible, and less focused on planning.',
      'extraversion': 'Reserved, prefers solitude, and thoughtful.',
      'agreeableness': 'More skeptical, competitive, and direct.',
      'neuroticism': 'Calm, emotionally stable, and resilient.',
    };
    return descriptions[trait.toLowerCase()] ?? '';
  }

  static String _getModerateDescription(String trait) {
    const descriptions = {
      'openness': 'Balanced between creativity and practicality.',
      'conscientiousness': 'Moderately organized with some flexibility.',
      'extraversion': 'Comfortable in both social and solitary settings.',
      'agreeableness': 'Balanced between cooperation and assertiveness.',
      'neuroticism': 'Generally stable with normal emotional responses.',
    };
    return descriptions[trait.toLowerCase()] ?? '';
  }
}

