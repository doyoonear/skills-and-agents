---
name: perf-bottleneck-finder
description: |
  웹 애플리케이션의 성능 병목 지점을 탐색하고 구간별 측정을 수행하는 스킬.
  Playwright 자동 측정, DevTools 분석 가이드, 서버/DB 프로파일링을 포함하여
  프론트엔드부터 백엔드까지 전 구간의 병목을 정량적으로 식별합니다.
  Use when finding performance bottlenecks, profiling page load, measuring API response time,
  or when delegated from performance-improve-process skill.
  Not for general performance optimization process — use performance-improve-process for that.
---

# Performance Bottleneck Finder

성능 병목 지점을 찾고 구간별 시간을 정량적으로 측정하는 스킬입니다.

> **원칙: 직감을 믿지 말고 측정하라.** 개발자가 병목이라고 추측한 지점이 실제 병목인 경우는 절반도 되지 않는다.

---

## 전체 흐름

```
"느리다" 제보
    │
    ▼
[Phase 1] 문제 정의 — "무엇이 느린가?" 를 구체화
    │
    ▼
[Phase 2] 자동 측정 — Playwright로 페이지 성능 자동 수집
    │
    ▼
[Phase 3] 구간 분해 — 전체 시간을 프론트/네트워크/서버/DB로 분리
    │
    ▼
[Phase 4] 병목 판단 — 비율 분석으로 우선순위 결정
    │
    ▼
[Output] 병목 보고서 — 구간별 시간 + 비율 + 개선 우선순위
```

---

## Phase 1: 문제 정의

"느리다"는 주관적 표현이다. 반드시 아래 항목을 확인하여 측정 대상을 특정한다.

### 확인 항목

| 항목 | 질문 | 예시 |
|------|------|------|
| 어디서 | 어떤 페이지/화면에서? | "대시보드 페이지" |
| 언제 | 초기 로딩? 인터랙션 중? | "페이지 진입 시" |
| 어떻게 | 어떤 동작이 느린가? | "데이터가 표시되기까지" |
| 얼마나 | 체감 몇 초? | "약 4~5초" |
| 재현 | 항상? 특정 조건? | "데이터가 많을 때" |

### 재현 시나리오 확정

```
시나리오: [페이지/기능 이름]
트리거: [사용자 액션]
종료 조건: [완료 시점]
환경: [브라우저, 디바이스, 네트워크, 데이터 규모]
```

---

## Phase 2: Playwright 자동 측정

### 스크립트 실행

```bash
python scripts/measure_page_performance.py --url "http://localhost:3000/dashboard" --runs 3
```

**스크립트 옵션:**
- `--url`: 측정 대상 URL (필수)
- `--runs`: 반복 측정 횟수 (기본값 3, 평균 산출)
- `--output`: 결과 저장 파일 경로 (기본값: stdout)
- `--wait-for`: 측정 종료를 판단할 셀렉터 (예: `[data-loaded="true"]`)
- `--auth-cookie`: 인증이 필요한 경우 쿠키 값

**자동 측정 항목:**
- Page Load 전체 시간 (navigationStart → loadEventEnd)
- DOMContentLoaded 시간
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Time to Interactive (TTI)
- API 요청별 TTFB 및 총 소요 시간
- 응답 크기 (bytes)
- JavaScript 실행 시간
- 렌더링/페인팅 시간

### agent-browser로 수동 측정 (스크립트 대안)

스크립트 실행이 어려운 경우 agent-browser CLI를 활용한다:

```bash
# 1. 대상 페이지로 이동 + 네트워크 안정화
agent-browser open <url> && agent-browser wait --load networkidle

# 2. Performance API로 타이밍 데이터 수집
agent-browser eval --stdin <<'EVALEOF'
JSON.stringify({
  navigation: performance.getEntriesByType('navigation')[0],
  paint: performance.getEntriesByType('paint'),
  resources: performance.getEntriesByType('resource')
    .filter(r => r.initiatorType === 'fetch' || r.initiatorType === 'xmlhttprequest')
})
EVALEOF

# 3. 접근성 스냅샷으로 구조 확인
agent-browser snapshot -i

# 4. 시각적 상태 기록
agent-browser screenshot
```

**Performance API 측정 코드:**

