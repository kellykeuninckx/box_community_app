import 'package:cloud_firestore/cloud_firestore.dart';

enum RaceType { hyrox, gymrace }

extension RaceTypeLabel on RaceType {
  String get label {
    switch (this) {
      case RaceType.hyrox:
        return 'Hyrox';
      case RaceType.gymrace:
        return 'Gymrace';
    }
  }
}

enum RaceMode { solo, doubles }

extension RaceModeLabel on RaceMode {
  String get label {
    switch (this) {
      case RaceMode.solo:
        return 'Solo';
      case RaceMode.doubles:
        return 'Doubles';
    }
  }
}

class RaceResult {
  final String id;
  final String uid;
  final String nickname;
  final RaceType raceType;
  final RaceMode mode;
  final String gender;
  final int timeSeconds;
  final String? note;
  final DateTime createdAt;

  RaceResult({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.raceType,
    required this.mode,
    required this.gender,
    required this.timeSeconds,
    this.note,
    required this.createdAt,
  });

  factory RaceResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RaceResult(
      id: doc.id,
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? 'Onbekend lid',
      raceType: RaceType.values.firstWhere(
        (t) => t.name == data['raceType'],
        orElse: () => RaceType.hyrox,
      ),
      mode: RaceMode.values.firstWhere(
        (m) => m.name == data['mode'],
        orElse: () => RaceMode.solo,
      ),
      gender: data['gender'] ?? 'M',
      timeSeconds: (data['timeSeconds'] as num?)?.toInt() ?? 0,
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedTime {
    final minutes = timeSeconds ~/ 60;
    final seconds = timeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
