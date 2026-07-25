import 'package:cloud_firestore/cloud_firestore.dart';
import 'challenge.dart';

class ChallengeResult {
  final String id;
  final String uid;
  final String nickname;
  final String challengeId;
  final ChallengeScoreType scoreType;
  final double rawValue;
  final String? note;
  final DateTime createdAt;

  /// Null voor scores die zijn ingevuld vóór de man/vrouw-splitsing bestond —
  /// die tonen we apart onder "Onbekend" in plaats van te gokken.
  final String? gender;

  ChallengeResult({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.challengeId,
    required this.scoreType,
    required this.rawValue,
    this.note,
    required this.createdAt,
    this.gender,
  });

  factory ChallengeResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeResult(
      id: doc.id,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? 'Onbekend lid',
      challengeId: data['challengeId'] ?? '',
      scoreType: ChallengeScoreType.values.firstWhere(
        (t) => t.name == data['scoreType'],
        orElse: () => ChallengeScoreType.time,
      ),
      rawValue: (data['rawValue'] as num?)?.toDouble() ?? 0,
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'],
    );
  }

  String get formattedValue {
    if (scoreType == ChallengeScoreType.reps) {
      return '${rawValue.round()} reps';
    }
    final totalSeconds = rawValue.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
