import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/members/data/member_summary.dart';
import 'package:bap_pulse/members/data/members_api.dart';
import 'package:bap_pulse/shared/models/player.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<MemberSummary>> _future;
  final _api = MembersApi();
  final _searchCtrl = TextEditingController();
  String _query = '';
  PlayerCategory? _category;

  @override
  void initState() {
    super.initState();
    _future = _api.fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = _api.fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: FutureBuilder<List<MemberSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _MembersLoading();
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final message = err is ApiException
                ? err.message
                : 'Impossible de charger les membres.';
            return _MembersError(message: message, onRetry: _retry);
          }
          return _MembersBody(
            members: snapshot.data ?? const [],
            query: _query,
            category: _category,
            searchCtrl: _searchCtrl,
            onQueryChanged: (v) => setState(() => _query = v),
            onCategoryChanged: (c) => setState(() => _category = c),
          );
        },
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _MembersBody extends StatelessWidget {
  final List<MemberSummary> members;
  final String query;
  final PlayerCategory? category;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PlayerCategory?> onCategoryChanged;

  const _MembersBody({
    required this.members,
    required this.query,
    required this.category,
    required this.searchCtrl,
    required this.onQueryChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final filtered = members
        .where((m) =>
            (category == null || m.category == category) &&
            (query.isEmpty ||
                _foldDiacritics(m.name.toLowerCase())
                    .contains(_foldDiacritics(query.toLowerCase()))))
        .toList()
      ..sort((a, b) =>
          _foldDiacritics(a.name).compareTo(_foldDiacritics(b.name)));

    final groups = <String, List<MemberSummary>>{};
    for (final m in filtered) {
      final letter = m.name.isNotEmpty
          ? _foldDiacritics(m.name[0]).toUpperCase()
          : '?';
      groups.putIfAbsent(letter, () => []).add(m);
    }
    final letters = groups.keys.toList()..sort();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 14,
            20,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Membres', style: AppTextStyles.h1),
              const SizedBox(height: 2),
              Text(
                '${members.length} membres',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search,
                    color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un joueur...',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              _Pill(
                label: 'Tous',
                selected: category == null,
                onTap: () => onCategoryChanged(null),
              ),
              const SizedBox(width: 6),
              _Pill(
                label: 'Simple H',
                selected: category == PlayerCategory.sh,
                onTap: () => onCategoryChanged(PlayerCategory.sh),
              ),
              const SizedBox(width: 6),
              _Pill(
                label: 'Simple D',
                selected: category == PlayerCategory.sd,
                onTap: () => onCategoryChanged(PlayerCategory.sd),
              ),
            ],
          ),
        ),
        for (final letter in letters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.hardEdge,
                  // Material parent so InkWell hover/splash paint within
                  // this rounded clip instead of bleeding onto the Scaffold's
                  // Material (which has no border radius).
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        for (final m in groups[letter]!)
                          _MemberRow(
                            member: m,
                            isMe: m.id == myUid,
                            onTap: () =>
                                context.push('/members/player/${m.id}'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Pill (category filter) ──────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Member row ──────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final MemberSummary member;
  final bool isMe;
  final VoidCallback onTap;
  const _MemberRow(
      {required this.member, required this.isMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            _MemberAvatar(member: member),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isMe)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            '· toi',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${member.perfScore} pts · ${member.winsMonth}V/${member.lossesMonth}D · ELO ${member.elo}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              member.perfGain7d > 0 ? '+${member.perfGain7d} pts' : '—',
              style: AppTextStyles.numeric(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Round avatar showing the member's initials on a stable colored disc, with
/// an optional jersey badge in the bottom-right corner. Inlined here (rather
/// than reusing `PlayerAvatar`) because that widget is coupled to the legacy
/// `Player` model.
class _MemberAvatar extends StatelessWidget {
  final MemberSummary member;
  const _MemberAvatar({required this.member});

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    final jersey = member.jerseys.isNotEmpty ? member.jerseys.first : null;
    final badgeSize = _size * 0.5;
    // Reserve badge space whether or not the member holds a jersey, so the
    // name column starts at the same x for every row.
    return SizedBox(
      width: _size + badgeSize * 0.4,
      height: _size + badgeSize * 0.3,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColorFor(member.id),
            ),
            child: Text(
              member.initials,
              style: GoogleFonts.spaceGrotesk(
                fontSize: _size * 0.36,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (jersey != null)
            Positioned(
              right: -badgeSize * 0.2,
              bottom: -badgeSize * 0.05,
              child: JerseyBadge(kind: jersey, size: badgeSize),
            ),
        ],
      ),
    );
  }
}

// ── Loading & Error ─────────────────────────────────────────────────────────

class _MembersLoading extends StatelessWidget {
  const _MembersLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Membres', style: AppTextStyles.h1),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _MembersError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _MembersError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Membres', style: AppTextStyles.h1),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
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
    );
  }
}

// Strip French/Latin diacritics so "Élise" sorts and groups under E (not at
// the end of the Unicode range), and search ignores accents.
String _foldDiacritics(String s) {
  const from = 'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝŸàáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'AAAAAACEEEEIIIINOOOOOUUUUYYaaaaaaceeeeiiiinooooouuuuyy';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    final idx = from.indexOf(ch);
    buf.write(idx >= 0 ? to[idx] : ch);
  }
  return buf.toString();
}
