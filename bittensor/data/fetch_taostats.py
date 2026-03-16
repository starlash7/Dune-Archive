#!/usr/bin/env python3
"""
Taostats API → CSV 변환 스크립트
Bittensor 서브넷/밸리데이터/스테이킹/가격 데이터를 CSV로 추출하여 Dune에 업로드

사용법:
  1. https://dash.taostats.io 에서 API 키 발급
  2. export TAOSTATS_API_KEY="your-key-here"   또는  .env 파일에 저장
  3. pip install -r requirements.txt
  4. python fetch_taostats.py

출력: bittensor/data/csv/ 디렉토리에 6개 CSV 생성
"""

import os
import sys
import csv
import time
import json
import logging
from pathlib import Path
from datetime import datetime, timedelta

import requests
from dotenv import load_dotenv

# ── 설정 ──────────────────────────────────────────────
load_dotenv()

API_KEY = os.environ.get("TAOSTATS_API_KEY", "")
BASE_URL = "https://api.taostats.io/api"
OUTPUT_DIR = Path(__file__).parent / "csv"
MAX_RETRIES = 3
RETRY_DELAY = 21  # Taostats 429 기본 대기 시간(초)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-7s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("taostats")


# ── HTTP 헬퍼 ─────────────────────────────────────────
def api_get(path: str, params: dict | None = None) -> list[dict]:
    """
    GET 요청 + 페이지네이션 + 429/5xx 재시도.
    모든 페이지를 순회하여 전체 결과를 리스트로 반환.
    """
    url = f"{BASE_URL}/{path}"
    headers = {
        "accept": "application/json",
        "Authorization": API_KEY,
    }
    if params is None:
        params = {}
    params.setdefault("limit", 200)

    all_data: list[dict] = []
    page = 1

    while True:
        params["page"] = page
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                resp = requests.get(url, headers=headers, params=params, timeout=30)
            except requests.RequestException as e:
                log.warning("  요청 실패 (attempt %d): %s", attempt, e)
                time.sleep(RETRY_DELAY)
                continue

            if resp.status_code == 200:
                break
            elif resp.status_code == 429:
                wait = int(resp.headers.get("Retry-After", RETRY_DELAY))
                log.warning("  429 Rate-limit → %ds 대기 (attempt %d)", wait, attempt)
                time.sleep(wait)
            elif resp.status_code >= 500:
                log.warning("  %d 서버 에러 → 재시도 (attempt %d)", resp.status_code, attempt)
                time.sleep(RETRY_DELAY)
            else:
                log.error("  %d %s — %s", resp.status_code, resp.reason, resp.text[:200])
                return all_data
        else:
            log.error("  최대 재시도 초과: %s", url)
            return all_data

        body = resp.json()

        # 응답 구조: {"data": [...]} 또는 바로 [...]
        if isinstance(body, dict) and "data" in body:
            rows = body["data"]
        elif isinstance(body, list):
            rows = body
        else:
            rows = [body]

        if not rows:
            break

        all_data.extend(rows)
        log.info("  page %d → %d rows (누적 %d)", page, len(rows), len(all_data))

        # 페이지가 limit 미만이면 마지막 페이지
        if len(rows) < params["limit"]:
            break
        page += 1

    return all_data


def flatten(obj: dict, prefix: str = "") -> dict:
    """중첩 dict를 flat dict로 변환"""
    items: dict = {}
    for k, v in obj.items():
        key = f"{prefix}{k}" if not prefix else f"{prefix}_{k}"
        if isinstance(v, dict):
            items.update(flatten(v, key))
        elif isinstance(v, list):
            items[key] = json.dumps(v)
        else:
            items[key] = v
    return items


def save_csv(rows: list[dict], filename: str) -> Path:
    """리스트[dict]를 CSV로 저장"""
    if not rows:
        log.warning("  %s — 데이터 없음, 스킵", filename)
        return OUTPUT_DIR / filename

    flat = [flatten(r) for r in rows]
    filepath = OUTPUT_DIR / filename
    keys = list(flat[0].keys())
    # 모든 행에서 키 수집 (행마다 키가 다를 수 있음)
    all_keys = set()
    for row in flat:
        all_keys.update(row.keys())
    keys = sorted(all_keys)

    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=keys, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(flat)

    log.info("  ✓ %s — %d rows, %d cols", filename, len(flat), len(keys))
    return filepath


