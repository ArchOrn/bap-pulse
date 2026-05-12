-- +goose Up

ALTER TABLE users
    ADD COLUMN nickname VARCHAR(24);

-- +goose Down

ALTER TABLE users
    DROP COLUMN nickname;
