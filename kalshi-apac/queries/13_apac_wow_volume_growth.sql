-- 13. APAC Week-over-Week Volume Growth Rate
-- Purpose: Weekly volume growth rate for APAC markets by tag
--          Similar to Base Agentic dashboard's WoW Growth Rate chart
-- Charts:
--   1) Line Chart  -> X: week_start, Y: wow_growth_pct, Color: apac_tag
--   2) Column Chart -> X: week_start, Y: weekly_volume, Color: apac_tag
--   3) Counter     -> latest week's overall growth rate
--
-- Output columns:
--   week_start, apac_tag, weekly_volume, prev_week_volume,
--   wow_growth_pct, cumulative_volume, pct_of_total

WITH apac_classified AS (
    SELECT
        date,
        contracts_traded,
        report_ticker,
        ticker_name,
        CASE
            WHEN LOWER(ticker_name) LIKE '%tariff%'
              OR LOWER(ticker_name) LIKE '%china%'
              OR LOWER(ticker_name) LIKE '%prc%'
              OR LOWER(ticker_name) LIKE '%korea%'
              OR LOWER(ticker_name) LIKE '%bts%'
              OR LOWER(ticker_name) LIKE '%kpop%'
              OR LOWER(ticker_name) LIKE '%k-pop%'
                THEN 'Korea/China Trade'
            WHEN LOWER(ticker_name) LIKE '%fed%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
              OR LOWER(ticker_name) LIKE '%oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
              OR LOWER(ticker_name) LIKE '%recession%'
                THEN 'Fed/Oil/Macro'
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
              OR LOWER(ticker_name) LIKE '%s&p%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
              OR LOWER(ticker_name) LIKE '%cpi%'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN 'Crypto/Equity'
        END AS apac_tag
    FROM kalshi.trade_report
    WHERE date >= DATE '2025-01-01'
),

weekly_by_tag AS (
    SELECT
        DATE_TRUNC('week', date) AS week_start,
        apac_tag,
        SUM(contracts_traded) AS weekly_volume,
        COUNT(*) AS weekly_trades,
        COUNT(DISTINCT report_ticker) AS active_markets
    FROM apac_classified
    WHERE apac_tag IS NOT NULL
    GROUP BY DATE_TRUNC('week', date), apac_tag
),

with_lag AS (
    SELECT
        week_start,
        apac_tag,
        weekly_volume,
        weekly_trades,
        active_markets,
        LAG(weekly_volume) OVER (
            PARTITION BY apac_tag ORDER BY week_start
        ) AS prev_week_volume,
        SUM(weekly_volume) OVER (
            PARTITION BY apac_tag ORDER BY week_start
        ) AS cumulative_volume
    FROM weekly_by_tag
),

weekly_total AS (
    SELECT
        week_start,
        SUM(weekly_volume) AS total_volume
    FROM weekly_by_tag
    GROUP BY week_start
)

SELECT
    wl.week_start,
    wl.apac_tag,
    wl.weekly_volume,
    wl.weekly_trades,
    wl.active_markets,
    wl.prev_week_volume,
    CASE
        WHEN wl.prev_week_volume > 0
        THEN ROUND(
            (CAST(wl.weekly_volume AS DOUBLE) - wl.prev_week_volume)
            / wl.prev_week_volume * 100, 1
        )
        ELSE NULL
    END AS wow_growth_pct,
    wl.cumulative_volume,
    ROUND(
        CAST(wl.weekly_volume AS DOUBLE) / NULLIF(wt.total_volume, 0) * 100, 1
    ) AS pct_of_total
FROM with_lag wl
JOIN weekly_total wt ON wl.week_start = wt.week_start
ORDER BY wl.week_start DESC, wl.apac_tag
