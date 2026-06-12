-- +goose Up

-- Local cache of the club's FFBAD roster, synced from the official FFBAD API
-- (GET https://api.ffbad.org/club/?TokenClub=<token>) weekly on Thursdays
-- (FFBAD recomputes rankings on Thursdays) and on-demand by an admin.
-- Registration matches the submitted licence against this table: a hit means
-- the person is a club member → auto-approve + seed profile/ELO from here.
CREATE TABLE club_roster (
    license_number  TEXT PRIMARY KEY,
    per_id          TEXT,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    gender          TEXT CHECK (gender IN ('MALE', 'FEMALE')),
    -- Per-discipline FFBAD ranking name (e.g. N3, R4). Same set as users.ffbad_rank.
    rank_singles    TEXT CHECK (rank_singles IN ('NC','P12','P11','P10','D9','D8','D7','R6','R5','R4','N3','N2','N1')),
    rank_doubles    TEXT CHECK (rank_doubles IN ('NC','P12','P11','P10','D9','D8','D7','R6','R5','R4','N3','N2','N1')),
    rank_mixed      TEXT CHECK (rank_mixed   IN ('NC','P12','P11','P10','D9','D8','D7','R6','R5','R4','N3','N2','N1')),
    -- FFBAD "cote" (points) per discipline → seeds the matching tableau's ELO.
    cote_singles    INT,
    cote_doubles    INT,
    cote_mixed      INT,
    is_data_public  BOOLEAN NOT NULL DEFAULT true,
    matched_user_id VARCHAR(128) REFERENCES users(id) ON DELETE SET NULL,
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_club_roster_matched_user ON club_roster (matched_user_id);

-- +goose Down

DROP TABLE IF EXISTS club_roster;
