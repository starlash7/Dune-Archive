-- 01. Overview Counters
-- 목적: 대시보드 상단 핵심 지표 카운터 3개
-- 차트: Counter widgets (Dune에서 3개 별도 위젯 or 1개 쿼리 + 컬럼별 카운터)
--
-- 출력 컬럼:
--   apac_total_volume     — APAC 관련 마켓 총 거래량 (contracts)
--   apac_trade_count      — APAC 관련 마켓 총 트레이드 건수
--   apac_active_markets   — APAC 관련 활성(open) 마켓 수
--
-- 필터: 키워드 기반 APAC 관련 마켓 (created_time 컬럼 미존재하여 시간대 필터 불가)
-- 테이블: kalshi.trade_report, kalshi.market_report

SELECT
    -- APAC 관련 마켓 총 거래량
    (SELECT COALESCE(SUM(contracts_traded), 0)
     FROM kalshi.trade_report
     WHERE LOWER(ticker_name) LIKE '%tariff%'
        OR LOWER(ticker_name) LIKE '%china%'
        OR LOWER(ticker_name) LIKE '%prc%'
        OR LOWER(ticker_name) LIKE '%korea%'
        OR LOWER(ticker_name) LIKE '%bts%'
        OR LOWER(ticker_name) LIKE '%kpop%'
        OR LOWER(ticker_name) LIKE '%k-pop%'
        OR LOWER(ticker_name) LIKE '%bitcoin%'
        OR LOWER(ticker_name) LIKE '%ethereum%'
        OR LOWER(ticker_name) LIKE '%crypto%'
        OR LOWER(ticker_name) LIKE '%fed%'
        OR LOWER(ticker_name) LIKE '%interest rate%'
        OR LOWER(ticker_name) LIKE '%oil%'
        OR LOWER(ticker_name) LIKE '%recession%'
    ) AS apac_total_volume,

    -- APAC 관련 마켓 총 트레이드 건수
    (SELECT COUNT(*)
     FROM kalshi.trade_report
     WHERE LOWER(ticker_name) LIKE '%tariff%'
        OR LOWER(ticker_name) LIKE '%china%'
        OR LOWER(ticker_name) LIKE '%prc%'
        OR LOWER(ticker_name) LIKE '%korea%'
        OR LOWER(ticker_name) LIKE '%bts%'
        OR LOWER(ticker_name) LIKE '%kpop%'
        OR LOWER(ticker_name) LIKE '%k-pop%'
        OR LOWER(ticker_name) LIKE '%bitcoin%'
        OR LOWER(ticker_name) LIKE '%ethereum%'
        OR LOWER(ticker_name) LIKE '%crypto%'
        OR LOWER(ticker_name) LIKE '%fed%'
        OR LOWER(ticker_name) LIKE '%interest rate%'
        OR LOWER(ticker_name) LIKE '%oil%'
        OR LOWER(ticker_name) LIKE '%recession%'
    ) AS apac_trade_count,

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
