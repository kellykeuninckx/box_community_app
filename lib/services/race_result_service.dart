import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/race_result.dart';
import 'user_profile_service.dart';

class RaceResultService {
  final _collection = FirebaseFirestore.instance.collection('race_results');

  Stream<List<RaceResult>> resultsFor(RaceType raceType) {
    return _collection
        .where('raceType', isEqualTo: raceType.name)
        .orderBy('timeSeconds')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(RaceResult.fromFirestore).toList(),
        );
  }

  /// In tegenstelling tot lift-PR's (één document per persoon per lift, dat
  /// steeds wordt overschreven) krijgt hier elke inzending een eigen document,
  /// zodat de geschiedenis van meerdere evenementen per persoon bewaard blijft.
  Future<void> submitResult({
    required RaceType raceType,
    required RaceMode mode,
    required int timeSeconds,
    String? note,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileService = UserProfileService();
    final nickname = await profileService.nicknameFor(uid);
    final profile = await profileService.fetchOnce(uid);

    if (profile?.gender == null) return;

    await _collection.add({
      'uid': uid,
      'nickname': nickname,
      'raceType': raceType.name,
      'mode': mode.name,
      'gender': profile!.gender,
      'timeSeconds': timeSeconds,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResult(String docId) async {
    await _collection.doc(docId).delete();
  }
}
