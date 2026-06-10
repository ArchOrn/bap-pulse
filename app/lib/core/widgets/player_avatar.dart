import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// Round avatar showing a player's initials on a colored disc, with an optional
/// jersey badge in the bottom-right corner.
class PlayerAvatar extends StatelessWidget {
  final Player player;
  final double size;
  final bool showJersey;
  final JerseyVariant jerseyVariant;
  final double? borderWidth;
  final Color? borderColor;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 40,
    this.showJersey = true,
    this.jerseyVariant = JerseyVariant.disc,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final mainJersey = player.jerseys.isNotEmpty ? player.jerseys.first : null;
    final showBadge = showJersey && mainJersey != null;
    final badgeSize = size * 0.5;

    return SizedBox(
      width: size + (showBadge ? badgeSize * 0.4 : 0),
      height: size + (showBadge ? badgeSize * 0.3 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.color,
              border: borderWidth != null
                  ? Border.all(
                      color: borderColor ?? Colors.white,
                      width: borderWidth!,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: -2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Text(
              player.initials,
              style: GoogleFonts.spaceGrotesk(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: -badgeSize * 0.2,
              bottom: -badgeSize * 0.05,
              child: JerseyBadge(
                kind: mainJersey,
                size: badgeSize,
                variant: jerseyVariant,
              ),
            ),
        ],
      ),
    );
  }
}
