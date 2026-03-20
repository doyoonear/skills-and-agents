---
name: obsidian-writer
description: |
  옵시디언(Obsidian) vault에 문서를 작성하는 범용 스킬. 사용자가 옵시디언에 문서 작성을 요청할 때 자동으로 트리거.
  경로 레지스트리를 관리하여 한 번 알려준 위치를 기억하고, 다음 유사 요청 시 자동으로 해당 경로에 작성.
  Use when user mentions "옵시디언에 작성", "옵시디언에 정리", "옵시디언 문서", "obsidian", "vault에 저장",
  "노트 작성해줘", "문서로 정리해줘" (옵시디언 맥락), or any request to write/save documents to the Obsidian vault.
  Also triggers when user says "Areas/Career에", "면접 준비 문서", "이력서 정리", "예상질문 작성" or similar career-related document requests.
  Not for reading or searching existing Obsidian notes — only for writing new documents or updating existing ones.
---

# Obsidian Writer

사용자의 Obsidian vault에 문서를 작성하는 스킬. 핵심 가치는 **경로를 한 번만 알려주면 다음부터 자동으로 올바른 위치에 작성**하는 것.

## Vault 경로

```
/Users/doyoonlee/ObsidianVault
```

## Workflow

### Step 1: 카테고리 판별

사용자의 요청을 분석하여 어떤 카테고리의 문서인지 판별한다.

**판별 기준:**
- 요청 내용의 주제 (이력서, 면접, 회사 준비, 학습 노트 등)
- 사용자가 명시한 경로가 있으면 그대로 사용
- 이전 대화에서 언급된 맥락

### Step 2: 경로 레지스트리 조회

이 스킬의 `references/path-registry.json` 파일을 읽어 해당 카테고리에 매핑된 경로가 있는지 확인한다.

**매핑이 존재하면:** 해당 경로에 바로 작성한다. 사용자에게 경로를 다시 묻지 않는다.

**매핑이 없으면:**
1. 사용자에게 vault 내 어디에 저장할지 질문한다
2. 사용자가 알려준 경로를 `path-registry.json`에 새 카테고리로 추가한다
3. 해당 경로에 문서를 작성한다

### Step 3: 문서 작성

- vault 루트 경로와 레지스트리 경로를 결합하여 절대 경로를 구성한다
- Write 도구로 파일을 생성한다 (중간 디렉토리는 자동 생성됨)
- 파일명은 문서 내용에 맞게 한국어로 작성한다 (사용자가 별도 지정하지 않은 경우)

### Step 4: 경로 레지스트리 업데이트

새로운 카테고리-경로 매핑이 생겼거나, 사용자가 기존 카테고리의 경로를 변경한 경우:

1. `references/path-registry.json`을 읽는다
2. 해당 카테고리를 추가하거나 업데이트한다
3. 파일을 저장한다

이 업데이트는 문서 작성과 함께 자동으로 수행하며, 사용자에게 "경로를 저장했습니다" 정도로 짧게 알린다.

## 경로 레지스트리 구조

`references/path-registry.json` 파일은 다음 구조를 따른다:

```json
{
  "categories": [
    {
      "id": "career",
      "keywords": ["이력서", "면접", "커리어", "채용", "포트폴리오", "예상질문", "회사 준비", "JD"],
      "basePath": "Areas/Career",
      "subPaths": {
        "예상질문": "개발 로켓베이스/예상질문리스트",
        "면접 준비": "면접 준비",
        "이력서": "이력서",
        "포트폴리오": "포트폴리오",
        "채용 공고": "채용 공고",
        "회사별 준비": "개발 로켓베이스/회사별 준비"
      }
    }
  ]
}
```

**필드 설명:**
- `id`: 카테고리 고유 식별자
- `keywords`: 이 카테고리에 매칭되는 키워드 목록. 사용자 요청에 이 키워드가 포함되면 해당 카테고리로 판별
- `basePath`: vault 루트 기준 상대 경로
- `subPaths`: 세부 주제별 하위 경로. basePath 기준 상대 경로

### 경로 결정 로직

1. 사용자가 명시적 경로를 제공한 경우 → 그대로 사용
2. 키워드로 카테고리 매칭 → `basePath` 결정
3. 세부 주제로 `subPaths` 매칭 → 최종 경로 결정
4. subPath 매칭 실패 시 → `basePath`에 직접 작성

**예시:**
- "당근 커머스 예상질문 옵시디언에 정리해줘"
  → 키워드 "예상질문" → career 카테고리
  → subPath "예상질문" → `Areas/Career/개발 로켓베이스/예상질문리스트/`
  → 최종 경로: `/Users/doyoonlee/ObsidianVault/Areas/Career/개발 로켓베이스/예상질문리스트/당근 커머스 - 예상질문.md`

## 새 카테고리 등록 흐름

레지스트리에 매칭되는 카테고리가 없을 때, 아래 플로우를 따른다.

### 1단계: 유형 분석 및 제안

요청된 문서의 성격을 분석하여 **유형(카테고리)을 먼저 제안**한다.
단순히 "어디에 저장할까요?"라고 묻지 않는다. 어떤 유형의 글인지 먼저 판단하여 사용자에게 확인받는다.

**질문 형식 (AskUserQuestion 사용):**

> "이 글은 **[유형 이름]** 유형의 글로 보이는데요.
> 이런 유형의 글들을 vault 어디에 저장하면 될까요?
>
> - 유형 이름: (예: 블로그 글, 기술 메모, 독서 노트 등)
> - 저장 경로: (예: Areas/Blog, Resources/TechNotes 등)"

두 가지를 한 번에 확인한다:
1. **유형(카테고리) 이름** — 내가 분석한 유형이 맞는지, 다르게 부르고 싶은지
2. **저장 경로** — vault 내 어디에 저장할지

### 2단계: 사용자 응답 처리

사용자는 보통 이렇게 답한다:
- "그 유형 맞고, Areas/Blog에 저장해줘"
- "블로그 글이 아니라 기술 회고야. Resources/Retrospective에 넣어줘"
- "맞아, 그리고 이런이런 유형의 글도 다 거기에 넣어줘"

사용자가 추가로 포함시킬 유형이나 키워드를 알려주면 keywords에 모두 반영한다.

### 3단계: 레지스트리 등록

사용자 답변에서 추출한 정보로 카테고리를 구성한다:

```json
{
  "id": "blog",
  "keywords": ["블로그", "블로그 글", "포스트", "아티클"],
  "basePath": "Areas/Blog",
  "subPaths": {}
}
```

- `id`: 유형 이름을 영문 kebab-case로 변환
- `keywords`: 사용자가 언급한 유형명 + 관련 동의어를 넉넉하게 포함
- `basePath`: 사용자가 지정한 경로
- `subPaths`: 초기에는 비어있고, 이후 사용자가 하위 분류를 알려주면 추가

`path-registry.json`에 추가하고 "이후 [키워드들] 관련 문서는 [경로]에 자동 저장됩니다" 라고 짧게 알린다.

### 4단계: 문서 작성 진행

등록된 경로에 문서를 작성한다.

## 주의사항

- vault 경로는 항상 `references/path-registry.json`을 신뢰한다. 하드코딩하지 않는다.
- 기존 파일을 덮어쓰지 않는다. 같은 이름의 파일이 있으면 사용자에게 확인한다.
- Obsidian의 마크다운 렌더링에 맞게 작성한다 (테이블, 콜아웃, 프로퍼티 등).
- 문서 작성 후 생성된 파일 경로를 사용자에게 알린다.
