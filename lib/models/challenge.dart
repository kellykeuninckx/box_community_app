import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeScoreType { time, reps, holdTime }

extension ChallengeScoreTypeLabel on ChallengeScoreType {
  String get label {
    switch (this) {
      case ChallengeScoreType.time:
        return 'Tijd';
      case ChallengeScoreType.reps:
        return 'Reps';
      case ChallengeScoreType.holdTime:
        return 'Volhouden';
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

  /// Alleen relevant bij scoreType reps — overschrijft het standaardwoord
  /// "reps" (bv. "meter" of "kcal") zonder dat de sortering/winnaarslogica
  /// verandert, die blijft gewoon "hoogste getal wint".
  final String? unitLabel;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.scoreType,
    required this.startDate,
    required this.endDate,
    required this.createdByUid,
    required this.createdAt,
    this.unitLabel,
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
      unitLabel: data['unitLabel'],
    );
  }

  /// Geen handmatig wisselen/verwijderen nodig — een challenge is "actief"
  /// zolang vandaag binnen start- en einddatum valt.
  bool get isActiveNow {
    final now = DateTime.now();
    return !now.isBefore(startDate) && !now.isAfter(endDate);
  }

  /// Het label dat bij scoreType reps naast het getal getoond wordt.
  String get unit => (unitLabel?.trim().isNotEmpty ?? false) ? unitLabel!.trim() : 'reps';
}
