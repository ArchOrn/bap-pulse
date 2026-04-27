import 'package:flutter/material.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/pulse_logo.dart';
import 'package:bap_pulse/core/widgets/stat_card.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// Top of the home screen — title bar, huge rank number, inline metrics row.
/// Rendered against a radial green glow + watermark logo.
class RankHeader extends StatelessWidget {
  final Player me;
  final int rank;
  final int totalMembers;
  final int weekDelta;
  final VoidCallback? onBellTap;

  const RankHeader({
    super.key,
    required this.me,
    required this.rank,
    required this.totalMembers,
    required this.weekDelta,
    this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.9, -1.4),
          radius: 1.2,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.bgScaffold.withValues(alpha: 0),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: Opacity(
              opacity: 0.07,
              child: PulseLogo(size: 320, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'La Ligue du BAP',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TOUR D\'AVRIL · J18 / 30',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onBellTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Center(
                            child: Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 18),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.bgScaffold,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Huge rank
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$rank', style: AppTextStyles.displayHuge),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'e au général',
                          style: AppTextStyles.h2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall,
                            children: [
                              TextSpan(text: 'sur $totalMembers membres · '),
                              TextSpan(
                                text: weekDelta >= 0
                                    ? '+$weekDelta cette semaine'
                                    : '$weekDelta cette semaine',
                                style: const TextStyle(
                                    color: AppColors.trendUp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InlineMetric(
                        value: me.elo.toString(),
                        label: 'ELO',
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: InlineMetric(
                        value: me.trend >= 0 ? '+${me.trend}' : '${me.trend}',
                        label: 'Ce mois',
                        color: AppColors.trendUp,
                      ),
                    ),
                    Expanded(
                      child: InlineMetric(
                        value: '${me.winsMonth}/${me.matchesMonth}',
                        label: 'V/M',
                      ),
                    ),
                    Expanded(
                      child: InlineMetric(
                        value: me.streak.toString(),
                        label: 'Série',
                        color: AppColors.accentOrange,
                        icon: Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
