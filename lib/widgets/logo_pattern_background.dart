import 'package:flutter/material.dart';

/// Herhaald, laag-gedekt logo-silhouet als achtergrond — zelfde idee als de
/// haltertjes-achtergrond in Wheyt Watcher.
class LogoPatternBackground extends StatelessWidget {
  const LogoPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.06,
        child: Image.asset(
          'assets/images/logo_silhouette.png',
          repeat: ImageRepeat.repeat,
          fit: BoxFit.none,
          scale: 2.5,
        ),
      ),
    );
  }
}