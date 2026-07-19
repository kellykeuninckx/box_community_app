import 'package:cloud_firestore/cloud_firestore.dart';

class SocialComment {
  final String id;
  final String authorUid;
  final String authorNickname;
  final String text;
  final DateTime createdAt;

  SocialComment({
    required this.id,
    required this.authorUid,
    required this.authorNickname,
    required this.text,
    required this.createdAt,
  });

  factory SocialComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialComment(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorNickname: data['authorNickname'] ?? 'Onbekend lid',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}