import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/core/widgets/player_avatar.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/jersey.dart';

class JerseysScreen extends StatelessWidget {
  const JerseysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Heading
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

          // 4 jersey cards
          for (final j in repo.jerseys)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _JerseyCard(jersey: j),
            ),

          // Hall of Fame
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hall of Fame', style: AppTextStyles.h4),
                const SizedBox(height: 2),
                Text(
                  'Maillots jaunes des mois précédents',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  for (final r in repo.hallOfFame())
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
                          JerseyBadge(kind: JerseyKind.yellow, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.holder.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(r.month,
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            '${r.score}',
                            style: AppTextStyles.numeric(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JerseyCard extends StatelessWidget {
  final Jersey jersey;
  const _JerseyCard({required this.jersey});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final holder = repo.byId(jersey.holderId);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: jersey.color.withValues(alpha: 0.13),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Center(
                      child: JerseyBadge(kind: jersey.kind, size: 82),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jersey.name,
                            style: AppTextStyles.h4.copyWith(fontSize: 18)),
                        const SizedBox(height: 1),
                        Text(
                          jersey.tagline,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          jersey.description,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push('/club/player/${holder.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      PlayerAvatar(
                          player: holder, size: 36, showJersey: false),
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
                              holder.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${jersey.value}',
                            style: AppTextStyles.numeric(
                                size: 20, letterSpacing: -0.5),
                          ),
                          Text(
                            jersey.unit,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
