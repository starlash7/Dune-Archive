-- 12. APAC Tag % by Trades
-- 목적: APAC 태그별 트레이드 건수 비중 (Probable 스타일 Pie Chart)
-- 차트: Pie chart (x=apac_tag, y=trades_pct)
--
-- 출력 컬럼:
--   apac_tag, trade_count, trades_pct
--
-- 테이블: kalshi.trade_report

WITH apac_classified AS (
    SELECT
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
),

tag_counts AS (
    SELECT
        apac_tag,
        COUNT(*) AS trade_count
    FROM apac_classified
    WHERE apac_tag IS NOT NULL
    GROUP BY 1
),

grand_total AS (
    SELECT SUM(trade_count) AS total_trades FROM tag_counts
)

SELECT
    t.apac_tag,
    t.trade_count,
    ROUND(t.trade_count * 100.0 / NULLIF(gt.total_trades, 0), 1) AS trades_pct
FROM tag_counts t
CROSS JOIN grand_total gt
ORDER BY t.trade_count DESC
