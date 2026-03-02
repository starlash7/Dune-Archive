-- 02. APAC Daily Volume Trend
-- 목적: APAC 관련 마켓의 일별 거래량 추이
-- 차트: Area Chart (x=date, y=daily_volume, color=apac_tag)
--
-- 출력 컬럼:
--   date, apac_tag, daily_volume, trade_count
--
-- 테이블: kalshi.trade_report
-- 키워드 매핑: 00_apac_market_registry 와 동일

WITH apac_classified AS (
    SELECT
        date,
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
                THEN 'HIGH'
            WHEN LOWER(ticker_name) LIKE '%fed%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
              OR LOWER(ticker_name) LIKE '%oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
              OR LOWER(ticker_name) LIKE '%recession%'
                THEN 'MEDIUM'
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
              OR LOWER(ticker_name) LIKE '%s&p%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
              OR LOWER(ticker_name) LIKE '%cpi%'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN 'LOW'
        END AS apac_tag
    FROM kalshi.trade_report
)

SELECT
    date,
    apac_tag,
    SUM(contracts_traded) AS daily_volume,
    COUNT(*) AS trade_count
FROM apac_classified
WHERE apac_tag IS NOT NULL
GROUP BY date, apac_tag
ORDER BY date DESC, apac_tag
