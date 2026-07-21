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
    );
  }

  bool get hasWeightClassInfo => gender != null && bodyweightKg != null;
}