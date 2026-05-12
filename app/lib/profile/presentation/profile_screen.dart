import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/core/widgets/trend_chip.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/profile/bloc/profile_bloc.dart';
import 'package:bap_pulse/profile/data/profile_models.dart';
import 'package:bap_pulse/profile/presentation/widgets/elo_sparkline.dart';
import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/player.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => const _ProfileLoading(),
            ProfileError(:final message) => _ProfileError(message: message),
            ProfileLoaded(:final profile) => _ProfileBody(profile: profile),
          };
        },
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ProfileError extends StatelessWidget {
  final String message;
  const _ProfileError({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context
                  .read<ProfileBloc>()
                  .add(const ProfileRefreshRequested()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final history =
        profile.perfHistory.map((p) => p.value).toList(growable: false);
    return RefreshIndicator(
      onRefresh: () async => context
          .read<ProfileBloc>()
          .add(const ProfileRefreshRequested()),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Cover(profile: profile),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _ScoreCard(
                score: profile.performance.score,
                gain: profile.performance.gain7d,
                elo: profile.elo,
                rank: profile.performance.rank,
                history: history,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _StatGrid(stats: profile.statsMonth),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Mes maillots', style: AppTextStyles.h4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _MyJerseysCard(profile: profile),
          ),
          if (profile.headToHead.nemesis != null ||
              profile.headToHead.favoriteVictim != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('Face à face', style: AppTextStyles.h4),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _HeadToHeadRow(headToHead: profile.headToHead),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: _SettingsList(),
          ),
        ],
      ),
    );
  }
}

