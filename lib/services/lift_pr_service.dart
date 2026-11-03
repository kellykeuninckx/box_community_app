import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lift_pr.dart';
import 'user_profile_service.dart';

class LiftPrService {
  final _collection = FirebaseFirestore.instance.collection('lift_prs');

  Stream<List<LiftPr>> prsFor(String lift) {
    return _collection
        .where('lift', isEqualTo: lift)
        .orderBy('weightKg', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(LiftPr.fromFirestore).toList());
  }

  /// Eén document per persoon per lift (id: "{uid}_{lift}") — een nieuwe PR
  /// vervangt automatisch de vorige, in plaats van dat er dubbele regels ontstaan.
  /// De geschiedenis van eerdere PR's blijft wel bewaard in de "history"
  /// subcollectie eronder — zie [historyFor].
  Future<void> submitPr({
    required String lift,
    required double weightKg,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileService = UserProfileService();
    final nickname = await profileService.nicknameFor(uid);
    final profile = await profileService.fetchOnce(uid);

    if (profile == null || !profile.hasWeightClassInfo) return;

    final docRef = _collection.doc('${uid}_$lift');
    final batch = FirebaseFirestore.instance.batch();

    batch.set(docRef, {
      'uid': uid,
      'nickname': nickname,
      'lift': lift,
      'weightKg': weightKg,
      'gender': profile.gender,
      'bodyweightKg': profile.bodyweightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(docRef.collection('history').doc(), {
      'uid': uid,
      'weightKg': weightKg,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deletePr(String docId) async {
    await _collection.doc(docId).delete();
  }

  /// PR-geschiedenis voor één persoon + lift, nieuwste eerst. Blijft bewaard
  /// ook als de huidige PR in [_collection] verwijderd of overschreven wordt.
  Stream<List<LiftPrHistoryEntry>> historyFor(String uid, String lift) {
    return _collection
        .doc('${uid}_$lift')
        .collection('history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(LiftPrHistoryEntry.fromFirestore).toList());
  }
}