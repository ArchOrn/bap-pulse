import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/profile/presentation/widgets/elo_sparkline.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/player.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final me = repo.currentUser;
    final rank = repo.rankOf(me.id);
    final eloHistory = repo.eloHistory(me.id);
    final winRate = (me.winRate * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 14,
              24,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PROFIL · AVRIL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 19),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthSignOutRequested()),
                  icon: const Icon(Icons.logout, size: 19),
                  color: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: me.color,
                  ),
                  child: Text(
                    me.initials,
                    style: AppTextStyles.numeric(size: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me.name, style: AppTextStyles.h1.copyWith(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(
                        '#$rank du club · ${me.category.short}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Editorial headline
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RÉSUMÉ DU MOIS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 26,
                      letterSpacing: -0.6,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                          text: '« +${me.trend} pts en ${me.matchesMonth} matchs, porté par une série de '),
                      TextSpan(
                        text: '${me.streak} victoires',
                        style:
                            const TextStyle(color: AppColors.accentOrange),
                      ),
                      const TextSpan(
                          text: ' et un bon week-end contre les mieux classés. »'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Big numbers + sparkline
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider),
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BigNum(
                        value: '${me.elo}',
                        label: 'ELO',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: _BigNum(
                        value: '+${me.trend}',
                        label: 'Sur le mois',
                        color: AppColors.accentGreen,
                      ),
                    ),
                    Expanded(
                      child: _BigNum(
                        value: '$winRate%',
                        label: 'Victoires',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                EloSparkline(data: eloHistory),
              ],
            ),
          ),

          // Maillots portés
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text(
              'MAILLOTS PORTÉS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: me.jerseys.isEmpty
                ? Text(
                    'Aucun maillot ce mois — continue, ça viendra 💪',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  )
                : Wrap(
                    spacing: 20,
                    runSpacing: 14,
                    children: [
                      for (final k in me.jerseys)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            JerseyBadge(kind: k, size: 44),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repo
                                      .jersey(k)
                                      .name
                                      .replaceFirst('Maillot ', ''),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${repo.jersey(k).value} ${repo.jersey(k).unit}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
          ),

          // Faits marquants
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Text(
              'FAITS MARQUANTS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: const [
                _Fact(
                  date: '15 avr.',
                  title: 'Battu Sarah K.',
                  subtitle: '+16 ELO — retour en forme après 3 défaites',
                  isFirst: true,
                ),
                _Fact(
                  date: '14 avr.',
                  title: 'Battu Mehdi A. 2-1',
                  subtitle: 'Troisième confrontation gagnée',
                ),
                _Fact(
                  date: '11 avr.',
                  title: 'Défaite contre Hugo M.',
                  subtitle: 'Perdu 21-15, 21-19, mieux qu\'en mars',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 80),
            child: OutlinedButton(
              onPressed: () => context.push('/history'),
              child: const Text('Voir tout l\'historique'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigNum extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _BigNum(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style:
                AppTextStyles.numeric(size: 30, color: color, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final bool isFirst;
  const _Fact({
    required this.date,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: isFirst ? 0 : 14, bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst
              ? BorderSide.none
              : const BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              date,
              style: AppTextStyles.numeric(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
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
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
