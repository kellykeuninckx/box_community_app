import 'package:cloud_firestore/cloud_firestore.dart';

class WallOfFamePost {
  final String id;
  final String authorNickname;
  final String type;
  final String text;
  final DateTime createdAt;

  /// uid -> emoji, precies één reactie per persoon.
  final Map<String, String> reactionsByUser;

  WallOfFamePost({
    required this.id,
    required this.authorNickname,
    required this.type,
    required this.text,
    required this.createdAt,
    required this.reactionsByUser,
  });

  factory WallOfFamePost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WallOfFamePost(
      id: doc.id,
      authorNickname: data['authorNickname'] ?? 'Onbekend lid',
      type: data['type'] ?? 'Mijlpaal',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactionsByUser: Map<String, String>.from(data['reactionsByUser'] ?? {}),
    );
  }

  /// Aantal keer dat elke emoji is gekozen — afgeleid van reactionsByUser,
  /// dus altijd consistent (geen apart tellertje dat uit de pas kan lopen).
  Map<String, int> get reactionCounts {
    final counts = <String, int>{'👏': 0, '🔥': 0, '💪': 0};
    for (final emoji in reactionsByUser.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  String? reactionFor(String uid) => reactionsByUser[uid];
}