---
name: docs-writing
description: |
  문서 작성 요청의 최상위 라우터. 사용자가 "문서 작성", "문서로 정리", "정책 문서", "ADR", "runbook", "운영 문서", "아키텍처 문서", "계획 문서", "docs에 작성", "옵시디언에 남길지 판단" 등을 요청할 때 먼저 사용한다.
  repo docs와 Obsidian vault 중 어디에 무엇을 남길지 판단하고, repo 문서는 직접 작성하며, Obsidian 문서가 필요하면 obsidian-writing 스킬을 이어서 사용한다.
  This skill is the default for documentation-writing requests. It prevents confusion between project docs and Obsidian by deciding the canonical location first.
  Not for marketing copy, social posts, PR comments, code comments only, or pure prose style rewrites unless the output is a durable document.
---

# Docs Writing Router

문서 작성 요청을 받았을 때 **프로젝트 repo docs**와 **Obsidian vault** 중 무엇을 어디에 남길지 결정하는 최상위 스킬이다.

이 스킬은 문서의 **정본 위치(canonical location)** 를 먼저 정한다. 위치가 정해지기 전에는 곧바로 파일을 쓰지 않는다.

## 핵심 원칙

- 코드와 함께 바뀌어야 하는 확정 정책/결정/운영 절차는 프로젝트 repo에 둔다.
- 계획 문서는 Obsidian-first로 관리한다. 아이디어 단계와 상세 plan의 정본은 Obsidian에 둔다.
- 구현 중 체크리스트와 진행 상태는 repo 문서가 아니라 Pi todo/session state로 관리한다.
- 세션 간 이어받기 handoff는 Obsidian이 아니라 repo의 `docs/handoff/`에 둔다.
- 프로젝트 하나를 넘어 재사용되는 지식은 Obsidian에 둔다.
- 둘 다 필요한 경우에도 역할을 분리한다.
  - repo docs: 실행 가능한 정책, ADR 정본, runbook, 코드 계약, handoff
  - Obsidian: 계획 정본, 상위 지식, 요약, 링크, 일반화된 원칙
- Obsidian 위치는 이 스킬이 하드코딩하지 않는다. Obsidian에 작성해야 하면 반드시 `obsidian-writing` 스킬을 이어서 사용하고 vault 내부 `CLAUDE.md`/`_index.md`를 따른다.
- 사용자가 명시적으로 저장 위치를 정해도, 정본 위치가 위험해 보이면 한 번 짚고 넘어간다.

## 라우팅 판단 기준

### 프로젝트 repo `docs/`에 작성

다음 중 하나라도 해당하면 repo 문서가 정본이다.

| 기준 | 예시 |
|---|---|
| 코드 변경과 함께 PR에서 리뷰되어야 하는 확정 규칙 | API contract, Storage path 정책, DB migration 규칙 |
| 문서 위반이 버그/장애/비용으로 이어짐 | 업로드 정책, 배포 runbook, 환경변수 규칙 |
| 특정 코드베이스에 귀속된 구조적 결정 | ADR, 프로젝트 아키텍처 결정, 라이브러리 선택 이유 |
| 자동화/스크립트/CI와 연결된 운영 절차 | 테스트 방법, 검증 명령, 운영 스크립트 사용법 |
| 세션 간 작업 상태를 다음 에이전트가 repo만 보고 이어받아야 함 | `docs/handoff/` |
| 온보딩 시 repo만 clone해도 알아야 함 | 개발 환경 설정, 프로젝트 구조, 배포 절차 |

권장 위치:

```txt
docs/adr/             # 아키텍처 의사결정 기록 정본
docs/operations/      # 운영 정책, runbook, 비용/스토리지/배포 정책
docs/architecture/    # 현재 시스템 구조 설명
docs/solutions/       # 해결 기록, 재발 방지 노트
docs/handoff/         # 세션/작업 인수인계
```

프로젝트에 기존 디렉토리 관례가 있으면 그 관례를 우선한다.

### Obsidian에 작성

다음에 해당하면 Obsidian 문서가 정본 또는 보조 문서다.