```javascript
// browser_evaluate로 실행
() => {
  const nav = performance.getEntriesByType('navigation')[0];
  const paint = performance.getEntriesByType('paint');
  const resources = performance.getEntriesByType('resource')
    .filter(r => r.initiatorType === 'fetch' || r.initiatorType === 'xmlhttprequest');

  return {
    pageLoad: {
      total: Math.round(nav.loadEventEnd - nav.startTime),
      domContentLoaded: Math.round(nav.domContentLoadedEventEnd - nav.startTime),
      domInteractive: Math.round(nav.domInteractive - nav.startTime),
      ttfb: Math.round(nav.responseStart - nav.requestStart),
    },
    paint: paint.map(p => ({ name: p.name, time: Math.round(p.startTime) })),
    apiRequests: resources.map(r => ({
      name: r.name.split('/').pop(),
      url: r.name,
      ttfb: Math.round(r.responseStart - r.requestStart),
      total: Math.round(r.responseEnd - r.startTime),
      size: r.transferSize,
    })),
  };
}
```

---

## Phase 3: 구간 분해

전체 소요 시간을 다음 구간으로 분리한다.

### 프론트엔드 구간

```
사용자 액션 발생
  │
  ├─[A] JS 번들 로딩 + 파싱 ────── ?ms
  ├─[B] 컴포넌트 마운트 ─────── ?ms
  ├─[C] API 요청 발송 대기 ────── ?ms
  ├─[D] 응답 수신 후 상태 업데이트 ─ ?ms
  └─[E] 렌더링 + 페인트 ──────── ?ms
```

**측정 도구:**
- Chrome DevTools → Performance 탭 녹화
- React Profiler (React 프로젝트)
- Performance API marks/measures

**React Profiler 활용:**

```
1. React DevTools → Profiler 탭
2. 녹화 시작 → 시나리오 수행 → 녹화 중지
3. 확인: 각 컴포넌트 렌더 횟수, 렌더 소요 시간, 불필요 리렌더 여부
```

### 네트워크 구간

```
API 요청 전송
  │
  ├─[F] DNS Lookup ──────── ?ms
  ├─[G] TCP Connection ──── ?ms
  ├─[H] TLS Handshake ───── ?ms
  ├─[I] TTFB (서버 처리) ─── ?ms  ← 핵심 지표
  └─[J] Content Download ─── ?ms
```

**측정 도구:**
- Chrome DevTools → Network 탭 → 각 요청의 Timing 탭
- `performance.getEntriesByType('resource')` API

**TTFB 판단 기준:**
- < 200ms: 양호
- 200~600ms: 보통
- 600ms~2s: 느림 (서버 최적화 필요)
- > 2s: 심각 (DB 쿼리 또는 서버 로직 점검 필수)

### 서버 사이드 구간

```
API 요청 수신
  │
  ├─[K] 미들웨어 처리 ───── ?ms
  ├─[L] 비즈니스 로직 ───── ?ms
  ├─[M] DB 쿼리 실행 ────── ?ms  ← 빈번한 병목
  ├─[N] 외부 API 호출 ───── ?ms
  └─[O] 응답 직렬화 ─────── ?ms
```

**측정 방법:**

서버 코드에 타이밍 로그를 삽입한다:

```python
# Python/FastAPI 예시
import time

@app.get("/api/dashboard")
async def get_dashboard():
    timings = {}
    t0 = time.perf_counter()

    t1 = time.perf_counter()
    users = await db.query("SELECT ...")
    timings["db_users"] = (time.perf_counter() - t1) * 1000

    t1 = time.perf_counter()
    orders = await db.query("SELECT ...")
    timings["db_orders"] = (time.perf_counter() - t1) * 1000

    t1 = time.perf_counter()
    result = aggregate(users, orders)
    timings["processing"] = (time.perf_counter() - t1) * 1000

    timings["total"] = (time.perf_counter() - t0) * 1000
    logger.info(f"Dashboard API timings: {timings}")
    return result
```

```typescript
// Node.js/Express 예시
app.get('/api/dashboard', async (req, res) => {
  const timings: Record<string, number> = {};
  const t0 = performance.now();

  let t1 = performance.now();
  const users = await db.query('SELECT ...');
  timings.db_users = performance.now() - t1;

  t1 = performance.now();
  const orders = await db.query('SELECT ...');
  timings.db_orders = performance.now() - t1;

  t1 = performance.now();
  const result = aggregate(users, orders);
  timings.processing = performance.now() - t1;

  timings.total = performance.now() - t0;
  console.log('Dashboard API timings:', timings);
  res.json(result);
});
```

### DB 쿼리 구간

**측정 방법:**
- `EXPLAIN ANALYZE` (PostgreSQL) / `EXPLAIN` (MySQL)
- ORM 쿼리 로깅 활성화
- Slow query log 확인

