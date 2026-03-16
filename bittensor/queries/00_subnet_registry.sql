-- 00. Subnet Registry
-- 목적: Bittensor 전체 서브넷 카탈로그 — 이름, emission, 가격, 뉴런 현황
-- 차트: Table
--
-- 출력 컬럼:
--   netuid, name, emission_pct, alpha_price, market_cap,
--   volume_24h, neuron_count, max_neurons, utilization_pct,
--   registration_cost, tempo, owner_hotkey
--
-- 테이블: dune.<user>.tao_subnets

SELECT
    netuid,
    name,
    ROUND(emission_pct, 2)                          AS emission_pct,
    ROUND(alpha_price, 4)                            AS alpha_price_tao,
    ROUND(market_cap, 2)                             AS market_cap_tao,
    ROUND(volume_24h, 2)                             AS volume_24h_tao,
    neuron_count,
    max_neurons,
    ROUND(
        CAST(neuron_count AS DOUBLE)
        / NULLIF(max_neurons, 0) * 100
    , 1)                                             AS utilization_pct,
    ROUND(registration_cost, 4)                      AS reg_cost_tao,
    tempo,
    SUBSTR(owner_hotkey, 1, 8)
        || '...'
        || SUBSTR(owner_hotkey, LENGTH(owner_hotkey) - 5)
                                                     AS owner_short
FROM dune.starlash7.tao_subnets
ORDER BY emission_pct DESC
