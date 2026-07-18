import 'package:flutter/material.dart';

/// Alleen coaches posten hier — officiële berichten, nieuwsbrief, verloren voorwerpen.
class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuws'),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Nog geen nieuwsberichten.\n(Hier komt straks de lijst.)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}