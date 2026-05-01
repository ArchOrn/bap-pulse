import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/core/widgets/player_avatar.dart';
import 'package:bap_pulse/core/widgets/trend_chip.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// Each criterion = one of the 4 jersey-aligned classements + their visual
/// signature (color, badge, label).
enum LeaderCriterion { performance, ligue, combatif, upsets }

class _CriterionMeta {
  final String name;
  final String headlineLabel;
  final JerseyKind jersey;
  final int Function(Player) value;
  final String unit;
  final List<Color> heroGradient;
  final Color heroText;
  final Color heroLabel;
  final bool showTrend;

  const _CriterionMeta({
    required this.name,
    required this.headlineLabel,
    required this.jersey,
    required this.value,
    required this.unit,
    required this.heroGradient,
    required this.heroText,
    required this.heroLabel,
    this.showTrend = false,
  });
}

final _criteriaMeta = <LeaderCriterion, _CriterionMeta>{
  LeaderCriterion.performance: _CriterionMeta(
    name: 'Performance',
    headlineLabel: 'CLASSEMENT GÉNÉRAL · AVRIL',
    jersey: JerseyKind.yellow,
    value: (p) => p.performance,
    unit: 'pts',
    heroGradient: const [Color(0xFFFFD60A), Color(0xFFFFB703)],
    heroText: const Color(0xFF0B0F14),
    heroLabel: const Color(0xFF5A4100),
    showTrend: true,
  ),
  LeaderCriterion.ligue: _CriterionMeta(
    name: 'Ligue',
    headlineLabel: 'CLASSEMENT LIGUE · AVRIL',
    jersey: JerseyKind.green,
    value: (p) => p.winsMonth,
    unit: 'V',
    heroGradient: const [Color(0xFF2FB974), Color(0xFF1E8C5A)],
    heroText: Colors.white,
    heroLabel: const Color(0xFFB7E3C8),
  ),
  LeaderCriterion.combatif: _CriterionMeta(
    name: 'Combatif',
    headlineLabel: 'CLASSEMENT COMBATIF · AVRIL',
    jersey: JerseyKind.fight,
    value: (p) => p.matchesMonth,
    unit: 'matchs',
    heroGradient: const [Color(0xFFF5F5F5), Color(0xFFCFCFCF)],
    heroText: const Color(0xFF0B0F14),
    heroLabel: const Color(0xFF555555),
  ),
  LeaderCriterion.upsets: _CriterionMeta(
    name: 'Upsets',
    headlineLabel: 'CLASSEMENT UPSETS · AVRIL',
    jersey: JerseyKind.polka,
    value: (p) => p.winsVsBetter,
    unit: 'upsets',
    heroGradient: const [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
    heroText: const Color(0xFF0B0F14),
    heroLabel: const Color(0xFFE63946),
  ),
};

enum _Period { week, month, season }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderCriterion _criterion = LeaderCriterion.performance;
  _Period _period = _Period.month;
  PlayerCategory? _category;

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final meta = _criteriaMeta[_criterion]!;

    final filtered = repo.players
        .where((p) => _category == null || p.category == _category)
        .toList()
      ..sort((a, b) => meta.value(b).compareTo(meta.value(a)));
    final leader = filtered.first;
    final leaderValue = meta.value(leader);

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 14,
              20,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.headlineLabel,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Tour d\'Avril', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'J18 · clôture le 30 avril',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Criterion selector — 4 chips with the jersey badge
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: LeaderCriterion.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = LeaderCriterion.values[i];
                final selected = c == _criterion;
                final cMeta = _criteriaMeta[c]!;
                return GestureDetector(
                  onTap: () => setState(() => _criterion = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.bgCardElevated
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JerseyBadge(
                            kind: cMeta.jersey,
                            size: 32,
                            variant: JerseyVariant.disc),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cMeta.name,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Period switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  for (final p in _Period.values)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _period = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _period == p
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              switch (p) {
                                _Period.week => 'Semaine',
                                _Period.month => 'Mois',
                                _Period.season => 'Saison',
                              },
                              style: TextStyle(
                                color: _period == p
                                    ? AppColors.onPrimary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Category pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _CategoryPill(
                    label: 'Tous',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null)),
                const SizedBox(width: 6),
                _CategoryPill(
                    label: 'Simple H',
                    selected: _category == PlayerCategory.sh,
                    onTap: () =>
                        setState(() => _category = PlayerCategory.sh)),
                const SizedBox(width: 6),
                _CategoryPill(
                    label: 'Simple D',
                    selected: _category == PlayerCategory.sd,
                    onTap: () =>
                        setState(() => _category = PlayerCategory.sd)),
              ],
            ),
          ),

          // Leader hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () => context.push('/club/player/${leader.id}'),
              child: _LeaderHero(meta: meta, leader: leader, value: leaderValue),
            ),
          ),

          // Table of remaining players
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  for (var i = 1; i < filtered.length; i++)
                    _LeaderRow(
                      rank: i + 1,
                      player: filtered[i],
                      value: meta.value(filtered[i]),
                      leaderValue: leaderValue,
                      unit: meta.unit,
                      isMe: filtered[i].id == MockRepository.currentUserId,
                      showTrend: meta.showTrend,
                      onTap: () =>
                          context.push('/club/player/${filtered[i].id}'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _LeaderHero extends StatelessWidget {
  final _CriterionMeta meta;
  final Player leader;
  final int value;

  const _LeaderHero(
      {required this.meta, required this.leader, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: meta.heroGradient,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
              right: 0, top: 0, child: JerseyBadge(kind: meta.jersey, size: 58)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEADER · ${meta.name.toUpperCase()}',
                style: TextStyle(
                  color: meta.heroLabel,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                leader.name,
                style: AppTextStyles.h2
                    .copyWith(fontSize: 28, color: meta.heroText),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: AppTextStyles.numeric(
                      size: 44,
                      color: meta.heroText,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      meta.unit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: meta.heroLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.bgCard,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.bgScaffold : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final Player player;
  final int value;
  final int leaderValue;
  final String unit;
  final bool isMe;
  final bool showTrend;
  final VoidCallback onTap;

  const _LeaderRow({
    required this.rank,
    required this.player,
    required this.value,
    required this.leaderValue,
    required this.unit,
    required this.isMe,
    required this.showTrend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        leaderValue == 0 ? 0.0 : (value / leaderValue).clamp(0.0, 1.0);
    final gap = leaderValue - value;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: AppTextStyles.numeric(size: 17),
              ),
            ),
            const SizedBox(width: 8),
            PlayerAvatar(player: player, size: 38, showJersey: rank <= 6),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isMe)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            '· toi',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        'ELO ${player.elo}',
                        style: AppTextStyles.numeric(
                          size: 10,
                          weight: FontWeight.w500,
                          color: AppColors.textFaint,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gap > 0 ? '-$gap' : '—',
                        style: AppTextStyles.numeric(
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppColors.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: AppTextStyles.numeric(size: 17),
                ),
                if (showTrend && player.perfGain > 0)
                  TrendChip(value: player.perfGain),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
