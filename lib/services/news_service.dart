import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_post.dart';
import 'user_profile_service.dart';

class NewsService {
  final _collection = FirebaseFirestore.instance.collection('news_posts');

  Stream<List<NewsPost>> get posts {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NewsPost.fromFirestore).toList());
  }

  Future<void> addPost({required String title, required String body}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nickname = uid != null
        ? await UserProfileService().nicknameFor(uid)
        : 'Onbekend lid';

    await _collection.add({
      'authorUid': uid ?? '',
      'authorNickname': nickname,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _collection.doc(postId).delete();
  }
}