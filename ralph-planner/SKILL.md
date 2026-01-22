---
name: ralph-planner
description: |
  Ralph를 사용한 프로젝트 플래닝 및 자동 실행 시스템입니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "ralph를 사용해서 [작업 설명]"
  - "Ralph로 [작업] 해줘"
  - "/ralph [type] [설명]"
  - "ralph feature/bugfix/refactor/optimize [설명]"
  한글 트리거: "ralph 써서", "랄프로", "Ralph 사용해서" 등의 요청이 있을 때 사용.
---

# Ralph Planner

작업 분석 → 프롬프트 생성 → **자체 구현 Stop Hook**을 통한 자동 반복 실행 워크플로우.

## 핵심 개념

Ralph Loop는 **Stop Hook 기반 자기 참조 루프**:
- Claude가 종료하려 할 때 Stop Hook이 가로채서 프롬프트 재주입
- 컨텍스트 초기화 후 같은 프롬프트로 재시작
- 진행 상황은 **파일과 git 히스토리**에 저장
- 장시간 무인 작업에 최적화

## 워크플로우

```
요청 분석 → 유형/복잡도 판단 → 프롬프트 생성 → setup-ralph.sh 실행 → Claude에 프롬프트 전달 → Stop Hook이 루프 관리
```

## Phase 1: 요청 분석

### 유형 판단

| 유형 | 키워드 | 용도 |
|------|--------|------|
| `feature` | 기능 추가, 새 기능, 구현, 만들어줘 | 새로운 기능 개발 |
| `bugfix` | 버그, 수정, 고쳐줘, 에러 | 버그 수정 |
| `refactor` | 리팩토링, 정리, 구조 변경 | 코드 개선 |
| `optimize` | 최적화, 성능, 빠르게 | 성능 개선 |

유형 불분명 시 → AskUserQuestion으로 확인.

### 복잡도 판단 (→ max-iterations 결정)

| 복잡도 | 기준 | iterations |
|--------|------|------------|
| **small** | 단일 파일, 간단한 변경 | 10 |
| **medium** | 2-5개 파일, 중간 규모 변경 | 30 |
| **large** | 6개+ 파일, 대규모 변경, 신규 기능 | 50 |

**판단 기준:**
- 영향받는 파일 수
- 신규 코드 vs 수정
- 테스트 필요 여부
- 의존성 복잡도

## Phase 2: 코드베이스 분석

1. `package.json` 확인 (기술 스택, 의존성)
2. 관련 코드 탐색 (기존 유사 기능, 영향받는 파일)
3. 테스트 설정 확인 (jest, vitest 등)
4. lint/type 설정 확인

## Phase 3: 프롬프트 생성

### 프롬프트 구조 (필수 포함 요소)

```markdown
# [TYPE]: [제목]

## Context
[package.json 기반 프로젝트 정보]
[기술 스택, 주요 의존성]

## Requirements
[사용자 요구사항 - 명확하고 구체적으로]

## Implementation Plan (with Commit Points)
1. [구체적 단계]
   - **Commit**: `[type]: [커밋 메시지]`
   - **Compaction**: 커밋 후 /compact 실행
2. [구체적 단계]
   - **Commit**: `[type]: [커밋 메시지]`
   - **Compaction**: 커밋 후 /compact 실행
...

## Success Criteria (자동 검증 가능해야 함)
- [ ] [검증 가능한 조건 1]
- [ ] [검증 가능한 조건 2]
- [ ] 모든 테스트 통과
- [ ] lint/type 에러 없음

## Completion
모든 Success Criteria 충족 시 출력:
<promise>[TYPE]_DONE</promise>

## If Stuck (15회 반복 후에도 미완료 시)
- 진행 차단 요소 문서화
- 시도한 방법 목록 작성
- 대안 접근법 제안
```

### completion-promise 규칙

| 유형 | Promise |
|------|---------|
| feature | `FEATURE_DONE` |
| bugfix | `BUGFIX_DONE` |
| refactor | `REFACTOR_DONE` |
| optimize | `OPTIMIZE_DONE` |

## Phase 4: 사용자 확인

프롬프트 생성 후 **반드시** 다음 정보를 사용자에게 보여주고 확인:

```markdown
## Ralph Loop 실행 준비

**유형**: [feature/bugfix/refactor/optimize]
**복잡도**: [small/medium/large]
**max-iterations**: [10/30/50]
**completion-promise**: [TYPE]_DONE

### 생성된 프롬프트:
[프롬프트 내용]

---
실행하시겠습니까?
```

## Phase 5: Ralph Loop 실행

### 1. Setup 스크립트 실행

```bash
~/.claude/skills/ralph-planner/scripts/setup-ralph.sh "<프롬프트>" --max-iterations <n> --completion-promise "<TYPE>_DONE"
```

이 스크립트가 `.ralph/` 디렉토리에 상태 파일을 생성합니다:
- `.ralph/state.md`: 세션 상태 (반복 횟수, 세션 ID 등)
- `.ralph/prompt.md`: 프롬프트 저장
- `.ralph/progress.log`: 진행 로그

### 2. 프롬프트 전달

setup 완료 후 생성된 프롬프트를 Claude에게 전달합니다.
Stop Hook이 자동으로 루프를 관리합니다.

### 실행 예시

```bash
# 1. Setup
~/.claude/skills/ralph-planner/scripts/setup-ralph.sh "# FEATURE: 다크모드 토글

## Context
React + TypeScript 프로젝트
스타일링: Tailwind CSS

## Requirements
- 헤더에 다크모드 토글 버튼 추가
- 시스템 설정 감지
- localStorage에 선호도 저장

## Implementation Plan
1. ThemeProvider 컨텍스트 생성
2. useTheme 훅 구현
3. 토글 버튼 컴포넌트 생성
4. 다크모드 스타일 적용

## Success Criteria
- [ ] 토글 클릭 시 테마 전환
- [ ] 페이지 새로고침 후에도 설정 유지
- [ ] 시스템 설정 자동 감지
- [ ] 모든 테스트 통과
- [ ] lint/type 에러 없음

## Completion
<promise>FEATURE_DONE</promise>

## If Stuck
- 진행 차단 요소 문서화
- 시도한 방법 목록 작성" --max-iterations 30 --completion-promise "FEATURE_DONE"

# 2. 프롬프트를 Claude에게 전달 (위 setup 후 자동으로 진행)
```

## 중단 및 재개

### 수동 중단

```bash
~/.claude/skills/ralph-planner/scripts/cancel-ralph.sh

# 로그 보존하면서 중단
~/.claude/skills/ralph-planner/scripts/cancel-ralph.sh --keep-logs
```

### 진행 상황 확인

```bash
cat .ralph/progress.log
cat .ralph/state.md
```

### 재개 방법

동일한 프롬프트로 다시 시작하면 `.ralph/` 상태를 기반으로 이어서 진행.

## 안전장치

### 자체 구현 Stop Hook

| 기능 | 설명 |
|------|------|
| **max-iterations** | 최대 반복 횟수 제한 (복잡도 기반 자동 결정) |
| **completion-promise** | 완료 조건 문자열 매칭 시 루프 종료 |
| **세션 격리** | 터미널 세션 ID 기반 (다중 세션 버그 방지) |
| **진행 상황 로깅** | `.ralph/progress.log`에 각 반복 기록 |

### 세션 격리 (다중 세션 버그 방지)

`$TERM_SESSION_ID` 또는 `$ITERM_SESSION_ID`를 사용하여 다른 터미널 세션의 Ralph Loop와 충돌하지 않습니다.

## 상태 파일 구조

### `.ralph/state.md`

```yaml
---
term_session_id: "xxx-xxx-xxx"
iteration: 5
max_iterations: 30
completion_promise: "FEATURE_DONE"
started_at: "2025-01-12T10:00:00"
---
```

### `.ralph/progress.log`

```
[2025-01-12 10:00:00] STARTED: Ralph Loop initialized
  - Max iterations: 30
  - Completion promise: FEATURE_DONE
  - Terminal session: xxx-xxx-xxx
[2025-01-12 10:01:00] ITERATION 1/30: Continuing...
[2025-01-12 10:02:00] ITERATION 2/30: Continuing...
...
[2025-01-12 10:30:00] COMPLETED: Found completion promise 'FEATURE_DONE' at iteration 15
```

## 슬립 방지 (macOS)

Ralph Loop는 장시간 무인 실행을 위해 설계되었으므로, macOS 슬립 모드를 방지해야 합니다.

### 슬립 모드 진입 시 발생하는 문제

