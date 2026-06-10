import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/members/data/member_summary.dart';
import 'package:bap_pulse/members/data/members_api.dart';
import 'package:bap_pulse/notifications/bloc/notifications_bloc.dart';
import 'package:bap_pulse/score/presentation/_modal_header.dart';
import 'package:bap_pulse/shared/models/match.dart';

/// Pending-match confirmation screen, reached either from the notification
/// center or directly via FCM deep-link. Loads the match + a members lookup,
/// then lets the recipient confirm (applies ELO) or contest (raises a flag).
class ScoreValidateScreen extends StatefulWidget {
  final String matchId;

  const ScoreValidateScreen({super.key, required this.matchId});

  @override
  State<ScoreValidateScreen> createState() => _ScoreValidateScreenState();
}

class _ScoreValidateScreenState extends State<ScoreValidateScreen> {
  late Future<_MatchView> _future;
  bool _busy = false;
  String? _outcomeMessage;
  Color? _outcomeColor;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MatchView> _load() async {
    final res = await Future.wait([
      ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/matches/${widget.matchId}',
      ),
      MembersApi().fetch(),
    ]);
    final match = (res[0] as dynamic).data as Map<String, dynamic>;
    final members = res[1] as List<MemberSummary>;
    return _MatchView.from(match, members);
  }

  Future<void> _act({required bool confirm}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = confirm ? 'confirm' : 'contest';
      await ApiClient.instance.dio.post('/matches/${widget.matchId}/$path');
      if (!mounted) return;
      setState(() {
        _outcomeMessage = confirm
            ? 'Match validé.'
            : 'Match contesté — le submitter est notifié.';
        _outcomeColor = confirm ? AppColors.accentGreen : AppColors.accentRed;
      });
      // Bubble back into the notification center so the badge updates and the
      // confirmed match disappears from "awaiting" state on next refresh.
      context.read<NotificationsBloc>().add(
        const NotificationsRefreshRequested(),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Action impossible';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.accentRed, content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: FutureBuilder<_MatchView>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorBody(snapshot.error);
          }
          final view = snapshot.data!;
          return _buildBody(view);
        },
      ),
    );
  }

  Widget _errorBody(Object? error) {
    final message = error is ApiException
        ? error.message
        : 'Match introuvable.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textFaint),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_MatchView view) {
    final iWon = view.iWon;
    final myWins = view.myWonSets;
    final theirWins = view.oppWonSets;
    final canAct = view.canAct && _outcomeMessage == null;

    final borderColor =
        _outcomeColor ??
        (view.status == MatchStatus.pending
            ? AppColors.primary
            : (view.status == MatchStatus.confirmed
                  ? AppColors.accentGreen
                  : AppColors.accentRed));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ModalHeader(
          title: 'Valider le match',
          subtitle: view.status == MatchStatus.pending
              ? 'Demande reçue'
              : view.status == MatchStatus.confirmed
              ? 'Validé'
              : 'Contesté',
        ),
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SCORE SOUMIS PAR ${view.submitterName.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Side(member: view.opponent, won: !iWon),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          children: [
                            const Text(
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
                                  '$theirWins',
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
                                  '$myWins',
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
                      child: _Side(member: view.me, won: iWon),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < view.mySetScores.length; i++) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SET ${i + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${view.oppSetScores[i]}',
                                  style: AppTextStyles.numeric(
                                    size: 16,
                                    color:
                                        view.oppSetScores[i] >
                                            view.mySetScores[i]
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
                                  '${view.mySetScores[i]}',
                                  style: AppTextStyles.numeric(
                                    size: 16,
                                    color:
                                        view.mySetScores[i] >
                                            view.oppSetScores[i]
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i != view.mySetScores.length - 1)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (canAct)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      side: const BorderSide(
                        color: AppColors.accentRed,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _busy ? null : () => _act(confirm: false),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _busy ? null : () => _act(confirm: true),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Valider le match'),
                  ),
                ),
              ],
            ),
          )
        else if (_outcomeMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_outcomeColor ?? AppColors.accentGreen).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _outcomeMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _outcomeColor ?? AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _statusLabel(view),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        if (canAct)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'En validant, le score des deux joueurs sera mis à jour.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
        const SizedBox(height: 60),
      ],
    );
  }

  String _statusLabel(_MatchView view) {
    if (view.status == MatchStatus.confirmed) {
      return view.iWon ? 'Match validé ✓' : 'Match validé';
    }
    if (view.status == MatchStatus.contested) {
      return 'Ce match a été contesté.';
    }
    if (!view.canAct) {
      return 'Tu n\'es pas concerné par ce match.';
    }
    return '';
  }
}

