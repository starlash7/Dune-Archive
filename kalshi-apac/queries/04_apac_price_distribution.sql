-- 04. APAC Price Distribution Heatmap
-- 목적: APAC 마켓의 가격대별 거래량 분포
-- 차트: Heatmap (x=price_bucket, y=apac_tag, value=total_volume)
--
-- 출력 컬럼:
--   price_bucket, apac_tag, total_volume, trade_count, avg_contracts
--
-- 테이블: kalshi.trade_report
-- 힌트: price를 10단위 버킷으로 분류 (0-9, 10-19, ..., 90-99)
--        price=1~99 센트 (Yes 가격 기준)

WITH apac_classified AS (
    SELECT
        price,
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
    WHERE price BETWEEN 1 AND 99
)

SELECT
    CAST(FLOOR(price / 10) * 10 AS INT) AS price_bucket_start,
    CAST(FLOOR(price / 10) * 10 + 9 AS INT) AS price_bucket_end,
    CONCAT(
        CAST(FLOOR(price / 10) * 10 AS VARCHAR),
        '-',
        CAST(FLOOR(price / 10) * 10 + 9 AS VARCHAR),
        '¢'
    ) AS price_bucket,
    apac_tag,
    SUM(contracts_traded) AS total_volume,
    COUNT(*) AS trade_count,
    AVG(contracts_traded) AS avg_contracts
FROM apac_classified
WHERE apac_tag IS NOT NULL
GROUP BY FLOOR(price / 10), apac_tag
ORDER BY price_bucket_start, apac_tag
