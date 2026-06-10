import 'package:flutter/material.dart';
import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/match.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// In-memory data source mirroring `data.jsx` from the design kit.
///
/// All screens read from this repository for the redesign milestone. When the
/// app is wired to the Go API, swap callers to an `ApiRepository` exposing the
/// same surface — the BLoCs above don't need to change.
class MockRepository {
  MockRepository._();
  static final MockRepository instance = MockRepository._();

  static const String currentUserId = 'u1';

  final List<Player> _players = const [
    Player(
      id: 'u1',
      name: 'Thomas L.',
      initials: 'TL',
      elo: 1842,
      trend: 34,
      performance: 320,
      perfGain: 52,
      matchesMonth: 14,
      winsMonth: 11,
      winsVsBetter: 4,
      streak: 4,
      category: PlayerCategory.sh,
      club: 'BAP',
      joined: '2023',
      color: Color(0xFFFF7A59),
      jerseys: [JerseyKind.yellow],
    ),
    Player(
      id: 'u2',
      name: 'Camille R.',
      initials: 'CR',
      elo: 1921,
      trend: -12,
      performance: 380,
      perfGain: 18,
      matchesMonth: 12,
      winsMonth: 9,
      winsVsBetter: 2,
      streak: 2,
      category: PlayerCategory.sd,
      club: 'BAP',
      joined: '2021',
      color: Color(0xFF5E60CE),
      jerseys: [JerseyKind.polka],
    ),
    Player(
      id: 'u3',
      name: 'Hugo M.',
      initials: 'HM',
      elo: 2034,
      trend: 18,
      performance: 480,
      perfGain: 90,
      matchesMonth: 18,
      winsMonth: 15,
      winsVsBetter: 6,
      streak: 7,
      category: PlayerCategory.sh,
      club: 'BAP',
      joined: '2019',
      color: Color(0xFF0A84FF),
      jerseys: [JerseyKind.yellow, JerseyKind.green],
    ),
    Player(
      id: 'u4',
      name: 'Léa B.',
      initials: 'LB',
      elo: 1756,
      trend: 52,
      performance: 290,
      perfGain: 75,
      matchesMonth: 21,
      winsMonth: 14,
      winsVsBetter: 5,
      streak: 3,
      category: PlayerCategory.sd,
      club: 'BAP',
      joined: '2024',
      color: Color(0xFF2FB974),
      jerseys: [JerseyKind.fight],
    ),
    Player(
      id: 'u5',
      name: 'Mehdi A.',
      initials: 'MA',
      elo: 1688,
      trend: 8,
      performance: 175,
      perfGain: 25,
      matchesMonth: 9,
      winsMonth: 5,
      winsVsBetter: 1,
      streak: 0,
      category: PlayerCategory.sh,
      club: 'BAP',
      joined: '2022',
      color: Color(0xFFE63946),
    ),
    Player(
      id: 'u6',
      name: 'Julie P.',
      initials: 'JP',
      elo: 1902,
      trend: 6,
      performance: 340,
      perfGain: 20,
      matchesMonth: 11,
      winsMonth: 8,
      winsVsBetter: 3,
      streak: 1,
      category: PlayerCategory.sd,
      club: 'BAP',
      joined: '2020',
      color: Color(0xFFFFB703),
    ),
    Player(
      id: 'u7',
      name: 'Antoine D.',
      initials: 'AD',
      elo: 1574,
      trend: -22,
      performance: 110,
      perfGain: 5,
      matchesMonth: 8,
      winsMonth: 3,
      winsVsBetter: 0,
      streak: 0,
      category: PlayerCategory.sh,
      club: 'BAP',
      joined: '2023',
      color: Color(0xFF8338EC),
    ),
    Player(
      id: 'u8',
      name: 'Sarah K.',
      initials: 'SK',
      elo: 1821,
      trend: 14,
      performance: 280,
      perfGain: 30,
      matchesMonth: 13,
      winsMonth: 9,
      winsVsBetter: 2,
      streak: 2,
      category: PlayerCategory.sd,
      club: 'BAP',
      joined: '2022',
      color: Color(0xFFFB5607),
    ),
    Player(
      id: 'u9',
      name: 'Paul V.',
      initials: 'PV',
      elo: 1711,
      trend: -4,
      performance: 195,
      perfGain: 10,
      matchesMonth: 7,
      winsMonth: 4,
      winsVsBetter: 1,
      streak: 1,
      category: PlayerCategory.sh,
      club: 'BAP',
      joined: '2024',
      color: Color(0xFF3A86FF),
    ),
    Player(
      id: 'u10',
      name: 'Emma T.',
      initials: 'ET',
      elo: 1645,
      trend: 28,
      performance: 240,
      perfGain: 60,
      matchesMonth: 16,
      winsMonth: 10,
      winsVsBetter: 3,
      streak: 5,
      category: PlayerCategory.sd,
      club: 'BAP',
      joined: '2023',
      color: Color(0xFFF72585),
    ),
    Player(
      id: 'u11',
      name: 'Nicolas G.',
      initials: 'NG',
      elo: 1988,
      trend: -18,
      performance: 360,
      perfGain: 12,
      matchesMonth: 10,
      winsMonth: 6,
      winsVsBetter: 2,
      streak: 0,
      category: PlayerCategory.sh,
      club: 'BAP',
      joined: '2018',
      color: Color(0xFF0077B6),
    ),
    Player(
      id: 'u12',
      name: 'Inès F.',
      initials: 'IF',
      elo: 1534,
      trend: 44,
      performance: 220,
      perfGain: 85,
      matchesMonth: 17,
      winsMonth: 12,
      winsVsBetter: 4,
      streak: 6,
      category: PlayerCategory.sd,
      club: 'BAP',
      joined: '2024',
      color: Color(0xFF06A77D),
    ),
  ];

