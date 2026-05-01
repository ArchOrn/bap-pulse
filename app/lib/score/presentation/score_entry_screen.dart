import 'package:flutter/material.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/player_avatar.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/score/presentation/_modal_header.dart';
import 'package:bap_pulse/score/presentation/_player_side.dart';
import 'package:bap_pulse/score/presentation/score_sent_screen.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/player.dart';

class ScoreEntryScreen extends StatefulWidget {
  /// If non-null, skip the opponent picker and start directly at score input.
  final String? preselectedOpponentId;

  const ScoreEntryScreen({super.key, this.preselectedOpponentId});

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen> {
  late String? _opponentId = widget.preselectedOpponentId;
  List<List<int>> _sets = [
    [21, 15],
    [19, 21],
    [21, 17],
  ];

  @override
  Widget build(BuildContext context) {
    if (_opponentId == null) {
      return _OpponentPicker(
        onSelected: (id) => setState(() => _opponentId = id),
      );
    }
    return _ScoreInput(
      opponentId: _opponentId!,
      sets: _sets,
      onSetsChanged: (sets) => setState(() => _sets = sets),
      onBack: () => setState(() => _opponentId = null),
    );
  }
}

// ─── Step 1: opponent picker ──────────────────────────────────────────────

class _OpponentPicker extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const _OpponentPicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final players = repo.players
        .where((p) => p.id != MockRepository.currentUserId)
        .take(8)
        .toList();

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
                  for (var i = 0; i < players.length; i++)
                    InkWell(
                      onTap: () => onSelected(players[i].id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            PlayerAvatar(player: players[i], size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    players[i].name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${players[i].performance} pts · ELO ${players[i].elo} · ${players[i].category.short}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.textMuted),
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

class _ScoreInput extends StatelessWidget {
  final String opponentId;
  final List<List<int>> sets;
  final ValueChanged<List<List<int>>> onSetsChanged;
  final VoidCallback onBack;

  const _ScoreInput({
    required this.opponentId,
    required this.sets,
    required this.onSetsChanged,
    required this.onBack,
  });

  Player get me => MockRepository.instance.currentUser;
  Player get opponent => MockRepository.instance.byId(opponentId);

  int get myWonSets =>
      sets.where((s) => s[0] > s[1]).length;
  int get oppWonSets =>
      sets.where((s) => s[1] > s[0]).length;
  bool get iWon => myWonSets > oppWonSets;

  void _update(int i, int side, int delta) {
    final next = sets.map((s) => [...s]).toList();
    next[i][side] = (next[i][side] + delta).clamp(0, 99);
    onSetsChanged(next);
  }

  void _addSet() {
    if (sets.length >= 3) return;
    onSetsChanged([...sets, [0, 0]]);
  }

  Future<void> _submit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScoreSentScreen(opponent: opponent, sets: sets),
        fullscreenDialog: true,
      ),
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Performance gains — winner picks up points, loser stays put
    // (perf can only go up).
    final myGain = iWon ? 14 : 0;
    final oppGain = iWon ? 0 : 14;
    final newMyScore = me.performance + myGain;
    final newOppScore = opponent.performance + oppGain;

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
                  onClose: onBack,
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
                              child: PlayerSide(player: me, won: iWon),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
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
                              child: PlayerSide(
                                  player: opponent, won: !iWon),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        for (var i = 0; i < sets.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SetCounter(
                                    value: sets[i][0],
                                    win: sets[i][0] > sets[i][1],
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
                                    value: sets[i][1],
                                    win: sets[i][1] > sets[i][0],
                                    onInc: () => _update(i, 1, 1),
                                    onDec: () => _update(i, 1, -1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        InkWell(
                          onTap: sets.length < 3 ? _addSet : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
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
                              opacity: sets.length >= 3 ? 0.4 : 1,
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
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: [
                        _InfoRow(label: 'Date', value: 'Aujourd\'hui · 20:10'),
                        _InfoRow(label: 'Terrain', value: 'Terrain 3'),
                        _InfoRow(label: 'Type', value: 'Simple homme', last: true),
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
                        Text(
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
                              from: me.performance,
                              to: newMyScore,
                              gain: myGain,
                            ),
                            _ScorePreview(
                              label: opponent.firstName,
                              from: opponent.performance,
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
                      label:
                          'Envoyer à ${opponent.firstName} pour validation',
                      onPressed: () => _submit(context),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _InfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
              color: gain > 0
                  ? AppColors.accentGreen
                  : AppColors.textMuted,
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
