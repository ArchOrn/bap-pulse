import 'package:flutter/material.dart';
import 'package:bap_pulse/home/presentation/tabs/ladder_screen.dart';
import 'package:bap_pulse/home/presentation/tabs/matches_screen.dart';
import 'package:bap_pulse/home/presentation/tabs/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    LadderScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1D18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF203229)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard_outlined),
                  activeIcon: Icon(Icons.leaderboard),
                  label: 'Ladder',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_tennis_outlined),
                  activeIcon: Icon(Icons.sports_tennis),
                  label: 'Matchs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
