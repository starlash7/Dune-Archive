-- 15. APAC Tag Trend Shift
-- Purpose: Shows how APAC tag dominance shifts over time
--          Which theme (tariff vs crypto vs fed) is gaining/losing attention?
-- Charts:
--   1) Area Chart (Stacked %) -> X: week_start, Y: pct_share, Color: apac_tag
--      (like Base dashboard's "Volume Market Share Trend")
--   2) Line Chart             -> X: week_start, Y: wow_growth_pct, Color: apac_tag
--   3) Heatmap/Table          -> week_start x apac_tag = weekly_volume
--
-- Output columns:
--   week_start, apac_tag, weekly_volume, weekly_trades, active_markets,
--   pct_share, wow_growth_pct, rolling_4w_avg

WITH apac_classified AS (
    SELECT
        date,
        contracts_traded,
        report_ticker,
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

weekly_total AS (
    SELECT
        week_start,
        SUM(weekly_volume) AS total_weekly_volume
    FROM weekly_by_tag
    GROUP BY week_start
),

with_metrics AS (
    SELECT
        w.week_start,
        w.apac_tag,
        w.weekly_volume,
        w.weekly_trades,
        w.active_markets,
        -- Market share %
        ROUND(
            CAST(w.weekly_volume AS DOUBLE) / NULLIF(wt.total_weekly_volume, 0) * 100, 1
        ) AS pct_share,
        -- WoW growth
        LAG(w.weekly_volume) OVER (
            PARTITION BY w.apac_tag ORDER BY w.week_start
        ) AS prev_week_volume,
        -- 4-week rolling average
        ROUND(
            AVG(CAST(w.weekly_volume AS DOUBLE)) OVER (
                PARTITION BY w.apac_tag
                ORDER BY w.week_start
                ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
            ), 0
        ) AS rolling_4w_avg
    FROM weekly_by_tag w
    JOIN weekly_total wt ON w.week_start = wt.week_start
)

SELECT
    week_start,
    apac_tag,
    weekly_volume,
    weekly_trades,
    active_markets,
    pct_share,
    CASE
        WHEN prev_week_volume > 0
        THEN ROUND(
            (CAST(weekly_volume AS DOUBLE) - prev_week_volume)
            / prev_week_volume * 100, 1
        )
        ELSE NULL
    END AS wow_growth_pct,
    rolling_4w_avg
FROM with_metrics
ORDER BY week_start DESC, pct_share DESC
