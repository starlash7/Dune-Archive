-- 16. APAC Volume Share vs Total Kalshi
-- Purpose: How much of total Kalshi volume is APAC-relevant?
--          Like Base dashboard's "Market Share" counter + trend chart
-- Charts:
--   1) Area Chart (Stacked %) -> X: week_start, Y: pct values, two series (APAC / Non-APAC)
--   2) Counter                -> Latest week APAC share %
--   3) Line Chart             -> X: week_start, Y: apac_share_pct (single line trend)
--   4) Column Chart           -> X: week_start, Y: apac_volume + non_apac_volume (stacked)
--
-- Output columns:
--   week_start, total_kalshi_volume, apac_volume, non_apac_volume,
--   apac_share_pct, apac_trade_count, total_trade_count,
--   apac_market_count, wow_share_change

WITH all_trades AS (
    SELECT
        DATE_TRUNC('week', date) AS week_start,
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
              OR LOWER(ticker_name) LIKE '%fed%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
              OR LOWER(ticker_name) LIKE '%oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
              OR LOWER(ticker_name) LIKE '%recession%'
              OR LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
              OR LOWER(ticker_name) LIKE '%s&p%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
              OR LOWER(ticker_name) LIKE '%cpi%'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN 1
            ELSE 0
        END AS is_apac
    FROM kalshi.trade_report
    WHERE date >= DATE '2025-01-01'
),

weekly_agg AS (
    SELECT
        week_start,
        SUM(contracts_traded) AS total_kalshi_volume,
        SUM(CASE WHEN is_apac = 1 THEN contracts_traded ELSE 0 END) AS apac_volume,
        SUM(CASE WHEN is_apac = 0 THEN contracts_traded ELSE 0 END) AS non_apac_volume,
        COUNT(*) AS total_trade_count,
        SUM(CASE WHEN is_apac = 1 THEN 1 ELSE 0 END) AS apac_trade_count,
        COUNT(DISTINCT CASE WHEN is_apac = 1 THEN report_ticker END) AS apac_market_count
    FROM all_trades
    GROUP BY week_start
),

with_share AS (
    SELECT
        week_start,
        total_kalshi_volume,
        apac_volume,
        non_apac_volume,
        ROUND(
            CAST(apac_volume AS DOUBLE) / NULLIF(total_kalshi_volume, 0) * 100, 1
        ) AS apac_share_pct,
        apac_trade_count,
        total_trade_count,
        apac_market_count,
        LAG(
            ROUND(CAST(apac_volume AS DOUBLE) / NULLIF(total_kalshi_volume, 0) * 100, 1)
        ) OVER (ORDER BY week_start) AS prev_week_share
    FROM weekly_agg
)

SELECT
    week_start,
    total_kalshi_volume,
    apac_volume,
    non_apac_volume,
    apac_share_pct,
    apac_trade_count,
    total_trade_count,
    apac_market_count,
    ROUND(apac_share_pct - COALESCE(prev_week_share, apac_share_pct), 1) AS wow_share_change
FROM with_share
ORDER BY week_start DESC
