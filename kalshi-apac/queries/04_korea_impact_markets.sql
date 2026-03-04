-- 04. Korea-Impact Markets
-- 목적: 한국 경제에 영향을 미치는 이슈 카테고리별 거래량
-- 차트: Bar Chart
--
-- 출력 컬럼:
--   impact_category, total_volume, market_count, avg_yes_price
--
-- 테이블: kalshi.trade_report
--
-- Dune 차트 설정:
--   Visualization → Bar Chart
--   X-axis: impact_category
--   Y-axis: total_volume
--   Group by: (없음)
--   Sort: Y-axis descending

WITH classified AS (
    SELECT
        report_ticker,
        contracts_traded,
        price,
        date,
        CASE
            WHEN LOWER(ticker_name) LIKE '%korea%'
                THEN 'Korea Direct'
            WHEN LOWER(ticker_name) LIKE '%bts %'
              OR LOWER(ticker_name) LIKE '%kpop%'
              OR LOWER(ticker_name) LIKE '%k-pop%'
                THEN 'K-Pop / Culture'
            WHEN LOWER(ticker_name) LIKE '%tariff%'
                THEN 'Tariff / Trade War'
            WHEN LOWER(ticker_name) LIKE '%china%'
                THEN 'China Risk'
            WHEN LOWER(ticker_name) LIKE '%fed %'
              OR LOWER(ticker_name) LIKE '%federal reserve%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
                THEN 'Fed / Interest Rate'
            WHEN LOWER(ticker_name) LIKE '%oil price%'
              OR LOWER(ticker_name) LIKE '%crude oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
                THEN 'Oil / Energy'
            WHEN LOWER(ticker_name) LIKE '%recession%'
                THEN 'US Recession'
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
                THEN 'Crypto'
            WHEN LOWER(ticker_name) LIKE '%s&p 500%'
              OR LOWER(ticker_name) LIKE '%s&p500%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
                THEN 'US Equities'
            WHEN LOWER(ticker_name) LIKE '%cpi %'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN 'Inflation / CPI'
        END AS impact_category
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
)

SELECT
    impact_category,
    SUM(contracts_traded) AS total_volume,
    COUNT(DISTINCT report_ticker) AS market_count,
    ROUND(AVG(price), 1) AS avg_yes_price
FROM classified
WHERE impact_category IS NOT NULL
GROUP BY impact_category
ORDER BY total_volume DESC
