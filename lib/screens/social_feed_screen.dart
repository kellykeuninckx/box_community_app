import 'package:flutter/material.dart';

/// Iedereen mag hier posten — vragen, "wie traint er mee", algemeen geklets.
class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nog geen berichten.\n(Hier komt straks de lijst.)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}