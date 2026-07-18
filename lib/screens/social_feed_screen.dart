import 'package:flutter/material.dart';

/// Iedereen mag hier posten — vragen, "wie traint er mee", algemeen geklets.
class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sociaal'),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Nog geen berichten.\n(Hier komt straks de lijst.)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}