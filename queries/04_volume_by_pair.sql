-- Clober V2 Volume by Pair (Base)
-- Trading volume breakdown by pair
-- Visualization: Pie chart or horizontal bar chart

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
        bytearray_to_uint256(topic1) AS book_id,
        bytearray_to_uint256(bytearray_substring(data, 33, 32)) AS unit
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
),

trades_usd AS (
    SELECT
        COALESCE(bt.symbol, CAST(b.base_token AS VARCHAR)) AS base_symbol,
        COALESCE(qt.symbol, CAST(b.quote_token AS VARCHAR)) AS quote_symbol,
        CAST(t.unit AS DOUBLE) * CAST(b.unit_size AS DOUBLE)
            / pow(10, COALESCE(qt.decimals, 18))
            * COALESCE(p.price, 0) AS volume_usd
    FROM takes t
    JOIN books b ON t.book_id = b.book_id
    LEFT JOIN tokens.erc20 bt
        ON bt.blockchain = 'base'
        AND bt.contract_address = b.base_token
    LEFT JOIN tokens.erc20 qt
        ON qt.blockchain = 'base'
        AND qt.contract_address = b.quote_token
    LEFT JOIN prices.usd p
        ON p.blockchain = 'base'
        AND p.contract_address = b.quote_token
        AND p.minute = date_trunc('minute', t.block_time)
)

SELECT
    base_symbol || '/' || quote_symbol AS pair,
    SUM(volume_usd) AS total_volume_usd,
    COUNT(*) AS num_trades
FROM trades_usd
GROUP BY 1
ORDER BY 2 DESC
