-- 07. K-Culture & Entertainment Markets
-- 목적: BTS, K-pop, 한국 관련 마켓의 일별 거래 활동 + 카테고리별 분포
--
-- 하나의 쿼리로 다양한 차트 생성 가능:
--   1) Bar Chart   → X: subcategory, Y: SUM(daily_volume)        — 카테고리별 총 거래량
--   2) Area Chart  → X: trade_date, Y: daily_volume, Color: subcategory — 일별 추이
--   3) Table       → 전체 로우 그대로 사용                        — 상세 데이터
--   4) Pie Chart   → Label: subcategory, Value: SUM(daily_volume) — 비중 비교
--
-- Dune 차트 설정 가이드:
--   [Bar] X=subcategory, Y=daily_volume (Aggregation: Sum), Sort: Y desc
--   [Area] X=trade_date, Y=daily_volume, Group=subcategory, Stacking: Normal
--   [Table] 모든 컬럼 표시, Sort: trade_date DESC
--   [Pie] Label=subcategory, Value=daily_volume (Aggregation: Sum)
--
-- 출력 컬럼:
--   trade_date, subcategory, daily_volume, trade_count, avg_price, market_count, top_market
--
-- 테이블: kalshi.trade_report

WITH kculture_classified AS (
    SELECT
        date AS trade_date,
        report_ticker,
        ticker_name,
        contracts_traded,
        price,
        CASE
            -- BTS / K-pop 직접 관련
            WHEN LOWER(ticker_name) LIKE '%bts %'
              OR LOWER(ticker_name) LIKE '%bts''%'
              OR LOWER(ticker_name) LIKE '%bangtan%'
              OR LOWER(ticker_name) LIKE '%kpop%'
              OR LOWER(ticker_name) LIKE '%k-pop%'
              OR LOWER(ticker_name) LIKE '%blackpink%'
              OR LOWER(ticker_name) LIKE '%grammy%k%'
                THEN 'K-Pop / BTS'
            -- 한국 드라마/엔터테인먼트
            WHEN LOWER(ticker_name) LIKE '%korean drama%'
              OR LOWER(ticker_name) LIKE '%k-drama%'
              OR LOWER(ticker_name) LIKE '%kdrama%'
              OR LOWER(ticker_name) LIKE '%squid game%'
              OR LOWER(ticker_name) LIKE '%netflix%korea%'
              OR LOWER(ticker_name) LIKE '%korean movie%'
              OR LOWER(ticker_name) LIKE '%oscar%korea%'
                THEN 'K-Drama / Film'
            -- 한국 직접 언급 (정치/경제/기타)
            WHEN LOWER(ticker_name) LIKE '%korea%'
              OR LOWER(ticker_name) LIKE '%korean%'
              OR LOWER(ticker_name) LIKE '%seoul%'
              OR LOWER(ticker_name) LIKE '%kospi%'
              OR LOWER(ticker_name) LIKE '%samsung%'
              OR LOWER(ticker_name) LIKE '%hyundai%'
                THEN 'Korea Direct'
            -- K-Food / 한국 문화 기타
            WHEN LOWER(ticker_name) LIKE '%kimchi%'
              OR LOWER(ticker_name) LIKE '%korean food%'
              OR LOWER(ticker_name) LIKE '%k-beauty%'
              OR LOWER(ticker_name) LIKE '%hallyu%'
                THEN 'K-Culture Other'
        END AS subcategory
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
),

-- 서브카테고리가 있는 것만 필터
filtered AS (
    SELECT * FROM kculture_classified
    WHERE subcategory IS NOT NULL
),

-- 날짜+카테고리별 집계
daily_stats AS (
    SELECT
        trade_date,
        subcategory,
        SUM(contracts_traded) AS daily_volume,
        COUNT(*) AS trade_count,
        ROUND(AVG(price), 1) AS avg_price,
        COUNT(DISTINCT report_ticker) AS market_count
    FROM filtered
    GROUP BY trade_date, subcategory
),

-- 카테고리별 대표 마켓 (거래량 최대)
top_market_per_cat AS (
    SELECT
        subcategory,
        ticker_name AS top_market,
        ROW_NUMBER() OVER (
            PARTITION BY subcategory
            ORDER BY SUM(contracts_traded) DESC
        ) AS rn
    FROM filtered
    GROUP BY subcategory, ticker_name
)

SELECT
    ds.trade_date,
    ds.subcategory,
    ds.daily_volume,
    ds.trade_count,
    ds.avg_price,
    ds.market_count,
    tm.top_market
FROM daily_stats ds
LEFT JOIN top_market_per_cat tm
    ON ds.subcategory = tm.subcategory
    AND tm.rn = 1
ORDER BY ds.trade_date DESC, ds.daily_volume DESC
