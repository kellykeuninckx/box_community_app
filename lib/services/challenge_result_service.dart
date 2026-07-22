import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/challenge_result.dart';
import 'user_profile_service.dart';

class ChallengeResultService {
  final _collection = FirebaseFirestore.instance.collection(
    'challenge_results',
  );

  Stream<List<ChallengeResult>> resultsFor(String challengeId) {
    return _collection
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('normalizedScore')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChallengeResult.fromFirestore).toList(),
        );
  }

  /// normalizedScore zorgt dat de query altijd oplopend sorteert, ongeacht of
  /// deze challenge op tijd (laagste wint) of reps (hoogste wint) scoort —
  /// zo hoeft er nooit een nieuwe index bij voor een nieuw soort challenge.
  Future<void> submitResult({
    required String challengeId,
    required ChallengeScoreType scoreType,
    required double rawValue,
    String? note,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileService = UserProfileService();
    final nickname = await profileService.nicknameFor(uid);
    final normalizedScore = scoreType == ChallengeScoreType.reps
        ? -rawValue
        : rawValue;

    await _collection.add({
      'uid': uid,
      'nickname': nickname,
      'challengeId': challengeId,
      'scoreType': scoreType.name,
      'rawValue': rawValue,
      'normalizedScore': normalizedScore,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResult(String docId) async {
    await _collection.doc(docId).delete();
  }
}
