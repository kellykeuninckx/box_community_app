import 'package:flutter/material.dart';
import 'news_feed_screen.dart';
import 'wall_of_fame_screen.dart';
import 'wod_list_screen.dart';
import 'lift_leaderboard_screen.dart';
import 'social_feed_screen.dart';
import 'photos_screen.dart';
import 'profile_screen.dart';
import '../widgets/logo_pattern_background.dart';

class _Tile {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  const _Tile({required this.icon, required this.label, required this.builder});
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<_Tile> _tiles = [
    _Tile(icon: Icons.campaign, label: 'Nieuws', builder: (_) => const NewsFeedScreen()),
    _Tile(icon: Icons.emoji_events, label: 'Wall of fame', builder: (_) => const WallOfFameScreen()),
    _Tile(icon: Icons.fitness_center, label: 'Benchmark WODs', builder: (_) => const WodListScreen()),
    _Tile(icon: Icons.leaderboard, label: 'Lift leaderboard', builder: (_) => const LiftLeaderboardScreen()),
    _Tile(icon: Icons.forum, label: 'Sociaal', builder: (_) => const SocialFeedScreen()),
    _Tile(icon: Icons.photo_library, label: 'Foto\'s', builder: (_) => const PhotosScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C3F),
      body: Stack(
        children: [
          const LogoPatternBackground(),
          SafeArea(
            child: Column(
              children: [
                // Logo (transparante achtergrond) rust direct op het navy canvas.
                // Profiel-icoon staat nu los, rechtsboven — niet meer over het logo heen.
                SizedBox(
                  height: 150,
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset('assets/images/logo_full.png', height: 130),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.person_outline, color: Color(0xFFF0EDC8)),
                          tooltip: 'Profiel',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: _tiles.map((tile) {
                      return _TileCard(tile: tile);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  final _Tile tile;

  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B2E5C),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: tile.builder),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0EDC8).withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tile.icon, size: 36, color: const Color(0xFF8B1E2B)),
              const SizedBox(height: 10),
              Text(
                tile.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0EDC8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}