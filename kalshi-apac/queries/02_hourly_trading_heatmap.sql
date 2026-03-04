-- 02. Daily Volume by APAC Category
-- 목적: APAC 카테고리별 일별 거래량 분포
-- 차트: Bar chart / Area chart
--
-- 원래 시간대별 히트맵이었으나 created_time 컬럼 미존재로
-- 일별 + APAC 카테고리별 거래량 분석으로 변경
--
-- 하나의 쿼리로 다양한 차트 생성 가능:
--   1) Bar Chart   → X: apac_category, Y: SUM(daily_volume) — 카테고리별 총 거래량
--   2) Area Chart  → X: trade_date, Y: daily_volume, Color: apac_category — 일별 추이
--   3) Table       → 전체 로우 — 상세 데이터
--
-- Dune 차트 설정 가이드:
--   [Bar]  X=apac_category, Y=daily_volume (Sum), Sort: Y desc
--   [Area] X=trade_date, Y=daily_volume, Group=apac_category, Stacking=Normal
--   [Table] Sort: trade_date DESC
--
-- 출력 컬럼:
--   trade_date, apac_category, daily_volume, trade_count, avg_price
--
-- 테이블: kalshi.trade_report

WITH categorized AS (
    SELECT
        date AS trade_date,
        contracts_traded,
        price,
        CASE
            WHEN LOWER(ticker_name) LIKE '%tariff%'
              OR LOWER(ticker_name) LIKE '%china%'
              OR LOWER(ticker_name) LIKE '%prc%'
                THEN 'China/Tariff'
            WHEN LOWER(ticker_name) LIKE '%korea%'
              OR LOWER(ticker_name) LIKE '%bts%'
              OR LOWER(ticker_name) LIKE '%kpop%'
              OR LOWER(ticker_name) LIKE '%k-pop%'
                THEN 'Korea/K-Culture'
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
                THEN 'Crypto'
            WHEN LOWER(ticker_name) LIKE '%fed%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
              OR LOWER(ticker_name) LIKE '%recession%'
                THEN 'Fed/Macro'
            WHEN LOWER(ticker_name) LIKE '%oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
              OR LOWER(ticker_name) LIKE '%cpi%'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN 'Energy/Inflation'
            WHEN LOWER(ticker_name) LIKE '%s&p%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
              OR LOWER(ticker_name) LIKE '%gdp%'
                THEN 'Equity/GDP'
        END AS apac_category
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
)

SELECT
    trade_date,
    apac_category,
    SUM(contracts_traded) AS daily_volume,
    COUNT(*) AS trade_count,
    ROUND(AVG(price), 1) AS avg_price
FROM categorized
WHERE apac_category IS NOT NULL
GROUP BY trade_date, apac_category
ORDER BY trade_date DESC, daily_volume DESC
