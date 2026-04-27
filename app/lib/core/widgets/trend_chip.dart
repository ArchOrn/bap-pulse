import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';

/// Small ▲/▼ + signed-value chip used in the leaderboard, profile, and
/// match rows.
class TrendChip extends StatelessWidget {
  final int value;
  final double fontSize;

  const TrendChip({super.key, required this.value, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: up ? AppColors.accentGreen : AppColors.accentRed,
          size: fontSize + 6,
        ),
        Text(
          value.abs().toString(),
          style: AppTextStyles.numeric(
            size: fontSize,
            weight: FontWeight.w600,
            color: up ? AppColors.accentGreen : AppColors.accentRed,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
