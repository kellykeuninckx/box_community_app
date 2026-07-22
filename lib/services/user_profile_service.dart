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

    final existing = await _collection.doc(uid).get();

    if (existing.exists) {
      // Alleen de naam bijwerken — meldingsvoorkeuren die iemand al had
      // ingesteld blijven ongemoeid.
      await _collection.doc(uid).set({
        'nickname': nickname,
      }, SetOptions(merge: true));
    } else {
      // Eerste keer: naam + standaardwaarden voor meldingen in één keer zetten,
      // zodat elk profiel deze velden altijd heeft (nodig voor de Cloud Functions).
      await _collection.doc(uid).set({
        'nickname': nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'notifyWallOfFameReactions': true,
        'notifyKoffiehoekjeReactions': true,
        'notifyNewsAndAgenda': true,
      });
    }
  }

  /// Voor Races is alleen geslacht nodig (geen gewichtsklasse) — apart houden
  /// van setWeightClassInfo zodat we niet onnodig om lichaamsgewicht vragen.
  Future<void> setGender(String gender) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).set({
      'gender': gender,
    }, SetOptions(merge: true));
  }

  /// Eenmalig te vragen, alléén wanneer iemand voor het eerst een lift-PR invult.
  Future<void> setWeightClassInfo({
    required String gender,
    required double bodyweightKg,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).set({
      'gender': gender,
      'bodyweightKg': bodyweightKg,
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> fetchOnce(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> setNotificationPreference(String field, bool value) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).set({
      field: value,
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