  final List<GameMatch> _matches = const [
    GameMatch(
      id: 'm1',
      playerAId: 'u1',
      playerBId: 'u3',
      scoreA: [21, 18, 19],
      scoreB: [15, 21, 21],
      winnerId: 'u3',
      date: 'Aujourd\'hui',
      time: '19:40',
      court: 'Terrain 3',
      status: MatchStatus.pending,
      eloChange: 18,
    ),
    GameMatch(
      id: 'm2',
      playerAId: 'u4',
      playerBId: 'u6',
      scoreA: [21, 21],
      scoreB: [17, 14],
      winnerId: 'u4',
      date: 'Hier',
      time: '20:15',
      court: 'Terrain 1',
      status: MatchStatus.confirmed,
      eloChange: 21,
    ),
    GameMatch(
      id: 'm3',
      playerAId: 'u1',
      playerBId: 'u8',
      scoreA: [21, 19, 21],
      scoreB: [14, 21, 17],
      winnerId: 'u1',
      date: '20 avr.',
      time: '19:00',
      court: 'Terrain 2',
      status: MatchStatus.confirmed,
      eloChange: 16,
    ),
    GameMatch(
      id: 'm4',
      playerAId: 'u2',
      playerBId: 'u11',
      scoreA: [21, 21],
      scoreB: [19, 15],
      winnerId: 'u2',
      date: '18 avr.',
      time: '20:45',
      court: 'Terrain 4',
      status: MatchStatus.confirmed,
      eloChange: 12,
    ),
    GameMatch(
      id: 'm5',
      playerAId: 'u1',
      playerBId: 'u9',
      scoreA: [21, 21],
      scoreB: [11, 16],
      winnerId: 'u1',
      date: '16 avr.',
      time: '19:30',
      court: 'Terrain 1',
      status: MatchStatus.confirmed,
      eloChange: 8,
    ),
    GameMatch(
      id: 'm6',
      playerAId: 'u3',
      playerBId: 'u11',
      scoreA: [21, 21],
      scoreB: [18, 19],
      winnerId: 'u3',
      date: '15 avr.',
      time: '20:00',
      court: 'Terrain 3',
      status: MatchStatus.confirmed,
      eloChange: 14,
    ),
    GameMatch(
      id: 'm7',
      playerAId: 'u1',
      playerBId: 'u5',
      scoreA: [21, 12, 21],
      scoreB: [18, 21, 15],
      winnerId: 'u1',
      date: '14 avr.',
      time: '19:15',
      court: 'Terrain 2',
      status: MatchStatus.confirmed,
      eloChange: 9,
    ),
    GameMatch(
      id: 'm8',
      playerAId: 'u4',
      playerBId: 'u10',
      scoreA: [21, 21],
      scoreB: [16, 18],
      winnerId: 'u4',
      date: '13 avr.',
      time: '20:30',
      court: 'Terrain 1',
      status: MatchStatus.confirmed,
      eloChange: 11,
    ),
  ];

