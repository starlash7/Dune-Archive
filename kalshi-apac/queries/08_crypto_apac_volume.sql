-- 08. Crypto Market Analysis for APAC
-- 목적: 크립토 마켓의 자산별 거래 패턴 + 가격대 분포 + 주간 모멘텀
--       한국은 세계적 크립토 거래 허브 — 자산별 볼륨/가격 추이 분석
--
-- 하나의 쿼리로 다양한 차트 생성 가능:
--   1) Area Chart (Stacked) → X: trade_date, Y: daily_volume, Color: crypto_asset — 자산별 일별 추이
--   2) Bar Chart            → X: crypto_asset, Y: SUM(daily_volume)              — 자산별 총 거래량
--   3) Pie Chart            → Label: crypto_asset, Value: SUM(daily_volume)      — 자산 점유율
--   4) Line Chart           → X: trade_date, Y: avg_price, Color: crypto_asset   — 평균 가격 추이 (시장 심리)
--   5) Table                → 전체 로우 그대로 사용                               — 상세 데이터
--
-- Dune 차트 설정 가이드:
--   [Area Stacked] X=trade_date, Y=daily_volume, Group=crypto_asset, Stacking=Normal
--   [Bar]          X=crypto_asset, Y=daily_volume (Sum), Sort: Y desc
--   [Pie]          Label=crypto_asset, Value=daily_volume (Sum)
--   [Line]         X=trade_date, Y=avg_price, Group=crypto_asset
--   [Table]        모든 컬럼 표시, Sort: trade_date DESC
--
-- 출력 컬럼:
--   trade_date, crypto_asset, daily_volume, trade_count, avg_price,
--   market_count, week_over_week_chg, price_bucket, cumulative_volume
--
-- 테이블: kalshi.trade_report

WITH crypto_classified AS (
    SELECT
        date AS trade_date,
        report_ticker,
        ticker_name,
        contracts_traded,
        price,
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
        -- 가격대 버킷 (시장 심리 분포용)
        CASE
            WHEN price BETWEEN 1 AND 20 THEN 'Strong No (1-20¢)'
            WHEN price BETWEEN 21 AND 40 THEN 'Lean No (21-40¢)'
            WHEN price BETWEEN 41 AND 60 THEN 'Toss-up (41-60¢)'
            WHEN price BETWEEN 61 AND 80 THEN 'Lean Yes (61-80¢)'
            WHEN price BETWEEN 81 AND 99 THEN 'Strong Yes (81-99¢)'
        END AS price_bucket
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
),

crypto_only AS (
    SELECT * FROM crypto_classified
    WHERE crypto_asset IS NOT NULL
),

-- 날짜 + 자산별 집계
daily_stats AS (
    SELECT
        trade_date,
        crypto_asset,
        SUM(contracts_traded) AS daily_volume,
        COUNT(*) AS trade_count,
        ROUND(AVG(price), 1) AS avg_price,
        COUNT(DISTINCT report_ticker) AS market_count
    FROM crypto_only
    GROUP BY trade_date, crypto_asset
),

-- 주간 볼륨 (WoW 변화율 계산용)
weekly_lag AS (
    SELECT
        trade_date,
        crypto_asset,
        daily_volume,
        SUM(daily_volume) OVER (
            PARTITION BY crypto_asset
            ORDER BY trade_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_7d_volume,
        SUM(daily_volume) OVER (
            PARTITION BY crypto_asset
            ORDER BY trade_date
            ROWS BETWEEN 13 PRECEDING AND 7 PRECEDING
        ) AS prev_7d_volume
    FROM daily_stats
),

-- 가격대 분포 (자산별)
price_dist AS (
    SELECT
        crypto_asset,
        price_bucket,
        SUM(contracts_traded) AS bucket_volume
    FROM crypto_only
    GROUP BY crypto_asset, price_bucket
),

-- 자산별 누적 볼륨 (랭킹용)
cumulative AS (
    SELECT
        trade_date,
        crypto_asset,
        SUM(daily_volume) OVER (
            PARTITION BY crypto_asset
            ORDER BY trade_date
        ) AS cumulative_volume
    FROM daily_stats
)

SELECT
    ds.trade_date,
    ds.crypto_asset,
    ds.daily_volume,
    ds.trade_count,
    ds.avg_price,
    ds.market_count,
    -- WoW 변화율 (%)
    CASE
        WHEN wl.prev_7d_volume > 0
        THEN ROUND(
            (CAST(wl.rolling_7d_volume AS DOUBLE) - wl.prev_7d_volume)
            / wl.prev_7d_volume * 100, 1
        )
        ELSE NULL
    END AS week_over_week_pct,
    c.cumulative_volume
FROM daily_stats ds
LEFT JOIN weekly_lag wl
    ON ds.trade_date = wl.trade_date
    AND ds.crypto_asset = wl.crypto_asset
LEFT JOIN cumulative c
    ON ds.trade_date = c.trade_date
    AND ds.crypto_asset = c.crypto_asset
ORDER BY ds.trade_date DESC, ds.daily_volume DESC
