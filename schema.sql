-- ============================================================
-- Schema: Baseball Analytics Database
-- Standard SQL | Mirrors MLB Statcast + FanGraphs structure
-- ============================================================

CREATE TABLE teams (
    team_id     INTEGER PRIMARY KEY,
    team_name   VARCHAR(50) NOT NULL,
    abbreviation VARCHAR(3) NOT NULL,
    league      VARCHAR(2) NOT NULL,   -- AL or NL
    division    VARCHAR(5) NOT NULL    -- East, West, Central
);

CREATE TABLE players (
    player_id   INTEGER PRIMARY KEY,
    player_name VARCHAR(100) NOT NULL,
    team_id     INTEGER REFERENCES teams(team_id),
    position    VARCHAR(5),            -- SP, RP, C, 1B, 2B, etc.
    age         INTEGER,
    bats        CHAR(1),               -- L, R, S
    throws      CHAR(1)                -- L, R
);

CREATE TABLE games (
    game_id         INTEGER PRIMARY KEY,
    game_date       DATE NOT NULL,
    home_team_id    INTEGER REFERENCES teams(team_id),
    away_team_id    INTEGER REFERENCES teams(team_id),
    home_pitcher_id INTEGER REFERENCES players(player_id),
    away_pitcher_id INTEGER REFERENCES players(player_id),
    venue           VARCHAR(100),
    home_score      INTEGER,
    away_score      INTEGER
);

CREATE TABLE pitches (
    pitch_id            INTEGER PRIMARY KEY,
    game_id             INTEGER REFERENCES games(game_id),
    pitcher_id          INTEGER REFERENCES players(player_id),
    batter_id           INTEGER REFERENCES players(player_id),

    -- Count
    balls               INTEGER,
    strikes             INTEGER,
    inning              INTEGER,

    -- Pitch characteristics (Statcast)
    pitch_type          VARCHAR(5),        -- FF, SL, CH, CU, SI, etc.
    release_speed       NUMERIC(5,1),      -- mph
    release_spin_rate   NUMERIC(7,1),      -- rpm
    release_extension   NUMERIC(4,2),      -- feet
    release_pos_x       NUMERIC(5,2),
    release_pos_z       NUMERIC(5,2),
    spin_axis           NUMERIC(6,1),      -- degrees

    -- Movement
    pfx_x               NUMERIC(5,2),      -- horizontal break (inches)
    pfx_z               NUMERIC(5,2),      -- induced vertical break (inches)

    -- Location at plate
    plate_x             NUMERIC(5,2),
    plate_z             NUMERIC(5,2),

    -- Outcome
    description         VARCHAR(50),       -- swinging_strike, called_strike, ball, etc.
    events              VARCHAR(50),       -- strikeout, walk, home_run, single, etc.
    delta_run_exp       NUMERIC(8,6),      -- change in run expectancy (Statcast)

    -- Batted ball (if contact)
    launch_speed        NUMERIC(5,1),      -- exit velocity (mph)
    launch_angle        NUMERIC(5,1)       -- degrees
);

CREATE TABLE pitcher_season_stats (
    player_id       INTEGER REFERENCES players(player_id),
    season          INTEGER,
    games           INTEGER,
    innings_pitched NUMERIC(6,1),
    era             NUMERIC(5,2),
    fip             NUMERIC(5,2),
    xfip            NUMERIC(5,2),
    k_pct           NUMERIC(5,2),
    bb_pct          NUMERIC(5,2),
    war             NUMERIC(5,1),
    PRIMARY KEY (player_id, season)
);

-- ============================================================
-- Indexes for query performance
-- ============================================================
CREATE INDEX idx_pitches_pitcher   ON pitches(pitcher_id);
CREATE INDEX idx_pitches_batter    ON pitches(batter_id);
CREATE INDEX idx_pitches_game      ON pitches(game_id);
CREATE INDEX idx_pitches_type      ON pitches(pitch_type);
CREATE INDEX idx_pitches_events    ON pitches(events);
CREATE INDEX idx_games_date        ON games(game_date);
