import 'package:cloud_firestore/cloud_firestore.dart';

class SocialPost {
  final String id;
  final String authorUid;
  final String authorNickname;
  final String text;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    required this.authorUid,
    required this.authorNickname,
    required this.text,
    required this.createdAt,
  });

  factory SocialPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialPost(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorNickname: data['authorNickname'] ?? 'Onbekend lid',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}