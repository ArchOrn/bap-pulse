import 'package:flutter/material.dart';
import 'package:bap_pulse/home/presentation/add_match_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Matchs'), centerTitle: true),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMatchScreen()),
            );
          },
          backgroundColor: const Color(0xFF28F39B),
          foregroundColor: const Color(0xFF052216),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau match'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: 6,
        itemBuilder: (context, index) {
          final isWin = index.isEven;
          final opponent = [
            'Kevin Sanjaya',
            'Viktor Axelsen',
            'Lee Zii Jia',
            'Anders Antonsen',
            'Kunlavut Vitidsarn',
            'Anthony Ginting',
          ][index];
          final score = isWin ? '21-18, 21-15' : '19-21, 22-24';
          final when = index == 0 ? '2h ago' : 'Il y a ${index + 1} jours';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14241D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF203229)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWin
                        ? const Color(0xFF1E3A2D)
                        : const Color(0xFF3A1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isWin ? 'W' : 'L',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isWin
                              ? const Color(0xFF28F39B)
                              : const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isWin ? 'WIN' : 'LOSS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs. $opponent',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Singles · League Stage',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      when,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
