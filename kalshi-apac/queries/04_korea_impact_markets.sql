-- 04. Korea-Impact Markets
-- 목적: 한국 경제에 영향을 미치는 마켓 리스트 + 최근 가격(odds)
-- 차트: Table
--
-- 출력 컬럼:
--   report_ticker, ticker_name, impact_level, impact_reason,
--   latest_yes_price, total_volume, trade_count, last_trade_date
--
-- 테이블: kalshi.trade_report

WITH classified AS (
    SELECT
        report_ticker,
        ticker_name,
        price,
        contracts_traded,
        date,
        created_time,
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
        END AS impact_level,
        CASE
            WHEN LOWER(ticker_name) LIKE '%tariff%'
              OR LOWER(ticker_name) LIKE '%china%'
              OR LOWER(ticker_name) LIKE '%prc%'
                THEN '중국 관세 → 한국 수출/KOSPI'
            WHEN LOWER(ticker_name) LIKE '%korea%'
              OR LOWER(ticker_name) LIKE '%bts%'
              OR LOWER(ticker_name) LIKE '%kpop%'
              OR LOWER(ticker_name) LIKE '%k-pop%'
                THEN '한국 직접 관련'
            WHEN LOWER(ticker_name) LIKE '%fed%'
              OR LOWER(ticker_name) LIKE '%interest rate%'
                THEN 'Fed 금리 → KRW 환율'
            WHEN LOWER(ticker_name) LIKE '%oil%'
              OR LOWER(ticker_name) LIKE '%wti%'
                THEN '에너지 가격 → 수입국 한국'
            WHEN LOWER(ticker_name) LIKE '%recession%'
                THEN '미국 경기침체 → 글로벌 수요'
            WHEN LOWER(ticker_name) LIKE '%bitcoin%'
              OR LOWER(ticker_name) LIKE '%ethereum%'
              OR LOWER(ticker_name) LIKE '%crypto%'
                THEN '한국 크립토 거래량 세계 상위'
            WHEN LOWER(ticker_name) LIKE '%s&p%'
              OR LOWER(ticker_name) LIKE '%nasdaq%'
                THEN '미국 증시 → KOSPI 동조화'
            WHEN LOWER(ticker_name) LIKE '%cpi%'
              OR LOWER(ticker_name) LIKE '%inflation%'
                THEN '글로벌 인플레 → BOK 정책'
        END AS impact_reason
    FROM kalshi.trade_report
    WHERE price BETWEEN 1 AND 99
),

-- 마켓별 최신 가격 (가장 최근 거래)
latest AS (
    SELECT
        report_ticker,
        price AS latest_yes_price,
        ROW_NUMBER() OVER (PARTITION BY report_ticker ORDER BY created_time DESC) AS rn
    FROM classified
    WHERE impact_level IS NOT NULL
),

-- 마켓별 집계
market_agg AS (
    SELECT
        report_ticker,
        ticker_name,
        impact_level,
        impact_reason,
        SUM(contracts_traded) AS total_volume,
        COUNT(*) AS trade_count,
        MAX(date) AS last_trade_date
    FROM classified
    WHERE impact_level IS NOT NULL
    GROUP BY report_ticker, ticker_name, impact_level, impact_reason
)

SELECT
    ma.report_ticker,
    ma.ticker_name,
    ma.impact_level,
    ma.impact_reason,
    l.latest_yes_price,
    ma.total_volume,
    ma.trade_count,
    ma.last_trade_date
FROM market_agg ma
LEFT JOIN latest l
    ON ma.report_ticker = l.report_ticker
    AND l.rn = 1
ORDER BY
    CASE ma.impact_level
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
    END,
    ma.total_volume DESC
