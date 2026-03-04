-- 04. Korea-Impact Markets
-- 목적: 한국 경제에 영향을 미치는 마켓 리스트 + 최근 가격(odds)
-- 차트: Table
--
-- 출력 컬럼:
--   ticker, title, category, impact_level, impact_reason,
--   latest_yes_price, volume, open_interest, status
--
-- 테이블: kalshi.market_report + kalshi.trade_report
-- 힌트: title 키워드로 한국 영향도 분류, 최근 가격은 trade_report에서 JOIN

WITH korea_markets AS (
    SELECT
        ticker,
        title,
        category,
        status,
        volume,
        open_interest,
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
        CASE
            WHEN LOWER(title) LIKE '%tariff%'
              OR LOWER(title) LIKE '%china%'
              OR LOWER(title) LIKE '%prc%'
                THEN '중국 관세 → 한국 수출/KOSPI'
            WHEN LOWER(title) LIKE '%korea%'
              OR LOWER(title) LIKE '%bts%'
              OR LOWER(title) LIKE '%kpop%'
              OR LOWER(title) LIKE '%k-pop%'
                THEN '한국 직접 관련'
            WHEN LOWER(title) LIKE '%fed%'
              OR LOWER(title) LIKE '%interest rate%'
                THEN 'Fed 금리 → KRW 환율'
            WHEN LOWER(title) LIKE '%oil%'
              OR LOWER(title) LIKE '%wti%'
                THEN '에너지 가격 → 수입국 한국'
            WHEN LOWER(title) LIKE '%recession%'
                THEN '미국 경기침체 → 글로벌 수요'
            WHEN LOWER(title) LIKE '%bitcoin%'
              OR LOWER(title) LIKE '%ethereum%'
              OR LOWER(title) LIKE '%crypto%'
                THEN '한국 크립토 거래량 세계 상위'
            WHEN LOWER(title) LIKE '%s&p%'
              OR LOWER(title) LIKE '%nasdaq%'
                THEN '미국 증시 → KOSPI 동조화'
            WHEN LOWER(title) LIKE '%cpi%'
              OR LOWER(title) LIKE '%inflation%'
                THEN '글로벌 인플레 → BOK 정책'
        END AS impact_reason
    FROM kalshi.market_report
    WHERE date = (SELECT MAX(date) FROM kalshi.market_report)
),

latest_price AS (
    SELECT
        report_ticker,
        price AS latest_yes_price,
        ROW_NUMBER() OVER (PARTITION BY report_ticker ORDER BY created_time DESC) AS rn
    FROM kalshi.trade_report
)

SELECT
    km.ticker,
    km.title,
    km.category,
    km.impact_level,
    km.impact_reason,
    lp.latest_yes_price,
    km.volume,
    km.open_interest,
    km.status
FROM korea_markets km
LEFT JOIN latest_price lp
    ON km.ticker = lp.report_ticker
    AND lp.rn = 1
WHERE km.impact_level IS NOT NULL
ORDER BY
    CASE km.impact_level
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
    END,
    km.volume DESC
