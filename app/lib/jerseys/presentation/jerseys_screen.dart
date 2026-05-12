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

/// Display-only metadata for each jersey — copy, ornament tint, criterion
/// binding. The dynamic data (holder, value) comes from the API via the
/// shared [LeaderboardBloc].
class _JerseyMeta {
  final LeaderboardCriterion criterion;
  final JerseyKind kind;
  final String name;
  final String tagline;
  final String description;
  final Color accent;
  final String unit;

  const _JerseyMeta({
    required this.criterion,
    required this.kind,
    required this.name,
    required this.tagline,
    required this.description,
    required this.accent,
    required this.unit,
  });
}

const List<_JerseyMeta> _jerseyMetas = [
  _JerseyMeta(
    criterion: LeaderboardCriterion.performance,
    kind: JerseyKind.yellow,
    name: 'Maillot Jaune',
    tagline: 'Leader du classement',
    description:
        'Porté par le 1er du score de performance du club. Se gagne et se perd à chaque match joué.',
    accent: Color(0xFFFFD60A),
    unit: 'pts',
  ),
  _JerseyMeta(
    criterion: LeaderboardCriterion.upsets,
    kind: JerseyKind.polka,
    name: 'Maillot à Pois',
    tagline: 'Tueur de géants',
    description:
        'Récompense le joueur avec le plus de victoires contre mieux classé que lui sur le mois.',
    accent: Color(0xFFE63946),
    unit: 'upsets',
  ),
  _JerseyMeta(
    criterion: LeaderboardCriterion.ligue,
    kind: JerseyKind.green,
    name: 'Maillot Vert',
    tagline: 'Finisseur du mois',
    description:
        'Plus de victoires sur la dernière semaine du mois. Celui qui termine fort.',
    accent: Color(0xFF2FB974),
    unit: 'V',
  ),
  _JerseyMeta(
    criterion: LeaderboardCriterion.combatif,
    kind: JerseyKind.fight,
    name: 'Maillot du Combatif',
    tagline: 'Infatigable',
    description:
        'Le plus grand nombre de matchs joués sur le mois, peu importe le résultat.',
    accent: Color(0xFF0A84FF),
    unit: 'matchs',
  ),
];

class JerseysScreen extends StatefulWidget {
  const JerseysScreen({super.key});

  @override
  State<JerseysScreen> createState() => _JerseysScreenState();
}

class _JerseysScreenState extends State<JerseysScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<LeaderboardBloc>();
    for (final m in _jerseyMetas) {
      bloc.add(LeaderboardLoadRequested(m.criterion));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RÉCOMPENSES · AVRIL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Les maillots du mois', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  'Chaque mois, 4 maillots récompensent les meilleurs joueurs du club selon des critères différents. Ils se gagnent et se perdent à chaque match.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<LeaderboardBloc, LeaderboardState>(
            builder: (context, state) {
              return Column(
                children: [
                  for (final meta in _jerseyMetas)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _JerseyCard(
                        meta: meta,
                        entries: state.cache[meta.criterion],
                        hasError: state is LeaderboardError &&
                            state.criterion == meta.criterion,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _JerseyCard extends StatelessWidget {
  final _JerseyMeta meta;
  final List<LeaderboardEntry>? entries;
  final bool hasError;

  const _JerseyCard({
    required this.meta,
    required this.entries,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final holder = (entries != null && entries!.isNotEmpty) ? entries!.first : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Soft gradient ornament — replaces the floating circle. Anchored
            // top-right, fades into the card background.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.0,
                      colors: [
                        meta.accent.withValues(alpha: 0.22),
                        meta.accent.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Center(
                          child: JerseyBadge(kind: meta.kind, size: 82),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.name,
                              style:
                                  AppTextStyles.h4.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              meta.tagline,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              meta.description,
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontSize: 12, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HolderRow(
                    meta: meta,
                    holder: holder,
                    isLoading: entries == null && !hasError,
                    hasError: hasError && entries == null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolderRow extends StatelessWidget {
  final _JerseyMeta meta;
  final LeaderboardEntry? holder;
  final bool isLoading;
  final bool hasError;

  const _HolderRow({
    required this.meta,
    required this.holder,
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final pill = BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
    );

    if (isLoading) {
      return Container(
        height: 56,
        decoration: pill,
      );
    }

    if (hasError) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pill,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Impossible de charger le porteur.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => context
                  .read<LeaderboardBloc>()
                  .add(LeaderboardLoadRequested(meta.criterion)),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (holder == null) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: pill,
        child: Text(
          'Pas encore de porteur ce mois-ci.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/members/player/${holder!.id}'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pill,
        child: Row(
          children: [
            _HolderAvatar(entry: holder!, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PORTÉ PAR',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    holder!.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${holder!.value}',
                  style: AppTextStyles.numeric(
                      size: 20, letterSpacing: -0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  meta.unit,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
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

class _HolderAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;

  const _HolderAvatar({required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
