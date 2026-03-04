-- 05. China Tariff Tracker
-- 목적: 중국 관세율 관련 Top 마켓의 일별 odds(가격) 추이
-- 차트: Line Chart (x=date, y=avg_yes_price, color=market_label)
--
-- 출력 컬럼:
--   date, market_label, avg_yes_price, daily_volume
--
-- 테이블: kalshi.trade_report
--
-- Dune 차트 설정:
--   Visualization → Line Chart
--   X-axis: date
--   Y-axis: avg_yes_price
--   Group by: market_label
--   Sort: X-axis ascending

WITH china_tariff AS (
    SELECT
        report_ticker,
        ticker_name,
        date,
        price,
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
    ct.date,
    -- 라벨을 짧게: ticker_name이 너무 길면 40자까지만
    SUBSTR(tm.ticker_name, 1, 40) AS market_label,
    AVG(ct.price) AS avg_yes_price,
    SUM(ct.contracts_traded) AS daily_volume
FROM china_tariff ct
INNER JOIN top_markets tm
    ON ct.report_ticker = tm.report_ticker
GROUP BY ct.date, tm.ticker_name
ORDER BY ct.date
