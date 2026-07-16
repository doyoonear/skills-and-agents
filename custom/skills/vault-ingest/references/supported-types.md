# 지원 소스 타입

vault-ingest 스킬이 처리할 수 있는 소스 타입과 각 타입별 핸들링 방식.

---

## 파일 타입

### `.md` (Markdown)

- **처리**: Read 도구로 직접 읽기
- **저장 위치**: 콘텐츠 성격에 따라 분기
  - 원본 아티클/클리핑 → `_raw/articles/`
  - 가공된 개념/이론 → `wiki/concepts/`
  - 도구/엔티티 정보 → `wiki/entities/`
- **frontmatter 보존**: 원본에 frontmatter가 있으면 `source_frontmatter` 필드에 원본 메타데이터 보존
- **비고**: 가장 일반적인 입력 타입. frontmatter의 유무와 내용으로 성격 판별

### `.pdf` (PDF)

- **처리**: OpenDataLoader PDF로 마크다운 변환 (`~/.claude/rules/pdf-reading.md` 규칙 준수)
  ```bash
  opendataloader-pdf "path/to/file.pdf" --format markdown --output-dir ./pdf-out
  ```
- **저장 위치**: `_raw/papers/`
- **OCR 폴백**: 텍스트 레이어가 없는 스캔 PDF는 하이브리드 OCR 모드로 재시도
  ```bash
  opendataloader-pdf-hybrid --port 5002 --force-ocr --ocr-lang "ko,en"
  opendataloader-pdf --hybrid docling-fast scanned.pdf
  ```
- **비고**: Claude 내장 Read로 PDF를 직접 여는 것은 OpenDataLoader가 동작 불가한 예외 상황에서만, 사용자 허가 후 허용

### `.txt` (Plain Text)

- **처리**: Read 도구로 직접 읽기
- **저장 위치**: `_raw/articles/`
- **변환**: 마크다운으로 변환 후 저장 (제목 추출, 단락 구분 등 기본 구조화)
- **비고**: 인코딩 문제 발생 시 UTF-8 변환 시도

### `.json` (JSON)

- **처리**: 구조 파싱 후 콘텐츠 성격 판별
- **저장 위치**: 콘텐츠에 따라 분기
  - API 응답/데이터 → `_raw/articles/` (마크다운으로 구조화)
  - 설정/스키마 → `_raw/articles/` (코드 블록으로 래핑)
  - Claude export JSON → 별도 가이드 (`references/import-claude-export.md`) 참조
- **비고**: 대용량 JSON(10MB 초과)은 사용자에게 확인 후 처리

---

## URL

- **처리 (1차)**: WebFetch로 페이지 콘텐츠 추출
- **처리 (폴백)**: WebFetch 결과에 실제 본문이 없으면(CSS/JS만 반환, SPA 등) agent-browser 스킬로 재시도
- **저장 위치**: `_raw/articles/`
- **frontmatter 추가 필드**: `source_url`에 원본 URL 기록
- **비고**: JavaScript 렌더링이 필요한 SPA 사이트는 agent-browser 폴백이 필수

---

## 디렉토리

- **처리**: 디렉토리 내 `.md` 및 `.json` 파일만 재귀 스캔
- **제한**: 최대 50개 파일. 초과 시 사용자에게 범위 축소 요청
- **저장 위치**: 각 파일의 타입에 따라 개별 판별 (위 규칙 적용)
- **비고**: `.pdf`, `.txt` 등 다른 타입은 디렉토리 배치 스캔에서 제외 (개별 경로로 지정해야 함)

---

## 타입별 저장 위치 요약

| 소스 타입 | 기본 저장 위치 | 조건부 저장 위치 |
|----------|--------------|----------------|
| `.md` | `_raw/articles/` | 가공 지식이면 `wiki/concepts/` 또는 `wiki/entities/` |
| `.pdf` | `_raw/papers/` | - |
| `.txt` | `_raw/articles/` | - |
| `.json` | `_raw/articles/` | Claude export는 별도 가이드 |
| URL | `_raw/articles/` | - |
| 디렉토리 | 개별 파일 규칙 적용 | - |
