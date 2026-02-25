-- Clober V2 Daily Trades & Users (Base)
-- Daily trade count and unique active traders
-- Visualization: Dual-axis line chart (trades on left, users on right)

SELECT
    block_date AS day,
    COUNT(*) AS num_trades,
    COUNT(DISTINCT bytearray_substring(topic2, 13, 20)) AS unique_traders
FROM base.logs
WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
  AND topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
GROUP BY 1
ORDER BY 1
