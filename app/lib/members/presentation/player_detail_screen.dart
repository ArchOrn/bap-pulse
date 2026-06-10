import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/challenges/data/challenges_repository.dart';
import 'package:bap_pulse/challenges/presentation/challenge_sent_screen.dart';
import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/core/widgets/trend_chip.dart';
import 'package:bap_pulse/profile/data/profile_api.dart';
import 'package:bap_pulse/profile/data/profile_models.dart';
import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/player.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  late Future<UserProfile> _future;
  final _api = ProfileApi();

  @override
  void initState() {
    super.initState();
    _future = _api.fetch(widget.playerId);
  }

  void _retry() {
    setState(() => _future = _api.fetch(widget.playerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: FutureBuilder<UserProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _PlayerDetailLoading(playerId: widget.playerId);
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final message = err is ApiException
                ? err.message
                : 'Impossible de charger ce joueur.';
            return _PlayerDetailError(message: message, onRetry: _retry);
          }
          return _PlayerDetailBody(
            playerId: widget.playerId,
            profile: snapshot.data!,
          );
        },
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _PlayerDetailBody extends StatelessWidget {
  final String playerId;
  final UserProfile profile;

  const _PlayerDetailBody({required this.playerId, required this.profile});

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final color = avatarColorFor(user.id);
    final category = PlayerCategoryX.fromGender(user.gender);
    final firstJersey = profile.jerseys.isNotEmpty
        ? JerseyKindX.fromSlug(profile.jerseys.first)
        : null;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isSelf = myUid == playerId;
    final winRate = profile.statsMonth.matches == 0
        ? 0.0
        : profile.statsMonth.wins / profile.statsMonth.matches;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Cover
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.55),
                AppColors.bgScaffold,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 12,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${profile.performance.rank} du club',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      user.initials,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: AppTextStyles.h2.copyWith(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.joinedYear > 0
                                ? '${category.long} · depuis ${user.joinedYear}'
                                : category.long,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Challenge CTA — hidden when the user is viewing themselves.
        // Sends a PENDING challenge via POST /challenges; the opponent then
        // receives a push and the challenge appears in their notification
        // center where they can accept or decline.
        if (!isSelf)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _ChallengeButton(
              opponentId: playerId,
              opponentFirstName: user.firstName,
            ),
          ),

        // Score + stats
        Padding(
          padding: EdgeInsets.fromLTRB(16, isSelf ? 14 : 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SCORE', style: AppTextStyles.label),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${profile.performance.score}',
                                style: AppTextStyles.numeric(
                                  size: 36,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (profile.performance.gain7d > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: TrendChip(
                                    value: profile.performance.gain7d,
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'ELO ${profile.elo}',
                              style: AppTextStyles.numeric(
                                size: 11,
                                weight: FontWeight.w500,
                                color: AppColors.textFaint,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (firstJersey != null)
                      JerseyBadge(kind: firstJersey, size: 46),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.dividerStrong,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniCell(
                          big: '${profile.statsMonth.wins}',
                          small: '/${profile.statsMonth.matches}',
                          label: 'Ce mois',
                        ),
                      ),
                      Expanded(
                        child: _MiniCell(
                          big: '${(winRate * 100).round()}%',
                          label: 'Victoires',
                        ),
                      ),
                      Expanded(
                        child: _MiniCell(
                          big: '${profile.statsMonth.streak}',
                          label: 'Série',
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Loading & Error ─────────────────────────────────────────────────────────

class _PlayerDetailLoading extends StatelessWidget {
  final String playerId;
  const _PlayerDetailLoading({required this.playerId});

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(playerId);
    return Stack(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.55),
                AppColors.bgScaffold,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _PlayerDetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PlayerDetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Réessayer'),
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

// ── Stats mini cell ─────────────────────────────────────────────────────────

class _MiniCell extends StatelessWidget {
  final String big;
  final String? small;
  final String label;
  final Color color;

  const _MiniCell({
    required this.big,
    this.small,
    required this.label,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              big,
              style: AppTextStyles.numeric(
                size: 22,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            if (small != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  small!,
                  style: AppTextStyles.numeric(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// CTA that fires off a SINGLES challenge to [opponentId] and, on success,
/// pushes the [ChallengeSentScreen]. Surfaces API errors as a snackbar.
class _ChallengeButton extends StatefulWidget {
  final String opponentId;
  final String opponentFirstName;

  const _ChallengeButton({
    required this.opponentId,
    required this.opponentFirstName,
  });

  @override
  State<_ChallengeButton> createState() => _ChallengeButtonState();
}

class _ChallengeButtonState extends State<_ChallengeButton> {
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ChallengesRepository.instance.create(toUserId: widget.opponentId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              ChallengeSentScreen(opponentFirstName: widget.opponentFirstName),
        ),
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
    return PrimaryButton(
      label: 'Défier ${widget.opponentFirstName}',
      icon: Icons.sports_kabaddi_rounded,
      loading: _busy,
      onPressed: _submit,
    );
  }
}
