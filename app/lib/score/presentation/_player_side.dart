import 'package:flutter/material.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/player_avatar.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// One side of a head-to-head display — avatar, name, score, and an optional
/// "VAINQUEUR" pill. Loser side renders at 75% opacity.
class PlayerSide extends StatelessWidget {
  final Player player;
  final bool won;
  final double avatarSize;

  const PlayerSide({
    super.key,
    required this.player,
    required this.won,
    this.avatarSize = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: won ? 1.0 : 0.75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(player: player, size: avatarSize),
          const SizedBox(height: 8),
          Text(
            player.name,
            style: AppTextStyles.numeric(size: 13, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${player.performance} pts',
            style: AppTextStyles.numeric(
              size: 11,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0,
            ),
          ),
          Text(
            'ELO ${player.elo}',
            style: AppTextStyles.numeric(
              size: 10,
              weight: FontWeight.w500,
              color: AppColors.textFaint,
              letterSpacing: 0,
            ),
          ),
          if (won) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'VAINQUEUR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
