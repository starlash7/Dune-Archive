-- 00. APAC Market Registry
-- 목적: APAC 관련 마켓을 키워드로 분류하는 기반 쿼리
-- 차트: Table
--
-- 출력 컬럼:
--   ticker, title, category, apac_tag, impact_level, volume, status
--
-- 테이블: kalshi.market_report

SELECT
    ticker,
    title,
    category,
    CASE
        WHEN LOWER(title) LIKE '%tariff%'
          OR LOWER(title) LIKE '%china%'
          OR LOWER(title) LIKE '%prc%'
          OR LOWER(title) LIKE '%korea%'
          OR LOWER(title) LIKE '%bts%'
          OR LOWER(title) LIKE '%kpop%'
          OR LOWER(title) LIKE '%k-pop%'
            THEN 'Korea/China Trade'
        WHEN LOWER(title) LIKE '%fed%'
          OR LOWER(title) LIKE '%interest rate%'
          OR LOWER(title) LIKE '%oil%'
          OR LOWER(title) LIKE '%wti%'
          OR LOWER(title) LIKE '%recession%'
            THEN 'Fed/Oil/Macro'
        WHEN LOWER(title) LIKE '%bitcoin%'
          OR LOWER(title) LIKE '%ethereum%'
          OR LOWER(title) LIKE '%crypto%'
          OR LOWER(title) LIKE '%s&p%'
          OR LOWER(title) LIKE '%nasdaq%'
          OR LOWER(title) LIKE '%cpi%'
          OR LOWER(title) LIKE '%inflation%'
            THEN 'Crypto/Equity'
    END AS apac_tag,
    CASE
        WHEN LOWER(title) LIKE '%tariff%'
          OR LOWER(title) LIKE '%china%'
          OR LOWER(title) LIKE '%prc%'
          OR LOWER(title) LIKE '%korea%'
          OR LOWER(title) LIKE '%bts%'
          OR LOWER(title) LIKE '%kpop%'
          OR LOWER(title) LIKE '%k-pop%'
            THEN 'HIGH'
        WHEN LOWER(title) LIKE '%fed%'
          OR LOWER(title) LIKE '%interest rate%'
          OR LOWER(title) LIKE '%oil%'
          OR LOWER(title) LIKE '%wti%'
          OR LOWER(title) LIKE '%recession%'
            THEN 'MEDIUM'
        WHEN LOWER(title) LIKE '%bitcoin%'
          OR LOWER(title) LIKE '%ethereum%'
          OR LOWER(title) LIKE '%crypto%'
          OR LOWER(title) LIKE '%s&p%'
          OR LOWER(title) LIKE '%nasdaq%'
          OR LOWER(title) LIKE '%cpi%'
          OR LOWER(title) LIKE '%inflation%'
            THEN 'LOW'
    END AS impact_level,
    volume,
    status
FROM kalshi.market_report
WHERE
    LOWER(title) LIKE '%tariff%'
    OR LOWER(title) LIKE '%china%'
    OR LOWER(title) LIKE '%prc%'
    OR LOWER(title) LIKE '%korea%'
    OR LOWER(title) LIKE '%bts%'
    OR LOWER(title) LIKE '%kpop%'
    OR LOWER(title) LIKE '%k-pop%'
    OR LOWER(title) LIKE '%fed%'
    OR LOWER(title) LIKE '%interest rate%'
    OR LOWER(title) LIKE '%oil%'
    OR LOWER(title) LIKE '%wti%'
    OR LOWER(title) LIKE '%recession%'
    OR LOWER(title) LIKE '%bitcoin%'
    OR LOWER(title) LIKE '%ethereum%'
    OR LOWER(title) LIKE '%crypto%'
    OR LOWER(title) LIKE '%s&p%'
    OR LOWER(title) LIKE '%nasdaq%'
    OR LOWER(title) LIKE '%cpi%'
    OR LOWER(title) LIKE '%inflation%'
ORDER BY
    CASE impact_level
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
    END,
    volume DESC
