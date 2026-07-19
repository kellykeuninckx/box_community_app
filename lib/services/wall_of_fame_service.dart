import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wall_of_fame_post.dart';
import 'user_profile_service.dart';

/// Reacties worden voor nu simpel als teller bijgehouden (niet per gebruiker) —
/// bewust eenvoudig gehouden voor de eerste versie.
class WallOfFameService {
  final _collection = FirebaseFirestore.instance.collection('wall_of_fame_posts');

  Stream<List<WallOfFamePost>> get posts {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WallOfFamePost.fromFirestore).toList());
  }

  Future<void> addPost({required String type, required String text}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nickname = uid != null
        ? await UserProfileService().nicknameFor(uid)
        : 'Onbekend lid';

    await _collection.add({
      'authorUid': uid ?? '',
      'authorNickname': nickname,
      'type': type,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'reactionsByUser': <String, String>{},
    });
  }

  Future<void> deletePost(String postId) async {
    await _collection.doc(postId).delete();
  }

  /// Precies één reactie per persoon: nogmaals tikken op dezelfde emoji trekt 'm in,
  /// tikken op een andere emoji wisselt de keuze.
  Future<void> toggleReaction(String postId, String emoji) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _collection.doc(postId);
    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>?;
    final current = Map<String, dynamic>.from(data?['reactionsByUser'] ?? {});

    if (current[uid] == emoji) {
      await docRef.update({'reactionsByUser.$uid': FieldValue.delete()});
    } else {
      await docRef.update({'reactionsByUser.$uid': emoji});
    }
  }

  /// Eenmalige telling (geen live stream nodig) — voor op het profielscherm.
  Future<int> countReactionsGiven(String uid) async {
    final snapshot = await _collection.get();
    var count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final reactionsByUser = Map<String, dynamic>.from(data['reactionsByUser'] ?? {});
      if (reactionsByUser.containsKey(uid)) count++;
    }

    return count;
  }
}