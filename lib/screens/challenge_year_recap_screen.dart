import 'package:flutter/material.dart';
import '../services/challenge_recap_service.dart';

const _cream = Color(0xFFF0EDC8);

/// Toont "Vaakst gewonnen", "Vaakst deelgenomen" en de losse per-challenge
/// weetjes — gebruikt in de eenmalige eindejaarspopup op de homepage.
class ChallengeYearRecapContent extends StatelessWidget {
  final ChallengeYearRecap recap;

  const ChallengeYearRecapContent({super.key, required this.recap});

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _cream,
      ),
    ),
  );

  Widget _entryRow(ChallengeRecapEntry entry, String suffix) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      '${entry.nickname} — ${entry.count}x $suffix',
      style: TextStyle(fontSize: 13, color: _cream.withOpacity(0.85)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (recap.isEmpty) {
      return Text(
        'Nog geen challenge-data voor ${recap.year}.',
        style: TextStyle(color: _cream.withOpacity(0.6)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recap.mostWins.isNotEmpty) ...[
          _sectionTitle('🏆 Vaakst gewonnen'),
          ...recap.mostWins.map((e) => _entryRow(e, 'gewonnen')),
          const SizedBox(height: 16),
        ],
        if (recap.mostParticipation.isNotEmpty) ...[
          _sectionTitle('🔥 Vaakst deelgenomen'),
          ...recap.mostParticipation.map((e) => _entryRow(e, 'meegedaan')),
          const SizedBox(height: 16),
        ],
        if (recap.funFacts.isNotEmpty) ...[
          _sectionTitle('📊 Weetjes'),
          ...recap.funFacts.map(
            (fact) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                fact,
                style: TextStyle(fontSize: 13, color: _cream.withOpacity(0.85)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