# ── 데이터 페처 ───────────────────────────────────────

def fetch_subnets() -> list[dict]:
    """서브넷 목록 (dTAO 포함)"""
    log.info("[1/6] 서브넷 목록 조회...")
    # dTao subnet endpoint
    data = api_get("dtao/subnet/latest/v1")
    if not data:
        # fallback: 기존 subnet endpoint
        log.info("  dtao 엔드포인트 실패, subnet/latest/v1 시도...")
        data = api_get("subnet/latest/v1")
    return data


def fetch_metagraph(netuids: list[int] | None = None) -> list[dict]:
    """
    메타그래프 (밸리데이터 + 마이너).
    상위 서브넷만 조회하여 API 호출 최소화.
    """
    log.info("[2/6] 메타그래프 조회...")
    if netuids is None:
        netuids = list(range(1, 21))  # 상위 20개 서브넷

    all_neurons: list[dict] = []
    for netuid in netuids:
        log.info("  netuid=%d", netuid)
        rows = api_get("metagraph/latest/v1", {"netuid": netuid})
        for r in rows:
            r["netuid"] = netuid
        all_neurons.extend(rows)
    return all_neurons


def fetch_validators(metagraph: list[dict]) -> list[dict]:
    """메타그래프에서 밸리데이터만 필터"""
    log.info("[3/6] 밸리데이터 필터링...")
    validators = []
    for n in metagraph:
        # is_validator 또는 stake_weight > 0 + dividends > 0
        is_val = n.get("is_validator") or n.get("validator_permit")
        if is_val:
            validators.append(n)
    log.info("  밸리데이터 %d명 추출", len(validators))
    return validators


def fetch_stake_balances() -> list[dict]:
    """스테이크 잔액"""
    log.info("[4/6] 스테이크 잔액 조회...")
    return api_get("dtao/stake_balance/latest/v1")


def fetch_price_history() -> list[dict]:
    """TAO 가격 히스토리 (180일)"""
    log.info("[5/6] 가격 히스토리 조회...")
    end = datetime.utcnow()
    start = end - timedelta(days=180)
    return api_get("price/history/v1", {
        "asset": "tao",
        "timestamp_start": start.strftime("%Y-%m-%d"),
        "timestamp_end": end.strftime("%Y-%m-%d"),
    })


def fetch_network_stats() -> list[dict]:
    """네트워크 통계"""
    log.info("[6/6] 네트워크 통계 조회...")
    return api_get("stats/latest/v1")


# ── 메인 ──────────────────────────────────────────────

def main():
    if not API_KEY:
        log.error("TAOSTATS_API_KEY 환경변수가 설정되지 않았습니다.")
        log.error("  export TAOSTATS_API_KEY='your-key'")
        log.error("  또는 bittensor/data/.env 파일에 TAOSTATS_API_KEY=your-key 추가")
        sys.exit(1)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    log.info("출력 디렉토리: %s", OUTPUT_DIR)
    log.info("=" * 50)

    # 1. 서브넷
    subnets = fetch_subnets()
    save_csv(subnets, "tao_subnets.csv")

    # 서브넷 ID 추출 (메타그래프 조회용)
    netuids = [s.get("netuid") for s in subnets if s.get("netuid") is not None]
    top_netuids = sorted(netuids)[:20]  # 상위 20개만

    # 2. 메타그래프
    metagraph = fetch_metagraph(top_netuids)
    save_csv(metagraph, "tao_metagraph.csv")

    # 3. 밸리데이터
    validators = fetch_validators(metagraph)
    save_csv(validators, "tao_validators.csv")

    # 4. 스테이크 잔액
    stakes = fetch_stake_balances()
    save_csv(stakes, "tao_stake_balances.csv")

    # 5. 가격 히스토리
    prices = fetch_price_history()
    save_csv(prices, "tao_price_history.csv")

    # 6. 네트워크 통계
    stats = fetch_network_stats()
    save_csv(stats, "tao_network_stats.csv")

    log.info("=" * 50)
    log.info("완료! CSV 파일 위치: %s", OUTPUT_DIR)
    log.info("다음 단계: Dune → Data → Upload CSV 로 업로드하세요.")


if __name__ == "__main__":
    main()
