import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/pulsing_placeholder.dart';

/// Minimal podium row — the data needed to render one of the three columns.
/// Built from the performance leaderboard's top entries.
class PodiumEntry {
  final String id;
  final String firstName;
  final String initials;
  final int score;

  const PodiumEntry({
    required this.id,
    required this.firstName,
    required this.initials,
    required this.score,
  });
}

/// 3-step podium for the top 3 players. Step heights mimic the JSX mockup
/// (88 / 112 / 74) and each step is colored gold / silver / bronze.
class Podium extends StatelessWidget {
  final List<PodiumEntry> top3;
  const Podium({super.key, required this.top3}) : assert(top3.length == 3);

  static const _gold = Color(0xFFFFD60A);
  static const _silver = Color(0xFFC0C7D1);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final order = [1, 0, 2]; // 2nd, 1st, 3rd
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((i) {
        final entry = top3[i];
        final colors = [_gold, _silver, _bronze];
        final heights = [112.0, 88.0, 74.0];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _PodiumColumn(
              entry: entry,
              rank: i + 1,
              color: colors[i],
              stepHeight: heights[i],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Placeholder podium shown while the performance ranking loads. Same
/// dimensions as [Podium] so swapping in real data doesn't shift the page.
/// Pulses gently so it reads as "loading".
class PodiumSkeleton extends StatelessWidget {
  const PodiumSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final order = [1, 0, 2];
    final heights = [112.0, 88.0, 74.0];
    final avatarSizes = [44.0, 54.0, 44.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PulsingPlaceholder(
                  width: avatarSizes[i],
                  height: avatarSizes[i],
                  borderRadius: BorderRadius.circular(avatarSizes[i] / 2),
                ),
                const SizedBox(height: 8),
                const PulsingPlaceholder(width: 64, height: 12),
                const SizedBox(height: 6),
                const PulsingPlaceholder(width: 40, height: 10),
                const SizedBox(height: 8),
                PulsingPlaceholder(
                  height: heights[i],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PodiumEntry entry;
  final int rank;
  final Color color;
  final double stepHeight;

  const _PodiumColumn({
    required this.entry,
    required this.rank,
    required this.color,
    required this.stepHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final size = isFirst ? 54.0 : 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColorFor(entry.id),
          ),
          child: Text(
            entry.initials,
            style: GoogleFonts.spaceGrotesk(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.firstName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.score} pts',
          style: AppTextStyles.numeric(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: stepHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.06),
              ],
            ),
            border: Border(top: BorderSide(color: color, width: 3)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          padding: const EdgeInsets.only(top: 8),
          alignment: Alignment.topCenter,
          child: Text(
            '$rank',
            style: AppTextStyles.numeric(
              size: 28,
              color: color,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }
}