// ─── Cover ────────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  final UserProfile profile;
  const _Cover({required this.profile});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final user = profile.user;
    final category = PlayerCategoryX.fromGender(user.gender);
    final color = avatarColorFor(user.id);
    final firstJersey = profile.jerseys.isNotEmpty
        ? JerseyKindX.fromSlug(profile.jerseys.first)
        : null;

    return Container(
      padding: EdgeInsets.only(top: topInset + 16, bottom: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.65),
            AppColors.primary.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        color: AppColors.bgScaffold,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Mon profil',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            user.initials,
                            style: AppTextStyles.numeric(
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (firstJersey != null)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: JerseyBadge(
                              kind: firstJersey,
                              size: 34,
                              variant: JerseyVariant.disc,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _subtitle(category, user.joinedYear),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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

  String _subtitle(PlayerCategory category, int joinedYear) {
    final base = '${category.long} · BAP';
    return joinedYear > 0 ? '$base · depuis $joinedYear' : base;
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const step = 20.0;
    for (double y = 1; y < size.height; y += step) {
      for (double x = 1; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Big Score card ───────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  final int gain;
  final int elo;
  final int rank;
  final List<int> history;

  const _ScoreCard({
    required this.score,
    required this.gain,
    required this.elo,
    required this.rank,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCORE · CLASSÉ $rankᵉ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$score',
                            style: AppTextStyles.numeric(
                              size: 48,
                              letterSpacing: -1.8,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TrendChip(value: gain),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'ELO $elo',
                          style: AppTextStyles.numeric(
                            size: 11,
                            weight: FontWeight.w500,
                            color: AppColors.textFaint,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partage à venir')),
                    );
                  },
                  child: const Text('Partager'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          EloSparkline(data: history, height: 70),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _firstOfMonthLabel(),
                  style: AppTextStyles.numeric(
                    size: 11,
                    weight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Aujourd\'hui',
                  style: AppTextStyles.numeric(
                    size: 11,
                    weight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String _firstOfMonthLabel() {
    final now = DateTime.now();
    return '1er ${_monthsFr[now.month - 1]}';
  }
}

// ─── Stat grid 2×2 ────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final ProfileStatsMonth stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final winRate = stats.matches == 0
        ? 0
        : ((stats.wins / stats.matches) * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                big: '${stats.wins}/${stats.matches}',
                label: 'Matchs ce mois',
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                big: '$winRate%',
                label: 'Taux de victoire',
                accent: AppColors.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                big: '${stats.upsetWins}',
                label: 'Victoires vs +fort',
                accent: AppColors.accentRed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                big: '${stats.streak}',
                label: 'Série en cours',
                accent: AppColors.accentOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String big;
  final String label;
  final Color accent;

  const _MiniStat({
    required this.big,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            big,
            style: AppTextStyles.numeric(
              size: 26,
              color: accent,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My jerseys card ──────────────────────────────────────────────────────

class _MyJerseysCard extends StatelessWidget {
  final UserProfile profile;
  const _MyJerseysCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final kinds = profile.jerseys
        .map(JerseyKindX.fromSlug)
        .whereType<JerseyKind>()
        .toList(growable: false);

    if (kinds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          'Aucun maillot ce mois — continue, ça viendra 💪',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    final pointsToYellow =
        profile.yellowJerseyThreshold - profile.performance.score;
    final hasYellow = kinds.contains(JerseyKind.yellow);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final k in kinds)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  JerseyBadge(kind: k, size: 56),
                  const SizedBox(height: 6),
                  Text(
                    k.shortLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: hasYellow
                  ? Text(
                      'Tu portes le maillot jaune. Continue à creuser l\'écart 💛',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Encore '),
                          TextSpan(
                            text: '$pointsToYellow pts',
                            style: const TextStyle(
                              color: AppColors.accentYellow,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' pour le maillot jaune.'),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Head-to-head row ─────────────────────────────────────────────────────

class _HeadToHeadRow extends StatelessWidget {
  final ProfileHeadToHead headToHead;
  const _HeadToHeadRow({required this.headToHead});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];
    if (headToHead.nemesis != null) {
      cards.add(Expanded(
        child: _NemesisCard(
          title: 'Bête noire',
          color: AppColors.accentRed,
          opponent: headToHead.nemesis!,
        ),
      ));
    }
    if (headToHead.favoriteVictim != null) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: 10));
      cards.add(Expanded(
        child: _NemesisCard(
          title: 'Victime favorite',
          color: AppColors.accentGreen,
          opponent: headToHead.favoriteVictim!,
        ),
      ));
    }
    return Row(children: cards);
  }
}

class _NemesisCard extends StatelessWidget {
  final String title;
  final Color color;
  final ProfileOpponent opponent;

  const _NemesisCard({
    required this.title,
    required this.color,
    required this.opponent,
  });

  @override
  Widget build(BuildContext context) {
    final user = opponent.user;
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/members/player/${user.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarColorFor(user.id),
                    ),
                    child: Text(
                      user.initials,
                      style: AppTextStyles.numeric(
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${opponent.wins}V / ${opponent.losses}D',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings list ────────────────────────────────────────────────────────

class _SettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = <_SettingsEntry>[
      _SettingsEntry(
        label: 'Mes défis',
        onTap: () => _todo(context, 'Mes défis'),
      ),
      _SettingsEntry(
        label: 'Historique complet',
        onTap: () => context.push('/history'),
      ),
      _SettingsEntry(
        label: 'Paramètres du compte',
        onTap: () => _todo(context, 'Paramètres du compte'),
      ),
      _SettingsEntry(
        label: 'Règlement & score',
        onTap: () => _todo(context, 'Règlement & score'),
      ),
      _SettingsEntry(
        label: 'Se déconnecter',
        color: AppColors.accentRed,
        onTap: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            InkWell(
              onTap: entries[i].onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: i == entries.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: AppColors.divider,
                            width: 0.5,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entries[i].label,
                        style: TextStyle(
                          fontSize: 15,
                          color: entries[i].color ?? AppColors.textPrimary,
                          fontWeight: entries[i].color != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: entries[i].color ?? AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _todo(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('« $label » à venir')));
  }
}

class _SettingsEntry {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsEntry({required this.label, required this.onTap, this.color});
}
