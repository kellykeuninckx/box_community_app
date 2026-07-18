import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wod_score.dart';
import 'user_profile_service.dart';

class WodService {
  final _collection = FirebaseFirestore.instance.collection('wod_scores');

  Stream<List<WodScore>> scoresFor(String wodName) {
    return _collection
        .where('wodName', isEqualTo: wodName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WodScore.fromFirestore).toList());
  }

  Future<void> submitTimeScore({
    required String wodName,
    required int timeInSeconds,
    required bool isScaled,
  }) async {
    final nickname = await _currentNickname();

    await _collection.add({
      'wodName': wodName,
      'nickname': nickname,
      'isScaled': isScaled,
      'timeInSeconds': timeInSeconds,
      'rounds': null,
      'extraReps': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitRepsScore({
    required String wodName,
    required int rounds,
    required int extraReps,
    required bool isScaled,
  }) async {
    final nickname = await _currentNickname();

    await _collection.add({
      'wodName': wodName,
      'nickname': nickname,
      'isScaled': isScaled,
      'timeInSeconds': null,
      'rounds': rounds,
      'extraReps': extraReps,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _currentNickname() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Onbekend lid';
    return UserProfileService().nicknameFor(uid);
  }
}