```sql
-- PostgreSQL
EXPLAIN ANALYZE SELECT * FROM orders WHERE date > '2026-01-01';

-- 결과에서 확인:
-- Planning Time: 0.5ms
-- Execution Time: 2680.3ms  ← 실제 실행 시간
-- Seq Scan vs Index Scan 여부
```

---

## Phase 4: 병목 판단

### 비율 분석

모든 구간의 측정값을 수집한 뒤, 전체 대비 비율을 계산한다.

```
전체 ????ms 중:

  구간 이름        시간      비율
  ─────────────  ────────  ──────
  DB쿼리(orders)  2680ms   62%   ← 1순위 병목
  렌더링          1390ms   32%   ← 2순위 병목
  DB쿼리(users)    124ms    3%
  기타              138ms    3%
```

### 판단 프레임워크

```
[규칙 1] 80/20 법칙
  → 전체 시간의 80%를 차지하는 상위 구간에 집중

[규칙 2] 절대값 기준 병행
  → 비율이 높아도 절대값이 작으면 개선 효과 미미
  → 예: 전체 200ms 중 50%인 100ms → 최적화 가치 낮음

[규칙 3] 개선 가능성
  → 물리적 한계(네트워크 지연)보다 쿼리/로직 최적화가 개선폭 큼
  → 쉽게 큰 개선이 가능한 구간을 우선 공략

[규칙 4] 의존관계
  → 직렬 체인의 시작점(root cause)부터 해결
  → 예: API가 느리면 → 프론트 렌더도 늦게 시작 → API부터 해결
```

### 개선 유형별 가이드

| 병목 위치 | 일반적 원인 | 개선 방향 |
|-----------|------------|-----------|
| DB 쿼리 | 인덱스 부재, N+1, 풀스캔 | 인덱스 추가, 쿼리 최적화, 페이지네이션 |
| API 서버 로직 | 동기 처리, 불필요한 연산 | 비동기화, 캐싱, 로직 간소화 |
| 네트워크 전송 | 응답 크기 과다 | gzip, 필드 선택, 페이지네이션 |
| JS 번들 | 번들 크기 과다 | 코드 스플리팅, tree-shaking, lazy load |
| 렌더링 | 과다 리렌더, 대량 DOM | 가상화, 메모이제이션, 리렌더 방지 |
| 외부 API | 응답 지연 | 캐싱, 타임아웃 설정, 병렬 호출 |

---

## Output: 병목 보고서

측정 완료 후 아래 형식으로 결과를 보고한다.

```
┌─────────────────────────────────────────────────────┐
│ 성능 병목 분석 보고서                                  │
├─────────────────────────────────────────────────────┤
│ 시나리오: [측정 대상]                                  │
│ 날짜: [측정 일시]                                     │
│ 환경: [브라우저, 디바이스, 네트워크, 데이터 규모]         │
│ 반복 횟수: [N회 평균]                                  │
├─────────────────────────────────────────────────────┤
│ 구간               │ 평균     │ 비율   │ 비고        │
│ ──────────────────│─────────│───────│────────────│
│ [구간 A]           │ ????ms  │ ??%   │            │
│ [구간 B]           │ ????ms  │ ??%   │ ← 1순위    │
│ [구간 C]           │ ????ms  │ ??%   │            │
│ ...                │         │       │            │
│────────────────────│─────────│───────│────────────│
│ 합계               │ ????ms  │ 100%  │            │
├─────────────────────────────────────────────────────┤
│ 병목 우선순위                                         │
│ 1. [구간명] — [원인 추정] — [개선 방향]                 │
│ 2. [구간명] — [원인 추정] — [개선 방향]                 │
└─────────────────────────────────────────────────────┘
```

---

## 재측정 (변경 후)

performance-improve-process 에서 변경을 적용한 뒤 재측정을 요청하면, 동일한 시나리오와 환경에서 측정을 반복하여 이전 baseline과 비교한다.

```
┌──────────────────────────────────────────────────────┐
│ 변경 전후 비교                                         │
├──────────────────────────────────────────────────────┤
│ 구간               │ Before   │ After    │ 변화      │
│ ──────────────────│─────────│─────────│──────────│
│ DB쿼리(orders)     │ 2680ms  │  340ms  │ -2340ms  │
│ 렌더링             │ 1390ms  │ 1390ms  │ 변화없음   │
│────────────────────│─────────│─────────│──────────│
│ 합계               │ 4332ms  │ 1992ms  │ -2340ms  │
└──────────────────────────────────────────────────────┘
```
