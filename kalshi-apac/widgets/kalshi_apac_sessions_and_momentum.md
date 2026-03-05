# APAC / Global Trading Sessions & Market Momentum

## Trading Session Definitions

Kalshi operates 24/7 as a US-regulated (CFTC) event contract exchange, but trading activity is not uniformly distributed across the day. This dashboard segments global activity into four overlapping sessions based on UTC time zones:

| Session | UTC Window | Local Reference | Characteristics |
|---------|-----------|-----------------|-----------------|
| **APAC** | 00:00 - 09:00 | KST 09:00-18:00 / JST 09:00-18:00 | Korean & Japanese business hours. Reacts to overnight US news, Asian macro data releases, BOK/BOJ policy signals |
| **EU** | 07:00 - 16:00 | CET 08:00-17:00 / GMT 07:00-16:00 | European session. ECB policy, EU economic data, overlap with late APAC and early US |
| **US** | 13:00 - 21:00 | EST 08:00-16:00 / PST 05:00-13:00 | Peak liquidity window. FOMC announcements, US economic releases (CPI, NFP, GDP), highest volume concentration |
| **Global Macro** | All hours | - | Aggregate view across all sessions. Captures 24h events like crypto movements, breaking geopolitical news, overnight tariff announcements |

> **Note**: Kalshi's `trade_report` table uses `date` (daily granularity) rather than intraday timestamps, so session-level breakdowns in this dashboard are approximated through **keyword-based APAC relevance tagging** rather than exact UTC hour filtering.

---

## APAC Volume Share: How Much of Kalshi is Asia-Relevant?

The **APAC Volume Share** analysis (Query 16) measures what percentage of total Kalshi trading volume flows through markets that directly or indirectly impact the Asia-Pacific region. This is not a geographic filter (Kalshi does not expose trader location), but a **thematic relevance score** based on market keywords.

**What counts as "APAC-relevant":**
- **Direct impact**: China tariffs, Korea trade, PRC policy, Korean cultural events (BTS, K-pop)
- **Macro transmission**: Fed rate decisions (KRW/USD exchange rate), US recession risk (Korean export demand), oil/WTI prices (Korea as net energy importer)
- **Cross-market correlation**: Bitcoin/Ethereum (Korea ranks top-3 globally in crypto trading volume), S&P 500/NASDAQ (KOSPI correlation >0.7), CPI/inflation (BOK policy input)

**Key metrics tracked weekly:**
- `apac_share_pct` - APAC-relevant volume as % of total Kalshi volume
- `wow_share_change` - Week-over-week percentage point shift
- `apac_market_count` - Number of distinct APAC-tagged markets active that week

A rising APAC share indicates growing global attention to Asia-impacting events (e.g., tariff escalation periods, FOMC weeks, crypto rallies during Asian hours).

---

## APAC Hot Predictions: Real-Time Momentum Leaderboard

The **Hot Predictions** leaderboard (Query 14) ranks APAC-relevant markets by a composite **Activity Score** that captures recent trading momentum. This answers: *"Which Asia-impacting predictions are attracting the most attention right now?"*

**Activity Score formula:**
```
Activity Score = 40% x (volume_7d normalized) + 30% x (trades_7d normalized) + 30% x (open_interest normalized)
```

Each component is normalized against the top performer in its category (0-100 scale), so the #1 market always scores near 100.

**APAC Tag classification:**

| Tag | Keywords | Korea Impact Path |
|-----|----------|-------------------|
| **Korea/China Trade** | tariff, china, prc, korea, bts, kpop | Direct: KOSPI, exports, KRW |
| **Fed/Oil/Macro** | fed, interest rate, oil, wti, recession | Transmission: BOK policy, energy costs, export demand |
| **Crypto/Equity** | bitcoin, ethereum, crypto, s&p, nasdaq, cpi, inflation | Correlation: Upbit/Bithumb volume, KOSPI beta |

**Impact Level** (HIGH / MEDIUM / LOW) reflects the directness and magnitude of Korea economic impact:
- **HIGH** = Korea/China Trade tag (direct trade flow & geopolitical exposure)
- **MEDIUM** = Fed/Oil/Macro tag (monetary policy transmission channel)
- **LOW** = Crypto/Equity tag (market correlation & sentiment spillover)

**How to read the leaderboard:**
- **WoW Volume Change %** > 0 means accelerating interest; negative means cooling
- **Latest Price** near 50 = maximum uncertainty = highest trading opportunity
- **Activity Score** drop-off from #1 to #5 shows concentration vs. broad interest

---

## Combining the Views

These two analyses work together as a complete APAC monitoring framework:

1. **Volume Share** (macro view) - answers "Is Asia becoming more important to Kalshi overall?"
2. **Hot Predictions** (micro view) - answers "Which specific Asia-impacting markets should I watch today?"
3. **Tag Trend Shift** (Query 15) bridges both - shows how thematic attention rotates between Korea/China Trade, Fed/Macro, and Crypto/Equity over time

When APAC volume share rises AND Hot Predictions cluster around Korea/China Trade with HIGH impact, it typically signals a major Asia-relevant event window (tariff announcements, FOMC meetings, BOK rate decisions).

---

*Data source: `kalshi.trade_report` via [Dune Analytics](https://dune.com) | Updated daily*
