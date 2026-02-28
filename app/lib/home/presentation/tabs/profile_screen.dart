import 'package:flutter/material.dart';
import 'package:bap_pulse/auth/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'Joueur';
    final email = user?.email ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1511),
                    Color(0xFF13231C),
                    Color(0xFF0E1C16),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  _buildHeader(context, displayName, email),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes Statistiques',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(context),
                  const SizedBox(height: 24),
                  Text(
                    'Rating Trend',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTrendCard(context),
                  const SizedBox(height: 24),
                  Text(
                    'Historique récent',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentHistory(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayName, String email) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13231C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF203229)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF28F39B), width: 2),
                ),
              ),
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF1E3027),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE7F6EE),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF28F39B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF28F39B)
                            .withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Color(0xFF052216),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2D24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF284237)),
            ),
            child: Text(
              'Elite Division · Club ID: #BC-8829',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9FB3A8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context,
            'Classement',
            '#12',
            '+2 spots',
            Icons.trending_up,
            const Color(0xFF28F39B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            context,
            'Win rate',
            '68%',
            '+3.1%',
            Icons.star,
            const Color(0xFF7DEFC1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            context,
            'Matchs',
            '142',
            'Last 30d: 12',
            Icons.sports_tennis,
            const Color(0xFF4DD4FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String label,
    String value,
    String hint,
    IconData icon,
    Color accent,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14241D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF203229)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: theme.textTheme.labelSmall?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context) {
    final theme = Theme.of(context);
    const data = [0.3, 0.5, 0.35, 0.55, 0.42, 0.75, 0.4, 0.6, 0.52, 0.8];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF14241D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF203229)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1,450 pts',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 30 Days +4.2%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF28F39B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                data: data,
                strokeColor: const Color(0xFF28F39B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('W', 'vs. Kevin Sanjaya', '21-18, 21-15', '2h ago'),
      ('L', 'vs. Viktor Axelsen', '19-21, 22-24', 'Yesterday'),
      ('W', 'vs. Lee Zii Jia', '21-14, 21-12', 'Oct 28'),
    ];

    return Column(
      children: items.map((item) {
        final isWin = item.$1 == 'W';
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isWin
                      ? const Color(0xFF1E3A2D)
                      : const Color(0xFF3A1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.$1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isWin
                          ? const Color(0xFF28F39B)
                          : const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.$4,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await AuthService().signOut();
    }
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.data,
    required this.strokeColor,
  });

  final List<double> data;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY);

    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final normalized = (data[i] - minY) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.strokeColor != strokeColor;
  }
}