  final List<Jersey> _jerseys = const [
    Jersey(
      kind: JerseyKind.yellow,
      name: 'Maillot Jaune',
      tagline: 'Leader du classement',
      description:
          'Porté par le 1er du score de performance du club. Se gagne et se perd à chaque match joué.',
      color: Color(0xFFFFD60A),
      textColor: Color(0xFF0B0F14),
      criterion: 'Performance',
      holderId: 'u3',
      unit: 'pts',
      value: 480,
    ),
    Jersey(
      kind: JerseyKind.polka,
      name: 'Maillot à Pois',
      tagline: 'Tueur de géants',
      description:
          'Récompense le joueur avec le plus de victoires contre mieux classé que lui sur le mois.',
      color: Color(0xFFFFFFFF),
      accent: Color(0xFFE63946),
      textColor: Color(0xFF0B0F14),
      criterion: 'Upsets',
      holderId: 'u3',
      unit: 'upsets ce mois',
      value: 6,
    ),
    Jersey(
      kind: JerseyKind.green,
      name: 'Maillot Vert',
      tagline: 'Finisseur du mois',
      description:
          'Plus de victoires sur la dernière semaine du mois. Celui qui termine fort.',
      color: Color(0xFF2FB974),
      textColor: Color(0xFFFFFFFF),
      criterion: 'Last week',
      holderId: 'u10',
      unit: 'V. sem. 4',
      value: 5,
    ),
    Jersey(
      kind: JerseyKind.fight,
      name: 'Maillot du Combatif',
      tagline: 'Infatigable',
      description:
          'Le plus grand nombre de matchs joués sur le mois, peu importe le résultat.',
      color: Color(0xFFF5F5F5),
      accent: Color(0xFF0A84FF),
      textColor: Color(0xFF0B0F14),
      criterion: 'Matchs joués',
      holderId: 'u4',
      unit: 'matchs',
      value: 21,
    ),
  ];

  // ── Read API ────────────────────────────────────────────────────────────

  List<Player> get players => List.unmodifiable(_players);
  List<GameMatch> get matches => List.unmodifiable(_matches);
  List<Jersey> get jerseys => List.unmodifiable(_jerseys);

  Player byId(String id) => _players.firstWhere((p) => p.id == id);
  Player? tryById(String id) {
    for (final p in _players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Player get currentUser => byId(currentUserId);

  Jersey jersey(JerseyKind kind) => _jerseys.firstWhere((j) => j.kind == kind);

  /// Players sorted by performance score desc — the **default public**
  /// classement (the maillot jaune leaderboard).
  List<Player> get byPerformance {
    final list = [..._players]
      ..sort((a, b) => b.performance.compareTo(a.performance));
    return list;
  }

  /// Players sorted by hidden ELO desc — internal/algorithmic use only,
  /// never displayed in the UI.
  List<Player> get byElo {
    final list = [..._players]..sort((a, b) => b.elo.compareTo(a.elo));
    return list;
  }

  int perfRankOf(String playerId) =>
      byPerformance.indexWhere((p) => p.id == playerId) + 1;

  List<GameMatch> matchesOf(String playerId) =>
      _matches.where((m) => m.involves(playerId)).toList();

  /// Head-to-head between two players (most recent first).
  List<GameMatch> headToHead(String a, String b) => _matches
      .where(
        (m) =>
            (m.playerAId == a && m.playerBId == b) ||
            (m.playerAId == b && m.playerBId == a),
      )
      .toList();

  /// Mocked performance history for the current user (13 points, used by
  /// the profile sparkline). Non-decreasing — ends at the player's current
  /// performance score.
  List<int> perfHistory(String playerId) {
    final p = byId(playerId);
    final end = p.performance;
    // Distribute points across 13 days, mostly increasing with some plateaus.
    final fractions = [
      0.10,
      0.18,
      0.22,
      0.22,
      0.32,
      0.32,
      0.42,
      0.50,
      0.60,
      0.70,
      0.80,
      0.90,
      1.0,
    ];
    return fractions.map((f) => (end * f).round()).toList();
  }

  /// Hall of Fame — past yellow-jersey holders (months ended, perf reset).
  List<({String month, Player holder, int score})> hallOfFame() => [
    (month: 'Mars 2026', holder: byId('u11'), score: 510),
    (month: 'Février 2026', holder: byId('u3'), score: 470),
    (month: 'Janvier 2026', holder: byId('u2'), score: 425),
  ];
}
