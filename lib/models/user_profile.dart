import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String nickname;
  final DateTime createdAt;

  /// Optioneel — alleen nodig zodra iemand op het lift-leaderboard wil verschijnen.
  final String? gender;
  final double? bodyweightKg;

  UserProfile({
    required this.uid,
    required this.nickname,
    required this.createdAt,
    this.gender,
    this.bodyweightKg,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'],
      bodyweightKg: (data['bodyweightKg'] as num?)?.toDouble(),
    );
  }

  bool get hasWeightClassInfo => gender != null && bodyweightKg != null;
}