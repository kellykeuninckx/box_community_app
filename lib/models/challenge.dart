import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeScoreType { time, reps }

extension ChallengeScoreTypeLabel on ChallengeScoreType {
  String get label {
    switch (this) {
      case ChallengeScoreType.time:
        return 'Tijd';
      case ChallengeScoreType.reps:
        return 'Reps';
    }
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeScoreType scoreType;
  final DateTime startDate;
  final DateTime endDate;
  final String createdByUid;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.scoreType,
    required this.startDate,
    required this.endDate,
    required this.createdByUid,
    required this.createdAt,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      scoreType: ChallengeScoreType.values.firstWhere(
        (t) => t.name == data['scoreType'],
        orElse: () => ChallengeScoreType.time,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByUid: data['createdByUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Geen handmatig wisselen/verwijderen nodig — een challenge is "actief"
  /// zolang vandaag binnen start- en einddatum valt.
  bool get isActiveNow {
    final now = DateTime.now();
    return !now.isBefore(startDate) && !now.isAfter(endDate);
  }
}
