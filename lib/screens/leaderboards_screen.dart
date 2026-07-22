import 'package:flutter/material.dart';
import 'lift_leaderboard_screen.dart';
import 'races_screen.dart';
import 'challenges_screen.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);

enum _LeaderboardTab { lifts, races, challenges }

class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen> {
  _LeaderboardTab _selected = _LeaderboardTab.lifts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      backgroundColor: _navy,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_LeaderboardTab>(
              segments: const [
                ButtonSegment(
                  value: _LeaderboardTab.lifts,
                  label: Text('Lifts'),
                ),
                ButtonSegment(
                  value: _LeaderboardTab.races,
                  label: Text('Races'),
                ),
                ButtonSegment(
                  value: _LeaderboardTab.challenges,
                  label: Text('Challenges'),
                ),
              ],
              selected: {_selected},
              onSelectionChanged: (selection) =>
                  setState(() => _selected = selection.first),
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
                  const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          Expanded(
            child: switch (_selected) {
              _LeaderboardTab.lifts => const LiftLeaderboardBody(),
              _LeaderboardTab.races => const RacesBody(),
              _LeaderboardTab.challenges => const ChallengesBody(),
            },
          ),
        ],
      ),
    );
  }
}
