---
name: obsidian-writing
description: |
  옵시디언(Obsidian) vault에 실제 파일을 작성하는 실행 스킬. 사용자가 명시적으로 "옵시디언", "Obsidian", "vault" 저장을 요청했거나 docs-writing 스킬이 Obsidian 대상이라고 판단한 뒤에 사용한다.
  저장 위치는 vault 내부 문서(CLAUDE.md, _index.md)를 SSOT로 따른다 — 스킬은 라우팅 정책을 보유하지 않는다.
  Use when user explicitly mentions "옵시디언에 작성", "옵시디언에 정리", "옵시디언 문서", "obsidian", "vault에 저장", or when docs-writing routes a document to Obsidian.
  Not for generic "문서 작성", "문서로 정리", ADR, runbook, architecture, policy, or repo docs requests — use docs-writing first. Not for reading/searching existing Obsidian notes.
---

# Obsidian Writing

사용자의 Obsidian vault에 문서를 실제로 작성하는 실행 스킬.

일반적인 문서 작성 요청의 최상위 라우팅은 `docs-writing` 스킬이 담당한다. 이 스킬은 Obsidian에 쓰기로 결정된 뒤, vault 내부 정책에 따라 정확한 위치와 형식을 결정한다.

**핵심 원칙: 라우팅 정책은 vault 내부 문서를 SSOT로 따른다.** 이 스킬은 vault 경로만 알고 있고, "어떤 글을 어디에 둘지"의 정책은 **vault 안의 `CLAUDE.md`/`_index.md`**에서 매 작업마다 새로 읽어 결정한다. 스킬에 카테고리 매핑을 사본으로 들고 있지 않는다.

repo docs와 Obsidian 중 정본 위치를 판단해야 하는 경우에는 먼저 `docs-writing`을 사용한다. 이 스킬은 Obsidian 내부 경로 판단만 수행한다.

## Vault 경로

```
/Users/doyoonlee/ObsidianVault
```

## Workflow

### Step 1: vault 루트 정책 읽기

작업 시작 시 항상 다음 파일을 읽어 최상위 라우팅 규칙을 확인한다:

```
/Users/doyoonlee/ObsidianVault/CLAUDE.md
```

이 파일은 vault의 핵심 디렉토리 분류, 파일 배치 규칙, 라우팅 위임 체인, 자주 쓰이는 매핑을 정의한다.

### Step 2: 가까운 _index 읽기

`CLAUDE.md`의 "라우팅 위임 체인" 섹션과 "자주 쓰이는 매핑" 표를 참고해 작성 대상 폴더를 좁힌다. 그 폴더 또는 상위 폴더에 다음이 있으면 모두 읽는다:

- `_index.md`

예시:
- 도구 카탈로그 작성 → `wiki/entities/tools/_index.md` 추가로 읽기 (frontmatter 템플릿, 등록 규칙)
- 모쓸무 프로젝트 문서 → `Projects/모쓸무/agents/_index.md` 추가로 읽기 (plans/architecture/solutions 분리 규칙)
- Career 관련 → `Areas/Career/_index.md` 추가로 읽기 (이력서/면접/포트폴리오 등 폴더 매핑)

**충돌 시 더 가까운 문서가 우선한다.** vault 루트 CLAUDE.md보다 폴더 _index가 우선.

### Step 3: 위치 결정

읽은 정책에 따라 정확한 저장 경로와 파일명 규칙을 결정한다.

**여전히 모호하면 사용자에게 질문한다 (AskUserQuestion):**

- 어떤 유형의 글인지 (예: "도구 카탈로그", "프로젝트 회고", "면접 개념학습")
- 가능한 후보 위치 2~3개를 제시하고 그중에서 선택받기
- 후보가 명백하지 않으면 vault에 추가할 새 정책의 위치도 함께 제안

스킬은 절대 추측만으로 위치를 결정하지 않는다. 정책 문서에 명시되지 않은 케이스라면 반드시 묻는다.

### Step 4: 문서 작성

- vault 루트 경로와 결정된 상대 경로를 결합해 절대 경로를 구성
- Write 도구로 파일 생성 (중간 디렉토리 자동 생성)
- 해당 폴더의 _index가 정의한 frontmatter 템플릿/파일명 규칙을 준수
- 같은 이름의 파일이 이미 있으면 덮어쓰지 않고 사용자에게 확인

### Step 5: 새 라우팅 정책이 필요한 경우 — vault 내부 문서를 직접 편집

사용자가 새 카테고리/저장 위치를 알려준 경우, 스킬이 외부에 사본을 두지 않는다. 대신 **vault 내부 문서를 직접 편집**한다:

1. 가장 적합한 _index 파일 식별 (가장 가까운 위치)
2. 사용자에게 "이 정책을 `{경로}` 에 추가하겠습니다"라고 확인
3. 동의 시 해당 문서의 "작성 위치 가이드" 섹션을 직접 편집
4. 그 정책에 따라 본 문서 작성

이렇게 하면 다음번 작업 때 Step 1·2에서 동일한 정책을 자연스럽게 다시 읽어 적용할 수 있다.

## 주의사항

- **라우팅 정책은 항상 vault 내부 문서를 신뢰한다.** 스킬에 매핑을 하드코딩하거나 외부 레지스트리에 사본을 두지 않는다.
- 폴더별 frontmatter 템플릿/파일명 규칙은 해당 폴더의 _index에 위임한다. 스킬 본문에 하드코딩하지 않는다.
- 기존 파일을 덮어쓰지 않는다. 같은 이름의 파일이 있으면 사용자에게 확인.
- Obsidian의 마크다운 렌더링에 맞게 작성한다 (테이블, 콜아웃, 프로퍼티, Mermaid 규칙 등 — vault 루트 CLAUDE.md의 규칙 참조).
- 문서 작성 후 생성된 파일 경로를 사용자에게 알린다.
- vault에 새 라우팅 정책을 추가할 때는 사용자 동의를 받고 vault 내부 문서를 직접 편집한다. **외부 레지스트리 파일을 새로 만들지 않는다.**
