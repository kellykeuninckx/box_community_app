import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wall_of_fame_post.dart';

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
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Onbekend';

    await _collection.add({
      'authorEmail': email,
      'type': type,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'reactions': {'👏': 0, '🔥': 0, '💪': 0},
    });
  }

  Future<void> addReaction(String postId, String emoji) async {
    await _collection.doc(postId).update({
      'reactions.$emoji': FieldValue.increment(1),
    });
  }
}