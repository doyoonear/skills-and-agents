---
name: vault-lint
description: |
  Obsidian vault 헬스체크 및 자동 정리. inbox 분류, frontmatter 검증,
  깨진 링크 탐지, 미참조 이미지 검출, 인덱스 재생성.
  Use when user mentions "/lint", "린트", "vault 정리", "헬스체크", "orphan 이미지".
  Not for 새 소스 수집(/ingest) 또는 지식 승급(/promote).
---

# vault-lint

Obsidian vault Second Brain 시스템의 헬스체크 및 자동 정리 스킬.

## 기본 동작 모드

- **기본값: report-only.** 분석 결과만 출력하고 파일을 변경하지 않는다.
- `--fix`: 파일 이동, frontmatter 자동 보정 등 수정 작업을 실행한다. 실행 전 사용자 확인 필수.
- `--delete-orphans`: 미참조 이미지를 `_assets/_orphaned/`로 이동한다. 실행 전 사용자 확인 필수.

## Vault 경로

`/Users/doyoonlee/ObsidianVault`

## Phase 개요

| Phase | 이름 | 기본 동작 | `--fix` 필요 | `--delete-orphans` 필요 |
|-------|------|-----------|-------------|------------------------|
| 1 | Inbox/ 분류 | 분류 제안 출력 | 파일 이동 실행 | - |
| 2 | frontmatter 검증 | 누락 필드 보고 | 자동 보정 | - |
| 3 | wikilink 무결성 | 깨진 링크 보고 | - | - |
| 3.5 | 이미지 참조 통일 + 미참조 검출 | 리포트 출력 | 형식 통일 실행 | orphan 이동 |
| 4 | wiki/index.md 통계 갱신 | 통계 업데이트 | - | - |
| 5 | 로그 기록 | wiki/logs/_current.md에 append | - | - |

---

## Phase 1: Inbox/ 분류

### 대상

`Inbox/` 디렉토리의 `.md` 파일만 스캔한다. 바이너리 파일과 비-마크다운 파일은 무시한다.

### 분류 로직

1. 각 파일의 frontmatter와 본문 내용을 분석한다.
2. vault의 CLAUDE.md 파일 배치 규칙에 따라 적절한 디렉토리를 판별한다:
   - 원본 소스 → `_raw/{type}/`
   - 추상 개념/이론 → `wiki/concepts/`
   - 도구/라이브러리/서비스/인물 → `wiki/entities/`
   - 프로젝트 관련 → `Projects/{slug}/` 하위
   - 지속 관리 영역 → `Areas/{area}/`
3. 분류 확신도에 따라:
   - **확실(Certain)**: 이동 대상 경로와 근거를 로그에 기록한 뒤 이동 (`--fix` 시).
   - **불확실(Uncertain)**: `Inbox/_unresolved/`로 이동 (`--fix` 시).

### 특수 규칙

- `Inbox/_unresolved/`에 이미 존재하는 파일은 재분류하지 않는다 (skip).
- report-only 모드에서는 분류 제안만 출력하고 파일을 이동하지 않는다.
- 이동 전 대상 경로에 동일 이름 파일 존재 여부를 확인한다. 충돌 시 사용자에게 보고하고 skip.

---

## Phase 2: frontmatter 검증

### 대상

`wiki/` 하위 모든 `.md` 파일을 스캔한다.

### 파일 유형별 필수 필드

각 유형의 상세 필드 정의는 `references/frontmatter-rules.md` 참조.

| 유형 | 필수 필드 |
|------|----------|
| concept | `title`, `type`, `tags`, `status`, `created`, `updated` |
| entity / tool | `name`, `type`, `category`, `status`, `tags`, `url`, `first_seen` |

### 검증 규칙

1. YAML frontmatter 파싱 오류 → 파일명 + 오류 내용 보고.
2. 필수 필드 누락 → 파일명 + 누락 필드 목록 보고.
3. `--fix` 모드에서만 자동 보정 실행:
   - `created` / `updated`: 파일의 mtime에서 추출하여 `YYYY-MM-DD` 형식으로 설정.
   - `type`: 부모 디렉토리명에서 추론 (`wiki/concepts/` → `concept`, `wiki/entities/` → `entity`).
   - 나머지 필드(`title`, `name`, `tags`, `status`, `category`, `url`, `first_seen`)는 자동 보정하지 않는다. 보고만 한다.

---

## Phase 3: wikilink 무결성

### 대상

vault 전체의 `.md` 파일에서 `[[...]]` 패턴을 추출한다.

### 검증 규칙

