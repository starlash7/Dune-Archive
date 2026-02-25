-- Clober V2 Books Registry (Base)
-- All opened trading pairs with metadata
-- Visualization: Table

SELECT
    bytearray_to_uint256(topic1) AS book_id,
    bytearray_substring(topic2, 13, 20) AS base_token,
    bytearray_substring(topic3, 13, 20) AS quote_token,
    bt.symbol AS base_symbol,
    qt.symbol AS quote_symbol,
    bt.decimals AS base_decimals,
    qt.decimals AS quote_decimals,
    COALESCE(bt.symbol, 'Unknown') || '/' || COALESCE(qt.symbol, 'Unknown') AS pair,
    bytearray_to_uint256(bytearray_substring(data, 1, 32)) AS unit_size,
    bytearray_to_uint256(bytearray_substring(data, 33, 32)) AS maker_policy_raw,
    bytearray_to_uint256(bytearray_substring(data, 65, 32)) AS taker_policy_raw,
    bytearray_substring(data, 109, 20) AS hooks,
    block_time AS opened_at,
    tx_hash
FROM base.logs
LEFT JOIN tokens.erc20 bt
    ON bt.blockchain = 'base'
    AND bt.contract_address = bytearray_substring(topic2, 13, 20)
LEFT JOIN tokens.erc20 qt
    ON qt.blockchain = 'base'
    AND qt.contract_address = bytearray_substring(topic3, 13, 20)
WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
  AND topic0 = 0x803427d75ce3214f82dc7aa4910635170a6655e2c1663dc03429dd04100cba5a
ORDER BY block_time DESC
