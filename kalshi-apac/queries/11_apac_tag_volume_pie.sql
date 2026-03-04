-- 11. APAC Tag % by Volume
-- 목적: APAC 태그별 거래량 비중 (Probable 스타일 Pie Chart)
-- 차트: Pie chart (x=apac_tag, y=volume_pct)
--
-- 출력 컬럼:
--   apac_tag, total_volume, volume_pct
--
-- 테이블: kalshi.trade_report

WITH apac_classified AS (
    SELECT
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
),

tag_totals AS (
    SELECT
        apac_tag,
        SUM(contracts_traded) AS total_volume,
        COUNT(*) AS trade_count
    FROM apac_classified
    WHERE apac_tag IS NOT NULL
    GROUP BY 1
),

grand_total AS (
    SELECT SUM(total_volume) AS grand_vol FROM tag_totals
)

SELECT
    t.apac_tag,
    t.total_volume,
    t.trade_count,
    ROUND(t.total_volume * 100.0 / NULLIF(gt.grand_vol, 0), 1) AS volume_pct
FROM tag_totals t
CROSS JOIN grand_total gt
ORDER BY t.total_volume DESC
