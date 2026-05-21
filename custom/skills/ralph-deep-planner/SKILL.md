---
name: ralph-deep-planner
description: |
  Ralph + Compound Engineering 통합 플래너. /ce:plan으로 깊은 계획 수립, Stop Hook 기반 Phase별 자동 반복 실행,
  조건부 /ce:compound 학습 기록, 완료 후 /ce:review 자동 실행.
  Use when user wants deep planning with compound learning, or mentions "ralph-deep", "랄프딥", "/ralph-deep".
  Not for simple tasks — use ralph-planner for straightforward work.
---

# Ralph Deep Planner

**ralph-planner의 세션 연속성** + **Compound Engineering의 계획 깊이·학습 축적·멀티 에이전트 리뷰**를 하나의 자동화 플로우로 통합.

## 핵심 차이점 (vs ralph-planner)

| 영역 | ralph-planner | ralph-deep-planner |
|------|--------------|-------------------|
| 계획 수립 | 자체 프롬프트 생성 | 상세 plan은 Obsidian-first, 실행 상태는 Ralph/HANDOFF로 관리 |
| Phase 완료 시 | HANDOFF.md + 커밋 | HANDOFF.md + 커밋 + **조건부 학습 기록** |
| 전체 완료 시 | completion-promise 출력 | **`/ce:review` 자동 실행** → completion-promise |
| Stop Hook | `planner_type: standard` | `planner_type: deep` |

## 워크플로우

```
/ce:plan 계획 수립 → 사용자 확인 → setup → Stop Hook 루프
                                              ↓
                                        각 Phase 완료 시
                                        조건부 학습 기록
                                              ↓
                                        전체 완료 시
                                        /ce:review 자동 실행
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

### 복잡도 판단 (→ max-iterations + 계획 상세도 결정)

| 복잡도 | 기준 | iterations | /ce:plan 상세도 |
|--------|------|------------|----------------|
| **small** | 단일 파일, 간단한 변경 | 10 | More |
| **medium** | 2-5개 파일, 중간 규모 변경 | 30 | More |
| **large** | 6개+ 파일, 대규모 변경, 신규 기능 | 50 | A Lot |

## Phase 2: /ce:plan 계획 수립

### 실행 방법

복잡도 판단 결과를 바탕으로 `/ce:plan`을 호출합니다.

```
/ce:plan [사용자의 요구사항 설명]
```

**중요**: 상세 plan의 정본은 repo `docs/plans/`가 아니라 Obsidian `Projects/{slug}/agents/plans/`에 둡니다. `/ce:plan` 또는 별도 계획 흐름이 repo plan 파일을 만들도록 유도하지 않습니다.

### /ce:plan 호출 시 지시사항

`/ce:plan` 실행 시 다음을 명시적으로 전달:

1. **상세도 선택**: 복잡도에 따라 자동 결정 (small/medium → More, large → A Lot)
2. **Phase 구조 필수**: Implementation Plan에 Phase별 구분이 반드시 포함되어야 함
3. **각 Phase에 커밋 포인트 포함**: Phase마다 HANDOFF.md 업데이트 + 커밋 단계 명시
4. **Post-generation option**: `/ce:plan` 완료 후 선택지에서 바로 Ralph Loop 실행으로 연결

### 계획 확정 후

계획 문서 경로를 확보합니다:
- 권장: Obsidian `Projects/{slug}/agents/plans/YYYY-MM-DD-...-plan.md`
- repo에는 확정 정책/ADR/handoff만 남깁니다.

이 파일을 Ralph Loop 프롬프트에 참조로 포함합니다.

## Phase 3: 프롬프트 생성

### 프롬프트 구조

```markdown
# [TYPE]: [제목]

## Plan Reference
이 작업의 상세 계획은 다음 Obsidian plan을 참조: `[plan-file]`
반드시 이 파일을 먼저 읽고 Implementation Plan의 Phase 구조를 따라 작업하세요.

## Context
[package.json 기반 프로젝트 정보]
[기술 스택, 주요 의존성]

## Requirements
[사용자 요구사항 - 명확하고 구체적으로]

## Handoff Protocol
- 핸드오프 문서 경로: `docs/ralph-{task-slug}/HANDOFF.md`
- 세션 시작 시 반드시 HANDOFF.md를 읽고 이전 진행 상황 파악
- Phase 완료 시 반드시 HANDOFF.md 업데이트 후 커밋

## Compound Learning Protocol
Phase 완료 후 다음 조건 중 하나에 해당하면 `docs/solutions/`에 학습 기록:
- 예상과 다른 동작을 발견하고 해결한 경우
- 새로운 패턴이나 우회 방법을 찾은 경우
- 디버깅에 15분 이상 소요된 문제를 해결한 경우
- 외부 라이브러리의 문서에 없는 동작을 발견한 경우

