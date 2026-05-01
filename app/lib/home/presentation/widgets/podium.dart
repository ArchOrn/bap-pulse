import 'package:flutter/material.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/player_avatar.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// 3-step podium for the top 3 players. Step heights mimic the JSX mockup
/// (88 / 112 / 74) and each step is colored gold / silver / bronze.
class Podium extends StatelessWidget {
  final List<Player> top3;
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
        final p = top3[i];
        final colors = [_gold, _silver, _bronze];
        final heights = [112.0, 88.0, 74.0];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _PodiumColumn(
              player: p,
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

class _PodiumColumn extends StatelessWidget {
  final Player player;
  final int rank;
  final Color color;
  final double stepHeight;

  const _PodiumColumn({
    required this.player,
    required this.rank,
    required this.color,
    required this.stepHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(player: player, size: isFirst ? 54 : 44),
        const SizedBox(height: 8),
        Text(
          player.firstName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${player.performance} pts',
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
