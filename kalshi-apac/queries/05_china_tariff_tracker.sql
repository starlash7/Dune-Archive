-- 05. China Tariff Tracker
-- 목적: 중국 관세율 관련 마켓의 일별 odds(가격) 추이
-- 차트: Line chart (x=date, y=avg_yes_price, color=ticker_name)
--
-- 출력 컬럼:
--   date, ticker_name, avg_yes_price, total_volume, trade_count
--
-- 테이블: kalshi.trade_report
-- 힌트: ticker_name에 tariff + china/prc 키워드 포함 마켓 필터
--        price=1~99 센트 (Yes 가격 기준, 확률로 해석 가능)

SELECT
    date,
    ticker_name,
    AVG(price) AS avg_yes_price,
    SUM(contracts_traded) AS total_volume,
    COUNT(*) AS trade_count
FROM kalshi.trade_report
WHERE (
    LOWER(ticker_name) LIKE '%tariff%'
    AND (
        LOWER(ticker_name) LIKE '%china%'
        OR LOWER(ticker_name) LIKE '%prc%'
    )
)
AND price BETWEEN 1 AND 99
GROUP BY date, ticker_name
ORDER BY date, ticker_name