1. `[[path|alias]]` 형태의 alias 링크 → `path` 부분만 검증한다.
2. 확장자 없는 링크 → `.md`를 붙여 파일 존재 여부를 확인한다 (Obsidian 규칙).
3. 짧은 경로 링크 `[[RSC]]` → vault 전체에서 `RSC.md` 검색.
4. `#heading` 앵커 → 검증 대상에서 제외한다 (복잡도 대비 가치가 낮음).
5. 깨진 링크 발견 시:
   - 유사한 파일명 후보를 제안한다 (레벤슈타인 거리 또는 부분 문자열 매칭).
   - 파일명, 링크 텍스트, 제안 후보를 보고한다.

---

## Phase 3.5: 이미지 참조 통일 + 미참조 _assets/ 검출

상세 정규식 패턴, 변환 규칙, 엣지 케이스는 `references/phase-details.md` 참조.

### 현재 vault 상태

| 형식 | 발생 수 | 파일 수 | 비고 |
|------|---------|---------|------|
| `![[image.png]]` wikilink embed | 1102 | 250 | 주력 형식 |
| `![alt](path)` markdown | 366 | 68 | 대부분 Archive/ 레거시 |
| `<img src>` HTML | 218 | 36 | 대부분 Archive/ 레거시 |

### Stage A: 사전 작업 - 형식 통일 (첫 실행 시에만)

이미지 참조 형식을 Obsidian wikilink `![[...]]`로 통일한다.

1. vault 전체에서 markdown 이미지 `![alt](path)` 및 HTML `<img src>` 패턴을 검색한다.
2. 대상 파일 목록 + 변환 예시를 사용자에게 보고한다.
3. 사용자 확인 후(`--fix` 필수) 일괄 변환을 실행한다:
   - `![alt](_assets/image.png)` → `![[image.png]]`
   - `![alt](image.png)` → `![[image.png]]`
   - `<img src="_assets/image.png">` → `![[image.png]]`
   - alt text가 존재하면: `![[image.png|alt]]`
4. 변환 내역을 로그에 기록한다.

### Stage B: 미참조 이미지 검출

형식 통일 후 단일 패턴 `![[...]]`으로만 검증한다.

1. `_assets/` 디렉토리의 모든 파일명을 수집한다.
2. vault 전체 `.md` 파일에서 `![[filename]]` 패턴을 검색한다.
3. 어떤 `.md`에서도 참조되지 않는 파일 = 미참조(orphan).
4. 출력: 파일 크기 내림차순 목록, 총 크기, 총 개수.
5. **기본값: report-only.** 삭제하지 않는다.
6. `--delete-orphans`: 미참조 파일을 `_assets/_orphaned/`로 이동한다 (즉시 삭제 아님). 사용자 확인 필수.

### 경고 사항

- Dataview, Templater 등 플러그인의 동적 참조는 정적 분석으로 감지할 수 없다. orphan 판정이 100% 정확하지 않을 수 있다.
- `_assets/_orphaned/` 이동 후에도 일정 기간(권장: 30일) 유지한 뒤 수동 삭제를 권장한다.

### 후속 lint 실행

이미 형식 통일이 완료된 상태라면 Stage A를 건너뛰고 Stage B(미참조 검출)만 실행한다. 통일 완료 여부 판별: markdown/HTML 이미지 패턴이 5건 미만이면 통일 완료로 간주한다.

---

## Phase 4: wiki/index.md 통계 갱신

### 대상

`wiki/index.md` 파일의 `## 통계` 섹션.

### 동작

1. 다음 디렉토리의 `.md` 파일 수를 카운트한다:
   - `wiki/concepts/`
   - `wiki/entities/`
   - `_raw/articles/`
2. `## 통계` 섹션의 숫자만 업데이트한다.
3. 다음 섹션은 절대 수정하지 않는다:
   - `## Concepts` 큐레이션 링크
   - `## Entities` 큐레이션 목록
   - `## Recent Updates` 테이블

---

## Phase 5: 로그 기록

### 대상

`wiki/logs/_current.md` (append-only)

### 로그 형식

```
## [YYYY-MM-DD HH:MM] lint | 정기 정리
- inbox classified: {n} files
  - → wiki/concepts/: {n1}
  - → wiki/entities/: {n2}
  - → _raw/articles/: {n3}
  - → Inbox/_unresolved/: {n4}
- frontmatter issues: {n} files ({fixed}/{reported})
- broken links: {n} (suggestions: {n1})
- orphan assets: {n} files ({size} MB)
  - moved to _orphaned/: {n} (--delete-orphans only)
- index.md stats updated
```

---

## 중요 vault 규칙 요약

- Vault 경로: `/Users/doyoonlee/ObsidianVault`
- 대문자 디렉토리: `Projects/`, `Areas/`, `Archive/`, `Inbox/`
- 소문자 디렉토리: `wiki/`, `_raw/`, `_assets/`
- Lint 정책: 파괴적 작업 최소화, 이동 전 반드시 로그 기록
- 불확실한 분류 → `Inbox/_unresolved/` (자동 삭제 금지)
- Lint 결과는 항상 `wiki/logs/_current.md`에 append
