-- 03. APAC Weekday Trading Pattern
-- 목적: APAC 마켓의 요일별 거래 패턴 분석
-- 차트: Bar Chart (x=weekday, y=avg_volume, color=apac_tag)
--
-- 출력 컬럼:
--   weekday_num, weekday_name, apac_tag, avg_volume, total_volume, trading_days
--
-- 테이블: kalshi.trade_report
-- 힌트: DOW(date) → 1=Mon ~ 7=Sun

WITH apac_classified AS (
    SELECT
        date,
        contracts_traded,
        report_ticker,
        ticker_name,
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
        END AS apac_tag
    FROM kalshi.trade_report
),

daily_agg AS (
    SELECT
        date,
        apac_tag,
        SUM(contracts_traded) AS daily_volume
    FROM apac_classified
    WHERE apac_tag IS NOT NULL
    GROUP BY date, apac_tag
)

SELECT
    DOW(date) AS weekday_num,
    CASE DOW(date)
        WHEN 1 THEN 'Mon'
        WHEN 2 THEN 'Tue'
        WHEN 3 THEN 'Wed'
        WHEN 4 THEN 'Thu'
        WHEN 5 THEN 'Fri'
        WHEN 6 THEN 'Sat'
        WHEN 7 THEN 'Sun'
    END AS weekday_name,
    apac_tag,
    AVG(daily_volume) AS avg_volume,
    SUM(daily_volume) AS total_volume,
    COUNT(*) AS trading_days
FROM daily_agg
GROUP BY DOW(date), apac_tag
ORDER BY weekday_num, apac_tag
