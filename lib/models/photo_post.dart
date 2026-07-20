import 'package:cloud_firestore/cloud_firestore.dart';

enum PhotoCategory { event, daily }

class PhotoPost {
  final String id;
  final String uid;
  final String nickname;
  final PhotoCategory category;
  final String title;
  final String imageUrl;
  final DateTime createdAt;

  PhotoPost({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PhotoPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoPost(
      id: doc.id,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? 'Onbekend lid',
      category: data['category'] == 'event' ? PhotoCategory.event : PhotoCategory.daily,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}