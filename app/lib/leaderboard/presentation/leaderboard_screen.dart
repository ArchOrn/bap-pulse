import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/leaderboard/bloc/leaderboard_bloc.dart';
import 'package:bap_pulse/leaderboard/data/leaderboard_models.dart';
import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/player.dart';

class _CriterionMeta {
  final String name;
  final String headlineLabel;
  final JerseyKind jersey;
  final String unit;
  final List<Color> heroGradient;
  final Color heroText;
  final Color heroLabel;

  const _CriterionMeta({
    required this.name,
    required this.headlineLabel,
    required this.jersey,
    required this.unit,
    required this.heroGradient,
    required this.heroText,
    required this.heroLabel,
  });
}

Map<LeaderboardCriterion, _CriterionMeta> _buildMeta(String monthLabel) {
  final upper = monthLabel.toUpperCase();
  return {
    LeaderboardCriterion.performance: _CriterionMeta(
      name: 'Performance',
      headlineLabel: 'CLASSEMENT GÉNÉRAL · $upper',
      jersey: JerseyKind.yellow,
      unit: 'pts',
      heroGradient: const [Color(0xFFFFD60A), Color(0xFFFFB703)],
      heroText: const Color(0xFF0B0F14),
      heroLabel: const Color(0xFF5A4100),
    ),
    LeaderboardCriterion.ligue: _CriterionMeta(
      name: 'Ligue',
      headlineLabel: 'CLASSEMENT LIGUE · $upper',
      jersey: JerseyKind.green,
      unit: 'V',
      heroGradient: const [Color(0xFF2FB974), Color(0xFF1E8C5A)],
      heroText: Colors.white,
      heroLabel: const Color(0xFFB7E3C8),
    ),
    LeaderboardCriterion.combatif: _CriterionMeta(
      name: 'Combatif',
      headlineLabel: 'CLASSEMENT COMBATIF · $upper',
      jersey: JerseyKind.fight,
      unit: 'matchs',
      heroGradient: const [Color(0xFFF5F5F5), Color(0xFFCFCFCF)],
      heroText: const Color(0xFF0B0F14),
      heroLabel: const Color(0xFF555555),
    ),
    LeaderboardCriterion.upsets: _CriterionMeta(
      name: 'Upsets',
      headlineLabel: 'CLASSEMENT UPSETS · $upper',
      jersey: JerseyKind.polka,
      unit: 'upsets',
      heroGradient: const [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
      heroText: const Color(0xFF0B0F14),
      heroLabel: const Color(0xFFE63946),
    ),
  };
}

const _monthsFr = [
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

enum _Period { week, month, season }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardCriterion _criterion = LeaderboardCriterion.performance;
  final _Period _period = _Period.month; // week & season disabled in this pass
  PlayerCategory? _category;

  @override
  void initState() {
    super.initState();
    context
        .read<LeaderboardBloc>()
        .add(LeaderboardLoadRequested(_criterion));
  }

  void _onCriterionTap(LeaderboardCriterion c) {
    if (c == _criterion) return;
    setState(() => _criterion = c);
    context.read<LeaderboardBloc>().add(LeaderboardCriterionChanged(c));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = _monthsFr[now.month - 1];
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final meta = _buildMeta(monthLabel)[_criterion]!;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          final cachedEntries = state.cache[_criterion];
          final filtered = cachedEntries
              ?.where((e) => _category == null || e.category == _category)
              .toList(growable: false);

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(
                headlineLabel: meta.headlineLabel,
                monthLabel: monthLabel,
                day: now.day,
                lastDay: lastDay,
              ),
              _CriterionChips(
                meta: _buildMeta(monthLabel),
                selected: _criterion,
                onTap: _onCriterionTap,
              ),
              _PeriodSelector(selected: _period),
              _CategoryPills(
                selected: _category,
                onChange: (c) => setState(() => _category = c),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _BodyContent(
                  // Key drives the fade: criterion change OR phase change
                  // (skeleton → loaded → error) re-keys the subtree.
                  key: ValueKey(
                    'body-${_criterion.name}-${_phaseKey(state, filtered)}',
                  ),
                  child: _bodyForState(
                    context: context,
                    meta: meta,
                    state: state,
                    entries: filtered,
                    myUid: myUid,
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }

  /// Returns a stable token for the current display phase. Used as part of
  /// the AnimatedSwitcher key so switching skeleton ↔ loaded ↔ error
  /// triggers a fade.
  String _phaseKey(LeaderboardState state, List<LeaderboardEntry>? entries) {
    if (entries != null && entries.isNotEmpty) return 'loaded';
    if (state is LeaderboardError && state.criterion == _criterion) {
      return 'error';
    }
    return 'skeleton';
  }

  Widget _bodyForState({
    required BuildContext context,
    required _CriterionMeta meta,
    required LeaderboardState state,
    required List<LeaderboardEntry>? entries,
    required String? myUid,
  }) {
    if (entries != null && entries.isNotEmpty) {
      return _LoadedBody(
        meta: meta,
        entries: entries,
        myUid: myUid,
      );
    }
    if (state is LeaderboardError && state.criterion == _criterion) {
      return _ErrorCard(message: state.message);
    }
    return const _LeaderboardSkeleton();
  }
}

/// Wrapper used as the AnimatedSwitcher child so the keys propagate properly.
class _BodyContent extends StatelessWidget {
  final Widget child;
  const _BodyContent({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _LoadedBody extends StatelessWidget {
  final _CriterionMeta meta;
  final List<LeaderboardEntry> entries;
  final String? myUid;

  const _LoadedBody({
    required this.meta,
    required this.entries,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final leader = entries.first;
    final leaderValue = leader.value;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: GestureDetector(
            onTap: () => context.push('/members/player/${leader.id}'),
            child: _LeaderHero(meta: meta, leader: leader),
          ),
        ),
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
                for (var i = 1; i < entries.length; i++)
                  _LeaderRow(
                    entry: entries[i],
                    leaderValue: leaderValue,
                    unit: meta.unit,
                    isMe: entries[i].id == myUid,
                    jerseyForLeader: null,
                    onTap: () =>
                        context.push('/members/player/${entries[i].id}'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String headlineLabel;
  final String monthLabel;
  final int day;
  final int lastDay;
  const _Header({
    required this.headlineLabel,
    required this.monthLabel,
    required this.day,
    required this.lastDay,
  });

  @override
  Widget build(BuildContext context) {
    final monthCap = monthLabel[0].toUpperCase() + monthLabel.substring(1);
    return Padding(
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
            headlineLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text('Tour de $monthCap', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'J$day · clôture le $lastDay $monthLabel',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Criterion chips ─────────────────────────────────────────────────────────

class _CriterionChips extends StatelessWidget {
  final Map<LeaderboardCriterion, _CriterionMeta> meta;
  final LeaderboardCriterion selected;
  final ValueChanged<LeaderboardCriterion> onTap;
  const _CriterionChips({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: LeaderboardCriterion.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = LeaderboardCriterion.values[i];
          final isSelected = c == selected;
          final cMeta = meta[c]!;
          return GestureDetector(
            onTap: () => onTap(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.bgCardElevated
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
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
                  Text(
                    cMeta.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Period selector (Semaine / Mois / Saison) ───────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  const _PeriodSelector({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                child: _PeriodCell(
                  period: p,
                  isSelected: p == selected,
                  // API only supports YYYY-MM today; week & season are
                  // surfaced grey-disabled until the API exposes them.
                  enabled: p == _Period.month,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodCell extends StatelessWidget {
  final _Period period;
  final bool isSelected;
  final bool enabled;
  const _PeriodCell({
    required this.period,
    required this.isSelected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (period) {
      _Period.week => 'Semaine',
      _Period.month => 'Mois',
      _Period.season => 'Saison',
    };
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category pills ──────────────────────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final PlayerCategory? selected;
  final ValueChanged<PlayerCategory?> onChange;
  const _CategoryPills({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _CategoryPill(
              label: 'Tous',
              selected: selected == null,
              onTap: () => onChange(null)),
          const SizedBox(width: 6),
          _CategoryPill(
              label: 'Simple H',
              selected: selected == PlayerCategory.sh,
              onTap: () => onChange(PlayerCategory.sh)),
          const SizedBox(width: 6),
          _CategoryPill(
              label: 'Simple D',
              selected: selected == PlayerCategory.sd,
              onTap: () => onChange(PlayerCategory.sd)),
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

// ── Leader hero card ────────────────────────────────────────────────────────

class _LeaderHero extends StatelessWidget {
  final _CriterionMeta meta;
  final LeaderboardEntry leader;

  const _LeaderHero({required this.meta, required this.leader});

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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${leader.value}',
                    style: AppTextStyles.numeric(
                      size: 44,
                      color: meta.heroText,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    meta.unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: meta.heroLabel,
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

// ── Leaderboard row ─────────────────────────────────────────────────────────

class _LeaderRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int leaderValue;
  final String unit;
  final bool isMe;
  final JerseyKind? jerseyForLeader;
  final VoidCallback onTap;

  const _LeaderRow({
    required this.entry,
    required this.leaderValue,
    required this.unit,
    required this.isMe,
    required this.jerseyForLeader,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = leaderValue == 0
        ? 0.0
        : (entry.value / leaderValue).clamp(0.0, 1.0);
    final gap = leaderValue - entry.value;
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
                '${entry.rank}',
                textAlign: TextAlign.center,
                style: AppTextStyles.numeric(size: 17),
              ),
            ),
            const SizedBox(width: 8),
            _EntryAvatar(entry: entry, size: 38, jersey: jerseyForLeader),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
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
                        'ELO ${entry.elo}',
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
            Text(
              '${entry.value}',
              style: AppTextStyles.numeric(size: 17),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar (inline — same recipe as profile screen) ─────────────────────────

class _EntryAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;
  final JerseyKind? jersey;
  const _EntryAvatar({
    required this.entry,
    required this.size,
    this.jersey,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = jersey != null;
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
          if (showBadge)
            Positioned(
              right: -badgeSize * 0.2,
              bottom: -badgeSize * 0.05,
              child: JerseyBadge(kind: jersey!, size: badgeSize),
            ),
        ],
      ),
    );
  }
}

// ── Skeleton & Error panels ─────────────────────────────────────────────────

/// Hero-shaped placeholder + 7 row-shaped placeholders. Same dimensions as
/// the real layout so swapping in real data doesn't shift the page. Pulses
/// between [AppColors.bgCard] and [AppColors.bgCardElevated] so it reads as
/// "loading". Cross-faded into the loaded body via AnimatedSwitcher.
class _LeaderboardSkeleton extends StatefulWidget {
  const _LeaderboardSkeleton();

  @override
  State<_LeaderboardSkeleton> createState() => _LeaderboardSkeletonState();
}

class _LeaderboardSkeletonState extends State<_LeaderboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _color = ColorTween(
      begin: AppColors.bgCard,
      end: AppColors.bgCardElevated,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, _) {
        final color = _color.value ?? AppColors.bgCard;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                height: 152,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Container(
                        height: 64,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: AppColors.divider, width: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context
                .read<LeaderboardBloc>()
                .add(const LeaderboardRefreshRequested()),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
