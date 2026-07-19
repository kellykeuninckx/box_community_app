import 'package:flutter/material.dart';
import '../widgets/logo_pattern_background.dart';

/// Coach-only foto-albums: evenementen én het dagelijkse scorebord, in aparte categorieën.
class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C3F),
      appBar: AppBar(
        title: const Text('Foto\'s'),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: const Color(0xFFF0EDC8),
      ),
      body: Stack(
        children: [
          const LogoPatternBackground(),
          Center(
            child: Text(
              'Nog geen albums.\n(Hier komt straks de lijst.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFFF0EDC8).withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
}