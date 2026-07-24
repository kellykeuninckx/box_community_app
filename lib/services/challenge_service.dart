import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';

class ChallengeService {
  final _collection = FirebaseFirestore.instance.collection('challenges');

  /// Zoekt tussen alle challenges degene waarvan vandaag binnen de start- en
  /// einddatum valt — dus geen handmatig wisselen of verwijderen nodig, en
  /// coaches kunnen gerust challenges voor komende maanden alvast klaarzetten.
  Stream<Challenge?> get activeChallenge {
    return _collection.orderBy('startDate', descending: true).snapshots().map((
      snapshot,
    ) {
      for (final doc in snapshot.docs) {
        final challenge = Challenge.fromFirestore(doc);
        if (challenge.isActiveNow) return challenge;
      }
      return null;
    });
  }

  /// Oplopend op startdatum, zodat de geschiedenis-navigatie in de UI
  /// gewoon met een index door de lijst kan bladeren.
  Stream<List<Challenge>> get allChallenges {
    return _collection.orderBy('startDate').snapshots().map(
      (snapshot) => snapshot.docs.map(Challenge.fromFirestore).toList(),
    );
  }

  /// Eenmalige versie van [allChallenges], voor het jaaroverzicht.
  Future<List<Challenge>> fetchAllChallenges() async {
    final snapshot = await _collection.orderBy('startDate').get();
    return snapshot.docs.map(Challenge.fromFirestore).toList();
  }

  Future<void> addChallenge({
    required String title,
    required String description,
    required ChallengeScoreType scoreType,
    required DateTime startDate,
    required DateTime endDate,
    String? unitLabel,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final trimmedUnitLabel = unitLabel?.trim();

    await _collection.add({
      'title': title,
      'description': description,
      'scoreType': scoreType.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      if (trimmedUnitLabel != null && trimmedUnitLabel.isNotEmpty) 'unitLabel': trimmedUnitLabel,
    });
  }
}
