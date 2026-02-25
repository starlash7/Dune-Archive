# Clober Dashboard

Dune SQL queries for [Clober V2 DEX Dashboard](https://dune.com/unit_tx/clober-dashboard).

## Contracts

| Chain | BookManager Address |
|-------|-------------------|
| Base (8453) | `0x8ca3a6f4a6260661fcb9a25584c796a1fa380112` |
| Arbitrum (42161) | `0x74ffe45757db60b24a7574b3b5948dad368c2fdf` |
| Monad (143) | `0x6657d192273731c3cac646cc82d5f28d0cbe8ccc` |

## Event Signatures

| Event | Topic0 |
|-------|--------|
| Open | `0x803427d75ce3214f82dc7aa4910635170a6655e2c1663dc03429dd04100cba5a` |
| Make | `0x251db4df45fa692f68b4e3f072919384c5b71995c71bf22888385168930fd22a` |
| Take | `0xc4c20b9c4a5ada3b01b7a391a08dd81a1be01dd8ef63170dd9da44ecee3db11b` |
| Cancel | `0x0c6ba7ef5064094c17cce013aa4c617a23e2582f867774d07a5931de43b85d72` |
| Claim | `0xfc7df80a30ee916cc040221cf6fcfb3c6dc994b3fa4c4ab23e8a0f134de5c0c0` |
| Collect | `0x1c4f94f28cc9152354d4b98b8614b28c6c828a98d88228fa9577c7b9475e120c` |

## Queries

| File | Description | Visualization |
|------|-------------|---------------|
| `00_books_registry.sql` | All opened books (trading pairs) with metadata | Table |
| `01_total_metrics.sql` | Summary counters (volume, trades, users, markets) | Counters |
| `02_daily_volume.sql` | Daily trading volume in USD | Bar chart |
| `03_cumulative_volume.sql` | Cumulative trading volume over time | Area chart |
| `04_volume_by_pair.sql` | Volume breakdown by trading pair | Pie chart |
| `05_daily_trades_and_users.sql` | Daily trade count and unique traders | Line chart |
| `06_order_flow.sql` | Daily Make/Take/Cancel/Claim event counts | Stacked bar |
| `07_top_traders.sql` | Top traders by volume | Table |
| `08_fee_collection.sql` | Fee collection analysis | Bar chart |

## Price Mechanism

Clober V2 uses a tick-based pricing system identical to Uniswap V3:
- `price(tick) = 1.0001^tick` (normalized)
- `quoteAmount = unit * unitSize`
- `baseAmount = quoteAmount / 1.0001^tick`
