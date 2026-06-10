import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/core/widgets/pulsing_placeholder.dart';
import 'package:bap_pulse/members/data/member_summary.dart';
import 'package:bap_pulse/members/data/members_api.dart';
import 'package:bap_pulse/notifications/bloc/notifications_bloc.dart';
import 'package:bap_pulse/score/presentation/_modal_header.dart';
import 'package:bap_pulse/score/presentation/score_sent_screen.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// Score entry flow — wired to the API:
///   step 1 → pick the opponent from `GET /members`
///   step 2 → enter sets, submit via `POST /matches` (status=PENDING)
///   step 3 → ScoreSentScreen (the opponent gets a push to confirm)
class ScoreEntryScreen extends StatefulWidget {
  /// If non-null, skip the opponent picker and start directly at score input.
  final String? preselectedOpponentId;

  const ScoreEntryScreen({super.key, this.preselectedOpponentId});

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen> {
  late Future<List<MemberSummary>> _membersFuture;
  String? _opponentId;
  // Default sets used until the user starts editing — visible in the preview
  // so the form never feels empty.
  List<List<int>> _sets = [
    [21, 15],
    [19, 21],
    [21, 17],
  ];

  @override
  void initState() {
    super.initState();
    _opponentId = widget.preselectedOpponentId;
    _membersFuture = MembersApi().fetch();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MemberSummary>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SkeletonScaffold();
        }
        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Impossible de charger les membres.';
          return _ErrorScaffold(
            message: message,
            onRetry: () =>
                setState(() => _membersFuture = MembersApi().fetch()),
          );
        }
        final members = snapshot.data ?? const <MemberSummary>[];
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        final me = members.firstWhere(
          (m) => m.id == myUid,
          orElse: () =>
              members.isNotEmpty ? members.first : _placeholderSelf(myUid),
        );
        final opponent = _opponentId == null
            ? null
            : members.firstWhere(
                (m) => m.id == _opponentId,
                orElse: () => _placeholderSelf(_opponentId!),
              );

        if (opponent == null) {
          return _OpponentPicker(
            members: members.where((m) => m.id != myUid).toList(),
            onSelected: (id) => setState(() => _opponentId = id),
          );
        }
        return _ScoreInput(
          me: me,
          opponent: opponent,
          sets: _sets,
          onSetsChanged: (sets) => setState(() => _sets = sets),
          onBack: () => setState(() => _opponentId = null),
        );
      },
    );
  }

  MemberSummary _placeholderSelf(String? uid) => MemberSummary(
    id: uid ?? '',
    firstName: 'Moi',
    lastName: '',
    gender: null,
    elo: 0,
    perfScore: 0,
    perfRank: 0,
    perfGain7d: 0,
    matchesMonth: 0,
    winsMonth: 0,
    lossesMonth: 0,
    jerseys: const [],
  );
}

// ─── Step 1: opponent picker ──────────────────────────────────────────────

