-- +goose Up

-- Rename the table (FK references in matches/elo_history are updated automatically by PostgreSQL)
ALTER TABLE players RENAME TO users;

-- Add first_name and last_name (nullable initially for data migration)
ALTER TABLE users
    ADD COLUMN first_name VARCHAR(100),
    ADD COLUMN last_name  VARCHAR(100);

-- Migrate existing data: put everything in first_name
UPDATE users SET first_name = name, last_name = '';

-- Now enforce NOT NULL
ALTER TABLE users
    ALTER COLUMN first_name SET NOT NULL,
    ALTER COLUMN last_name  SET NOT NULL;

-- Drop the old name column
ALTER TABLE users DROP COLUMN name;


-- +goose Down

ALTER TABLE users ADD COLUMN name VARCHAR(100);

UPDATE users
SET name = CASE
    WHEN last_name = '' THEN first_name
    ELSE first_name || ' ' || last_name
END;

ALTER TABLE users ALTER COLUMN name SET NOT NULL;

ALTER TABLE users
    DROP COLUMN first_name,
    DROP COLUMN last_name;

ALTER TABLE users RENAME TO players;
