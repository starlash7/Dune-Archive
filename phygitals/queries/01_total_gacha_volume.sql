-- ============================================================
-- 01. Total Gacha Volume (All-time)
-- ============================================================
-- 지표: 전체 팩 구매 금액 (USD)
-- 시각화: Counter  |  Title: Total Gacha Volume
--         Prefix: $  |  Decimals: 0
-- ============================================================
-- Treasury : 62Q9eeDY3eM8A5CnprBGYMPShdBjAzdpBdr71QHsS8dS
-- Excluded : 42oNTirN62M3MkA52KiTTGyf9RnDh2YvqNdpFSgkf97e  (internal)
--            5sn2nniGv88bxzxBDkqWP6i8bejsr9WwCpZXq2ZkLHgf  (internal)
-- USDC Mint: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
-- ============================================================

SELECT
    COALESCE(SUM(amount_usd), 0) AS total_gacha_volume_usd
FROM tokens_solana.transfers
WHERE token_mint_address = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'   -- USDC
  AND to_owner = '62Q9eeDY3eM8A5CnprBGYMPShdBjAzdpBdr71QHsS8dS'              -- Phygitals treasury
  AND from_owner NOT IN (
      '42oNTirN62M3MkA52KiTTGyf9RnDh2YvqNdpFSgkf97e',
      '5sn2nniGv88bxzxBDkqWP6i8bejsr9WwCpZXq2ZkLHgf'
  )
  AND amount_usd > 0.01