1. **프로세스 일시 중지** → Claude Code CLI 멈춤
2. **네트워크 끊김** → API 호출 불가
3. **세션 끊김** → 깨어났을 때 Stop Hook 작동 불가

### 해결 방법: caffeinate

| 방법 | 명령어/설정 | 특징 |
|------|-------------|------|
| **caffeinate** | `caffeinate -dims` | 터미널이 열려있는 동안 슬립 방지 |
| 시스템 설정 | 에너지 → 슬립 비활성화 | 전원 연결 시에만 권장 |
| 클라우드 VM | EC2, GCP, Azure 등 | 로컬 상태와 무관하게 24시간 실행 |

### caffeinate 옵션

| 옵션 | 의미 |
|------|------|
| `-d` | 디스플레이 슬립 방지 |
| `-i` | 시스템 유휴 슬립 방지 |
| `-m` | 디스크 슬립 방지 |
| `-s` | 시스템 슬립 방지 (전원 연결 시) |

### 사용 방법

```bash
# Ralph 작업 전에 백그라운드로 실행
caffeinate -dims &

# 또는 Claude와 함께 실행 (Claude 종료 시 caffeinate도 종료)
caffeinate -dims -- claude

# 작업 완료 후 해제
pkill caffeinate
```

### setup-ralph.sh에 통합

setup-ralph.sh 실행 시 자동으로 caffeinate를 시작하도록 설정할 수 있습니다:

```bash
# setup-ralph.sh 내부에서
if [[ "$OSTYPE" == "darwin"* ]]; then
  caffeinate -dims &
  echo "caffeinate started (PID: $!)"
fi
```

## 필수 원칙 (반드시 준수)

> ⚠️ 아래 원칙은 Ralph Loop의 안정성과 추적 가능성을 위해 **반드시** 준수해야 합니다.

### 원칙 1: Phase별 커밋 계획 수립

Implementation Plan 작성 시 **각 단계별 커밋 시점을 미리 명시**합니다.

- 하나의 논리적 단위 = 하나의 커밋
- 커밋 메시지 템플릿을 계획 단계에서 작성
- Phase 완료 전 반드시 커밋하여 진행 상황 보존

### 원칙 2: 커밋 후 Compaction 실행

모든 커밋 직후 `/compact` 명령을 실행합니다.

- 컨텍스트 초기화로 장시간 세션 안정성 확보
- 긴 세션에서도 일관된 동작 보장
- Stop Hook 재시작 시 깔끔한 상태 유지

### 워크플로우 다이어그램

```
┌─────────────┐    ┌──────────┐    ┌────────┐    ┌───────────┐
│ Phase 구현  │ → │  테스트   │ → │  커밋  │ → │ /compact  │
└─────────────┘    └──────────┘    └────────┘    └───────────┘
       ↑                                              │
       └──────────────── 다음 Phase ←─────────────────┘
```

### 예시 워크플로우

```
1. 프리셋 타입 정의 구현
2. 테스트/검증
3. git commit -m "feat: 프리셋 타입 및 데이터 정의"
4. /compact  ← 필수!
5. Store 수정 구현
6. 테스트/검증
7. git commit -m "feat: trainingStore에 프리셋 선택 상태 추가"
8. /compact  ← 필수!
9. ... 반복
```

## 주의사항

1. **자동 검증 가능한 완료 조건** 필수 (테스트, lint, type check)
2. **max-iterations**는 안전장치 - 항상 설정
3. **모호한 요구사항**은 Ralph에 부적합 → 먼저 명확화 필요
4. **아키텍처 결정**이 필요한 작업은 사전에 결정 후 실행
5. **다중 세션 사용 시** 각 터미널에서 독립적으로 작동 (세션 격리)
6. **macOS에서 장시간 실행 시** caffeinate로 슬립 방지 필수
7. **필수 원칙 준수** - 위 "필수 원칙" 섹션의 커밋/compaction 규칙 필수 이행

## 스크립트 위치

| 스크립트 | 경로 |
|----------|------|
| Stop Hook | `~/.claude/skills/ralph-planner/scripts/stop-hook.sh` |
| Setup | `~/.claude/skills/ralph-planner/scripts/setup-ralph.sh` |
| Cancel | `~/.claude/skills/ralph-planner/scripts/cancel-ralph.sh` |
