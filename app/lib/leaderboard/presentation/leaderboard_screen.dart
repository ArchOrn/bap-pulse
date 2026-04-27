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

enum _Period { week, month, season }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _Period _period = _Period.month;
  PlayerCategory? _category; // null = all

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final filtered = repo.leaderboard
        .where((p) => _category == null || p.category == _category)
        .toList();
    final leader = filtered.first;

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
                  'CLASSEMENT · AVRIL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tour d\'Avril',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 4),
                Text(
                  'J18 · clôture le 30 avril · ELO',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          // Period switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                  onTap: () => setState(() => _category = null),
                ),
                const SizedBox(width: 6),
                _CategoryPill(
                  label: 'Simple H',
                  selected: _category == PlayerCategory.sh,
                  onTap: () =>
                      setState(() => _category = PlayerCategory.sh),
                ),
                const SizedBox(width: 6),
                _CategoryPill(
                  label: 'Simple D',
                  selected: _category == PlayerCategory.sd,
                  onTap: () =>
                      setState(() => _category = PlayerCategory.sd),
                ),
              ],
            ),
          ),
          // Leader hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () => context.push('/club/player/${leader.id}'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD60A), Color(0xFFFFB703)],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: JerseyBadge(
                        kind: JerseyKind.yellow,
                        size: 58,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAILLOT JAUNE — LEADER',
                          style: TextStyle(
                            color: const Color(0xFF5A4100),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          leader.name,
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 28,
                            color: const Color(0xFF0B0F14),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${leader.elo}',
                              style: AppTextStyles.numeric(
                                size: 44,
                                color: const Color(0xFF0B0F14),
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'ELO',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5A4100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${leader.trend} pts ce mois · ${leader.winsMonth} victoires',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF5A4100),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Table
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
                      gap: leader.elo - filtered[i].elo,
                      isMe: filtered[i].id == MockRepository.currentUserId,
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
  final int gap;
  final bool isMe;
  final VoidCallback onTap;

  const _LeaderRow({
    required this.rank,
    required this.player,
    required this.gap,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ((player.elo - 1400) / 700).clamp(0.0, 1.0),
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
                        '-$gap',
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
                  '${player.elo}',
                  style: AppTextStyles.numeric(size: 17),
                ),
                TrendChip(value: player.trend),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
