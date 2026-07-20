import 'package:cloud_firestore/cloud_firestore.dart';

class AgendaEvent {
  final String id;
  final String authorUid;
  final String authorNickname;
  final String title;
  final String description;
  final DateTime eventDate;
  final DateTime createdAt;

  AgendaEvent({
    required this.id,
    required this.authorUid,
    required this.authorNickname,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.createdAt,
  });

  factory AgendaEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgendaEvent(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorNickname: data['authorNickname'] ?? 'Onbekend lid',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}