class _OpponentPicker extends StatelessWidget {
  final List<MemberSummary> members;
  final ValueChanged<String> onSelected;
  const _OpponentPicker({required this.members, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ModalHeader(
            title: 'Qui as-tu affronté ?',
            subtitle: 'Choisis ton adversaire',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  for (final m in members)
                    InkWell(
                      onTap: () => onSelected(m.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            _MemberAvatar(member: m, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${m.perfScore} pts · ELO ${m.elo} · ${m.category.short}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
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

// ─── Step 2: score input ──────────────────────────────────────────────────

class _ScoreInput extends StatefulWidget {
  final MemberSummary me;
  final MemberSummary opponent;
  final List<List<int>> sets;
  final ValueChanged<List<List<int>>> onSetsChanged;
  final VoidCallback onBack;

  const _ScoreInput({
    required this.me,
    required this.opponent,
    required this.sets,
    required this.onSetsChanged,
    required this.onBack,
  });

  @override
  State<_ScoreInput> createState() => _ScoreInputState();
}

class _ScoreInputState extends State<_ScoreInput> {
  bool _submitting = false;

  int get myWonSets => widget.sets.where((s) => s[0] > s[1]).length;
  int get oppWonSets => widget.sets.where((s) => s[1] > s[0]).length;
  bool get iWon => myWonSets > oppWonSets;

  void _update(int i, int side, int delta) {
    final next = widget.sets.map((s) => [...s]).toList();
    next[i][side] = (next[i][side] + delta).clamp(0, 99);
    widget.onSetsChanged(next);
  }

  void _addSet() {
    if (widget.sets.length >= 3) return;
    widget.onSetsChanged([
      ...widget.sets,
      [0, 0],
    ]);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final sets = widget.sets
          .map((s) => {'team1': s[0], 'team2': s[1]})
          .toList(growable: false);
      await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/matches',
        data: {
          'match_type': 'SINGLES',
          'team1_player1_id': widget.me.id,
          'team2_player1_id': widget.opponent.id,
          'sets': sets,
        },
      );
      if (!mounted) return;
      // Refresh notifications so the submitter sees their newly created
      // "awaiting confirmation" record reflected in the badge state.
      context.read<NotificationsBloc>().add(
        const NotificationsRefreshRequested(),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              ScoreSentScreen(opponentFirstName: widget.opponent.firstName),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Envoi impossible';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.accentRed, content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final opponent = widget.opponent;
    final myGain = iWon ? 14 : 0;
    final oppGain = iWon ? 0 : 14;
    final newMyScore = me.perfScore + myGain;
    final newOppScore = opponent.perfScore + oppGain;

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 140),
              children: [
                ModalHeader(
                  title: 'Saisir le score',
                  subtitle: 'Simple · ${me.category.short}',
                  onClose: widget.onBack,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MemberSide(member: me, won: iWon),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'VS',
                                  style: AppTextStyles.numeric(
                                    size: 18,
                                    weight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: _MemberSide(member: opponent, won: !iWon),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        for (var i = 0; i < widget.sets.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SetCounter(
                                    value: widget.sets[i][0],
                                    win: widget.sets[i][0] > widget.sets[i][1],
                                    onInc: () => _update(i, 0, 1),
                                    onDec: () => _update(i, 0, -1),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    'S${i + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _SetCounter(
                                    value: widget.sets[i][1],
                                    win: widget.sets[i][1] > widget.sets[i][0],
                                    onInc: () => _update(i, 1, 1),
                                    onDec: () => _update(i, 1, -1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        InkWell(
                          onTap: widget.sets.length < 3 ? _addSet : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.textMuted,
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                            ),
                            child: Opacity(
                              opacity: widget.sets.length >= 3 ? 0.4 : 1,
                              child: const Text(
                                '+ Ajouter un set',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'APERÇU SCORE (APRÈS VALIDATION)',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ScorePreview(
                              label: 'Toi',
                              from: me.perfScore,
                              to: newMyScore,
                              gain: myGain,
                            ),
                            _ScorePreview(
                              label: opponent.firstName,
                              from: opponent.perfScore,
                              to: newOppScore,
                              gain: oppGain,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom CTA
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.bgScaffold.withValues(alpha: 0),
                      AppColors.bgScaffold,
                    ],
                    stops: const [0.0, 0.4],
                  ),
                ),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Envoyer à ${opponent.firstName} pour validation',
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ton adversaire devra valider pour que le score soit mis à jour.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final MemberSummary member;
  final double size;
  const _MemberAvatar({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColorFor(member.id),
      ),
      child: Text(
        member.initials,
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

class _MemberSide extends StatelessWidget {
  final MemberSummary member;
  final bool won;

  const _MemberSide({required this.member, required this.won});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: won ? 1.0 : 0.75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MemberAvatar(member: member, size: 54),
          const SizedBox(height: 8),
          Text(
            member.name,
            style: AppTextStyles.numeric(size: 13, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${member.perfScore} pts',
            style: AppTextStyles.numeric(
              size: 11,
              weight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0,
            ),
          ),
          Text(
            'ELO ${member.elo}',
            style: AppTextStyles.numeric(
              size: 10,
              weight: FontWeight.w500,
              color: AppColors.textFaint,
              letterSpacing: 0,
            ),
          ),
          if (won) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'VAINQUEUR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetCounter extends StatelessWidget {
  final int value;
  final bool win;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _SetCounter({
    required this.value,
    required this.win,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: win ? AppColors.accentGreen : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onDec,
            icon: const Icon(Icons.remove),
            color: AppColors.textPrimary,
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
          Text(
            '$value',
            style: AppTextStyles.numeric(
              size: 26,
              color: win ? AppColors.accentGreen : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          IconButton(
            onPressed: onInc,
            icon: const Icon(Icons.add),
            color: AppColors.textPrimary,
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ScorePreview extends StatelessWidget {
  final String label;
  final int from;
  final int to;
  final int gain;

  const _ScorePreview({
    required this.label,
    required this.from,
    required this.to,
    required this.gain,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' : $from → '),
          TextSpan(
            text: '$to',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: gain > 0 ? AppColors.accentGreen : AppColors.textMuted,
            ),
          ),
          if (gain > 0)
            TextSpan(
              text: ' (+$gain)',
              style: const TextStyle(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _SkeletonScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ModalHeader(
            title: 'Saisir le score',
            subtitle: 'Chargement des membres…',
          ),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: PulsingPlaceholder(
                height: 56,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: AppColors.bgScaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: AppColors.textFaint,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
        ),
      ),
    );
  }
}
