class PersonalityQuestion {
  final int id;
  final String text;
  final String dimension;
  final bool reverse;

  PersonalityQuestion({
    required this.id,
    required this.text,
    required this.dimension,
    required this.reverse,
  });

  factory PersonalityQuestion.fromJson(Map<String, dynamic> json) {
    return PersonalityQuestion(
      id: json['id'] as int,
      text: json['text'] as String,
      dimension: json['dimension'] as String,
      reverse: json['reverse'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'dimension': dimension,
      'reverse': reverse,
    };
  }
}

