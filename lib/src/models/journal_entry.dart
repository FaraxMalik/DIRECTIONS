class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;
  final String mood; // happy, sad, neutral, excited, stressed, etc.
  final int wordCount;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.tags = const [],
    this.mood = 'neutral',
    required this.wordCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'tags': tags,
      'mood': mood,
      'wordCount': wordCount,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modifiedAt'] ?? 0),
      tags: List<String>.from(map['tags'] ?? []),
      mood: map['mood'] ?? 'neutral',
      wordCount: map['wordCount'] ?? 0,
    );
  }

  JournalEntry copyWith({
    String? title,
    String? content,
    DateTime? modifiedAt,
    List<String>? tags,
    String? mood,
    int? wordCount,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}