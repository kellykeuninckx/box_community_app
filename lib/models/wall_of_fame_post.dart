import 'package:cloud_firestore/cloud_firestore.dart';

class WallOfFamePost {
  final String id;
  final String authorEmail;
  final String type;
  final String text;
  final DateTime createdAt;
  final Map<String, int> reactions;

  WallOfFamePost({
    required this.id,
    required this.authorEmail,
    required this.type,
    required this.text,
    required this.createdAt,
    required this.reactions,
  });

  factory WallOfFamePost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WallOfFamePost(
      id: doc.id,
      authorEmail: data['authorEmail'] ?? '',
      type: data['type'] ?? 'Mijlpaal',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, int>.from(data['reactions'] ?? {}),
    );
  }
}