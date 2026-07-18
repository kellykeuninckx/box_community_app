import 'package:cloud_firestore/cloud_firestore.dart';

class WodScore {
  final String id;
  final String wodName;
  final String nickname;
  final bool isScaled;
  final int? timeInSeconds;
  final int? rounds;
  final int? extraReps;
  final DateTime createdAt;

  WodScore({
    required this.id,
    required this.wodName,
    required this.nickname,
    required this.isScaled,
    this.timeInSeconds,
    this.rounds,
    this.extraReps,
    required this.createdAt,
  });

  factory WodScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WodScore(
      id: doc.id,
      wodName: data['wodName'] ?? '',
      nickname: data['nickname'] ?? 'Onbekend lid',
      isScaled: data['isScaled'] ?? false,
      timeInSeconds: data['timeInSeconds'],
      rounds: data['rounds'],
      extraReps: data['extraReps'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedScore {
    if (timeInSeconds != null) {
      final minutes = timeInSeconds! ~/ 60;
      final seconds = timeInSeconds! % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    if (rounds != null) {
      return '$rounds ronden + ${extraReps ?? 0} reps';
    }
    return '—';
  }
}