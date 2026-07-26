import 'package:cloud_firestore/cloud_firestore.dart';

class SocialPost {
  final String id;
  final String authorUid;
  final String authorNickname;
  final String text;
  final DateTime createdAt;
  final List<String>? pollOptions;
  final Map<String, String>? pollVotesByUser;

  SocialPost({
    required this.id,
    required this.authorUid,
    required this.authorNickname,
    required this.text,
    required this.createdAt,
    this.pollOptions,
    this.pollVotesByUser,
  });

  factory SocialPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialPost(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorNickname: data['authorNickname'] ?? 'Onbekend lid',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pollOptions: (data['pollOptions'] as List?)?.map((e) => e.toString()).toList(),
      pollVotesByUser: (data['pollVotesByUser'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  bool get isPoll => pollOptions != null && pollOptions!.isNotEmpty;

  int get totalVotes => pollVotesByUser?.length ?? 0;

  Map<String, int> get voteCounts {
    final counts = <String, int>{for (final option in pollOptions ?? <String>[]) option: 0};
    for (final choice in (pollVotesByUser ?? const {}).values) {
      counts[choice] = (counts[choice] ?? 0) + 1;
    }
    return counts;
  }

  String? voteFor(String uid) => pollVotesByUser?[uid];
}