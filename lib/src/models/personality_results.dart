class BigFiveScores {
  final double openness;
  final double conscientiousness;
  final double extraversion;
  final double agreeableness;
  final double neuroticism;

  BigFiveScores({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
  });

  Map<String, dynamic> toMap() {
    return {
      'openness': openness,
      'conscientiousness': conscientiousness,
      'extraversion': extraversion,
      'agreeableness': agreeableness,
      'neuroticism': neuroticism,
    };
  }

  factory BigFiveScores.fromMap(Map<String, dynamic> map) {
    return BigFiveScores(
      openness: (map['openness'] ?? 0).toDouble(),
      conscientiousness: (map['conscientiousness'] ?? 0).toDouble(),
      extraversion: (map['extraversion'] ?? 0).toDouble(),
      agreeableness: (map['agreeableness'] ?? 0).toDouble(),
      neuroticism: (map['neuroticism'] ?? 0).toDouble(),
    );
  }
}

class PersonalityResults {
  final String mbtiLikeType;
  final BigFiveScores bigFive;
  final DateTime timestamp;

  PersonalityResults({
    required this.mbtiLikeType,
    required this.bigFive,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'mbtiLikeType': mbtiLikeType,
      'bigFive': bigFive.toMap(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PersonalityResults.fromMap(Map<String, dynamic> map) {
    return PersonalityResults(
      mbtiLikeType: map['mbtiLikeType'] ?? '',
      bigFive: BigFiveScores.fromMap(map['bigFive'] ?? {}),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

