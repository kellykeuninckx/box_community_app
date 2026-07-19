import 'package:cloud_firestore/cloud_firestore.dart';

class NewsPost {
  final String id;
  final String authorUid;
  final String authorNickname;
  final String title;
  final String body;
  final DateTime createdAt;

  NewsPost({
    required this.id,
    required this.authorUid,
    required this.authorNickname,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NewsPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsPost(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorNickname: data['authorNickname'] ?? 'Onbekend lid',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}