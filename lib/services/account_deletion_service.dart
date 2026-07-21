import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Verwijdert alles wat redelijkerwijs bij een account hoort: eigen content,
/// eigen reacties/opmerkingen op andermans content, het profiel, en tot slot
/// het inlogaccount zelf. Kan niet ongedaan gemaakt worden.
class AccountDeletionService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> deleteMyAccount({required String password}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    // Firebase vereist een recente login voor het verwijderen van een account —
    // dus eerst opnieuw verifiëren met het wachtwoord.
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    // 1. Eigen posts, scores en events verwijderen
    await _deleteWhereEquals('wall_of_fame_posts', 'authorUid', uid);
    await _deleteWhereEquals('social_posts', 'authorUid', uid);
    await _deleteWhereEquals('wod_scores', 'uid', uid);
    await _deleteWhereEquals('news_posts', 'authorUid', uid);
    await _deleteWhereEquals('agenda_events', 'authorUid', uid);

    // 2. Eigen lift-PR's (voorspelbare document-ID's: uid_lift)
    for (final lift in ['deadlift', 'benchPress', 'backSquat', 'shoulderPress']) {
      await _firestore.collection('lift_prs').doc('${uid}_$lift').delete().catchError((_) {});
    }

    // 3. Eigen geüploade foto's — zowel het bestand in Storage als het document
    final photoSnapshot = await _firestore.collection('photo_posts').where('uid', isEqualTo: uid).get();
    for (final doc in photoSnapshot.docs) {
      final imageUrl = doc.data()['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (_) {
          // Bestand al weg of ontoegankelijk — blokkeert de rest niet.
        }
      }
      await doc.reference.delete();
    }

    // 4. Eigen reacties op andermans Wall of Fame-posts
    final allWofPosts = await _firestore.collection('wall_of_fame_posts').get();
    for (final doc in allWofPosts.docs) {
      final reactions = Map<String, dynamic>.from(doc.data()['reactionsByUser'] ?? {});
      if (reactions.containsKey(uid)) {
        await doc.reference.update({'reactionsByUser.$uid': FieldValue.delete()});
      }
    }

    // 5. Eigen reacties op andermans Sociaal-berichten
    final allSocialPosts = await _firestore.collection('social_posts').get();
    for (final postDoc in allSocialPosts.docs) {
      final comments = await postDoc.reference.collection('comments').where('authorUid', isEqualTo: uid).get();
      for (final commentDoc in comments.docs) {
        await commentDoc.reference.delete();
      }
    }

    // 6. Het profiel zelf
    await _firestore.collection('user_profiles').doc(uid).delete();

    // 7. Tot slot het inlogaccount zelf
    await user.delete();
  }

  Future<void> _deleteWhereEquals(String collection, String field, String value) async {
    final snapshot = await _firestore.collection(collection).where(field, isEqualTo: value).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}