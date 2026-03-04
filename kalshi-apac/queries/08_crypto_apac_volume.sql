-- 08. Crypto APAC Session Volume
-- 목적: 크립토 마켓의 APAC vs Global 세션별 거래 패턴 + 자산별 분포
--       한국은 세계적 크립토 거래 허브 — APAC 시간대 활동이 유독 높은지 분석
--
-- 하나의 쿼리로 다양한 차트 생성 가능:
--   1) Area Chart (Stacked) → X: trade_date, Y: daily_volume, Color: crypto_asset — 자산별 일별 추이
--   2) Bar Chart (Grouped)  → X: crypto_asset, Y: SUM(daily_volume), Color: session — APAC vs Global 비교
--   3) Pie Chart            → Label: crypto_asset, Value: SUM(daily_volume)        — 자산 점유율
--   4) Table                → 전체 로우 그대로 사용                                 — 상세 데이터
--   5) Counter              → SUM(daily_volume) WHERE session='APAC' / 전체         — APAC 비중 %
--
-- Dune 차트 설정 가이드:
--   [Area Stacked] X=trade_date, Y=daily_volume, Group=crypto_asset, Stacking=Normal
--   [Grouped Bar]  X=crypto_asset, Y=daily_volume (Sum), Group=session
--   [Pie]          Label=crypto_asset, Value=daily_volume (Sum)
--   [Table]        모든 컬럼 표시, Sort: trade_date DESC
--
-- 출력 컬럼:
--   trade_date, crypto_asset, session, daily_volume, trade_count,
--   avg_price, apac_volume, global_volume, apac_share_pct
--
-- 테이블: kalshi.trade_report

WITH crypto_trades AS (
    SELECT
        date AS trade_date,
        report_ticker,
        ticker_name,
        contracts_traded,
        price,
        created_time,
        -- 크립토 자산 분류
        CASE
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%btc%'
                THEN 'Bitcoin'
            WHEN LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%eth %'
              OR LOWER(ticker_name) LIKE '%ether %'
                THEN 'Ethereum'
            WHEN LOWER(ticker_name) LIKE '%solana%'
              OR LOWER(ticker_name) LIKE '%sol %'
                THEN 'Solana'
            WHEN LOWER(ticker_name) LIKE '%xrp%'
              OR LOWER(ticker_name) LIKE '%ripple%'
                THEN 'XRP'
            WHEN LOWER(ticker_name) LIKE '%doge%'
                THEN 'Dogecoin'
            WHEN LOWER(ticker_name) LIKE '%crypto%'
              OR LOWER(ticker_name) LIKE '%defi%'
              OR LOWER(ticker_name) LIKE '%nft%'
              OR LOWER(ticker_name) LIKE '%token%'
              OR LOWER(ticker_name) LIKE '%blockchain%'
                THEN 'Crypto Other'
        END AS crypto_asset,
        -- APAC 세션 판별 (UTC 00:00~09:00 = KST 09:00~18:00)
        CASE
            WHEN HOUR(created_time) BETWEEN 0 AND 8
                THEN 'APAC'
            ELSE 'Global'
        END AS session
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
),

-- 크립토만 필터
crypto_only AS (
    SELECT * FROM crypto_trades
    WHERE crypto_asset IS NOT NULL
),

-- 날짜 + 자산 + 세션별 집계
daily_session AS (
    SELECT
        trade_date,
        crypto_asset,
        session,
        SUM(contracts_traded) AS daily_volume,
        COUNT(*) AS trade_count,
        ROUND(AVG(price), 1) AS avg_price
    FROM crypto_only
    GROUP BY trade_date, crypto_asset, session
),

-- 날짜 + 자산별 APAC vs Global 볼륨 (APAC 비중 계산용)
apac_ratio AS (
    SELECT
        trade_date,
        crypto_asset,
        SUM(CASE WHEN session = 'APAC' THEN daily_volume ELSE 0 END) AS apac_volume,
        SUM(CASE WHEN session = 'Global' THEN daily_volume ELSE 0 END) AS global_volume,
        SUM(daily_volume) AS total_volume
    FROM daily_session
    GROUP BY trade_date, crypto_asset
)

SELECT
    ds.trade_date,
    ds.crypto_asset,
    ds.session,
    ds.daily_volume,
    ds.trade_count,
    ds.avg_price,
    ar.apac_volume,
    ar.global_volume,
    CASE
        WHEN ar.total_volume > 0
        THEN ROUND(CAST(ar.apac_volume AS DOUBLE) / ar.total_volume * 100, 1)
        ELSE 0
    END AS apac_share_pct
FROM daily_session ds
INNER JOIN apac_ratio ar
    ON ds.trade_date = ar.trade_date
    AND ds.crypto_asset = ar.crypto_asset
ORDER BY ds.trade_date DESC, ds.daily_volume DESC
