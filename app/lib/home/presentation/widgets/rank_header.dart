import 'package:flutter/material.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/bap_logo.dart';
import 'package:bap_pulse/core/widgets/pulse_logo.dart';
import 'package:bap_pulse/core/widgets/pulsing_placeholder.dart';
import 'package:bap_pulse/core/widgets/stat_card.dart';

const _frenchMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Top of the home screen — title bar, huge rank number, inline metrics row.
/// Renders against a radial green glow + watermark logo.
///
/// Data primitives come from the API (current user's [UserProfile] + the
/// performance leaderboard length). When [isLoading] is true the data area
/// is replaced by a pulsing skeleton of the same dimensions, cross-faded
/// into the real content once loaded.
class RankHeader extends StatelessWidget {
  final int rank;
  final int totalMembers;
  final int weekDelta;
  final int score;
  final int perfGain;
  final int wins;
  final int matches;
  final int streak;
  final bool isLoading;
  final VoidCallback? onBellTap;
  final int unreadCount;

  const RankHeader({
    super.key,
    required this.rank,
    required this.totalMembers,
    required this.weekDelta,
    required this.score,
    required this.perfGain,
    required this.wins,
    required this.matches,
    required this.streak,
    this.isLoading = false,
    this.onBellTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = _frenchMonths[now.month - 1].toUpperCase();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

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
              _TitleRow(
                monthLabel: monthLabel,
                day: now.day,
                lastDay: lastDay,
                onBellTap: onBellTap,
                unreadCount: unreadCount,
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isLoading
                    ? const _BodyLoading(key: ValueKey('loading'))
                    : _BodyLoaded(
                        key: const ValueKey('loaded'),
                        rank: rank,
                        totalMembers: totalMembers,
                        weekDelta: weekDelta,
                        score: score,
                        perfGain: perfGain,
                        wins: wins,
                        matches: matches,
                        streak: streak,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Title row (always visible) ──────────────────────────────────────────────

class _TitleRow extends StatelessWidget {
  final String monthLabel;
  final int day;
  final int lastDay;
  final VoidCallback? onBellTap;
  final int unreadCount;

  const _TitleRow({
    required this.monthLabel,
    required this.day,
    required this.lastDay,
    required this.onBellTap,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('La Ligue du', style: AppTextStyles.h3),
                  const SizedBox(width: 8),
                  const BapLogo(height: 20, color: Colors.white),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'TOUR DE $monthLabel · J$day / $lastDay',
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
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.bgScaffold,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loaded body ─────────────────────────────────────────────────────────────

class _BodyLoaded extends StatelessWidget {
  final int rank;
  final int totalMembers;
  final int weekDelta;
  final int score;
  final int perfGain;
  final int wins;
  final int matches;
  final int streak;

  const _BodyLoaded({
    super.key,
    required this.rank,
    required this.totalMembers,
    required this.weekDelta,
    required this.score,
    required this.perfGain,
    required this.wins,
    required this.matches,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final perfGainText = perfGain >= 0 ? '+$perfGain' : '$perfGain';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  if (totalMembers > 0)
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall,
                        children: [
                          TextSpan(
                            text:
                                'sur $totalMembers membre${totalMembers > 1 ? "s" : ""}',
                          ),
                          if (weekDelta != 0) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: weekDelta > 0
                                  ? '+$weekDelta cette semaine'
                                  : '$weekDelta cette semaine',
                              style: const TextStyle(color: AppColors.trendUp),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _MetricsBar(
          children: [
            InlineMetric(
              value: '$score',
              label: 'Score',
              color: AppColors.primary,
            ),
            InlineMetric(
              value: perfGainText,
              label: '7 jours',
              color: AppColors.trendUp,
            ),
            InlineMetric(value: '$wins/$matches', label: 'V/M'),
            InlineMetric(
              value: '$streak',
              label: 'Série',
              color: AppColors.accentOrange,
              icon: Icons.local_fire_department,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Loading body — same skeleton dimensions as _BodyLoaded ──────────────────

class _BodyLoading extends StatelessWidget {
  const _BodyLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Big rank placeholder — matches displayHuge (~88pt rendered).
            const PulsingPlaceholder(width: 110, height: 78),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  PulsingPlaceholder(width: 130, height: 22),
                  SizedBox(height: 6),
                  PulsingPlaceholder(width: 110, height: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _MetricsBar(
          children: List.generate(
            4,
            (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                PulsingPlaceholder(width: 46, height: 20),
                SizedBox(height: 4),
                PulsingPlaceholder(width: 36, height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared metrics bar wrapper ──────────────────────────────────────────────

class _MetricsBar extends StatelessWidget {
  final List<Widget> children;
  const _MetricsBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Row(children: [for (final c in children) Expanded(child: c)]),
    );
  }
}
