import 'package:flutter/material.dart';

/// Coach-only foto-albums per evenement (Hyrox, Murph, Kerst-WOD, etc.).
class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nog geen albums.\n(Hier komt straks de lijst.)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}