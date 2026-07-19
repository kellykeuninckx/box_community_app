import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_post.dart';
import '../models/social_comment.dart';
import 'user_profile_service.dart';

class SocialService {
  final _collection = FirebaseFirestore.instance.collection('social_posts');

  Stream<List<SocialPost>> get posts {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SocialPost.fromFirestore).toList());
  }

  Future<void> addPost(String text) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nickname = uid != null
        ? await UserProfileService().nicknameFor(uid)
        : 'Onbekend lid';

    await _collection.add({
      'authorUid': uid ?? '',
      'authorNickname': nickname,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _collection.doc(postId).delete();
  }

  Stream<List<SocialComment>> commentsFor(String postId) {
    return _collection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SocialComment.fromFirestore).toList());
  }

  Future<void> addComment(String postId, String text) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nickname = uid != null
        ? await UserProfileService().nicknameFor(uid)
        : 'Onbekend lid';

    await _collection.doc(postId).collection('comments').add({
      'authorUid': uid ?? '',
      'authorNickname': nickname,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _collection.doc(postId).collection('comments').doc(commentId).delete();
  }
}