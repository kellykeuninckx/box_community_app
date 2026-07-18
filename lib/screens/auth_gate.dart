import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'choose_nickname_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // Ingelogd — check nu of er al een nickname is gekozen.
        return StreamBuilder<UserProfile?>(
          stream: UserProfileService().currentUserProfile,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null || profile.nickname.isEmpty) {
              return const ChooseNicknameScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}