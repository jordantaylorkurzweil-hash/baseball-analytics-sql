-- ============================================================
-- Baseball Analytics SQL Portfolio
-- Jordan Kurzweil
-- Standard SQL | Data: MLB Statcast + FanGraphs (2024 Season)
-- ============================================================
--
-- Schema Overview:
--   pitches   — pitch-level Statcast data (one row per pitch)
--   players   — pitcher and hitter metadata
--   games     — game-level metadata
--   teams     — team information
--
-- See schema.sql for full table definitions and sample data.
-- ============================================================


-- ============================================================
-- TIER 1 — FOUNDATIONAL
-- Filtering, aggregation, GROUP BY
-- ============================================================

-- Query 1: Average fastball velocity by pitcher (min 100 fastballs)
-- Business question: Who threw the hardest in 2024?
SELECT
    p.player_name,
    t.team_name,
    ROUND(AVG(pi.release_speed), 1)   AS avg_velo,
    COUNT(*)                           AS fastballs_thrown
FROM pitches pi
JOIN players p  ON pi.pitcher_id = p.player_id
JOIN teams t    ON p.team_id     = t.team_id
WHERE pi.pitch_type IN ('FF', 'SI')       -- Four-seam and sinker fastballs
GROUP BY p.player_name, t.team_name
HAVING COUNT(*) >= 100
ORDER BY avg_velo DESC
LIMIT 20;


-- Query 2: Strikeout and walk rates by team
-- Business question: Which teams had the best pitching discipline in 2024?
SELECT
    t.team_name,
    COUNT(*)                                                        AS total_pitches,
    SUM(CASE WHEN pi.events = 'strikeout' THEN 1 ELSE 0 END)       AS strikeouts,
    SUM(CASE WHEN pi.events = 'walk' THEN 1 ELSE 0 END)            AS walks,
    ROUND(
        100.0 * SUM(CASE WHEN pi.events = 'strikeout' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT pi.batter_id), 0), 1)              AS k_pct,
    ROUND(
        100.0 * SUM(CASE WHEN pi.events = 'walk' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT pi.batter_id), 0), 1)              AS bb_pct
FROM pitches pi
JOIN players p  ON pi.pitcher_id = p.player_id
JOIN teams t    ON p.team_id     = t.team_id
GROUP BY t.team_name
ORDER BY k_pct DESC;


-- Query 3: Pitch type usage breakdown across MLB
-- Business question: How has pitch mix evolved? What are the most common pitch types?
SELECT
    pitch_type,
    COUNT(*)                                          AS total_thrown,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_all_pitches,
    ROUND(AVG(release_speed), 1)                      AS avg_velo,
    ROUND(AVG(release_spin_rate), 0)                  AS avg_spin
FROM pitches
WHERE pitch_type IS NOT NULL
GROUP BY pitch_type
ORDER BY total_thrown DESC;


-- Query 4: Top 20 hitters by average exit velocity (min 50 batted balls)
-- Business question: Who made the hardest contact in 2024?
SELECT
    p.player_name,
    t.team_name,
    ROUND(AVG(pi.launch_speed), 1)    AS avg_exit_velo,
    ROUND(AVG(pi.launch_angle), 1)    AS avg_launch_angle,
    COUNT(*)                           AS batted_balls
FROM pitches pi
JOIN players p  ON pi.batter_id  = p.player_id
JOIN teams t    ON p.team_id     = t.team_id
WHERE pi.launch_speed IS NOT NULL
GROUP BY p.player_name, t.team_name
HAVING COUNT(*) >= 50
ORDER BY avg_exit_velo DESC
LIMIT 20;


-- ============================================================
-- TIER 2 — INTERMEDIATE
-- JOINs, CASE WHEN, subqueries
-- ============================================================

