import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/widgets/section_title.dart';
import 'package:bap_pulse/home/presentation/widgets/podium.dart';
import 'package:bap_pulse/home/presentation/widgets/pulse_feed.dart';
import 'package:bap_pulse/home/presentation/widgets/quick_actions.dart';
import 'package:bap_pulse/home/presentation/widgets/rank_header.dart';
import 'package:bap_pulse/leaderboard/bloc/leaderboard_bloc.dart';
import 'package:bap_pulse/leaderboard/data/leaderboard_models.dart';
import 'package:bap_pulse/news/data/news.dart';
import 'package:bap_pulse/news/data/news_repository.dart';
import 'package:bap_pulse/profile/bloc/profile_bloc.dart';

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
    // Performance ranking — used for the podium and the "sur N membres"
    // count in the rank header. Bloc dedupes via cache, so this is a
    // no-op when the leaderboard tab has already been visited.
    context.read<LeaderboardBloc>().add(
          const LeaderboardLoadRequested(LeaderboardCriterion.performance),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Rank header — driven by ProfileBloc (current user) + the
          // performance leaderboard cache (for total members count).
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              return BlocBuilder<LeaderboardBloc, LeaderboardState>(
                builder: (context, lbState) {
                  final entries =
                      lbState.cache[LeaderboardCriterion.performance];
                  if (profileState is ProfileLoaded) {
                    final p = profileState.profile;
                    return RankHeader(
                      rank: p.performance.rank,
                      totalMembers: entries?.length ?? 0,
                      weekDelta: 0, // no API data for week-over-week
                      score: p.performance.score,
                      perfGain: p.performance.gain7d,
                      wins: p.statsMonth.wins,
                      matches: p.statsMonth.matches,
                      streak: p.statsMonth.streak,
                    );
                  }
                  return const RankHeader(
                    rank: 0,
                    totalMembers: 0,
                    weekDelta: 0,
                    score: 0,
                    perfGain: 0,
                    wins: 0,
                    matches: 0,
                    streak: 0,
                    isLoading: true,
                  );
                },
              );
            },
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
            child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
              builder: (context, state) {
                final entries =
                    state.cache[LeaderboardCriterion.performance];
                if (entries != null && entries.length >= 3) {
                  return Podium(
                    top3: entries
                        .take(3)
                        .map((e) => PodiumEntry(
                              id: e.id,
                              firstName: e.firstName,
                              initials: e.initials,
                              score: e.value,
                            ))
                        .toList(),
                  );
                }
                return const PodiumSkeleton();
              },
            ),
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
