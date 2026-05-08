import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/widgets/section_title.dart';
import 'package:bap_pulse/home/presentation/widgets/podium.dart';
import 'package:bap_pulse/home/presentation/widgets/pulse_feed.dart';
import 'package:bap_pulse/home/presentation/widgets/quick_actions.dart';
import 'package:bap_pulse/home/presentation/widgets/rank_header.dart';
import 'package:bap_pulse/news/data/news.dart';
import 'package:bap_pulse/news/data/news_repository.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<News>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = NewsRepository.instance.latest(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final me = repo.currentUser;
    final rank = repo.perfRankOf(me.id);
    final podium = repo.byPerformance.take(3).toList();

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
            child: SectionTitle(
              title: 'Le pouls du club',
              action: 'Voir tout →',
              onAction: () => context.push('/news'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: FutureBuilder<List<News>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _PulseFeedSkeleton();
                }
                if (snapshot.hasError) {
                  return _PulseFeedError(
                    onRetry: () => setState(() {
                      _newsFuture =
                          NewsRepository.instance.latest(limit: 5);
                    }),
                  );
                }
                return PulseFeed(items: snapshot.data ?? const []);
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _PulseFeedSkeleton extends StatelessWidget {
  const _PulseFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          if (i != 2) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PulseFeedError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PulseFeedError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Impossible de charger le fil.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
