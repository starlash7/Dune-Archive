-- Clober V2 Maker vs Taker Ratio (Base + Monad)
-- Daily Make/Take/Cancel event counts and maker-taker ratio per chain
-- Visualization: Dual-axis line chart (bars: event counts, line: ratio)

WITH events AS (
    SELECT
        'base' AS chain,
        block_date,
        CASE
            WHEN topic0 = 0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a THEN 'Make'
            WHEN topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b THEN 'Take'
            WHEN topic0 = 0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72 THEN 'Cancel'
        END AS event_type
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND (
          topic0 = 0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a
       OR topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
       OR topic0 = 0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72
      )

    UNION ALL

    SELECT
        'monad' AS chain,
        block_date,
        CASE
            WHEN topic0 = 0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a THEN 'Make'
            WHEN topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b THEN 'Take'
            WHEN topic0 = 0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72 THEN 'Cancel'
        END AS event_type
    FROM monad_testnet.logs
    WHERE contract_address = 0x6657d192273731c3cac646cc82d5f28d0cbe8ccc
      AND (
          topic0 = 0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a
       OR topic0 = 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b
       OR topic0 = 0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72
      )
)

SELECT
    block_date AS day,
    chain,
    COUNT(CASE WHEN event_type = 'Make'   THEN 1 END) AS make_count,
    COUNT(CASE WHEN event_type = 'Take'   THEN 1 END) AS take_count,
    COUNT(CASE WHEN event_type = 'Cancel' THEN 1 END) AS cancel_count,
    ROUND(
        COUNT(CASE WHEN event_type = 'Make' THEN 1 END) * 1.0
        / NULLIF(COUNT(CASE WHEN event_type = 'Take' THEN 1 END), 0),
        2
    ) AS maker_taker_ratio
FROM events
GROUP BY 1, 2
ORDER BY 1, 2
