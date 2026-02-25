-- Clober V2 New vs Returning Users (Base + Monad)
-- Daily unique user count: first-time vs returning traders, per chain
-- Visualization: Stacked bar chart (x: day, y: users, color: user_type)

WITH all_takes AS (
    SELECT
        'base' AS chain,
        block_date,
        bytearray_substring(topic2, 13, 20) AS taker
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b

    UNION ALL

    SELECT
        'monad' AS chain,
        block_date,
        bytearray_substring(topic2, 13, 20) AS taker
    FROM monad_testnet.logs
    WHERE contract_address = 0x6657d192273731c3cac646cc82d5f28d0cbe8ccc
      AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
),

user_first_day AS (
    SELECT
        chain,
        taker,
        MIN(block_date) AS first_day
    FROM all_takes
    GROUP BY 1, 2
),

daily_active AS (
    SELECT DISTINCT
        chain,
        block_date AS day,
        taker
    FROM all_takes
)

SELECT
    d.day,
    d.chain,
    COUNT(DISTINCT CASE WHEN d.day = u.first_day THEN d.taker END) AS new_users,
    COUNT(DISTINCT CASE WHEN d.day > u.first_day THEN d.taker END) AS returning_users
FROM daily_active d
JOIN user_first_day u
    ON d.taker = u.taker
    AND d.chain = u.chain
GROUP BY 1, 2
ORDER BY 1, 2
