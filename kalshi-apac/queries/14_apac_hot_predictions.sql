-- 14. APAC Hot Predictions Leaderboard
-- Purpose: Rank APAC-relevant markets by recent momentum
--          Shows which predictions are trending NOW
-- Charts:
--   1) Table        -> Full leaderboard with all columns
--   2) Bar Chart    -> X: ticker_name, Y: activity_score (top 15)
--   3) Counter      -> #1 hottest market ticker_name
--
-- Scoring: Activity Score = 40% volume_7d + 30% trades_7d + 30% oi_current
--          Each normalized to top performer (0-100 scale)
--
-- Output columns:
--   rank, ticker_name, report_ticker, apac_tag, impact_level,
--   volume_7d, volume_30d, trades_7d, oi_current,
--   wow_volume_chg_pct, latest_price, activity_score

WITH apac_trades AS (
    SELECT
        date,
        report_ticker,
        ticker_name,
        contracts_traded,
        open_interest,
        price,
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
        END AS apac_tag,
        CASE
            WHEN LOWER(ticker_name) LIKE '%tariff%'
              OR LOWER(ticker_name) LIKE '%china%'
              OR LOWER(ticker_name) LIKE '%prc%'
              OR LOWER(ticker_name) LIKE '%korea%'
                THEN 'HIGH'
            WHEN LOWER(ticker_name) LIKE '%fed%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
              OR LOWER(ticker_name) LIKE '%oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
              OR LOWER(ticker_name) LIKE '%recession%'
                THEN 'MEDIUM'
            ELSE 'LOW'
        END AS impact_level
    FROM kalshi.trade_report
    WHERE date >= CURRENT_DATE - INTERVAL '30' DAY
      AND price BETWEEN 1 AND 99
),

apac_only AS (
    SELECT * FROM apac_trades WHERE apac_tag IS NOT NULL
),

-- 7-day and 30-day aggregates per market
market_stats AS (
    SELECT
        report_ticker,
        MAX(ticker_name) AS ticker_name,
        MAX(apac_tag) AS apac_tag,
        MAX(impact_level) AS impact_level,
        -- 7d metrics
        SUM(CASE WHEN date >= CURRENT_DATE - INTERVAL '7' DAY
            THEN contracts_traded ELSE 0 END) AS volume_7d,
        SUM(CASE WHEN date >= CURRENT_DATE - INTERVAL '7' DAY
            THEN 1 ELSE 0 END) AS trades_7d,
        -- 30d metrics
        SUM(contracts_traded) AS volume_30d,
        COUNT(*) AS trades_30d,
        -- Previous 7d (for WoW comparison)
        SUM(CASE WHEN date >= CURRENT_DATE - INTERVAL '14' DAY
                  AND date < CURRENT_DATE - INTERVAL '7' DAY
            THEN contracts_traded ELSE 0 END) AS volume_prev_7d,
        -- Latest OI and price
        MAX(open_interest) AS oi_current,
        -- Latest price (from most recent trade)
        MAX_BY(price, date) AS latest_price,
        MAX(date) AS last_trade_date
    FROM apac_only
    GROUP BY report_ticker
    HAVING SUM(CASE WHEN date >= CURRENT_DATE - INTERVAL '7' DAY
               THEN contracts_traded ELSE 0 END) > 0
),

-- Normalize for scoring
scored AS (
    SELECT
        *,
        -- WoW change
        CASE
            WHEN volume_prev_7d > 0
            THEN ROUND(
                (CAST(volume_7d AS DOUBLE) - volume_prev_7d)
                / volume_prev_7d * 100, 1
            )
            ELSE NULL
        END AS wow_volume_chg_pct,
        -- Activity Score: 40% volume + 30% trades + 30% OI
        ROUND(
            40.0 * volume_7d / NULLIF(MAX(volume_7d) OVER (), 0)
          + 30.0 * trades_7d / NULLIF(MAX(trades_7d) OVER (), 0)
          + 30.0 * oi_current / NULLIF(MAX(oi_current) OVER (), 0)
        , 1) AS activity_score
    FROM market_stats
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY activity_score DESC) AS rank
    FROM scored
)

SELECT
    rank,
    ticker_name,
    report_ticker,
    apac_tag,
    impact_level,
    volume_7d,
    volume_30d,
    trades_7d,
    oi_current,
    wow_volume_chg_pct,
    latest_price,
    last_trade_date,
    activity_score
FROM ranked
WHERE rank <= 25
ORDER BY rank ASC
