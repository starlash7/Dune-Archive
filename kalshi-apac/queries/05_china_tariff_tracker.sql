-- 05. China Tariff Tracker
-- 목적: 중국 관세 관련 Top 마켓의 일별 거래량 흐름 (Stacked Area)
-- 차트: Area Chart (Stacked 100%)
--
-- 출력 컬럼:
--   trade_week, market_label, weekly_volume
--
-- 테이블: kalshi.trade_report
--
-- Dune 차트 설정:
--   Visualization → Area Chart
--   X-axis: trade_week
--   Y-axis: weekly_volume
--   Group by: market_label
--   Stacking: Percent (100%)
--   Sort: X-axis ascending

WITH china_tariff AS (
    SELECT
        report_ticker,
        ticker_name,
        date,
        contracts_traded
    FROM kalshi.trade_report
    WHERE (
        LOWER(ticker_name) LIKE '%tariff%'
        AND (
            LOWER(ticker_name) LIKE '%china%'
            OR LOWER(ticker_name) LIKE '%prc%'
        )
    )
    AND price BETWEEN 1 AND 99
),

-- 거래량 기준 Top 5 마켓만 선별
top_markets AS (
    SELECT
        report_ticker,
        MIN(ticker_name) AS ticker_name,
        SUM(contracts_traded) AS total_vol
    FROM china_tariff
    GROUP BY report_ticker
    ORDER BY total_vol DESC
    LIMIT 5
)

SELECT
    DATE_TRUNC('week', ct.date) AS trade_week,
    SUBSTR(tm.ticker_name, 1, 30) AS market_label,
    SUM(ct.contracts_traded) AS weekly_volume
FROM china_tariff ct
INNER JOIN top_markets tm
    ON ct.report_ticker = tm.report_ticker
GROUP BY DATE_TRUNC('week', ct.date), tm.ticker_name
ORDER BY trade_week
