---
name: vault-promote
description: |
  프로젝트의 responses/solutions를 wiki로 승급하는 지식 승급 도구.
  Use when user mentions "/promote", "프로모트", "승급", "wiki로 올려", "지식 승급".
  Not for vault 정리(/lint) 또는 소스 수집(/ingest).
---

# vault-promote

프로젝트에서 축적된 문제 해결 기록(responses, solutions)을 평가하여, 재사용 가치가 높은 지식을 wiki 지식베이스로 승급시키는 스킬.

- Vault 경로: `/Users/doyoonlee/ObsidianVault`
- 로그 파일: `wiki/logs/_current.md`
- wiki는 agents-only 영역이다. human은 검수/피드백만 한다.

## 사용법

```
/promote {프로젝트 slug}            # 해당 프로젝트의 승급 후보 스캔 및 실행
/promote {프로젝트 slug} --complete  # 승급 + 프로젝트 완료 처리 + Archive 이동
```

## 전체 워크플로우

### 1단계: 대상 스캔

`Projects/{slug}/agents/responses/*.md`와 `Projects/{slug}/agents/solutions/*.md`를 스캔한다.

**스캔 규칙:**

- frontmatter에 `promoted_to:` 필드가 이미 있는 파일은 승급 완료 상태이므로 건너뛴다.
- 동일 토픽의 responses가 3개 이상 누적된 경우, wiki 통합(consolidation)을 사용자에게 제안한다.
  - 예: CORS 관련 responses가 3개 → "CORS 관련 문서 3개를 하나의 wiki 문서로 통합할까요?" 제안

### 2단계: 재사용 가치 판정

스캔된 각 파일에 대해 세 가지 기준으로 평가한다. **2개 이상 충족 시 승급 후보**로 판정한다.

| 기준 | 설명 | 예시 |
|------|------|------|
| **일반성** | 특정 프로젝트에 국한되지 않는 기술/패턴/도구의 일반적 설명을 포함 | "Next.js App Router에서 RSC 캐싱 전략" |
| **재발 가능성** | 다른 프로젝트에서도 같은 문제가 발생할 가능성이 높음 | CORS, 인증, 캐싱, DB 마이그레이션, 환경 설정 |
| **근거/비교 포함** | 단순 코드 수정이 아니라, 왜 이 접근이 맞는지 근거를 설명하거나 대안을 비교 | "A 방식 vs B 방식 비교 후 A 선택한 이유" |

**판정 후 반드시 사용자에게 결과를 보고하고, 확인을 받은 뒤에만 승급을 실행한다.**

보고 형식 예시:

```
## 승급 후보 판정 결과

| 파일 | 일반성 | 재발 가능성 | 근거/비교 | 판정 |
|------|--------|-------------|-----------|------|
| responses/cors-proxy-setup.md | O | O | O | 승급 |
| responses/fix-env-typo.md | X | X | X | 제외 |
| solutions/supabase-rls-pattern.md | O | O | X | 승급 |
```

사용자 확인 후, 승급 대상 파일에서 **프로젝트 고유 내용을 제거하고 일반화**한다:

- 프로젝트 고유 변수명, 경로, 설정값 제거
- 일반적인 설명과 패턴으로 재작성
- 원본의 핵심 인사이트와 근거는 보존

### 3단계: 승급 실행

승급 대상 파일마다 다음을 수행한다.

**wiki 문서 생성:**

- 개념/이론/패턴 → `wiki/concepts/{slug}.md`
- 도구/라이브러리/서비스 → `wiki/entities/{slug}.md` (또는 `wiki/entities/tools/{slug}.md`)
- 새 wiki 문서의 frontmatter에 `extracted_from:` 필드를 추가하여 출처를 명시한다.

```yaml
---
title: "Supabase RLS 패턴"
extracted_from: "Projects/my-app/agents/solutions/supabase-rls-pattern.md"
tags:
  - supabase
  - rls
  - security
---
```

**원본 파일 업데이트:**

- 원본 파일의 frontmatter에 `promoted_to:` 필드를 추가한다.

```yaml
---
promoted_to: "wiki/concepts/supabase-rls-pattern.md"
---
```

**이름 충돌 처리:**

- 생성하려는 wiki 문서와 동일한 이름의 파일이 이미 존재하면, 자동으로 덮어쓰지 않는다.
- 대신 "merge candidate report"를 생성하여 사용자에게 보고한다.
  - 기존 문서와 새 문서의 내용을 비교
  - 병합 제안 또는 별도 문서 생성 여부를 사용자에게 질문

**wiki 인덱스 업데이트:**

- 새 문서를 `wiki/index.md`에 추가한다.

### 4단계: `--complete` 플래그 처리

`--complete` 플래그가 있을 때만 실행한다. 프로젝트 완료 처리 전체 흐름이다.

1. **승급 완료 확인**: 모든 승급 후보가 처리되었는지 확인한다. 미처리 후보가 있으면 먼저 승급을 완료한다.

2. **참조 경로 업데이트**: vault 전체에서 `Projects/{slug}/`를 참조하는 파일을 검색한다.
   - 발견된 모든 참조 경로를 `Archive/Projects/{slug}/`로 변경한다.
   - 변경 대상 파일 목록을 사용자에게 보고한다.

3. **프로젝트 폴더 이동**: `Projects/{slug}/` 전체를 `Archive/Projects/{slug}/`로 이동한다.

4. **상태 업데이트**: `Archive/Projects/{slug}/_context.md`의 status를 `completed`로 변경한다.

### 5단계: 로그 기록

모든 작업 완료 후 `wiki/logs/_current.md`에 로그를 append한다.

로그 형식:

```
## [YYYY-MM-DD HH:MM] promote | {project}
- scanned: {n} files (responses: {n1}, solutions: {n2})
- promoted: {n3} files
  - {source_path} → {wiki_path}
- skipped: {n4} files (project-specific / already promoted)
- archived: {yes/no}
```

## 주기적 제안

- 매월 1일 또는 마지막 promote 실행 후 30일이 경과하면, 활성 프로젝트에 대해 지식 승급을 제안한다.
- 제안 시 각 프로젝트의 미승급 responses/solutions 파일 수를 함께 표시한다.

## 주의사항

- `wiki/`는 agents-only 영역이다. 승급 문서는 agent가 작성하고 human이 검수한다.
- `Projects/`는 human 주도 영역이다. 구조 변경(Archive 이동 포함)은 반드시 사용자 확인 후 실행한다.
- 디렉토리명은 대문자로 시작한다: `Projects/`, `Areas/`, `Archive/`.
- 승급 판정 결과는 반드시 사용자에게 먼저 보고하고, 확인 없이 실행하지 않는다.
- 이름 충돌 시 자동 생성하지 않고 merge candidate report를 먼저 제시한다.
