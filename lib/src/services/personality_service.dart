import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/personality_results.dart';

class PersonalityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save personality results to Firestore
  Future<void> savePersonalityResults(PersonalityResults results) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'mbtiLikeType': results.mbtiLikeType,
      'bigFive': results.bigFive.toMap(),
      'personalityTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get personality results from Firestore
  Future<PersonalityResults?> getPersonalityResults() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (data == null || 
        data['mbtiLikeType'] == null || 
        data['bigFive'] == null) {
      return null;
    }

    return PersonalityResults(
      mbtiLikeType: data['mbtiLikeType'] as String,
      bigFive: BigFiveScores.fromMap(data['bigFive'] as Map<String, dynamic>),
      timestamp: (data['personalityTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Check if user has completed personality test
  Future<bool> hasCompletedTest() async {
    final results = await getPersonalityResults();
    return results != null;
  }

  // Stream of personality results
  Stream<PersonalityResults?> personalityResultsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null || 
          data['mbtiLikeType'] == null || 
          data['bigFive'] == null) {
        return null;
      }

      return PersonalityResults(
        mbtiLikeType: data['mbtiLikeType'] as String,
        bigFive: BigFiveScores.fromMap(data['bigFive'] as Map<String, dynamic>),
        timestamp: (data['personalityTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }
}





