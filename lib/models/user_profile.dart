import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String nickname;
  final DateTime createdAt;

  /// Optioneel — alleen nodig zodra iemand op het lift-leaderboard wil verschijnen.
  final String? gender;
  final double? bodyweightKg;

  /// Handmatig gezet in de Firebase Console (geen in-app beheerscherm) — coaches
  /// mogen posten bij Foto's, admins (een subset van de coaches) ook bij Nieuws.
  final bool isCoach;
  final bool isAdmin;

  /// Meldingsvoorkeuren — allemaal standaard aan.
  final bool notifyWallOfFameReactions;
  final bool notifyKoffiehoekjeReactions;
  final bool notifyNewsAndAgenda;
  final bool notifyChallengeReminders;

  /// Of het welkomstbericht al getoond is — voorkomt dat het bij elke login
  /// opnieuw verschijnt.
  final bool hasSeenWelcome;

  /// Het jaartal van het laatst geziene eindejaars-jaaroverzicht — voorkomt
  /// dat de popup elke keer opnieuw verschijnt binnen hetzelfde venster.
  final int? lastSeenYearRecap;

  UserProfile({
    required this.uid,
    required this.nickname,
    required this.createdAt,
    this.gender,
    this.bodyweightKg,
    this.isCoach = false,
    this.isAdmin = false,
    this.notifyWallOfFameReactions = true,
    this.notifyKoffiehoekjeReactions = true,
    this.notifyNewsAndAgenda = true,
    this.notifyChallengeReminders = true,
    this.hasSeenWelcome = false,
    this.lastSeenYearRecap,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'],
      bodyweightKg: (data['bodyweightKg'] as num?)?.toDouble(),
      isCoach: data['isCoach'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      notifyWallOfFameReactions: data['notifyWallOfFameReactions'] ?? true,
      notifyKoffiehoekjeReactions: data['notifyKoffiehoekjeReactions'] ?? true,
      notifyNewsAndAgenda: data['notifyNewsAndAgenda'] ?? true,
      notifyChallengeReminders: data['notifyChallengeReminders'] ?? true,
      hasSeenWelcome: data['hasSeenWelcome'] ?? false,
      lastSeenYearRecap: data['lastSeenYearRecap'] as int?,
    );
  }

  bool get hasWeightClassInfo => gender != null && bodyweightKg != null;
}
