-- 01. Overview Counters
-- 목적: 대시보드 상단 핵심 지표 카운터 3개
-- 차트: Counter widgets (Dune에서 3개 별도 위젯 or 1개 쿼리 + 컬럼별 카운터)
--
-- 출력 컬럼:
--   apac_trade_count    — APAC 시간대(UTC 00~08) 총 트레이드 수
--   apac_contract_count — APAC 시간대 총 계약 수 (SUM(count))
--   apac_active_markets — APAC 관련 활성(open) 마켓 수
--
-- 시간대 필터: HOUR(created_time) BETWEEN 0 AND 8 (UTC) = KST 09:00~17:00
-- 테이블: kalshi.trade_report (트레이드/계약), kalshi.market_report (활성 마켓)

SELECT
    -- APAC 시간대(UTC 00~08 = KST 09~17) 총 트레이드 수
    (SELECT COUNT(*)
     FROM kalshi.trade_report
     WHERE HOUR(created_time) BETWEEN 0 AND 8
    ) AS apac_trade_count,

    -- APAC 시간대 총 계약 수
    (SELECT SUM(count)
     FROM kalshi.trade_report
     WHERE HOUR(created_time) BETWEEN 0 AND 8
    ) AS apac_contract_count,

    -- APAC 관련 활성 마켓 수
    (SELECT COUNT(*)
     FROM kalshi.market_report
     WHERE status = 'open'
       AND (
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
       )
    ) AS apac_active_markets
