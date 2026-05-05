-- +goose Up

ALTER TABLE users
    ADD COLUMN gender     TEXT CHECK (gender IN ('MALE', 'FEMALE')),
    ADD COLUMN ffbad_rank TEXT CHECK (ffbad_rank IN
        ('NC','P12','P11','P10','D9','D8','D7','R6','R5','R4','N3','N2','N1'));

-- +goose Down

ALTER TABLE users
    DROP COLUMN ffbad_rank,
    DROP COLUMN gender;
