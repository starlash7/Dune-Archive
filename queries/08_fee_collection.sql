-- Clober V2 Fee Collection (Base)
-- Fee revenue by provider and currency
-- Visualization: Bar chart or table

WITH fee_events AS (
    SELECT
        block_time,
        block_date,
        bytearray_substring(topic1, 13, 20) AS provider,
        bytearray_substring(topic2, 13, 20) AS recipient,
        bytearray_substring(topic3, 13, 20) AS currency,
        bytearray_to_uint256(bytearray_substring(data, 1, 32)) AS amount_raw
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 = 0x1c4f94f28cc9152354d4b98b8614b28c6c828a98d88228fa9577c7b9475e120c
),

fees_usd AS (
    SELECT
        f.block_date,
        f.provider,
        f.currency,
        COALESCE(t.symbol, CAST(f.currency AS VARCHAR)) AS currency_symbol,
        CAST(f.amount_raw AS DOUBLE) / pow(10, COALESCE(t.decimals, 18)) AS amount,
        CAST(f.amount_raw AS DOUBLE) / pow(10, COALESCE(t.decimals, 18))
            * COALESCE(p.price, 0) AS amount_usd
    FROM fee_events f
    LEFT JOIN tokens.erc20 t
        ON t.blockchain = 'base'
        AND t.contract_address = f.currency
    LEFT JOIN prices.usd p
        ON p.blockchain = 'base'
        AND p.contract_address = f.currency
        AND p.minute = date_trunc('minute', f.block_time)
)

SELECT
    block_date AS day,
    currency_symbol,
    SUM(amount) AS total_collected,
    SUM(amount_usd) AS total_collected_usd,
    COUNT(*) AS collection_count
FROM fees_usd
GROUP BY 1, 2
ORDER BY 1 DESC, 4 DESC