기록 형식:
1. `docs/solutions/[category]/[slug].md` 파일 생성
2. YAML frontmatter 포함 (title, category, date, tags)
3. 문제 증상, 원인, 해결 방법, 예방 전략 포함

조건 미해당 시 HANDOFF.md에 간단한 메모만 남기고 진행.

## Implementation Plan
`[plan-file]`의 Implementation Plan을 따릅니다.
각 Phase 완료 시:
1. 테스트/검증
2. HANDOFF.md 업데이트 (Phase 완료 기록 + 학습 메모)
3. 조건부 학습 기록 (Compound Learning Protocol 참조)
4. git add -A && git commit -m "[type]: [커밋 메시지]"

## Success Criteria (자동 검증 가능해야 함)
- [ ] [검증 가능한 조건 1]
- [ ] [검증 가능한 조건 2]
- [ ] 모든 테스트 통과
- [ ] lint/type 에러 없음

## Completion
모든 Success Criteria 충족 시:
1. HANDOFF.md에 최종 완료 기록
2. `docs/ralph-{task-slug}/` 폴더 삭제
3. git add -A && git commit -m "[type]: [최종 커밋 메시지]"
4. /ce:review 실행 (멀티 에이전트 코드 리뷰)
5. 리뷰 결과 반영 후 출력: <promise>[TYPE]_DONE</promise>

## If Stuck (15회 반복 후에도 미완료 시)
- 진행 차단 요소를 HANDOFF.md에 문서화
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
## Ralph Deep Loop 실행 준비

**유형**: [feature/bugfix/refactor/optimize]
**복잡도**: [small/medium/large]
**max-iterations**: [10/30/50]
**completion-promise**: [TYPE]_DONE
**핸드오프 경로**: docs/ralph-[task-slug]/HANDOFF.md
**계획 파일**: [Obsidian plan path]
**계획 상세도**: [More/A Lot]

### Compound Engineering 통합:
- 계획: /ce:plan ✅ (완료)
- Phase별 학습: 조건부 /ce:compound
- 완료 후 리뷰: /ce:review 자동 실행

### 생성된 프롬프트:
[프롬프트 내용]

---
실행하시겠습니까?
```

## Phase 5: Ralph Deep Loop 실행

### 1. Setup 스크립트 실행

```bash
~/.claude/skills/ralph-deep-planner/scripts/setup-ralph-deep.sh "<프롬프트>" \
  --max-iterations <n> \
  --completion-promise "<TYPE>_DONE" \
  --task-slug "<영문-타이틀>" \
  --plan-file "<Obsidian plan path>"
```

이 스크립트가 생성하는 파일:
- `.ralph/state.md`: 세션 상태 (`planner_type: deep` 포함)
- `.ralph/prompt.md`: 프롬프트 저장
- `.ralph/progress.log`: 진행 로그
- `docs/ralph-{task-slug}/HANDOFF.md`: repo-local 핸드오프 문서 (초기 상태, Obsidian에 작성하지 않음)

### 2. 프롬프트 전달

setup 완료 후 생성된 프롬프트를 Claude에게 전달합니다.
Stop Hook이 자동으로 루프를 관리합니다.

## Phase별 작업 흐름

### 일반 작업

```
┌─────────────┐    ┌──────────┐    ┌──────────────────┐    ┌──────────────┐    ┌────────┐
│ Phase 구현  │ → │  테스트   │ → │ HANDOFF.md 업데이트│ → │ 조건부 학습  │ → │  커밋  │
└─────────────┘    └──────────┘    └──────────────────┘    └──────────────┘    └────────┘
       ↑                                                                           │
       └─────────────────────── 다음 Phase ←───────────────────────────────────────┘
```

### 퍼블리싱/디자인/FE 작업

```
┌─────────────┐    ┌──────────┐    ┌────────────────────────┐    ┌──────────────────┐    ┌──────────────┐    ┌────────┐
│ Phase 구현  │ → │  테스트   │ → │ agent-browser 시각검증  │ → │ HANDOFF.md 업데이트│ → │ 조건부 학습  │ → │  커밋  │
└─────────────┘    └──────────┘    └────────────────────────┘    └──────────────────┘    └──────────────┘    └────────┘
       ↑                                  │ 문제 발견                                                           │
       │                                  ↓                                                                     │
       │                           ┌──────────┐                                                                 │
       │                           │   수정    │──→ 재검증                                                       │
       │                           └──────────┘                                                                 │
       └──────────────────────── 다음 Phase ←───────────────────────────────────────────────────────────────────┘
