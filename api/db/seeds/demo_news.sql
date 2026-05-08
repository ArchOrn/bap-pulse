-- Demo news for local dev / staging.
--
-- Idempotent: if rows with these literal IDs already exist, the INSERT does
-- nothing (ON CONFLICT DO NOTHING on the primary key). Reapply at any time.
-- The dates are anchored on May 2026 to match the design mockups; tweak them
-- before running if you want fresher relative-time labels in the app.
--
-- Run with: make seed-news

INSERT INTO news (id, emoji, title, body, source, match_id, created_by, created_at)
VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    '🔥',
    '**Léa B.** est en série de 3 victoires — prochain match vendredi.',
    E'Trois victoires d''affilée pour **Léa**, qui grimpe à la 4ᵉ place du classement performance.\n\nProchain match : *vendredi 8 mai* contre **Hugo M.**',
    'MANUAL',
    NULL,
    NULL,
    '2026-05-05 07:30:00+02'
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    '⚡️',
    '**Hugo M.** bat **Nicolas G.** 21-18, 21-19',
    E'Score final : **21-18, 21-19**\n\nELO :\n- **Hugo** +14\n- **Nicolas** -14\n\nPerformance gagnée :\n- **Hugo** +90 pts\n\n*Match en simple.*',
    'AUTO_MATCH',
    NULL,
    NULL,
    '2026-05-04 21:00:00+02'
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    '🎯',
    '**Inès F.** crée la surprise face à **Camille R.**',
    E'Score : **22-20, 19-21, 21-18**\n\nELO :\n- **Inès** +28\n- **Camille** -28\n\nPerformance gagnée :\n- **Inès** +85 pts\n\n*Match en simple.*',
    'AUTO_MATCH',
    NULL,
    NULL,
    '2026-05-03 19:45:00+02'
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    '🏸',
    'Tournoi interne **« Printemps »** — inscriptions ouvertes',
    E'Le tournoi annuel revient le **samedi 23 mai**. Tableaux SH, SD, DH, DD et MX.\n\nInscription auprès de **Camille** ou via le tableau au club avant le *15 mai*.',
    'MANUAL',
    NULL,
    NULL,
    '2026-05-02 18:00:00+02'
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    '🏆',
    '**Hugo M.** reprend le maillot jaune ce mois-ci',
    E'Avec **480 pts** de performance, Hugo prend la tête du classement mensuel.\n\nIl devance **Camille** (380 pts) de 100 points à 11 jours de la fin du mois.',
    'MANUAL',
    NULL,
    NULL,
    '2026-05-01 09:00:00+02'
  ),
  (
    '66666666-6666-6666-6666-666666666666',
    '📅',
    'Reprise des cours adultes le **lundi 11 mai**',
    E'Reprise normale après les vacances. Cours dirigés *2 heures* par **Mehdi A.** au gymnase Charlie Parker.',
    'MANUAL',
    NULL,
    NULL,
    '2026-04-30 14:00:00+02'
  )
ON CONFLICT (id) DO NOTHING;