| 기준 | 예시 |
|---|---|
| 프로젝트 plan/아이디어/설계 검토 | `Projects/{slug}/agents/plans/` |
| 코드가 아직 없거나 구현 전 탐색 단계 | 기능 구상, 제품/UX 방향성, 대안 비교 |
| 여러 프로젝트에 재사용되는 지식 | 이미지 저장 전략, 문서 운영 모델, 상태관리 패턴 |
| 학습/리서치/비교/해석 중심 | 커뮤니티 베스트프랙티스 조사, 개념 정리 |
| 프로젝트별 실행 규칙보다 상위 원칙 | 원본/파생 이미지 보존 철학, docs-as-code 개념 |
| 개인/팀 second brain에 연결해야 함 | 요약, 링크 모음, 지식 그래프 노드 |
| 사용자가 명시적으로 vault/옵시디언 저장을 요청 | "옵시디언에 정리해줘" |

Obsidian에 작성할 때는 이 스킬에서 위치를 추측하지 말고 `obsidian-writing` 스킬을 사용한다.

### 둘 다 작성

다음처럼 역할이 다르면 둘 다 작성한다.

| 주제 | repo docs | Obsidian |
|---|---|---|
| Storage 이미지 정책 | 이 프로젝트의 bucket/path/금지 규칙 | 범용 이미지 보존 전략, 요약, 관련 ADR 링크 |
| ADR | 특정 repo의 의사결정 정본 | 의사결정에서 추출한 일반 원칙, 인덱스/요약 |
| Plan | 원칙적으로 작성하지 않음 | 상세 plan 정본 |
| Handoff | `docs/handoff/` 정본 | 작성하지 않음 |
| 장애 대응 | 서비스별 runbook | 장애 대응 패턴, 회고, 학습 노트 |
| 아키텍처 | 현재 코드 구조와 계약 | 아키텍처 패턴화/비교/재사용 지식 |

## 문서 유형별 작성 규칙

### ADR

ADR은 특정 코드베이스의 중요한 결정 정본이다. 기본 위치는 repo `docs/adr/`다.

파일명:

```txt
YYYY-MM-DD-short-decision-title.md
```

템플릿:

```md
# ADR: <결정 제목>

## Status
Accepted | Proposed | Deprecated | Superseded

## Context
왜 이 결정을 해야 했는가. 제약, 문제, 관찰한 사실.

## Decision
무엇을 선택했는가. 정책/구조/기술 선택을 명확히 쓴다.

## Consequences
좋아지는 점, 나빠지는 점, 운영상 주의점.

## Implementation Notes
코드/스크립트/마이그레이션/검증과 연결되는 실행 메모.

## Related
관련 문서, PR, 이슈, Obsidian 요약 링크가 있으면 추가.
```

### 운영 정책 / Runbook

기본 위치는 `docs/operations/`다.

포함할 내용:

- 정책의 적용 범위
- 금지/허용 규칙
- 실행 절차
- 검증 명령
- 롤백/복구 방법
- 관련 ADR

### 아키텍처 문서

repo에 둘 때는 현재 코드와 직접 연결되는 구조만 적는다.

- 시스템 구성 요소
- 데이터 흐름
- 주요 모듈 책임
- 변경 시 주의할 계약
- 관련 파일 경로

상위 패턴/일반화된 해설은 Obsidian 대상으로 분리한다.

### 계획 문서

계획 문서는 Obsidian-first로 관리한다. 사용자가 plan, 구현 계획, 아이디어 정리, 설계 검토를 요청하면 기본 정본은 Obsidian `Projects/{slug}/agents/plans/`다.

repo에는 얇은 실행용 plan/tasks 문서를 기본 생성하지 않는다. 구현 직전/중간 체크리스트는 Pi todo/session state로 관리한다.

repo에 남길 수 있는 예외는 다음뿐이다.

- 이미 확정된 결정이므로 ADR로 승격해야 하는 경우
- 코드가 반드시 지켜야 하는 정책/운영 절차가 되어 `docs/operations/` 또는 `docs/architecture/`로 승격해야 하는 경우
- 다음 세션이 이어받아야 하는 현재 작업 상태라서 `docs/handoff/`가 필요한 경우

계획 문서에 포함할 내용:

- 목표와 배경
- 범위와 비범위
- 대안과 결정 기준
- 구현 단계 초안
- 리스크와 검증 관점

### 구조적 글쓰기 / MECE

