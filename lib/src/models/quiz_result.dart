class QuizResult {
  final List<String> recommendedCareers;
  final Map<String, double> scores;
  final DateTime createdAt;
  final String? personalityType; // MBTI type
  final String? description;

  QuizResult({
    required this.recommendedCareers,
    required this.scores,
    required this.createdAt,
    this.personalityType,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'recommendedCareers': recommendedCareers,
      'scores': scores,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'personalityType': personalityType,
      'description': description,
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      recommendedCareers: List<String>.from(map['recommendedCareers'] ?? []),
      scores: Map<String, double>.from(map['scores'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      personalityType: map['personalityType'],
      description: map['description'],
    );
  }
}