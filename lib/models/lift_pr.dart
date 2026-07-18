import 'package:cloud_firestore/cloud_firestore.dart';

enum LiftType { deadlift, benchPress, backSquat, shoulderPress }

extension LiftTypeLabel on LiftType {
  String get label {
    switch (this) {
      case LiftType.deadlift:
        return 'Deadlift';
      case LiftType.benchPress:
        return 'Bench Press';
      case LiftType.backSquat:
        return 'Back Squat';
      case LiftType.shoulderPress:
        return 'Shoulder Press';
    }
  }
}

class LiftPr {
  final String uid;
  final String nickname;
  final String lift;
  final double weightKg;
  final String gender;
  final double bodyweightKg;
  final DateTime updatedAt;

  LiftPr({
    required this.uid,
    required this.nickname,
    required this.lift,
    required this.weightKg,
    required this.gender,
    required this.bodyweightKg,
    required this.updatedAt,
  });

  factory LiftPr.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiftPr(
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? 'Onbekend lid',
      lift: data['lift'] ?? '',
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0,
      gender: data['gender'] ?? 'M',
      bodyweightKg: (data['bodyweightKg'] as num?)?.toDouble() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}