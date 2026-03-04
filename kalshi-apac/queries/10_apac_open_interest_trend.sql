-- 10. APAC Open Interest Trend
-- 목적: APAC 마켓의 일별 Open Interest 추이 (포지션 진입/이탈 신호)
-- 차트: Line Chart (X: date, Y: daily_oi, color: apac_tag)
-- 테이블: kalshi.trade_report

WITH apac_oi AS (
    SELECT
        date,
        report_ticker,
        ticker_name,
        open_interest,
        contracts_traded,
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

daily_agg AS (
    SELECT
        date,
        apac_tag,
        SUM(open_interest) AS daily_oi,
        SUM(contracts_traded) AS daily_volume,
        COUNT(DISTINCT report_ticker) AS market_count
    FROM apac_oi
    WHERE apac_tag IS NOT NULL
    GROUP BY date, apac_tag
),

with_change AS (
    SELECT
        date,
        apac_tag,
        daily_oi,
        daily_volume,
        market_count,
        daily_oi - LAG(daily_oi) OVER (
            PARTITION BY apac_tag ORDER BY date
        ) AS oi_change,
        ROUND(
            CAST(daily_oi - LAG(daily_oi) OVER (
                PARTITION BY apac_tag ORDER BY date
            ) AS DOUBLE) / NULLIF(LAG(daily_oi) OVER (
                PARTITION BY apac_tag ORDER BY date
            ), 0) * 100,
            1
        ) AS oi_change_pct
    FROM daily_agg
)

SELECT
    date,
    apac_tag,
    daily_oi,
    oi_change,
    oi_change_pct,
    daily_volume,
    market_count
FROM with_change
ORDER BY date DESC, apac_tag
