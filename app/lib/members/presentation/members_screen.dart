import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/avatar_color.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/jersey_badge.dart';
import 'package:bap_pulse/core/widgets/pulsing_placeholder.dart';
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
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final members = snapshot.data;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(memberCount: isLoading ? null : (members?.length ?? 0)),
              _SearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              _CategoryPills(
                selected: _category,
                onChange: (c) => setState(() => _category = c),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _bodyForState(
                  key: ValueKey(_phaseKey(isLoading, hasError)),
                  isLoading: isLoading,
                  hasError: hasError,
                  errorMessage: snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Impossible de charger les membres.',
                  members: members ?? const [],
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _phaseKey(bool loading, bool error) {
    if (loading) return 'skeleton';
    if (error) return 'error';
    return 'loaded';
  }

  Widget _bodyForState({
    required Key key,
    required bool isLoading,
    required bool hasError,
    required String errorMessage,
    required List<MemberSummary> members,
  }) {
    if (isLoading) return _MembersSkeleton(key: key);
    if (hasError) {
      return _MembersErrorCard(
        key: key,
        message: errorMessage,
        onRetry: _retry,
      );
    }
    return _MembersGroupedList(
      key: key,
      members: members,
      query: _query,
      category: _category,
    );
  }
}

// ── Persistent header pieces ────────────────────────────────────────────────

class _Header extends StatelessWidget {
  /// `null` while loading — renders a placeholder subtitle to avoid layout jump.
  final int? memberCount;
  const _Header({required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          const SizedBox(height: 4),
          if (memberCount != null)
            Text('$memberCount membres', style: AppTextStyles.bodySmall)
          else
            const PulsingPlaceholder(width: 90, height: 12),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
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
    );
  }
}

class _CategoryPills extends StatelessWidget {
  final PlayerCategory? selected;
  final ValueChanged<PlayerCategory?> onChange;
  const _CategoryPills({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          _Pill(
            label: 'Tous',
            selected: selected == null,
            onTap: () => onChange(null),
          ),
          const SizedBox(width: 6),
          _Pill(
            label: 'Simple H',
            selected: selected == PlayerCategory.sh,
            onTap: () => onChange(PlayerCategory.sh),
          ),
          const SizedBox(width: 6),
          _Pill(
            label: 'Simple D',
            selected: selected == PlayerCategory.sd,
            onTap: () => onChange(PlayerCategory.sd),
          ),
        ],
      ),
    );
  }
}

// ── Loaded body ─────────────────────────────────────────────────────────────

class _MembersGroupedList extends StatelessWidget {
  final List<MemberSummary> members;
  final String query;
  final PlayerCategory? category;

  const _MembersGroupedList({
    super.key,
    required this.members,
    required this.query,
    required this.category,
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

    if (letters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Text(
            query.isEmpty
                ? 'Aucun membre dans cette catégorie.'
                : 'Aucun résultat pour « $query ».',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
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

// ── Skeleton & Error ────────────────────────────────────────────────────────

/// Two fake letter sections (A, B) each holding a rounded card with 4 row
/// placeholders. Dimensions mirror the real `_MemberRow` so the swap from
/// skeleton → loaded body doesn't shift the page.
class _MembersSkeleton extends StatelessWidget {
  const _MembersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final _ in [0, 1])
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 4, 10, 6),
                  child: PulsingPlaceholder(width: 14, height: 12),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: i == 3
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                      color: AppColors.divider,
                                      width: 0.5,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              const PulsingPlaceholder(
                                width: 38,
                                height: 38,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(19)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: const [
                                    PulsingPlaceholder(
                                        width: 130, height: 13),
                                    SizedBox(height: 6),
                                    PulsingPlaceholder(
                                        width: 180, height: 11),
                                  ],
                                ),
                              ),
                              const PulsingPlaceholder(width: 56, height: 12),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MembersErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _MembersErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
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
