import 'package:flutter/material.dart';

/// Coaches én leden kunnen hier posten — PR's, mijlpalen, bord-foto's.
class WallOfFameScreen extends StatelessWidget {
  const WallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nog geen prestaties gedeeld.\n(Hier komt straks de lijst.)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}