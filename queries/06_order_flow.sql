-- Clober V2 Order Flow (Base)
-- Daily Make/Take/Cancel/Claim event counts
-- Visualization: Stacked bar chart (x: day, y: count, color: event_type)

WITH events AS (
    SELECT
        block_date,
        CASE topic0
            WHEN 0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a THEN 'Make'
            WHEN 0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b THEN 'Take'
            WHEN 0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72 THEN 'Cancel'
            WHEN 0xfc7df80a30ee916cc040221cf6fcfb3c6dc994b3fa4c4ab23e8a0f134de5c0c0 THEN 'Claim'
        END AS event_type
    FROM base.logs
    WHERE contract_address = 0x8ca3a6f4a6260661fcb9a25584c796a1fa380112
      AND topic0 IN (
          0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a,
          0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b,
          0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72,
          0xfc7df80a30ee916cc040221cf6fcfb3c6dc994b3fa4c4ab23e8a0f134de5c0c0
      )
)

SELECT
    block_date AS day,
    event_type,
    COUNT(*) AS event_count
FROM events
GROUP BY 1, 2
ORDER BY 1, 2