사용자가 MECE, 구조적 분석, 체계적 정리를 요청하면 별도 문서 유형으로 분리하지 말고, 이 스킬 안에서 다음 원칙을 적용한다.

- 결론을 먼저 쓴다.
- 대분류는 3~5개로 유지한다.
- 분류끼리 중복되지 않고 전체를 포괄하는지 확인한다.
- 각 섹션은 주장 → 근거 → 시사점 순서로 쓴다.

단, 사용자가 명시적으로 MECE 프레임워크 자체를 깊게 요청하면 `mece-writing`의 상세 절차를 참고할 수 있다.

## Workflow

### Step 1: 요청 분류

사용자의 요청을 다음 축으로 분류한다.

- 문서 주제
- 목적: 정책 / ADR / runbook / 아키텍처 / 계획 / handoff / 리서치 요약 / 지식화
- 정본 위치 후보: repo / Obsidian / 둘 다
- 코드와 동시 변경 필요 여부
- 장기 재사용 지식 여부

### Step 2: 위치 결정

명확하면 바로 결정한다. 모호하면 2~4개 선택지로 사용자에게 묻는다.

질문 예:

- "이 문서는 코드 변경과 함께 PR 리뷰되어야 하나요?"
- "프로젝트 실행 정책인가요, 여러 프로젝트에 재사용할 상위 지식인가요?"
- "이건 Obsidian plan으로 관리하고, 확정된 결정만 repo ADR로 남기면 될까요?"

### Step 3: repo 문서 작성

repo 문서가 필요하면 기존 `docs/` 구조를 확인한다.

- `find docs -maxdepth 2 -type d`
- 관련 기존 문서가 있으면 먼저 읽는다.
- 새 문서는 기존 디렉토리 관례에 맞춘다.
- 기존 파일을 덮어쓰지 않는다.

### Step 4: Obsidian 문서 위임

Obsidian 문서가 필요하면 다음을 따른다.

1. `obsidian-writing` 스킬을 읽는다.
2. vault 루트 `CLAUDE.md`와 가까운 `_index.md`를 읽는다.
3. vault 정책에 따라 위치를 결정한다.
4. 이 스킬의 판단 결과를 `obsidian-writing`에 전달한다.

전달할 내용:

- 왜 Obsidian 대상인지
- repo 정본 문서 경로가 있으면 그 링크/경로
- Obsidian에 남길 내용은 요약/상위 지식/링크인지, 원문/프로젝트 산출물인지

### Step 5: 혼동 방지 체크

완료 전 확인한다.

- 확정 정책/ADR/runbook/API contract를 Obsidian에만 남기지 않았는가?
- 상세 plan을 불필요하게 repo `docs/plans`류로 만들지 않았는가?
- 구현 중 체크리스트를 repo 문서로 중복 관리하지 않고 Pi todo/session state로 처리했는가?
- handoff를 Obsidian에 쓰지 않고 repo `docs/handoff/`에 두었는가?
- 같은 내용을 양쪽에 복붙해 중복 정본을 만들지 않았는가?
- 둘 다 작성했다면 각 문서의 역할이 명확한가?
- repo 문서가 코드/스크립트와 함께 유지될 수 있는 위치에 있는가?

## 출력 형식

작업 완료 시 사용자에게 다음을 간단히 보고한다.

```md
## 작성 위치 판단
- repo docs: <작성/미작성 및 이유>
- Obsidian: <작성/미작성 및 이유>

## 생성/수정 파일
- <path>

## 후속 주의사항
- <필요 시>
```

## 다른 스킬과의 관계

- `obsidian-writing`: Obsidian에 실제로 파일을 작성할 때만 이어서 사용한다.
- `mece-writing`: MECE 깊은 분석 요청일 때만 참고한다. 일반 문서 라우팅은 이 스킬이 우선한다.
- `toss-blog-writing`, `copywriting`, `humanizer`: 문체/마케팅/자연스러운 문장 변환이 목적일 때만 사용한다. 프로젝트 문서 위치 판단에는 사용하지 않는다.
- `handoff`, `wrap`, `solutions-suggest`: 세션 마무리/해결 기록 제안이 목적일 때 사용한다. 일반 문서 작성 요청의 기본 라우터는 이 스킬이다.