-- Query 5: Pitch effectiveness by count — whiff rate in hitter vs. pitcher counts
-- Business question: Do pitchers maintain stuff when behind in the count?
SELECT
    CASE
        WHEN balls = 0 AND strikes = 0 THEN '0-0'
        WHEN balls < strikes           THEN 'Pitcher Count'
        WHEN balls > strikes           THEN 'Hitter Count'
        ELSE 'Even Count'
    END                                                             AS count_type,
    COUNT(*)                                                        AS total_pitches,
    SUM(CASE WHEN description = 'swinging_strike' THEN 1 ELSE 0 END) AS whiffs,
    ROUND(
        100.0 * SUM(CASE WHEN description = 'swinging_strike' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1)                                   AS whiff_pct
FROM pitches
GROUP BY count_type
ORDER BY whiff_pct DESC;


-- Query 6: Pitchers who outperform their FIP (ERA - FIP gap)
-- Business question: Which pitchers benefited most from defense or luck in 2024?
SELECT
    p.player_name,
    t.team_name,
    ps.era,
    ps.fip,
    ROUND(ps.era - ps.fip, 2)   AS era_minus_fip,
    CASE
        WHEN ps.era - ps.fip < -0.50 THEN 'Likely lucky (ERA much better than FIP)'
        WHEN ps.era - ps.fip >  0.50 THEN 'Likely unlucky (ERA much worse than FIP)'
        ELSE 'Expected range'
    END                          AS interpretation
FROM pitcher_season_stats ps
JOIN players p ON ps.player_id = p.player_id
JOIN teams t   ON p.team_id    = t.team_id
WHERE ps.innings_pitched >= 100
ORDER BY era_minus_fip ASC
LIMIT 20;


-- Query 7: Home vs. away performance split for top starters
-- Business question: Do elite pitchers maintain performance on the road?
SELECT
    p.player_name,
    g.venue,
    CASE WHEN pi.pitcher_id = g.home_pitcher_id THEN 'Home' ELSE 'Away' END AS home_away,
    COUNT(DISTINCT g.game_id)                                                 AS games,
    ROUND(AVG(pi.release_speed), 1)                                           AS avg_velo,
    ROUND(
        100.0 * SUM(CASE WHEN pi.description = 'swinging_strike' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1)                                             AS whiff_pct
FROM pitches pi
JOIN players p ON pi.pitcher_id = p.player_id
JOIN games g   ON pi.game_id    = g.game_id
WHERE p.player_id IN (
    -- Subquery: qualify pitchers with 150+ IP
    SELECT player_id
    FROM pitcher_season_stats
    WHERE innings_pitched >= 150
)
GROUP BY p.player_name, g.venue, home_away
ORDER BY p.player_name, home_away;


-- Query 8: Batters with high hard-hit rate but low HR total — power underperformers
-- Business question: Which hitters hit the ball hard but aren't getting results?
SELECT
    p.player_name,
    t.team_name,
    COUNT(*)                                                                AS batted_balls,
    ROUND(
        100.0 * SUM(CASE WHEN pi.launch_speed >= 95 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1)                                          AS hard_hit_pct,
    SUM(CASE WHEN pi.events = 'home_run' THEN 1 ELSE 0 END)               AS home_runs,
    ROUND(AVG(pi.launch_angle), 1)                                         AS avg_launch_angle
FROM pitches pi
JOIN players p ON pi.batter_id = p.player_id
JOIN teams t   ON p.team_id    = t.team_id
WHERE pi.launch_speed IS NOT NULL
GROUP BY p.player_name, t.team_name
HAVING COUNT(*) >= 100
   AND ROUND(
        100.0 * SUM(CASE WHEN pi.launch_speed >= 95 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1) >= 45
   AND SUM(CASE WHEN pi.events = 'home_run' THEN 1 ELSE 0 END) <= 10
ORDER BY hard_hit_pct DESC;


-- ============================================================
-- TIER 3 — ADVANCED
-- CTEs, window functions, rankings
-- ============================================================

-- Query 9: Rolling 7-day strikeout rate for a starting pitcher
-- Business question: Track in-season performance trends over time
WITH daily_stats AS (
    SELECT
        pi.pitcher_id,
        g.game_date,
        COUNT(*)                                                          AS pitches,
        SUM(CASE WHEN pi.events = 'strikeout' THEN 1 ELSE 0 END)        AS strikeouts,
        COUNT(DISTINCT pi.batter_id)                                      AS batters_faced
    FROM pitches pi
    JOIN games g ON pi.game_id = g.game_id
    GROUP BY pi.pitcher_id, g.game_date
)
SELECT
    p.player_name,
    ds.game_date,
    ds.strikeouts,
    ds.batters_faced,
    ROUND(
        100.0 * SUM(ds.strikeouts) OVER (
            PARTITION BY ds.pitcher_id
            ORDER BY ds.game_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )
        / NULLIF(SUM(ds.batters_faced) OVER (
            PARTITION BY ds.pitcher_id
            ORDER BY ds.game_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 0), 1)                                                         AS rolling_7day_k_pct
FROM daily_stats ds
JOIN players p ON ds.pitcher_id = p.player_id
ORDER BY p.player_name, ds.game_date;


-- Query 10: Rank pitchers within each team by Stuff+ score
-- Business question: Who is each team's best pitcher by raw stuff?
WITH pitcher_stuff AS (
    SELECT
        pi.pitcher_id,
        p.player_name,
        p.team_id,
        -- Simplified Stuff+ proxy: normalize predicted run value to 100-scale
        ROUND(
            100 - (
                (AVG(pi.delta_run_exp) - AVG(AVG(pi.delta_run_exp)) OVER ())
                / NULLIF(STDDEV(AVG(pi.delta_run_exp)) OVER (), 0)
                * 10
            ), 1)                   AS stuff_plus,
        COUNT(*)                    AS pitches_thrown
    FROM pitches pi
    JOIN players p ON pi.pitcher_id = p.player_id
    GROUP BY pi.pitcher_id, p.player_name, p.team_id
    HAVING COUNT(*) >= 200
)
SELECT
    t.team_name,
    ps.player_name,
    ps.stuff_plus,
    ps.pitches_thrown,
    RANK() OVER (PARTITION BY ps.team_id ORDER BY ps.stuff_plus DESC) AS team_rank
FROM pitcher_stuff ps
JOIN teams t ON ps.team_id = t.team_id
ORDER BY t.team_name, team_rank;


-- Query 11: Percentile rankings for hitters across key metrics
-- Business question: How does each hitter rank league-wide across multiple dimensions?
WITH hitter_metrics AS (
    SELECT
        pi.batter_id,
        p.player_name,
        t.team_name,
        ROUND(AVG(pi.launch_speed), 1)                                      AS avg_exit_velo,
        ROUND(AVG(pi.launch_angle), 1)                                       AS avg_launch_angle,
        ROUND(
            100.0 * SUM(CASE WHEN pi.launch_speed >= 95 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 1)                                       AS hard_hit_pct,
        COUNT(*)                                                              AS batted_balls
    FROM pitches pi
    JOIN players p ON pi.batter_id = p.player_id
    JOIN teams t   ON p.team_id    = t.team_id
    WHERE pi.launch_speed IS NOT NULL
    GROUP BY pi.batter_id, p.player_name, t.team_name
    HAVING COUNT(*) >= 100
)
SELECT
    player_name,
    team_name,
    avg_exit_velo,
    avg_launch_angle,
    hard_hit_pct,
    ROUND(PERCENT_RANK() OVER (ORDER BY avg_exit_velo)  * 100, 0)  AS exit_velo_percentile,
    ROUND(PERCENT_RANK() OVER (ORDER BY hard_hit_pct)   * 100, 0)  AS hard_hit_percentile
FROM hitter_metrics
ORDER BY exit_velo_percentile DESC
LIMIT 30;


-- Query 12: Year-over-year velocity change by pitcher
-- Business question: Which pitchers gained or lost velocity heading into 2024?
WITH velo_by_year AS (
    SELECT
        pi.pitcher_id,
        EXTRACT(YEAR FROM g.game_date)    AS season,
        ROUND(AVG(pi.release_speed), 1)   AS avg_velo,
        COUNT(*)                           AS fastballs
    FROM pitches pi
    JOIN games g ON pi.game_id = g.game_id
    WHERE pi.pitch_type IN ('FF', 'SI')
    GROUP BY pi.pitcher_id, season
    HAVING COUNT(*) >= 100
)
SELECT
    p.player_name,
    v2023.avg_velo                          AS velo_2023,
    v2024.avg_velo                          AS velo_2024,
    ROUND(v2024.avg_velo - v2023.avg_velo, 1) AS velo_change,
    CASE
        WHEN v2024.avg_velo - v2023.avg_velo >= 1.5  THEN 'Significant gain'
        WHEN v2024.avg_velo - v2023.avg_velo <= -1.5 THEN 'Significant loss'
        ELSE 'Stable'
    END                                     AS trend
FROM velo_by_year v2024
JOIN velo_by_year v2023 ON v2024.pitcher_id = v2023.pitcher_id
                        AND v2023.season = 2023
                        AND v2024.season = 2024
JOIN players p           ON v2024.pitcher_id = p.player_id
ORDER BY velo_change DESC;


-- ============================================================
-- TIER 4 — ANALYTICAL
-- Multi-step business questions, front-office style analysis
-- ============================================================

-- Query 13: Identify breakout hitter candidates — young players with elite contact metrics
-- Business question: Which under-25 hitters show elite batted ball profiles worth targeting?
WITH contact_profile AS (
    SELECT
        pi.batter_id,
        p.player_name,
        p.age,
        t.team_name,
        COUNT(*)                                                              AS batted_balls,
        ROUND(AVG(pi.launch_speed), 1)                                        AS avg_exit_velo,
        ROUND(
            100.0 * SUM(CASE WHEN pi.launch_speed >= 95 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 1)                                        AS hard_hit_pct,
        ROUND(
            100.0 * SUM(CASE WHEN pi.launch_angle BETWEEN 8 AND 32 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 1)                                        AS sweet_spot_pct,
        SUM(CASE WHEN pi.events = 'home_run' THEN 1 ELSE 0 END)             AS home_runs
    FROM pitches pi
    JOIN players p ON pi.batter_id = p.player_id
    JOIN teams t   ON p.team_id    = t.team_id
    WHERE pi.launch_speed IS NOT NULL
    GROUP BY pi.batter_id, p.player_name, p.age, t.team_name
    HAVING COUNT(*) >= 100
)
SELECT
    player_name,
    age,
    team_name,
    avg_exit_velo,
    hard_hit_pct,
    sweet_spot_pct,
    home_runs,
    -- Composite quality score
    ROUND((hard_hit_pct * 0.4) + (sweet_spot_pct * 0.4) + (avg_exit_velo - 85) * 0.2, 1) AS contact_score
FROM contact_profile
WHERE age <= 25
  AND hard_hit_pct  >= 40
  AND sweet_spot_pct >= 30
ORDER BY contact_score DESC
LIMIT 15;


-- Query 14: Bullpen construction analysis — categorize relievers by role and effectiveness
-- Business question: How should a front office prioritize bullpen additions?
WITH reliever_stats AS (
    SELECT
        pi.pitcher_id,
        p.player_name,
        t.team_name,
        COUNT(DISTINCT g.game_id)                                             AS appearances,
        COUNT(*)                                                               AS total_pitches,
        ROUND(AVG(pi.release_speed), 1)                                       AS avg_velo,
        ROUND(
            100.0 * SUM(CASE WHEN pi.description = 'swinging_strike' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 1)                                        AS whiff_pct,
        ROUND(AVG(pi.delta_run_exp) * -1, 4)                                  AS run_value_per_pitch
    FROM pitches pi
    JOIN players p ON pi.pitcher_id = p.player_id
    JOIN teams t   ON p.team_id     = t.team_id
    JOIN games g   ON pi.game_id    = g.game_id
    WHERE p.position = 'RP'
    GROUP BY pi.pitcher_id, p.player_name, t.team_name
    HAVING COUNT(DISTINCT g.game_id) >= 20
),
ranked_relievers AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY run_value_per_pitch DESC) AS performance_quartile
    FROM reliever_stats
)
SELECT
    player_name,
    team_name,
    appearances,
    avg_velo,
    whiff_pct,
    run_value_per_pitch,
    CASE performance_quartile
        WHEN 1 THEN 'Elite — Closer/Setup'
        WHEN 2 THEN 'Above Average — High Leverage'
        WHEN 3 THEN 'Average — Middle Relief'
        WHEN 4 THEN 'Below Average — Roster Decision'
    END AS role_recommendation
FROM ranked_relievers
ORDER BY run_value_per_pitch DESC;


-- Query 15: Full pitcher arsenal report — multi-pitch effectiveness breakdown
-- Business question: Which pitchers have the deepest, most effective arsenals?
WITH pitch_level AS (
    SELECT
        pi.pitcher_id,
        pi.pitch_type,
        COUNT(*)                                                               AS thrown,
        ROUND(AVG(pi.release_speed), 1)                                       AS avg_velo,
        ROUND(AVG(pi.release_spin_rate), 0)                                   AS avg_spin,
        ROUND(AVG(pi.pfx_z), 1)                                               AS avg_ivb,
        ROUND(
            100.0 * SUM(CASE WHEN pi.description = 'swinging_strike' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 1)                                        AS whiff_pct,
        ROUND(AVG(pi.delta_run_exp) * -1, 4)                                  AS run_value_per_pitch
    FROM pitches pi
    GROUP BY pi.pitcher_id, pi.pitch_type
    HAVING COUNT(*) >= 50
),
arsenal_summary AS (
    SELECT
        pl.pitcher_id,
        COUNT(DISTINCT pl.pitch_type)                   AS pitch_types,
        ROUND(AVG(pl.whiff_pct), 1)                     AS avg_whiff_pct,
        ROUND(AVG(pl.run_value_per_pitch), 4)           AS avg_run_value,
        MAX(pl.whiff_pct)                               AS best_pitch_whiff_pct
    FROM pitch_level pl
    GROUP BY pl.pitcher_id
)
SELECT
    p.player_name,
    t.team_name,
    ar.pitch_types,
    ar.avg_whiff_pct,
    ar.best_pitch_whiff_pct,
    ar.avg_run_value,
    RANK() OVER (ORDER BY ar.avg_run_value DESC)        AS arsenal_rank
FROM arsenal_summary ar
JOIN players p ON ar.pitcher_id = p.player_id
JOIN teams t   ON p.team_id     = t.team_id
WHERE ar.pitch_types >= 3
ORDER BY arsenal_rank
LIMIT 25;
