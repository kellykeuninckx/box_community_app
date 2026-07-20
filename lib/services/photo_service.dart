import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/photo_post.dart';
import 'user_profile_service.dart';

class PhotoService {
  final _collection = FirebaseFirestore.instance.collection('photo_posts');
  final _storage = FirebaseStorage.instance;

  Stream<List<PhotoPost>> postsFor(PhotoCategory category) {
    return _collection
        .where('category', isEqualTo: category == PhotoCategory.event ? 'event' : 'daily')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PhotoPost.fromFirestore).toList());
  }

  /// Eenmalige lijst van al gebruikte evenement-albumnamen, voor suggesties bij het uploaden.
  Future<List<String>> existingEventAlbumTitles() async {
    final snapshot = await _collection.where('category', isEqualTo: 'event').get();
    final titles = snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['title'] as String? ?? '').where((t) => t.isNotEmpty).toSet().toList();
    titles.sort();
    return titles;
  }

  Future<void> uploadPhoto({
    required File imageFile,
    required PhotoCategory category,
    required String title,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final nickname = await UserProfileService().nicknameFor(uid);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('photos/$uid/$fileName');

    await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
    final downloadUrl = await ref.getDownloadURL();

    await _collection.add({
      'uid': uid,
      'nickname': nickname,
      'category': category == PhotoCategory.event ? 'event' : 'daily',
      'title': title,
      'imageUrl': downloadUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePhoto(PhotoPost post) async {
    await _collection.doc(post.id).delete();

    // Best effort — als het bestand om wat voor reden dan ook al weg is,
    // hoeft dat de rest van het verwijderen niet te blokkeren.
    try {
      await _storage.refFromURL(post.imageUrl).delete();
    } catch (_) {}
  }
}