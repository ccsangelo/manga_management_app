import 'package:flutter/material.dart';

class ScoreGradient extends StatelessWidget {
  const ScoreGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
          stops: [0.5, 1.0],
        ),
      ),
    );
  }
}

class ScoreBadge extends StatelessWidget {
  final double score;
  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      right: 6,
      child: Text(
        score.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
