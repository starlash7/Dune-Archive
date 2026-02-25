-- Clober V2 Total Metrics (Base)
-- Summary counters: total volume, trades, users, active markets
-- Visualization: Counter widgets

WITH books AS (
    SELECT
        bytearray_to_uint256(topic1) AS book_id,
        bytearray_substring(topic2, 13, 20) AS base_token,
        bytearray_substring(topic3, 13, 20) AS quote_token,
        bytearray_to_uint256(bytearray_substring(data, 1, 32)) AS unit_size
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0x803427d75ce3214f82dc7aa4910635170a6655e2c1663dc03429dd04100cba5a
),

takes AS (
    SELECT
        block_time,
        tx_hash,
        bytearray_to_uint256(topic1) AS book_id,
        bytearray_substring(topic2, 13, 20) AS taker,
        bytearray_to_int256(bytearray_substring(data, 1, 32)) AS tick,
        bytearray_to_uint256(bytearray_substring(data, 33, 32)) AS unit
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
),

trades AS (
    SELECT
        t.block_time,
        t.tx_hash,
        t.taker,
        b.base_token,
        b.quote_token,
        CAST(t.unit AS DOUBLE) * CAST(b.unit_size AS DOUBLE) AS quote_amount_raw,
        COALESCE(qt.decimals, 18) AS quote_decimals
    FROM takes t
    JOIN books b ON t.book_id = b.book_id
    LEFT JOIN tokens.erc20 qt
        ON qt.blockchain = 'base'
        AND qt.contract_address = b.quote_token
),

trades_usd AS (
    SELECT
        tr.*,
        tr.quote_amount_raw / pow(10, tr.quote_decimals) AS quote_amount,
        tr.quote_amount_raw / pow(10, tr.quote_decimals) * COALESCE(p.price, 0) AS volume_usd
    FROM trades tr
    LEFT JOIN prices.usd p
        ON p.blockchain = 'base'
        AND p.contract_address = tr.quote_token
        AND p.minute = date_trunc('minute', tr.block_time)
)

SELECT
    COALESCE(SUM(volume_usd), 0) AS total_volume_usd,
    COUNT(*) AS total_trades,
    COUNT(DISTINCT taker) AS unique_traders,
    (SELECT COUNT(DISTINCT book_id) FROM books) AS active_markets
FROM trades_usd
