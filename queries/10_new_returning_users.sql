-- Clober V2 New vs Returning Users (Base)
-- Daily tx count split by first-time vs returning traders
-- Visualization: Stacked bar chart (x: day, y: tx count, color: user_type)

WITH user_first_day AS (
    SELECT
        bytearray_substring(topic2, 13, 20) AS taker,
        MIN(block_date) AS first_day
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
    GROUP BY 1
),

daily_txs AS (
    SELECT
        block_date AS day,
        bytearray_substring(topic2, 13, 20) AS taker
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
)

SELECT
    d.day,
    COUNT(CASE WHEN d.day = u.first_day THEN 1 END) AS new_user_txs,
    COUNT(CASE WHEN d.day > u.first_day THEN 1 END) AS returning_user_txs
FROM daily_txs d
JOIN user_first_day u ON d.taker = u.taker
GROUP BY 1
ORDER BY 1
