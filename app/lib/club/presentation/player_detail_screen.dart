import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/core/widgets/trend_chip.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/player.dart';

class PlayerDetailScreen extends StatelessWidget {
  final String playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final p = repo.byId(playerId);
    final me = repo.currentUser;
    final rank = repo.rankOf(p.id);
    final h2h = repo.headToHead(me.id, p.id);
    final myWins = h2h.where((m) => m.winnerId == me.id).length;
    final theirWins = h2h.length - myWins;

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cover
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.color.withValues(alpha: 0.95),
                  p.color.withValues(alpha: 0.55),
                  AppColors.bgScaffold,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#$rank du club',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.color,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        p.initials,
                        style: AppTextStyles.numeric(size: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: AppTextStyles.h2.copyWith(fontSize: 24, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              '${p.category.long} · depuis ${p.joined}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Challenge CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: PrimaryButton(
              label: 'Défier ${p.firstName}',
              icon: Icons.sports_kabaddi_rounded,
              onPressed: () =>
                  context.push('/score/new?opponent=${p.id}'),
            ),
          ),

          // ELO + stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ELO',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p.elo}',
                                  style: AppTextStyles.numeric(
                                      size: 36, letterSpacing: -1),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: TrendChip(value: p.trend),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (p.jerseys.isNotEmpty)
                        JerseyBadge(kind: p.jerseys.first, size: 46),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: AppColors.dividerStrong, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniCell(
                            big: '${p.winsMonth}',
                            small: '/${p.matchesMonth}',
                            label: 'Ce mois',
                          ),
                        ),
                        Expanded(
                          child: _MiniCell(
                            big: '${(p.winRate * 100).round()}%',
                            label: 'Victoires',
                          ),
                        ),
                        Expanded(
                          child: _MiniCell(
                            big: '${p.streak}',
                            label: 'Série',
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Head-to-head
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Face à face', style: AppTextStyles.h4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TOI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$myWins',
                              style: AppTextStyles.numeric(
                                size: 32,
                                color: myWins >= theirWins
                                    ? AppColors.accentGreen
                                    : AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('—',
                          style: AppTextStyles.numeric(
                              size: 14, color: AppColors.textMuted)),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              p.firstName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$theirWins',
                              style: AppTextStyles.numeric(
                                size: 32,
                                color: theirWins > myWins
                                    ? AppColors.accentRed
                                    : AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (h2h.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final m in h2h.take(5)) ...[
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: m.winnerId == me.id
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.winnerId == me.id ? 'V' : 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Last matches of player
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Ses derniers matchs', style: AppTextStyles.h4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  for (final m in repo.matchesOf(p.id).take(4)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.divider, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: m.winnerId == p.id
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(text: 'vs '),
                                  TextSpan(
                                    text: repo
                                        .byId(m.opponentOf(p.id))
                                        .name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            m.date,
                            style: AppTextStyles.numeric(
                              size: 12,
                              weight: FontWeight.w500,
                              color: AppColors.textMuted,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCell extends StatelessWidget {
  final String big;
  final String? small;
  final String label;
  final Color color;

  const _MiniCell({
    required this.big,
    this.small,
    required this.label,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(big,
                style: AppTextStyles.numeric(
                    size: 22, color: color, letterSpacing: -0.5)),
            if (small != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  small!,
                  style: AppTextStyles.numeric(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
