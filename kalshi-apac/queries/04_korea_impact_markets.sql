-- 04. Korea-Impact Markets
-- 목적: 한국 경제에 영향을 미치는 마켓의 거래량 비교
-- 차트: Bar Chart (Horizontal)
--
-- 출력 컬럼:
--   market_label, impact_level, total_volume, latest_yes_price
--
-- 테이블: kalshi.trade_report
--
-- Dune 차트 설정:
--   Visualization → Bar Chart
--   X-axis: market_label
--   Y-axis: total_volume
--   Group by: impact_level
--   Sort: Y-axis descending
--   Horizontal 추천 (라벨 길이 때문)

WITH classified AS (
    SELECT
        report_ticker,
        ticker_name,
        price,
        contracts_traded,
        date,
        CASE
            WHEN LOWER(ticker_name) LIKE '%korea%'
              OR LOWER(ticker_name) LIKE '%bts %'
              OR LOWER(ticker_name) LIKE '%kpop%'
              OR LOWER(ticker_name) LIKE '%k-pop%'
                THEN 'HIGH'
            WHEN LOWER(ticker_name) LIKE '%tariff%'
              OR LOWER(ticker_name) LIKE '%china tariff%'
              OR LOWER(ticker_name) LIKE '%china trade%'
                THEN 'HIGH'
            WHEN LOWER(ticker_name) LIKE '%fed %'
              OR LOWER(ticker_name) LIKE '%federal reserve%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
              OR LOWER(ticker_name) LIKE '%oil price%'
              OR LOWER(ticker_name) LIKE '%crude oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
              OR LOWER(ticker_name) LIKE '%recession%'
                THEN 'MEDIUM'
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
              OR LOWER(ticker_name) LIKE '%s&p 500%'
              OR LOWER(ticker_name) LIKE '%s&p500%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
              OR LOWER(ticker_name) LIKE '%cpi %'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN 'LOW'
        END AS impact_level
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
),

market_agg AS (
    SELECT
        report_ticker,
        impact_level,
        SUM(contracts_traded) AS total_volume,
        COUNT(*) AS trade_count
    FROM classified
    WHERE impact_level IS NOT NULL
    GROUP BY report_ticker, impact_level
),

latest AS (
    SELECT
        report_ticker,
        price AS latest_yes_price,
        ROW_NUMBER() OVER (PARTITION BY report_ticker ORDER BY date DESC) AS rn
    FROM classified
    WHERE impact_level IS NOT NULL
),

ranked AS (
    SELECT
        ma.report_ticker,
        ma.impact_level,
        ma.total_volume,
        ma.trade_count,
        l.latest_yes_price,
        ROW_NUMBER() OVER (
            PARTITION BY ma.impact_level
            ORDER BY ma.total_volume DESC
        ) AS level_rank
    FROM market_agg ma
    LEFT JOIN latest l
        ON ma.report_ticker = l.report_ticker
        AND l.rn = 1
)

SELECT
    -- 막대 라벨용: ticker 짧게 자르기
    SUBSTR(report_ticker, 3) AS market_label,
    impact_level,
    total_volume,
    latest_yes_price,
    trade_count
FROM ranked
WHERE level_rank <= 5
ORDER BY
    CASE impact_level
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
    END,
    total_volume DESC
