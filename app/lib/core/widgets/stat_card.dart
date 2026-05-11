import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';

/// Compact stat block — big number + uppercase label. Used in many places
/// (home metrics row, profile mini-stats, history summary).
class StatCard extends StatelessWidget {
  final String big;
  final String? small;
  final String label;
  final Color accent;
  final IconData? icon;
  final EdgeInsets padding;

  const StatCard({
    super.key,
    required this.big,
    this.small,
    required this.label,
    this.accent = AppColors.textPrimary,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 3),
              ],
              Text(
                big,
                style: AppTextStyles.numeric(
                  size: 26,
                  color: accent,
                  letterSpacing: -1,
                ),
              ),
              if (small != null) ...[
                const SizedBox(width: 2),
                Text(
                  small!,
                  style: AppTextStyles.numeric(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline metric (no card) — used inside hero containers (e.g. rank header).
class InlineMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const InlineMetric({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.textPrimary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTextStyles.numeric(
                size: 20,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
