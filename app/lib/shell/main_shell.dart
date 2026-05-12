import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _routes = [
    '/home',
    '/leaderboard',
    '/members',
    '/jerseys',
    '/profile',
  ];

  static int _indexOf(String location) {
    final i = _routes.indexWhere((r) => location.startsWith(r));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexOf(loc);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgScaffold.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = i == index;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (i != index) context.go(_routes[i]);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? tab.iconSelected : tab.icon,
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData iconSelected;
  const _Tab(this.label, this.icon, this.iconSelected);
}

const _tabs = [
  _Tab('Accueil', Icons.home_outlined, Icons.home_rounded),
  _Tab('Classement', Icons.emoji_events_outlined, Icons.emoji_events_rounded),
  _Tab('Membres', Icons.groups_2_outlined, Icons.groups_2_rounded),
  _Tab('Maillots', Icons.sports_outlined, Icons.sports),
  _Tab('Moi', Icons.person_outline, Icons.person_rounded),
];
