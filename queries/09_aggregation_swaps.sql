-- Clober V2 All Time Aggregation Swaps (Base)
-- Counter: total swaps, aggregator-routed vs direct
-- Visualization: Counter widget

WITH takes AS (
    SELECT
        t."from" AS tx_sender,
        bytearray_substring(l.topic2, 13, 20) AS taker
    FROM base.logs l
    INNER JOIN base.transactions t
        ON t.hash = l.tx_hash
        AND t.block_date = l.block_date
    WHERE l.contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND l.topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
)

SELECT
    COUNT(*) AS total_swaps,
    COUNT(CASE WHEN tx_sender != taker THEN 1 END) AS aggregation_swaps,
    COUNT(CASE WHEN tx_sender = taker THEN 1 END) AS direct_swaps,
    ROUND(COUNT(CASE WHEN tx_sender != taker THEN 1 END) * 100.0 / COUNT(*), 1) AS aggregation_pct
FROM takes
