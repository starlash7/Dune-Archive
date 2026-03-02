-- 02. Hourly Trading Heatmap
-- 목적: 시간대별 트레이딩 볼륨 분포 — APAC 시간대(UTC 00~08) 하이라이트
-- 차트: Bar chart (X: hour, Y: contract_count, Color: session)
--
-- 출력 컬럼:
--   hour_utc       — 시간대 (0~23)
--   trade_count    — 트레이드 건수
--   contract_count — 총 계약 수 (SUM(count))
--   session        — 'APAC (KST 09-17)' / 'Global'
--   hour_label     — 표시용 라벨 (e.g. '00:00 UTC')
--
-- 테이블: kalshi.trade_report

WITH hourly AS (
    SELECT
        HOUR(created_time) AS hour_utc,
        COUNT(*) AS trade_count,
        SUM(count) AS contract_count
    FROM kalshi.trade_report
    GROUP BY 1
)

SELECT
    hour_utc,
    trade_count,
    contract_count,
    CASE
        WHEN hour_utc BETWEEN 0 AND 8
        THEN 'APAC (KST 09-17)'
        ELSE 'Global'
    END AS session,
    LPAD(CAST(hour_utc AS VARCHAR), 2, '0') || ':00 UTC' AS hour_label
FROM hourly
ORDER BY hour_utc
