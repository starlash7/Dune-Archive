-- 06. Fed Rate Impact Tracker
-- 목적: Fed 금리 결정 관련 마켓의 일별 odds 추이 — KRW 영향 분석
-- 차트: Line chart (x=date, y=avg_yes_price, color=ticker_name)
--
-- 출력 컬럼:
--   date, ticker_name, avg_yes_price, total_volume, trade_count
--
-- 테이블: kalshi.trade_report
-- 힌트: fed, interest rate, fomc, federal reserve 키워드 필터
--        price=1~99 센트 → 확률로 해석 (50¢ = 50% 확률)

SELECT
    date,
    ticker_name,
    AVG(price) AS avg_yes_price,
    SUM(contracts_traded) AS total_volume,
    COUNT(*) AS trade_count
FROM kalshi.trade_report
WHERE (
    LOWER(ticker_name) LIKE '%fed%'
    OR LOWER(ticker_name) LIKE '%interest rate%'
    OR LOWER(ticker_name) LIKE '%fomc%'
    OR LOWER(ticker_name) LIKE '%federal reserve%'
)
AND price BETWEEN 1 AND 99
GROUP BY date, ticker_name
ORDER BY date, ticker_name