class _Side extends StatelessWidget {
  final MemberSummary member;
  final bool won;

  const _Side({required this.member, required this.won});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: won ? 1.0 : 0.75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColorFor(member.id),
            ),
            child: Text(
              member.initials,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            member.name,
            style: AppTextStyles.numeric(size: 13, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
        ],
      ),
    );
  }
}

/// Decoded match payload + the resolved opponent / submitter for the current
/// user's perspective.
class _MatchView {
  final MemberSummary me;
  final MemberSummary opponent;
  final MemberSummary submitter;
  final String submitterId;
  final MatchStatus status;
  final List<int> mySetScores;
  final List<int> oppSetScores;
  final int myWonSets;
  final int oppWonSets;
  final bool canAct;

  _MatchView({
    required this.me,
    required this.opponent,
    required this.submitter,
    required this.submitterId,
    required this.status,
    required this.mySetScores,
    required this.oppSetScores,
    required this.myWonSets,
    required this.oppWonSets,
    required this.canAct,
  });

  bool get iWon => myWonSets > oppWonSets;

  String get submitterName => submitter.firstName;

  factory _MatchView.from(
    Map<String, dynamic> json,
    List<MemberSummary> members,
  ) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    MemberSummary byId(String id) =>
        members.firstWhere((m) => m.id == id, orElse: () => _placeholder(id));

    final team1P1 = json['team1_player1_id'] as String;
    final team2P1 = json['team2_player1_id'] as String;
    final team1P2 = json['team1_player2_id'] as String?;
    final team2P2 = json['team2_player2_id'] as String?;

    final myTeam1 = team1P1 == myUid || team1P2 == myUid;
    final myId = myTeam1 ? team1P1 : team2P1;
    final oppId = myTeam1 ? team2P1 : team1P1;
    final me = byId(myUid.isEmpty ? myId : myUid);
    final opponent = byId(oppId);

    final submitterId = json['submitted_by_id'];
    final resolvedSubmitterId = submitterId is String && submitterId.isNotEmpty
        ? submitterId
        : team1P1;
    final submitter = byId(resolvedSubmitterId);

    final status = parseMatchStatus(json['status'] as String? ?? 'CONFIRMED');

    int team1Scored(String key) => (json[key] as num? ?? 0).toInt();
    final List<int> team1Sets = [
      team1Scored('set1_team1'),
      team1Scored('set2_team1'),
      if (json['set3_team1'] != null) team1Scored('set3_team1'),
    ];
    final List<int> team2Sets = [
      team1Scored('set1_team2'),
      team1Scored('set2_team2'),
      if (json['set3_team2'] != null) team1Scored('set3_team2'),
    ];
    final mySets = myTeam1 ? team1Sets : team2Sets;
    final oppSets = myTeam1 ? team2Sets : team1Sets;

    int countWins(List<int> mine, List<int> theirs) {
      var w = 0;
      for (var i = 0; i < mine.length; i++) {
        if (mine[i] > theirs[i]) w++;
      }
      return w;
    }

    final myWins = countWins(mySets, oppSets);
    final oppWins = countWins(oppSets, mySets);

    // Confirm/contest is reserved to a member of the team opposite to the
    // submitter — and only while the match is still PENDING.
    final iAmInMatch =
        team1P1 == myUid ||
        team1P2 == myUid ||
        team2P1 == myUid ||
        team2P2 == myUid;
    final iAmSubmitter = resolvedSubmitterId == myUid;
    final submitterTeam1 =
        resolvedSubmitterId == team1P1 || resolvedSubmitterId == team1P2;
    final iAmOnOpposingTeam = submitterTeam1
        ? team2P1 == myUid || team2P2 == myUid
        : team1P1 == myUid || team1P2 == myUid;

    final canAct =
        iAmInMatch &&
        !iAmSubmitter &&
        iAmOnOpposingTeam &&
        status == MatchStatus.pending;

    return _MatchView(
      me: me,
      opponent: opponent,
      submitter: submitter,
      submitterId: resolvedSubmitterId,
      status: status,
      mySetScores: mySets,
      oppSetScores: oppSets,
      myWonSets: myWins,
      oppWonSets: oppWins,
      canAct: canAct,
    );
  }

  static MemberSummary _placeholder(String id) => MemberSummary(
    id: id,
    firstName: 'Joueur',
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
