-- ============================================================
-- 01. Total Gacha Volume (All-time)
-- ============================================================
-- 지표: 전체 팩 구매 금액 (USD)
-- 시각화: Counter
-- 설명: Phygitals 플랫폼에서 발생한 모든 가챠/팩 구매의
--       누적 USDC 결제 금액을 집계합니다.
-- ============================================================
-- ⚠️  TODO: 아래 주소를 Phygitals treasury/payment 지갑 주소로 교체하세요
--     Solscan에서 확인: https://solscan.io
-- ============================================================

SELECT
    COALESCE(SUM(amount), 0) AS total_gacha_volume_usd
FROM tokens_solana.transfers
WHERE token_mint_address = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'   -- USDC on Solana
  AND to_owner = '{{phygitals_treasury_wallet}}'                               -- Phygitals treasury wallet
