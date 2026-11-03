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

/// Eén regel uit de PR-geschiedenis van een persoon voor één lift — blijft
/// bewaard ook als de huidige PR in [LiftPr] hierboven overschreven wordt.
class LiftPrHistoryEntry {
  final double weightKg;
  final DateTime createdAt;

  LiftPrHistoryEntry({required this.weightKg, required this.createdAt});

  factory LiftPrHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiftPrHistoryEntry(
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}