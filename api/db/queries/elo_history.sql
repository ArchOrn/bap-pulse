-- name: CreateEloHistory :one
INSERT INTO elo_history (player_id, elo_before, elo_after, match_id, performance_points)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: GetUserEloHistory :many
SELECT * FROM elo_history
WHERE player_id = $1
ORDER BY created_at DESC;

-- name: GetMatchEloHistory :many
SELECT * FROM elo_history
WHERE match_id = $1;

-- name: SumPerformancePointsByPlayer :many
SELECT eh.player_id, SUM(eh.performance_points)::INT AS points
FROM elo_history eh
JOIN matches m ON m.id = eh.match_id
WHERE m.match_type = $1
  AND eh.created_at >= $2
  AND eh.created_at <  $3
GROUP BY eh.player_id;

-- name: CountMatchesPlayedByPlayerInTableau :one
-- Counts matches the player has already played in this tableau (used for K-factor).
SELECT COUNT(*)::INT AS total
FROM elo_history eh
JOIN matches m ON m.id = eh.match_id
WHERE eh.player_id = $1
  AND m.match_type = $2;

-- name: GetMatchEloBefore :many
-- For a given match, returns each player's ELO BEFORE the match.
-- Used to compute giant-killer wins (compare opponent ELO at match time).
SELECT player_id, elo_before
FROM elo_history
WHERE match_id = $1;

-- name: SumPerformancePointsByPlayerInRange :one
-- Sum of perf points awarded to ONE player in [from, to) for the given tableau.
SELECT COALESCE(SUM(eh.performance_points), 0)::INT AS points
FROM elo_history eh
JOIN matches m ON m.id = eh.match_id
WHERE eh.player_id = $1
  AND m.match_type = $2
  AND eh.created_at >= $3
  AND eh.created_at <  $4;

-- name: GetDailyPerformancePointsByPlayer :many
-- Daily perf points awarded to ONE player in [from, to). Empty days are absent;
-- callers fill gaps and cumulate as needed.
SELECT date_trunc('day', eh.created_at)::DATE AS day,
       SUM(eh.performance_points)::INT AS points
FROM elo_history eh
JOIN matches m ON m.id = eh.match_id
WHERE eh.player_id = $1
  AND m.match_type = $2
  AND eh.created_at >= $3
  AND eh.created_at <  $4
GROUP BY day
ORDER BY day;
