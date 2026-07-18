import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final _collection = FirebaseFirestore.instance.collection('user_profiles');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Stream van het eigen profiel — geeft `null` zolang er nog geen nickname is gekozen.
  Stream<UserProfile?> get currentUserProfile {
    final uid = _uid;
    if (uid == null) return Stream.value(null);

    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> setNickname(String nickname) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).set({
      'nickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Voor het tonen van iemand ánders nickname (bijvoorbeeld bij een Wall of Fame-post).
  Future<String> nicknameFor(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nickname'] ?? 'Onbekend lid';
    }
    return 'Onbekend lid';
  }
}