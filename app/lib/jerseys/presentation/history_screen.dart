import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/match.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final me = repo.currentUser;
    final myMatches = repo.matchesOf(me.id);
    final wins = myMatches.where((m) => m.wonBy(me.id)).length;
    final losses = myMatches.length - wins;
    final winRate =
        myMatches.isEmpty ? 0 : (wins / myMatches.length * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 14,
              20,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HISTORIQUE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Mes matchs', style: AppTextStyles.h1),
                    ],
                  ),
                ),
                TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Fermer')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Cell(
                      big: '${myMatches.length}',
                      label: 'Matchs',
                      color: AppColors.textPrimary),
                  _Cell(
                      big: '$wins',
                      label: 'Victoires',
                      color: AppColors.accentGreen),
                  _Cell(
                      big: '$losses',
                      label: 'Défaites',
                      color: AppColors.accentRed),
                  _Cell(
                      big: '$winRate%',
                      label: 'Taux V',
                      color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Text(
              'AVRIL',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  for (final m in myMatches) _Row(match: m, meId: me.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String big;
  final String label;
  final Color color;
  const _Cell({required this.big, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(big,
            style: AppTextStyles.numeric(
                size: 22, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final GameMatch match;
  final String meId;
  const _Row({required this.match, required this.meId});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final opp = repo.byId(match.opponentOf(meId));
    final scores = match.scoresFor(meId);
    final won = match.wonBy(meId);
    final pending = match.status == MatchStatus.pending;
    final eloForMe = won ? match.eloChange : -match.eloChange;

    return Opacity(
      opacity: pending ? 0.75 : 1,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pending
                    ? AppColors.accentAmber.withValues(alpha: 0.15)
                    : (won
                        ? AppColors.accentGreen.withValues(alpha: 0.15)
                        : AppColors.accentRed.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pending ? '?' : (won ? 'V' : 'D'),
                style: AppTextStyles.numeric(
                  size: 14,
                  color: pending
                      ? AppColors.accentAmber
                      : (won
                          ? AppColors.accentGreen
                          : AppColors.accentRed),
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs ${opp.name}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.date} · ${match.court}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  [
                    for (var i = 0; i < scores.mine.length; i++)
                      '${scores.mine[i]}-${scores.opp[i]}'
                  ].join(' · '),
                  style: AppTextStyles.numeric(size: 14),
                ),
                if (!pending)
                  Text(
                    '${eloForMe >= 0 ? '+' : ''}$eloForMe ELO',
                    style: AppTextStyles.numeric(
                      size: 11,
                      weight: FontWeight.w600,
                      color: eloForMe >= 0
                          ? AppColors.accentGreen
                          : AppColors.accentRed,
                      letterSpacing: 0,
                    ),
                  ),
                if (pending)
                  Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentAmber,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
