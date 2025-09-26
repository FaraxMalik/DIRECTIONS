class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? age;
  final String? gender;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.age,
    this.gender,
    this.preferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'age': age,
      'gender': gender,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      age: map['age'],
      gender: map['gender'],
      preferences: map['preferences'],
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? age,
    String? gender,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      preferences: preferences ?? this.preferences,
    );
  }
}
