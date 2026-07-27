import 'package:flutter/material.dart';
import 'lift_leaderboard_screen.dart';
import 'races_screen.dart';
import 'challenges_screen.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);

enum LeaderboardTab { lifts, races, challenges }

class LeaderboardsScreen extends StatefulWidget {
  final LeaderboardTab? initialTab;

  const LeaderboardsScreen({super.key, this.initialTab});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen> {
  late LeaderboardTab _selected = widget.initialTab ?? LeaderboardTab.lifts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<LeaderboardTab>(
                segments: const [
                  ButtonSegment(
                    value: LeaderboardTab.lifts,
                    label: Text('Lifts'),
                  ),
                  ButtonSegment(
                    value: LeaderboardTab.races,
                    label: Text('Races'),
                  ),
                  ButtonSegment(
                    value: LeaderboardTab.challenges,
                    label: Text('Challenges'),
                  ),
                ],
                selected: {_selected},
                onSelectionChanged: (selection) =>
                    setState(() => _selected = selection.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected) ? _red : null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.white
                        : _cream;
                  }),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 13),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: switch (_selected) {
                LeaderboardTab.lifts => const LiftLeaderboardBody(),
                LeaderboardTab.races => const RacesBody(),
                LeaderboardTab.challenges => const ChallengesBody(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
