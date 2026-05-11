import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/profile/bloc/match_history_bloc.dart';
import 'package:bap_pulse/profile/data/match_history_models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: uid == null
          ? const _SignedOut()
          : BlocProvider(
              create: (_) => MatchHistoryBloc()
                ..add(MatchHistoryLoadRequested(uid)),
              child: const _HistoryBody(),
            ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tu dois être connecté pour voir ton historique.',
        textAlign: TextAlign.center,
        style:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchHistoryBloc, MatchHistoryState>(
      builder: (context, state) {
        return switch (state) {
          MatchHistoryInitial() || MatchHistoryLoading() =>
            const _LoadingView(),
          MatchHistoryError(:final message) => _ErrorView(message: message),
          MatchHistoryLoaded(:final matches) => _LoadedView(matches: matches),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
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
                  .read<MatchHistoryBloc>()
                  .add(const MatchHistoryRefreshRequested()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final List<UserMatchEntry> matches;
  const _LoadedView({required this.matches});

  @override
  Widget build(BuildContext context) {
    final wins = matches.where((m) => m.wonByUser).length;
    final losses = matches.length - wins;
    final winRate =
        matches.isEmpty ? 0 : (wins / matches.length * 100).round();

    return RefreshIndicator(
      onRefresh: () async => context
          .read<MatchHistoryBloc>()
          .add(const MatchHistoryRefreshRequested()),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 14,
              20,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HISTORIQUE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Mes matchs', style: AppTextStyles.h1),
                    ],
                  ),
                ),
                TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Fermer')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Cell(
                      big: '${matches.length}',
                      label: 'Matchs',
                      color: AppColors.textPrimary),
                  _Cell(
                      big: '$wins',
                      label: 'Victoires',
                      color: AppColors.accentGreen),
                  _Cell(
                      big: '$losses',
                      label: 'Défaites',
                      color: AppColors.accentRed),
                  _Cell(
                      big: '$winRate%',
                      label: 'Taux V',
                      color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
          if (matches.isEmpty)
            const _EmptyState()
          else
            ..._buildMonthSections(matches),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static List<Widget> _buildMonthSections(List<UserMatchEntry> matches) {
    // Matches arrive sorted DESC by played_at — walk them in order and split
    // on month change.
    final sections = <Widget>[];
    final buffer = <UserMatchEntry>[];
    int? currentYear;
    int? currentMonth;

    void flushBuffer() {
      if (buffer.isEmpty) return;
      sections.add(_MonthHeader(label: _frenchMonthLabel(buffer.first.playedAt)));
      sections.add(_MatchList(matches: List<UserMatchEntry>.of(buffer)));
      buffer.clear();
    }

    for (final m in matches) {
      final y = m.playedAt.year;
      final mo = m.playedAt.month;
      if (currentYear != y || currentMonth != mo) {
        flushBuffer();
        currentYear = y;
        currentMonth = mo;
      }
      buffer.add(m);
    }
    flushBuffer();
    return sections;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          'Aucun match pour l\'instant.\nFonce sur le terrain 🏸',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<UserMatchEntry> matches;
  const _MatchList({required this.matches});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            for (final m in matches) _Row(entry: m),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String big;
  final String label;
  final Color color;
  const _Cell({required this.big, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(big,
            style: AppTextStyles.numeric(
                size: 22, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final UserMatchEntry entry;
  const _Row({required this.entry});

  @override
  Widget build(BuildContext context) {
    final pending = !entry.validated;
    final won = entry.wonByUser;
    final eloChange = entry.eloChange;

    return Opacity(
      opacity: pending ? 0.75 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pending
                    ? AppColors.accentAmber.withValues(alpha: 0.15)
                    : (won
                        ? AppColors.accentGreen.withValues(alpha: 0.15)
                        : AppColors.accentRed.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pending ? '?' : (won ? 'V' : 'D'),
                style: AppTextStyles.numeric(
                  size: 14,
                  color: pending
                      ? AppColors.accentAmber
                      : (won
                          ? AppColors.accentGreen
                          : AppColors.accentRed),
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
                    'vs ${entry.opponent.fullName}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPlayedAt(entry.playedAt),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  [
                    for (final s in entry.sets) '${s.mine}-${s.opp}',
                  ].join(' · '),
                  style: AppTextStyles.numeric(size: 14),
                ),
                if (!pending)
                  Text(
                    '${eloChange >= 0 ? '+' : ''}$eloChange ELO',
                    style: AppTextStyles.numeric(
                      size: 11,
                      weight: FontWeight.w600,
                      color: eloChange >= 0
                          ? AppColors.accentGreen
                          : AppColors.accentRed,
                      letterSpacing: 0,
                    ),
                  ),
                if (pending)
                  Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentAmber,
                      letterSpacing: 0.5,
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

// ─── Date formatting ───────────────────────────────────────────────────────

const List<String> _monthsFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Local date label like `12 mai · 19h30` (year omitted; visible in the
/// section header above).
String _formatPlayedAt(DateTime dt) {
  final local = dt.toLocal();
  final day = local.day;
  final month = _monthsFr[local.month - 1];
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$day $month · ${hh}h$mm';
}

/// Month section header like `MAI 2026` (uppercase, year suffix).
String _frenchMonthLabel(DateTime dt) {
  final local = dt.toLocal();
  return '${_monthsFr[local.month - 1].toUpperCase()} ${local.year}';
}
