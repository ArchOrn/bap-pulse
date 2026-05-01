import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/player_avatar.dart';
import 'package:bap_pulse/core/widgets/trend_chip.dart';
import 'package:bap_pulse/shared/data/mock_repository.dart';
import 'package:bap_pulse/shared/models/player.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  String _query = '';
  PlayerCategory? _category;
  late final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final filtered = repo.players
        .where((p) =>
            (_category == null || p.category == _category) &&
            (_query.isEmpty ||
                p.name.toLowerCase().contains(_query.toLowerCase())))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final groups = <String, List<Player>>{};
    for (final p in filtered) {
      final letter = p.name[0].toUpperCase();
      groups.putIfAbsent(letter, () => []).add(p);
    }
    final letters = groups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: ListView(
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
                Text('Club', style: AppTextStyles.h1),
                const SizedBox(height: 2),
                Text(
                  '${repo.players.length} membres actifs ce mois',
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
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un joueur...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
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
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                const SizedBox(width: 6),
                _Pill(
                  label: 'Simple H',
                  selected: _category == PlayerCategory.sh,
                  onTap: () =>
                      setState(() => _category = PlayerCategory.sh),
                ),
                const SizedBox(width: 6),
                _Pill(
                  label: 'Simple D',
                  selected: _category == PlayerCategory.sd,
                  onTap: () =>
                      setState(() => _category = PlayerCategory.sd),
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
                    child: Column(
                      children: [
                        for (final p in groups[letter]!)
                          _PlayerRow(
                            player: p,
                            isMe: p.id == MockRepository.currentUserId,
                            onTap: () =>
                                context.push('/club/player/${p.id}'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

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

class _PlayerRow extends StatelessWidget {
  final Player player;
  final bool isMe;
  final VoidCallback onTap;
  const _PlayerRow(
      {required this.player, required this.isMe, required this.onTap});

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
            PlayerAvatar(
              player: player,
              size: 38,
              showJersey: player.jerseys.isNotEmpty,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
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
                    '${player.performance} pts · ${player.winsMonth}V/${player.lossesMonth}D · ELO ${player.elo}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            TrendChip(value: player.perfGain),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
