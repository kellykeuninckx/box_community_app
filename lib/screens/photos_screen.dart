import 'package:flutter/material.dart';

/// Coach-only foto-albums: evenementen én het dagelijkse scorebord, in aparte categorieën.
class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto\'s'),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Nog geen albums.\n(Hier komt straks de lijst.)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}