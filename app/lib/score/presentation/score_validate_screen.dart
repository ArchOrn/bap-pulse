import 'package:flutter/material.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/score/presentation/_modal_header.dart';
import 'package:bap_pulse/score/presentation/_player_side.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/match.dart';

enum _ValidateStatus { pending, validated, contested }

class ScoreValidateScreen extends StatefulWidget {
  final String matchId;

  const ScoreValidateScreen({super.key, required this.matchId});

  @override
  State<ScoreValidateScreen> createState() => _ScoreValidateScreenState();
}

class _ScoreValidateScreenState extends State<ScoreValidateScreen> {
  _ValidateStatus _status = _ValidateStatus.pending;

  GameMatch get _match {
    final repo = MockRepository.instance;
    final found =
        repo.matches.where((m) => m.id == widget.matchId).cast<GameMatch?>();
    return found.isNotEmpty ? found.first! : repo.matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final m = _match;
    // The current user (me) is the validator. The submitter is the opponent.
    final me = repo.currentUser;
    final submitter = repo.byId(m.opponentOf(me.id));

    final myScores = m.scoresFor(me.id).mine;
    final theirScores = m.scoresFor(me.id).opp;
    final iWon = m.winnerId == me.id;
    final mySetWins = [for (var i = 0; i < myScores.length; i++) i]
        .where((i) => myScores[i] > theirScores[i])
        .length;
    final theirSetWins = myScores.length - mySetWins;

    final borderColor = switch (_status) {
      _ValidateStatus.pending => AppColors.primary,
      _ValidateStatus.validated => AppColors.accentGreen,
      _ValidateStatus.contested => AppColors.accentRed,
    };

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ModalHeader(title: 'Valider le match', subtitle: 'Demande reçue'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SCORE SOUMIS PAR ${submitter.name.toUpperCase()}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text('il y a 2min', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PlayerSide(
                            player: submitter,
                            won: !iWon,
                            avatarSize: 50),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            children: [
                              Text(
                                'RÉSULTAT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$theirSetWins',
                                    style: AppTextStyles.numeric(
                                      size: 36,
                                      color: iWon
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '—',
                                    style: AppTextStyles.numeric(
                                      size: 22,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '$mySetWins',
                                    style: AppTextStyles.numeric(
                                      size: 36,
                                      color: iWon
                                          ? AppColors.accentGreen
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: PlayerSide(
                            player: me, won: iWon, avatarSize: 50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < myScores.length; i++) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'SET ${i + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${theirScores[i]}',
                                    style: AppTextStyles.numeric(
                                      size: 16,
                                      color: theirScores[i] > myScores[i]
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    ' - ',
                                    style: AppTextStyles.numeric(
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '${myScores[i]}',
                                    style: AppTextStyles.numeric(
                                      size: 16,
                                      color: myScores[i] > theirScores[i]
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (i != myScores.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 13, height: 1.4),
                        children: [
                          TextSpan(
                            text: m.court,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' · ${m.date} ${m.time} · Simple H'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_status == _ValidateStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentRed,
                        side: const BorderSide(
                            color: AppColors.accentRed, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => setState(
                          () => _status = _ValidateStatus.contested),
                      child: const Text('Contester'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => setState(
                          () => _status = _ValidateStatus.validated),
                      child: const Text('Valider le match'),
                    ),
                  ),
                ],
              ),
            ),
          if (_status == _ValidateStatus.pending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'En validant, le score des deux joueurs sera mis à jour.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ),
          if (_status == _ValidateStatus.validated)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  iWon
                      ? '✓  Match validé — +${m.eloChange} pts pour toi'
                      : '✓  Match validé',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (_status == _ValidateStatus.contested)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Match contesté — ${submitter.firstName} sera notifié',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
