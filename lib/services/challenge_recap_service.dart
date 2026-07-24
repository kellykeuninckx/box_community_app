import '../models/challenge.dart';
import '../models/challenge_result.dart';
import 'challenge_result_service.dart';
import 'challenge_service.dart';

class ChallengeRecapEntry {
  final String uid;
  final String nickname;
  final int count;

  const ChallengeRecapEntry({
    required this.uid,
    required this.nickname,
    required this.count,
  });
}

class ChallengeYearRecap {
  final int year;
  final List<ChallengeRecapEntry> mostWins;
  final List<ChallengeRecapEntry> mostParticipation;
  final List<String> funFacts;

  const ChallengeYearRecap({
    required this.year,
    required this.mostWins,
    required this.mostParticipation,
    required this.funFacts,
  });

  bool get isEmpty =>
      mostWins.isEmpty && mostParticipation.isEmpty && funFacts.isEmpty;
}

class ChallengeRecapService {
  final _challengeService = ChallengeService();
  final _resultService = ChallengeResultService();

  Future<ChallengeYearRecap> buildRecap(int year) async {
    final allChallenges = await _challengeService.fetchAllChallenges();
    final yearChallenges = allChallenges
        .where((c) => c.startDate.year == year)
        .toList();

    final winCounts = <String, int>{};
    final participationCounts = <String, int>{};
    final nicknames = <String, String>{};
    final funFacts = <String>[];

    for (final challenge in yearChallenges) {
      final allResults = await _resultService.fetchResultsOnce(challenge.id);
      if (allResults.isEmpty) continue;

      // Zelfde truc als op het scorebord: normalizedScore staat al oplopend,
      // dus de eerste keer dat iemands uid voorbij komt is zijn beste poging.
      final seenUids = <String>{};
      final bestPerUid = <ChallengeResult>[
        for (final result in allResults)
          if (seenUids.add(result.uid)) result,
      ];

      for (final result in bestPerUid) {
        nicknames[result.uid] = result.nickname;
        participationCounts[result.uid] =
            (participationCounts[result.uid] ?? 0) + 1;
      }

      final winnerUid = bestPerUid.first.uid;
      winCounts[winnerUid] = (winCounts[winnerUid] ?? 0) + 1;

      funFacts.add(_funFact(challenge, bestPerUid));
    }

    return ChallengeYearRecap(
      year: year,
      mostWins: _topEntries(winCounts, nicknames),
      mostParticipation: _topEntries(participationCounts, nicknames),
      funFacts: funFacts,
    );
  }

  List<ChallengeRecapEntry> _topEntries(
    Map<String, int> counts,
    Map<String, String> nicknames,
  ) {
    final entries = counts.entries
        .map(
          (e) => ChallengeRecapEntry(
            uid: e.key,
            nickname: nicknames[e.key] ?? 'Onbekend lid',
            count: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return entries.take(5).toList();
  }

  /// Som van ieders beste poging bij deze ene challenge — geen optelsom over
  /// meerdere verschillende challenges heen (dat zou appels met peren mixen
  /// zodra ze een andere eenheid of scoretype hebben).
  String _funFact(Challenge challenge, List<ChallengeResult> bestPerUid) {
    final total = bestPerUid.fold<double>(0, (sum, r) => sum + r.rawValue);

    switch (challenge.scoreType) {
      case ChallengeScoreType.reps:
        return '"${challenge.title}": samen ${total.round()} ${challenge.unit}';
      case ChallengeScoreType.holdTime:
        return '"${challenge.title}": samen ${(total / 60).round()} minuten volgehouden';
      case ChallengeScoreType.time:
        return '"${challenge.title}": samen ${(total / 60).round()} minuten getraind';
    }
  }
}
