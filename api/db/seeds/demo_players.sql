-- Demo players for local dev / staging.
--
-- Idempotent: ON CONFLICT (id) DO NOTHING on users PK. Reapply at any time.
-- IDs are fake Firebase UIDs (users.id is VARCHAR(128) without an FK to
-- Firebase). 16 players with mixed gender and ELO spread between ~860 and
-- ~1280 for a realistic SINGLES leaderboard out of the box.
--
-- Run with: make seed-players

INSERT INTO users (id, first_name, last_name, email, gender, ffbad_rank, elo_singles, elo_doubles, elo_mixed, role, created_at)
VALUES
  ('fake_player_001', 'Hugo',      'Marchand',  'hugo.fake@bap.local',      'MALE',   'R5',  1280, 1240, 1260, 'player', '2025-09-15 18:00:00+02'),
  ('fake_player_002', 'Camille',   'Rousseau',  'camille.fake@bap.local',   'FEMALE', 'R6',  1240, 1210, 1230, 'player', '2025-08-10 18:00:00+02'),
  ('fake_player_003', 'Mehdi',     'Aouli',     'mehdi.fake@bap.local',     'MALE',   'R6',  1210, 1200, 1190, 'player', '2025-09-22 18:00:00+02'),
  ('fake_player_004', 'Léa',       'Bernard',   'lea.fake@bap.local',       'FEMALE', 'D7',  1180, 1140, 1160, 'player', '2025-10-05 18:00:00+02'),
  ('fake_player_005', 'Nicolas',   'Garnier',   'nicolas.fake@bap.local',   'MALE',   'D7',  1140, 1110, 1130, 'player', '2025-11-03 18:00:00+02'),
  ('fake_player_006', 'Inès',      'Faure',     'ines.fake@bap.local',      'FEMALE', 'D8',  1100, 1080, 1090, 'player', '2025-11-18 18:00:00+02'),
  ('fake_player_007', 'Théo',      'Lemoine',   'theo.fake@bap.local',      'MALE',   'D8',  1080, 1050, 1070, 'player', '2025-12-02 18:00:00+02'),
  ('fake_player_008', 'Sarah',     'Khelifi',   'sarah.fake@bap.local',     'FEMALE', 'D8',  1050, 1030, 1040, 'player', '2025-12-15 18:00:00+02'),
  ('fake_player_009', 'Antoine',   'Dupré',     'antoine.fake@bap.local',   'MALE',   'D9',  1020,  990, 1010, 'player', '2026-01-10 18:00:00+02'),
  ('fake_player_010', 'Marion',    'Lepetit',   'marion.fake@bap.local',    'FEMALE', 'D9',   990,  970,  980, 'player', '2026-01-25 18:00:00+02'),
  ('fake_player_011', 'Julien',    'Tessier',   'julien.fake@bap.local',    'MALE',   'P10',  960,  940,  950, 'player', '2026-02-08 18:00:00+02'),
  ('fake_player_012', 'Élise',     'Marchetti', 'elise.fake@bap.local',     'FEMALE', 'P10',  930,  910,  920, 'player', '2026-02-22 18:00:00+02'),
  ('fake_player_013', 'Bastien',   'Roux',      'bastien.fake@bap.local',   'MALE',   'P11',  900,  880,  890, 'player', '2026-03-05 18:00:00+02'),
  ('fake_player_014', 'Charlotte', 'Vidal',     'charlotte.fake@bap.local', 'FEMALE', 'P11',  880,  860,  870, 'player', '2026-03-18 18:00:00+02'),
  ('fake_player_015', 'Romain',    'Ferrand',   'romain.fake@bap.local',    'MALE',   'P12',  870,  850,  860, 'player', '2026-04-02 18:00:00+02'),
  ('fake_player_016', 'Anaïs',     'Lefèvre',   'anais.fake@bap.local',     'FEMALE', 'P12',  860,  840,  850, 'player', '2026-04-15 18:00:00+02')
ON CONFLICT (id) DO NOTHING;
