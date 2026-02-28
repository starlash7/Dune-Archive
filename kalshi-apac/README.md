# Kalshi APAC Impact Dashboard

> **Concept**: APAC(한국/중국) 관점에서 Kalshi 프리딕션 마켓을 분석하는 대시보드.
> 한국 경제에 직접 영향을 미치는 글로벌 이벤트 마켓 + K-Culture 마켓 + APAC 시간대 트레이딩 패턴 분석.

---

## Dune Tables

| Table | Description |
|-------|-------------|
| `kalshi.market_report` | 마켓 메타데이터 (ticker, category, status, volume, open_interest, date) |
| `kalshi.trade_report` | 트레이드 레벨 데이터 (trade_id, ticker, price, count, yes_price, no_price, taker_side, created_time) |

### Column Reference (추정 — Kalshi API 기반)

**kalshi.market_report**
| Column | Type | Note |
|--------|------|------|
| ticker | varchar | 마켓 고유 ID (e.g. `kxtariffrateprc-26`) |
| event_ticker | varchar | 이벤트 그룹 ID |
| title | varchar | 마켓 제목 |
| category | varchar | politics, economics, crypto, culture, climate, sports, world 등 |
| status | varchar | open, closed, settled |
| volume | bigint | 총 거래 볼륨 (contracts) |
| open_interest | bigint | 미결제 약정 |
| close_time | timestamp | 마켓 종료 시간 |
| date | date | 데이터 집계 날짜 |

**kalshi.trade_report**
| Column | Type | Note |
|--------|------|------|
| trade_id | varchar | 트레이드 고유 ID |
| ticker | varchar | 마켓 ticker (market_report JOIN key) |
| yes_price | integer | YES 가격 (cents) |
| no_price | integer | NO 가격 (cents) |
| count | integer | 계약 수 |
| taker_side | varchar | yes / no |
| created_time | timestamp | 트레이드 실행 시각 (UTC) |

> **Note**: 정확한 컬럼명은 Dune 에디터에서 `SELECT * FROM kalshi.market_report LIMIT 10` 으로 확인 필요.
> 위 스키마는 Kalshi REST API 응답 필드 기반 추정.

---

## APAC 필터링 전략

Kalshi 데이터에는 유저 IP/국가 정보가 없음. 대신 다음 전략으로 APAC 관련성을 구성:

| 전략 | 방법 |
|------|------|
| **시간대 필터** | `created_time` 기준 UTC 00:00~09:00 = KST 09:00~18:00 (한국 장중) |
| **마켓 키워드 필터** | title/ticker에 Korea, China, tariff, PRC, BTS, kpop 등 포함 |
| **카테고리 필터** | economics (금리/GDP), crypto (한국 크립토 강국), culture (K-pop) |
| **영향도 매핑** | Fed 금리 → KRW, China 관세 → KOSPI, Crypto → 한국 거래소 볼륨 |

---

## Dashboard Sections & Query Index

### Section 1: Overview Counters
| File | Description | Visualization |
|------|-------------|---------------|
| `00_apac_market_registry.sql` | APAC 관련 마켓 분류 레지스트리 | Table |
| `01_overview_counters.sql` | 핵심 지표 카운터 (APAC 볼륨, 마켓 수, OI) | Counter widgets |

### Section 2: Trading Pattern Analysis
| File | Description | Visualization |
|------|-------------|---------------|
| `02_hourly_trading_heatmap.sql` | 시간대별 트레이딩 볼륨 분포 (APAC 하이라이트) | Bar chart |
| `03_apac_vs_global_sessions.sql` | APAC vs US vs EU 세션별 볼륨 비교 | Stacked bar |

### Section 3: Korea-Impact Markets
| File | Description | Visualization |
|------|-------------|---------------|
| `04_korea_impact_markets.sql` | 한국에 영향 주는 마켓 리스트 + 현재 odds | Table |
| `05_china_tariff_tracker.sql` | 중국 관세율 마켓 odds 추이 | Line chart |
| `06_fed_rate_impact.sql` | Fed 금리 결정 마켓 → KRW 영향 분석 | Line chart |

### Section 4: K-Culture & Crypto
| File | Description | Visualization |
|------|-------------|---------------|
| `07_kculture_markets.sql` | BTS, K-pop, Korean entertainment 마켓 | Table + Bar chart |
| `08_crypto_apac_volume.sql` | Crypto 카테고리 APAC 시간대 볼륨 | Area chart |

### Section 5: Trends & Rankings
| File | Description | Visualization |
|------|-------------|---------------|
| `09_weekly_apac_volume_trend.sql` | 주간 APAC 시간대 볼륨 추이 | Area chart |
| `10_top_apac_markets.sql` | APAC 시간대 볼륨 TOP 마켓 랭킹 | Bar chart |

---

## APAC 관련 마켓 키워드 매핑

### 한국 직접 영향 (High Impact)
| 키워드 | Kalshi Ticker 예시 | 영향 경로 |
|--------|-------------------|-----------|
| `tariff*prc` / `tariff*china` | kxtariffrateprc, kxtariffsprc | 중국 관세 → 한국 수출/KOSPI |
| `fed` / `interest rate` | FOMC 관련 | Fed 금리 → KRW 환율 |
| `recession` | kxrecession | 미국 경기침체 → 글로벌 수요 |
| `gdp` | kxgdp | GDP → 한국 수출 환경 |

### 한국 간접 영향 (Medium Impact)
| 키워드 | 영향 경로 |
|--------|-----------|
| `bitcoin` / `ethereum` / `crypto` | 한국 크립토 거래량 세계 상위 |
| `s&p 500` / `nasdaq` | 미국 증시 → KOSPI 동조화 |
| `cpi` / `inflation` | 글로벌 인플레 → BOK 정책 |
| `oil` / `wti` | 에너지 수입국 한국 직접 영향 |

### K-Culture (Direct Korea)
| 키워드 | 설명 |
|--------|------|
| `bts` / `kpop` / `k-pop` | BTS 앨범 판매, K-pop 그래미 |
| `korean` / `korea` | 한국 직접 관련 이벤트 |
| `samsung` / `kospi` | 한국 기업/주식 (현재 마켓 없음, 향후 추가 시 대응) |

---

## References

- [Kalshi Dune Integration](https://dune.com/blog/kalshi-is-now-live-on-dune)
- [Kalshi Dune Docs](https://docs.dune.com/data-catalog/kalshi/overview)
- [Kalshi API - Get Markets](https://docs.kalshi.com/api-reference/market/get-markets)
- [Kalshi API - Get Trades](https://docs.kalshi.com/api-reference/market/get-trades)
- [Existing Kalshi Overview Dashboard](https://dune.com/datadashboards/kalshi-overview)
- [Kalshi Economics Category](https://kalshi.com/category/economics)
- [Tariff Rate China Market](https://kalshi.com/markets/kxtariffrateprc/tariff-rate-china)
