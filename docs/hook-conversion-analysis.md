# Hook 전환 분석: 스킬에서 훅으로

> 참고: [In Defense of Not Reading the Code](https://www.benshoemaker.us/writing/in-defense-of-not-reading-the-code/)
>
> 핵심 인사이트: "각 단계가 끝나면 체크포인트 스킬이 다층 게이트를 실행한다.
> 타입 체크, 린팅, 테스트, 빌드, 뮤테이션 테스트, 보안 스캔이 이루어진다."
> — 이것들은 에이전트가 건너뛸 수 없는 **자동 실행 인프라**여야 한다.

---

## 문제

현재 `verification-loop`과 `security-reviewer`는 수동 호출 스킬/에이전트로 존재한다.
에이전트가 `/verify`나 `/security-review`를 호출하지 않으면 검증 없이 커밋이 가능하다.

**스킬 = "해줘" (요청)** vs **훅 = "반드시" (강제)**

---

## P0: 반드시 Hook으로 전환해야 할 항목

### 1. verification-loop → PreToolUse Hook (git commit 차단)

| 항목 | 현재 | 전환 후 |
|-----|------|--------|
| 트리거 | `/verify` 수동 호출 | `git commit` 명령 자동 감지 |
| 실행 | 선택적 | 강제 |
| 실패 시 | 에이전트 판단에 의존 | 커밋 차단 (deny) |

**동작 방식:**
1. PreToolUse hook이 Bash 명령에서 `git commit` 패턴 감지
2. `pnpm tsc --noEmit && pnpm test && pnpm lint` 순차 실행
3. 하나라도 실패 → `permissionDecision: "deny"` → 커밋 차단
4. 모두 성공 → 커밋 허용

**스크립트:** `custom/hooks/skill-sync/hooks/verify-before-commit.sh`

### 2. security-reviewer (CRITICAL 항목) → PreToolUse Hook (git commit 차단)

| 항목 | 현재 | 전환 후 |
|-----|------|--------|
| 트리거 | `/security-review` 수동 호출 | `git commit` 명령 자동 감지 |
| 범위 | 전체 보안 체크리스트 | CRITICAL만 (자격증명 노출) |
| 실패 시 | 에이전트 판단에 의존 | 커밋 차단 (deny) |

**동작 방식:**
1. PreToolUse hook이 Bash 명령에서 `git commit` 패턴 감지
2. staged 파일에서 하드코딩된 시크릿 패턴 검색
3. CRITICAL 발견 → `permissionDecision: "deny"` → 커밋 차단
4. 클린 → 커밋 허용

**스크립트:** `custom/hooks/skill-sync/hooks/security-check-before-commit.sh`

---

## P1 (다음 작업): Handoff 관련

- `handoff` Resume → Session 시작 시 `docs/handoff/` 자동 읽기
- `handoff` Create → Session 종료 시 인수인계 문서 자동 생성

---

## hooks.json 변경 사항

기존 hooks.json에 PreToolUse Bash matcher를 추가하여
`git commit` 감지 시 verification + security check를 순차 실행.

두 검사를 하나의 스크립트(`pre-commit-gate.sh`)로 통합하여
한 번의 hook 호출로 처리하는 것이 효율적.
