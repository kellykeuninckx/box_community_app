import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String nickname;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.nickname,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}