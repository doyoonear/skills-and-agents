# Frontmatter 필수 필드 규칙

vault-lint Phase 2에서 참조하는 파일 유형별 frontmatter 필수 필드 정의.

---

## concept (wiki/concepts/)

추상 개념, 이론, 패턴, 방법론을 다루는 문서.

### 필수 필드

| 필드 | 타입 | 설명 | 예시 | --fix 자동 보정 |
|------|------|------|------|----------------|
| `title` | string | 개념 이름 | `"React Server Components"` | 불가 |
| `type` | string | 항상 `"concept"` | `"concept"` | 가능 (부모 디렉토리에서 추론) |
| `tags` | list | 분류 태그 | `["react", "ssr", "architecture"]` | 불가 |
| `status` | string | 문서 상태 | `"draft"` / `"active"` / `"archived"` | 불가 |
| `created` | string | 생성 날짜 (YYYY-MM-DD) | `"2025-03-15"` | 가능 (파일 mtime) |
| `updated` | string | 수정 날짜 (YYYY-MM-DD) | `"2025-04-10"` | 가능 (파일 mtime) |

### 선택 필드 (검증하지 않으나 권장)

| 필드 | 타입 | 설명 |
|------|------|------|
| `aliases` | list | Obsidian alias (약칭, 한글명 등) |
| `projects` | list | 연결된 프로젝트 slug |
| `related` | list | 관련 개념 wikilink |
| `sources` | list | 참고 소스 (URL 또는 _raw/ 경로) |

### 예시

```yaml
---
title: "React Server Components"
type: concept
tags: [react, ssr, architecture]
status: active
created: "2025-03-15"
updated: "2025-04-10"
aliases: [RSC]
projects: [my-web-app]
---
```

---

## entity / tool (wiki/entities/)

도구, 라이브러리, 서비스, 인물 등 구체적인 엔티티를 다루는 문서.
`wiki/entities/tools/` 하위의 도구 문서도 이 규칙을 따른다.

### 필수 필드

| 필드 | 타입 | 설명 | 예시 | --fix 자동 보정 |
|------|------|------|------|----------------|
| `name` | string | 엔티티 이름 | `"Supabase"` | 불가 |
| `type` | string | `"entity"` 또는 `"tool"` | `"tool"` | 가능 (부모 디렉토리에서 추론) |
| `category` | string | 분류 카테고리 | `"database"` / `"framework"` / `"service"` | 불가 |
| `status` | string | 문서 상태 | `"draft"` / `"active"` / `"archived"` | 불가 |
| `tags` | list | 분류 태그 | `["backend", "baas", "postgres"]` | 불가 |
| `url` | string | 공식 URL | `"https://supabase.com"` | 불가 |
| `first_seen` | string | 최초 인지 날짜 (YYYY-MM-DD) | `"2025-01-20"` | 불가 |

### 선택 필드 (검증하지 않으나 권장)

| 필드 | 타입 | 설명 |
|------|------|------|
| `aliases` | list | 별칭 |
| `projects` | list | 연결된 프로젝트 slug |
| `related` | list | 관련 엔티티/개념 wikilink |
| `pricing` | string | 가격 모델 (`"free"`, `"freemium"`, `"paid"`) |
| `license` | string | 라이선스 (`"MIT"`, `"Apache-2.0"`, `"proprietary"`) |

### 예시

```yaml
---
name: "Supabase"
type: tool
category: database
status: active
tags: [backend, baas, postgres, realtime]
url: "https://supabase.com"
first_seen: "2025-01-20"
aliases: [수파베이스]
pricing: freemium
license: Apache-2.0
---
```

---

## response (Projects/{slug}/agents/responses/)

대화 추출 응답 문서. lint의 직접 검증 대상은 아니지만 참고용으로 기록한다.

### 권장 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `title` | string | 응답 요약 |
| `type` | string | `"response"` |
| `project` | string | 소속 프로젝트 slug |
| `created` | string | 생성 날짜 |
| `tags` | list | 관련 태그 |
| `promote_candidate` | boolean | 승급 후보 여부 |

---

## _raw/article (_raw/articles/)

원본 소스 아티클. lint의 직접 검증 대상은 아니지만 참고용으로 기록한다.

### 권장 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `title` | string | 아티클 제목 |
| `type` | string | `"article"` |
| `source` | string | 원본 URL |
| `author` | string | 저자 |
| `date` | string | 원본 게시 날짜 |
| `tags` | list | 관련 태그 |
| `ingested` | string | 수집 날짜 |

---

## --fix 자동 보정 규칙 상세

자동 보정은 오류 가능성이 낮은 필드에만 적용한다.

### 보정 가능 필드

1. **`created`**: 파일 시스템의 생성 시간(birthtime) 또는 mtime 중 이른 값을 `YYYY-MM-DD` 형식으로 설정.
2. **`updated`**: 파일 시스템의 mtime을 `YYYY-MM-DD` 형식으로 설정.
3. **`type`**: 부모 디렉토리 경로에서 추론.
   - `wiki/concepts/**` → `"concept"`
   - `wiki/entities/**` → `"entity"`
   - `wiki/entities/tools/**` → `"tool"`

### 보정 불가 필드

의미적 판단이 필요한 필드는 자동 보정하지 않는다. 누락 사실만 보고한다.

- `title`, `name`: 파일명에서 추측할 수 있으나 정확도 보장 불가.
- `tags`: 본문 분석 필요.
- `status`: 문서 완성도 판단 필요.
- `category`, `url`, `first_seen`: 외부 정보 필요.
