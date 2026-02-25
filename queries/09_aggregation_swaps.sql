-- Clober V2 All Time Aggregation Swaps (Base + Monad)
-- Counter: total swaps, aggregator-routed vs direct, per chain
-- Visualization: Counter widget

WITH takes AS (
    SELECT
        'base' AS chain,
        t."from" AS tx_sender,
        bytearray_substring(l.topic2, 13, 20) AS taker
    FROM base.logs l
    INNER JOIN base.transactions t
        ON t.hash = l.tx_hash
        AND t.block_date = l.block_date
    WHERE l.contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND l.topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b

    UNION ALL

    SELECT
        'monad' AS chain,
        t."from" AS tx_sender,
        bytearray_substring(l.topic2, 13, 20) AS taker
    FROM monad_testnet.logs l
    INNER JOIN monad_testnet.transactions t
        ON t.hash = l.tx_hash
        AND t.block_date = l.block_date
    WHERE l.contract_address = 0x6657d192273731c3cac646cc82d5f28d0cbe8ccc
      AND l.topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
)

SELECT
    chain,
    COUNT(*) AS total_swaps,
    COUNT(CASE WHEN tx_sender != taker THEN 1 END) AS aggregation_swaps,
    COUNT(CASE WHEN tx_sender = taker THEN 1 END) AS direct_swaps,
    ROUND(COUNT(CASE WHEN tx_sender != taker THEN 1 END) * 100.0 / COUNT(*), 1) AS aggregation_pct
FROM takes
GROUP BY 1
ORDER BY 1
