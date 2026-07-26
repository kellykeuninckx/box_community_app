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

  Future<void> addPost(String text, {List<String>? pollOptions}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nickname = uid != null
        ? await UserProfileService().nicknameFor(uid)
        : 'Onbekend lid';

    final data = <String, dynamic>{
      'authorUid': uid ?? '',
      'authorNickname': nickname,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (pollOptions != null && pollOptions.isNotEmpty) {
      data['pollOptions'] = pollOptions;
      data['pollVotesByUser'] = <String, dynamic>{};
    }

    await _collection.add(data);
  }

  Future<void> deletePost(String postId) async {
    await _collection.doc(postId).delete();
  }

  /// Stemt op een pollOptie. Tikken op de al gekozen optie trekt de stem in
  /// (zelfde toggle-gedrag als de Wall of Fame-reacties).
  Future<void> vote(String postId, String option) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _collection.doc(postId);
    final doc = await docRef.get();
    final data = doc.data();
    final current = Map<String, dynamic>.from(data?['pollVotesByUser'] ?? {});

    if (current[uid] == option) {
      await docRef.update({'pollVotesByUser.$uid': FieldValue.delete()});
    } else {
      await docRef.update({'pollVotesByUser.$uid': option});
    }
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