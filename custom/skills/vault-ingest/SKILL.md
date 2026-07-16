---
name: vault-ingest
description: |
  Obsidian vault에 외부 소스를 수집하여 _raw/ + wiki/로 통합.
  Use when user mentions "/ingest", "인제스트", "소스 수집", "vault에 추가", "문서 수집".
  Not for vault 정리(/lint) 또는 지식 승급(/promote).
---

# vault-ingest

외부 소스를 Obsidian vault의 Second Brain 시스템(`_raw/` + `wiki/`)으로 수집하는 스킬.

## Vault 경로

```
/Users/doyoonlee/ObsidianVault
```

---

## 워크플로우

### 1. 소스 타입 판별

입력 유형에 따라 처리 방식을 결정한다.

| 입력 | 판별 기준 | 처리 |
|------|----------|------|
| 파일 경로 | 확장자 `.md`, `.pdf`, `.txt`, `.json` | 확장자별 핸들러로 분기 |
| URL | `http://` 또는 `https://` 시작 | WebFetch로 콘텐츠 추출. 실패 시 agent-browser 스킬로 폴백 |
| 디렉토리 경로 | 경로가 디렉토리인 경우 | `.md`/`.json` 파일만 재귀 스캔 (최대 50개). 초과 시 사용자에게 범위 확인 질문 |

각 타입별 상세 핸들링은 `references/supported-types.md`를 참조한다.

### 2. 중복 검사

수집 전 기존 `_raw/` 디렉토리에서 중복 여부를 확인한다.

- `_raw/` 하위 모든 `.md` 파일의 frontmatter에서 `source:` 또는 `source_url:` 필드를 grep
- 동일 소스가 이미 존재하면 사용자에게 알린 후 선택지 제공:
  - **덮어쓰기**: 기존 파일을 새 내용으로 교체
  - **건너뛰기**: 수집하지 않고 다음 소스로 이동

### 3. `_raw/` 저장

수집된 콘텐츠를 `_raw/{type}/` 하위에 저장한다.

**파일명 규칙:**

```
{YYYY-MM-DD}-{slugified-title}.md
```

- `slugified-title`: 제목에서 공백을 `-`로 변환, 특수문자 제거, 소문자 변환 (한글은 그대로 유지)
- 예: `2026-04-17-react-server-components-deep-dive.md`

**Frontmatter 구조:**

```yaml
---
title: "문서 제목"
type: article | paper | tool | reference
source: "파일 경로 또는 URL"
source_url: "원본 URL (URL 소스인 경우)"
date: YYYY-MM-DD
tags:
  - 키워드1
  - 키워드2
---
```

### 4. 배치 및 태깅

소스 성격에 따라 저장 위치와 태그를 결정한다.

| 소스 성격 | 저장 위치 | 비고 |
|----------|----------|------|
| 원본 아티클/웹 클리핑 | `_raw/articles/` | 키워드 태그 부여 |
| PDF/논문 | `_raw/papers/` | 키워드 태그 부여 |
| 도구/라이브러리 리서치 | `_raw/articles/` | `type: tool` 태그 |
| 가공된 개념/이론/패턴 | `wiki/concepts/` | 직접 wiki에 배치 |
| 도구/서비스/인물 엔티티 | `wiki/entities/` | 직접 wiki에 배치 |

**중요 규칙:**

- `wiki/sources/`는 사용하지 않는다 (폐기됨). 대신 `agents/responses/` + 태깅 조합을 사용한다.
- wiki에 이미 동일/유사 문서가 있으면 **병합을 제안**하되 자동 생성하지 않는다.
- 태그는 콘텐츠 분석을 통해 3~5개의 키워드를 자동 추출하여 부여한다.

### 5. 인덱스/로그 갱신

수집 완료 후 다음 파일들을 업데이트한다.

- **`wiki/index.md`**: stats 섹션의 문서 수 카운트만 갱신
- **`wiki/logs/_current.md`**: 수집 로그를 append

**로그 형식:**

```markdown
## [YYYY-MM-DD HH:MM] ingest | {title}

- source: {소스 경로 또는 URL}
- type: {article | paper | tool | reference}
- destination: {저장 경로}
- tags: {태그 목록}
```

---

## 실행 범위

- **단일 소스** 또는 **제한된 배치**(최대 50개 파일)만 처리한다.
- 대규모 Claude export 파일은 이 스킬이 아니라 별도의 `references/import-claude-export.md` 가이드를 따른다.

---

## 에러 처리

| 상황 | 대응 |
|------|------|
| URL fetch 실패 (WebFetch + agent-browser 모두) | 에러 메시지 출력 후 해당 소스 건너뛰기. 로그에 실패 기록 |
| PDF 텍스트 추출 불가 (텍스트 레이어 없음) | OpenDataLoader PDF의 OCR 모드로 재시도 (`--force-ocr`) |
| 인코딩 오류 | UTF-8 변환 시도. 실패 시 사용자에게 인코딩 지정 요청 |
| 디렉토리 내 파일 50개 초과 | 사용자에게 범위 축소 또는 확인 요청 |

---

## Vault 필수 규칙

이 스킬 실행 시 반드시 준수해야 하는 vault 규칙:

1. **`_raw/`는 append-only** - 기존 파일을 수정하지 않는다 (덮어쓰기는 사용자 명시 승인 시에만)
2. **`wiki/`는 agents-only** - human은 검수만 수행
3. **대소문자 주의** - `Projects/` (대문자 P). `projects/`가 아니다
4. **PDF 읽기** - 반드시 OpenDataLoader PDF를 사용한다 (`~/.claude/rules/pdf-reading.md` 참조)
5. **브라우저 자동화** - 반드시 agent-browser 스킬을 사용한다 (Playwright MCP 사용 금지)
6. **마크다운 리스트** - `-` 뒤에 반드시 공백 1개 이상 (`- 텍스트`)
