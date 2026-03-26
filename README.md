# ⚾ Baseball Analytics SQL Portfolio

A collection of 15 SQL queries demonstrating analytical depth across MLB Statcast and FanGraphs-style data — from foundational aggregations to front-office-grade multi-step analysis.

---

## 🎯 Purpose

SQL is the primary screening tool for analytics and business intelligence roles. This project demonstrates proficiency across four skill tiers using a realistic baseball database schema that mirrors what you'd find in an MLB organization's data warehouse.

---

## 📁 Repository Structure

```
baseball-analytics-sql/
│
├── baseball_analytics.sql   # All 15 queries — annotated
├── schema.sql               # Full table definitions + indexes
└── README.md                # This file
```

---

## 🗄️ Schema Overview

Four tables modeled after real MLB Statcast + FanGraphs data structures:

| Table | Description | Key Fields |
|-------|-------------|------------|
| `pitches` | One row per pitch — the core fact table | `pitch_type`, `release_speed`, `pfx_z`, `delta_run_exp`, `launch_speed` |
| `players` | Pitcher and hitter metadata | `player_name`, `position`, `age`, `team_id` |
| `games` | Game-level metadata | `game_date`, `venue`, `home_team_id` |
| `teams` | Team info | `team_name`, `league`, `division` |
| `pitcher_season_stats` | Aggregated season stats | `era`, `fip`, `xfip`, `war` |

---

## 📊 Query Index

### Tier 1 — Foundational
*Filtering, aggregation, GROUP BY, HAVING*

| # | Query | Business Question |
|---|-------|------------------|
| 1 | Average fastball velocity by pitcher | Who threw the hardest in 2024? |
| 2 | Strikeout and walk rates by team | Which teams had the best pitching discipline? |
| 3 | Pitch type usage breakdown | How is pitch mix distributed across MLB? |
| 4 | Top hitters by average exit velocity | Who made the hardest contact in 2024? |

### Tier 2 — Intermediate
*JOINs, CASE WHEN, subqueries, NULLIF*

| # | Query | Business Question |
|---|-------|------------------|
| 5 | Whiff rate by count type | Do pitchers maintain stuff when behind in the count? |
| 6 | ERA vs FIP gap — luck indicator | Which pitchers over/underperformed their peripherals? |
| 7 | Home vs. away performance split | Do elite pitchers hold up on the road? |
| 8 | High hard-hit rate, low HR — power underperformers | Which hitters are hitting it hard but not getting results? |

### Tier 3 — Advanced
*CTEs, window functions, RANK, PERCENT_RANK, rolling aggregations*

| # | Query | Business Question |
|---|-------|------------------|
| 9 | Rolling 7-day strikeout rate | Track in-season pitcher performance trends |
| 10 | Rank pitchers within each team by Stuff+ | Who is each team's best pitcher by raw stuff? |
| 11 | Percentile rankings across hitter metrics | How does each hitter rank league-wide? |
| 12 | Year-over-year velocity change | Which pitchers gained or lost velo in 2024? |

### Tier 4 — Analytical
*Multi-step CTEs, composite scoring, front-office style questions*

| # | Query | Business Question |
|---|-------|------------------|
| 13 | Breakout hitter candidates (age ≤ 25) | Which young hitters show elite contact profiles worth targeting? |
| 14 | Bullpen role classification | How should a front office prioritize bullpen additions? |
| 15 | Full pitcher arsenal report | Which pitchers have the deepest, most effective arsenals? |

---

## 🔑 Key Concepts Demonstrated

- **Aggregation & filtering**: `GROUP BY`, `HAVING`, `NULLIF` for safe division
- **Conditional logic**: `CASE WHEN` for count states, luck indicators, role classification
- **Multi-table JOINs**: Joining fact and dimension tables across 4+ tables
- **Subqueries**: Inline qualification filters (e.g., pitchers with 150+ IP)
- **CTEs**: Multi-step logic broken into readable, reusable blocks
- **Window functions**: `RANK()`, `PERCENT_RANK()`, `NTILE()`, rolling aggregations with `ROWS BETWEEN`
- **Composite scoring**: Weighted metric combinations for player evaluation
- **Business framing**: Every query answers a front-office decision, not just a data question

---

## 📐 Metrics Reference

| Metric | Definition |
|--------|-----------|
| `delta_run_exp` | Change in run expectancy per pitch (Statcast) — core pitch value signal |
| `pfx_z` | Induced vertical break — how much a pitch rises or drops vs. gravity |
| `pfx_x` | Horizontal movement — arm-side or glove-side break |
| `launch_speed` | Exit velocity off the bat (mph) |
| `launch_angle` | Vertical angle off the bat (degrees) — 8–32° is the "sweet spot" |
| `FIP` | Fielding Independent Pitching — ERA based only on K, BB, HR (removes defense) |
| `xFIP` | Expected FIP — normalizes HR rate to league average |
| `WAR` | Wins Above Replacement — overall player value |
| `whiff_pct` | Swinging strikes / total pitches — pure swing-and-miss rate |
| `hard_hit_pct` | % of batted balls at 95+ mph exit velocity |

---

## 🛠️ Running the Queries

These queries are written in standard SQL and are compatible with PostgreSQL, MySQL, SQLite, BigQuery, and Snowflake with minimal adjustment.

To run locally:
1. Set up a local database (PostgreSQL recommended)
2. Run `schema.sql` to create tables
3. Load your own Statcast data via `pybaseball` or use the [Baseball Savant bulk download](https://baseballsavant.mlb.com/statcast_search)
4. Run individual queries from `baseball_analytics.sql`

> **Note:** Queries reference real Statcast field names. Data can be pulled directly using the `pybaseball` library — see the companion [Stuff+ Model repo](https://github.com/jordantaylorkurzweil-hash/stuff-plus-model) for the data pipeline.

---

## 🙋 About

**Jordan Kurzweil**
M.S. Business Administration candidate, Pace University (Lubin School of Business) — August 2026
Google Data Analytics Certificate · SABR Analytics Certification Levels I–IV
[LinkedIn](https://linkedin.com/in/YOUR_LINKEDIN) · [GitHub](https://github.com/jordantaylorkurzweil-hash)

---

*Schema modeled after MLB Statcast data available at [baseballsavant.mlb.com](https://baseballsavant.mlb.com). Queries written in standard SQL.*