```

### 최종 Phase (Completion)

```
┌──────────────────┐    ┌────────────────┐    ┌──────────────────┐    ┌─────────────────────────┐
│ 모든 Phase 완료  │ → │ /ce:review 실행 │ → │ 리뷰 결과 반영   │ → │ <promise>TYPE_DONE</promise> │
└──────────────────┘    └────────────────┘    └──────────────────┘    └─────────────────────────┘
```

## Compound Learning Protocol 상세

### 기록 조건 (하나 이상 해당 시 `docs/solutions/`에 기록)

1. **예상과 다른 동작** — 문서와 실제 동작이 다른 경우
2. **새로운 패턴 발견** — 기존에 없던 해결 패턴을 찾은 경우
3. **긴 디버깅** — 15분 이상 소요된 문제를 해결한 경우
4. **라이브러리 미문서화 동작** — 외부 라이브러리의 숨겨진 동작 발견

### 기록 형식

```markdown
---
title: [문제 제목]
category: [build-errors|test-failures|runtime-errors|performance-issues|database-issues|security-issues|ui-bugs|integration-issues|logic-errors]
date: YYYY-MM-DD
tags: [관련 기술, 프레임워크 등]
---

# [문제 제목]

## 증상
[정확한 에러 메시지, 관찰된 동작]

## 원인
[기술적 근본 원인]

## 해결 방법
[단계별 수정 내용 + 코드 예시]

## 예방 전략
[향후 동일 문제 방지 방법]
```

### 조건 미해당 시

HANDOFF.md의 `## 의사결정 기록` 섹션에 간단한 메모만 남깁니다:

```markdown
- Phase N: [간단한 요약] (학습 기록 불필요 - 예상대로 진행됨)
```

## 중단 및 재개

### 수동 중단

```bash
~/.claude/skills/ralph-deep-planner/scripts/cancel-ralph-deep.sh

# 로그 보존하면서 중단
~/.claude/skills/ralph-deep-planner/scripts/cancel-ralph-deep.sh --keep-logs
```

### 진행 상황 확인

```bash
cat .ralph/progress.log
cat .ralph/state.md
cat docs/ralph-{task-slug}/HANDOFF.md
```

### 재개 방법

동일한 프롬프트로 다시 시작하면 HANDOFF.md를 기반으로 이어서 진행.
Obsidian plan은 그대로 유지되므로 계획도 참조 가능.

## 안전장치

| 기능 | 설명 |
|------|------|
| **max-iterations** | 최대 반복 횟수 제한 (복잡도 기반 자동 결정) |
| **completion-promise** | 완료 조건 문자열 매칭 시 루프 종료 |
| **세션 격리** | 터미널 세션 ID 기반 (다중 세션 충돌 방지) |
| **진행 상황 로깅** | `.ralph/progress.log`에 각 반복 기록 |
| **핸드오프 문서** | `docs/ralph-{task-slug}/HANDOFF.md`에 작업 맥락 보존 |
| **계획 파일 보존** | Obsidian plan은 루프 완료 후에도 유지 |

## agent-browser 시각 검증 (퍼블리싱/디자인/FE 작업)

퍼블리싱, 디자인, FE 관련 작업에서는 각 Phase 완료 후 커밋 전에 agent-browser 시각 검증을 실행합니다.

### 적용 대상

다음 키워드가 포함된 작업에 자동 적용:
- 컴포넌트 UI 변경, 스타일 수정, 레이아웃 변경
- 색상, 타이포그래피, 간격 등 시각적 속성 변경
- 반응형 디자인 작업
- CSS/Tailwind 변경

### 검증 절차

```bash
agent-browser open <url> && agent-browser wait --load networkidle
agent-browser snapshot -i
agent-browser screenshot
agent-browser eval 'JSON.stringify(console._errors || [])'
```

## 슬립 방지 (macOS)

장시간 무인 실행 시 caffeinate 사용:

```bash
caffeinate -dims &
# 또는
caffeinate -dims -- claude
```

## 주의사항

1. **자동 검증 가능한 완료 조건** 필수
2. **max-iterations**는 안전장치 - 항상 설정
3. **모호한 요구사항**은 부적합 → 먼저 /ce:plan 단계에서 명확화
4. **아키텍처 결정**은 /ce:plan 단계에서 사전 결정
5. **다중 세션 사용 시** 각 터미널에서 독립적으로 작동
6. **macOS 장시간 실행 시** caffeinate로 슬립 방지 필수

## 스크립트 위치

| 스크립트 | 경로 |
|----------|------|
| Stop Hook | `~/.claude/skills/ralph-planner/scripts/stop-hook.sh` (통합 hook, planner_type으로 분기) |
| Setup | `~/.claude/skills/ralph-deep-planner/scripts/setup-ralph-deep.sh` |
| Cancel | `~/.claude/skills/ralph-deep-planner/scripts/cancel-ralph-deep.sh` |
