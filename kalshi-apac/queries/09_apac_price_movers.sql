-- 09. APAC Price Movers Top 20
-- 목적: 최근 30일간 가격 변동이 큰 APAC 마켓 랭킹
-- 차트: Table + Bar Chart (X: ticker_name, Y: price_change)
-- 테이블: kalshi.trade_report

WITH recent_trades AS (
    SELECT
        report_ticker,
        ticker_name,
        date,
        price,
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
    WHERE date >= CURRENT_DATE - INTERVAL '30' DAY
      AND price BETWEEN 1 AND 99
),

first_last AS (
    SELECT
        report_ticker,
        ticker_name,
        apac_tag,
        -- 기간 내 첫 거래 가격
        MIN(price) AS period_low,
        MAX(price) AS period_high,
        -- 첫날 평균가 vs 마지막날 평균가
        SUM(contracts_traded) AS total_volume,
        COUNT(*) AS trade_count,
        MIN(date) AS first_date,
        MAX(date) AS last_date
    FROM recent_trades
    WHERE apac_tag IS NOT NULL
    GROUP BY report_ticker, ticker_name, apac_tag
),

with_direction AS (
    SELECT
        f.*,
        -- 첫날 가중평균가
        (SELECT ROUND(AVG(r.price), 1)
         FROM recent_trades r
         WHERE r.report_ticker = f.report_ticker
           AND r.date = f.first_date
        ) AS start_price,
        -- 마지막날 가중평균가
        (SELECT ROUND(AVG(r.price), 1)
         FROM recent_trades r
         WHERE r.report_ticker = f.report_ticker
           AND r.date = f.last_date
        ) AS end_price
    FROM first_last f
    WHERE total_volume >= 1000
),

ranked AS (
    SELECT
        *,
        end_price - start_price AS price_change,
        period_high - period_low AS price_range,
        ROW_NUMBER() OVER (
            ORDER BY ABS(end_price - start_price) DESC
        ) AS rank
    FROM with_direction
)

SELECT
    rank,
    ticker_name,
    report_ticker,
    apac_tag,
    start_price,
    end_price,
    price_change,
    CASE
        WHEN price_change > 0 THEN '▲'
        WHEN price_change < 0 THEN '▼'
        ELSE '—'
    END AS direction,
    period_low,
    period_high,
    price_range,
    total_volume,
    trade_count,
    first_date,
    last_date
FROM ranked
WHERE rank <= 20
ORDER BY rank ASC
