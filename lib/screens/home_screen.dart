import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import 'news_feed_screen.dart';
import 'wall_of_fame_screen.dart';
import 'social_feed_screen.dart';
import 'photos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Nieuws', 'Wall of fame', 'Sociaal', 'Foto\'s'];

  static const _screens = [
    NewsFeedScreen(),
    WallOfFameScreen(),
    SocialFeedScreen(),
    PhotosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Uitloggen',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<UserProfile?>(
            stream: UserProfileService().currentUserProfile,
            builder: (context, snapshot) {
              final nickname = snapshot.data?.nickname ?? '';
              return Container(
                width: double.infinity,
                color: const Color(0xFF8B1E2B).withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  'Ingelogd als $nickname',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              );
            },
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF0F1C3F),
        indicatorColor: const Color(0xFF8B1E2B),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.campaign, color: Colors.white),
            label: 'Nieuws',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.emoji_events, color: Colors.white),
            label: 'Wall of fame',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.forum, color: Colors.white),
            label: 'Sociaal',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.photo_library, color: Colors.white),
            label: 'Foto\'s',
          ),
        ],
      ),
    );
  }
}