import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/widgets/section_title.dart';
import 'package:bap_pulse/home/presentation/widgets/podium.dart';
import 'package:bap_pulse/home/presentation/widgets/pulse_feed.dart';
import 'package:bap_pulse/home/presentation/widgets/quick_actions.dart';
import 'package:bap_pulse/home/presentation/widgets/rank_header.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final me = repo.currentUser;
    final rank = repo.rankOf(me.id);
    final podium = repo.leaderboard.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          RankHeader(
            me: me,
            rank: rank,
            totalMembers: repo.players.length,
            weekDelta: 2,
          ),
          // Podium
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: SectionTitle(
              title: 'Podium du mois',
              action: 'Tout le classement →',
              onAction: () => context.go('/leaderboard'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Podium(top3: podium),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: QuickActionsRow(
              onChallenge: () => context.push('/club'),
              onScore: () => context.push('/score/new'),
            ),
          ),
          // Pulse feed
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionTitle(title: 'Le pouls du club'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: PulseFeed(items: _feed),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

const _bold = TextStyle(fontWeight: FontWeight.w700, color: Colors.white);

final _feed = <PulseFeedItem>[
  PulseFeedItem(
    emoji: '🔥',
    spans: const [
      TextSpan(text: 'Léa B.', style: _bold),
      TextSpan(text: ' est en série de 3 victoires — prochain match vendredi.'),
    ],
    time: 'il y a 2h',
  ),
  PulseFeedItem(
    emoji: '⚡️',
    spans: const [
      TextSpan(text: 'Hugo M.', style: _bold),
      TextSpan(text: ' a battu '),
      TextSpan(text: 'Nicolas G.', style: _bold),
      TextSpan(text: ' 21-18 · 21-19 et reprend le maillot jaune.'),
    ],
    time: 'hier',
  ),
  PulseFeedItem(
    emoji: '🎯',
    spans: const [
      TextSpan(text: 'Inès F.', style: _bold),
      TextSpan(text: ' a battu 2 joueurs mieux classés ce week-end.'),
    ],
    time: '2 jours',
  ),
  PulseFeedItem(
    emoji: '🏸',
    spans: const [
      TextSpan(text: 'Tournoi interne '),
      TextSpan(text: '« Printemps »', style: _bold),
      TextSpan(text: ' — inscriptions ouvertes.'),
    ],
    time: '3 jours',
  ),
];
