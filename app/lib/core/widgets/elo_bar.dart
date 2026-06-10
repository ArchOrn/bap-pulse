import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';

class EloBar extends StatelessWidget {
  final int elo;
  final int min;
  final int max;
  final Color color;
  final double height;

  const EloBar({
    super.key,
    required this.elo,
    this.min = 1400,
    this.max = 2100,
    this.color = AppColors.primary,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((elo - min) / (max - min)).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: color.withValues(alpha: 0.1)),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}
