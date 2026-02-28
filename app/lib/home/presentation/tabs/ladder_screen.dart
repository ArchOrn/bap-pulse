import 'package:flutter/material.dart';

class LadderScreen extends StatelessWidget {
  const LadderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Rankings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF28F39B),
          foregroundColor: const Color(0xFF052216),
          child: const Icon(Icons.add),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopPlayer(
                context,
                rank: 2,
                name: 'Sarah J.',
                points: '2,120',
                ringColor: const Color(0xFFB5BDC4),
              ),
              _buildTopPlayer(
                context,
                rank: 1,
                name: 'Marcus Chen',
                points: '2,450',
                ringColor: const Color(0xFF28F39B),
                isChampion: true,
              ),
              _buildTopPlayer(
                context,
                rank: 3,
                name: 'Mike R.',
                points: '1,980',
                ringColor: const Color(0xFFFFA94D),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFilterChip('All Players', true),
              const SizedBox(width: 12),
              _buildFilterChip('Mens', false),
              const SizedBox(width: 12),
              _buildFilterChip('Womens', false),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Full Leaderboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Updated 2h ago',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(7, (index) {
            final position = index + 4;
            final points = 1840 - (index * 60);
            final streak = index.isEven ? 'W${index + 1} Streak' : 'L${index} Streak';
            final streakColor = index.isEven
                ? const Color(0xFF28F39B)
                : const Color(0xFFFF6B6B);
            final change = index.isEven ? '+${index + 1}' : '-1';
            return _buildLeaderboardRow(
              context,
              rank: position,
              name: 'Player ${String.fromCharCode(65 + index)}',
              record: '${12 - index}W - ${4 + index}L',
              streak: streak,
              streakColor: streakColor,
              points: points,
              change: change,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopPlayer(
    BuildContext context, {
    required int rank,
    required String name,
    required String points,
    required Color ringColor,
    bool isChampion = false,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: isChampion ? 96 : 76,
                height: isChampion ? 96 : 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 3),
                ),
              ),
              CircleAvatar(
                radius: isChampion ? 40 : 32,
                backgroundColor: const Color(0xFF1E3027),
                child: Text(
                  name.substring(0, 1),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF052216),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (isChampion)
                Positioned(
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ringColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: Color(0xFF052216),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$points pts',
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF28F39B),
            ),
          ),
          if (isChampion)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'CLUB CHAMPION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF28F39B) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFF28F39B) : const Color(0xFF6C8177),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(
    BuildContext context, {
    required int rank,
    required String name,
    required String record,
    required String streak,
    required Color streakColor,
    required int points,
    required String change,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14241D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF203229)),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF22362C),
            child: Text(
              name.substring(0, 1),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      record,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      streak,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: streakColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: change.startsWith('+')
                      ? const Color(0xFF28F39B)
                      : const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
