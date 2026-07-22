import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

/// Globale navigator-toegang zodat de notification service (buiten de
/// widget-boom) kan navigeren naar een specifieke post na een tik op een melding.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GymCommunityApp());
}

class GymCommunityApp extends StatelessWidget {
  const GymCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Sportschool Community',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1E2B),
          brightness: Brightness.dark,
          primary: const Color(0xFF8B1E2B),
          secondary: const Color(0xFFF0EDC8),
          surface: const Color(0xFF16264B),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1C3F),
        cardTheme: CardThemeData(color: const Color(0xFF16264B), elevation: 0),
      ),
      home: const AuthGate(),
    );
  }
}
