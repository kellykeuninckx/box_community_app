import 'package:flutter/material.dart';

/// Verspreide, laag-gedekte dumbbell-iconen — zelfde idee als Wheyt Watcher.
class LogoPatternBackground extends StatelessWidget {
  const LogoPatternBackground({super.key});

  static const _positions = [
    Alignment(-0.9, -0.85),
    Alignment(0.8, -0.55),
    Alignment(-0.5, -0.15),
    Alignment(0.9, 0.2),
    Alignment(-0.85, 0.6),
    Alignment(0.4, 0.85),
    Alignment(0.1, -0.9),
    Alignment(-0.2, 0.35),
    Alignment(0.65, 0.55),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: _positions.map((alignment) {
          return Align(
            alignment: alignment,
            child: Transform.rotate(
              angle: -0.4,
              child: Icon(
                Icons.fitness_center,
                size: 46,
                color: const Color(0xFFF0EDC8).withOpacity(0.06),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}