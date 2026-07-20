import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agenda_event.dart';
import 'user_profile_service.dart';

class AgendaService {
  final _collection = FirebaseFirestore.instance.collection('agenda_events');

  /// Alleen aankomende (of vandaag) events, eerstkomende bovenaan.
  Stream<List<AgendaEvent>> get upcomingEvents {
    final startOfToday = DateTime.now().subtract(const Duration(hours: 24));

    return _collection
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('eventDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AgendaEvent.fromFirestore).toList());
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime eventDate,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nickname = uid != null
        ? await UserProfileService().nicknameFor(uid)
        : 'Onbekend lid';

    await _collection.add({
      'authorUid': uid ?? '',
      'authorNickname': nickname,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _collection.doc(eventId).delete();
  }

  Future<void> updateEvent(
    String eventId, {
    required String title,
    required String description,
    required DateTime eventDate,
  }) async {
    await _collection.doc(eventId).update({
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
    });
  }
}