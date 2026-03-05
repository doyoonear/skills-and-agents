# Custom Skills Audit Report

Skill Creator 원칙 기반 전수 평가 결과 (2026-03-05)

## 평가 기준 (Skill Creator Principles)

1. **Metadata Quality**: frontmatter의 name/description이 구체적이고, 트리거/제외 조건 명시
2. **Third-person voice**: "This skill should be used when..." 형식 사용
3. **Writing style**: Imperative/infinitive form 사용
4. **Progressive disclosure**: SKILL.md는 lean하게, 상세 내용은 references/로 분리
5. **Single responsibility**: 하나의 명확한 역할
6. **No duplication**: 중복 스킬 없음

---

## 1. 정상 스킬 (개선 완료) - 28개

다음 스킬들은 frontmatter를 skill creator 원칙에 맞게 개선 완료:

| # | Skill | Status | Notes |
|---|-------|--------|-------|
| 1 | allow-permissions | OK | Frontmatter 개선 완료 |
| 2 | autonomous-agent | OK | Frontmatter 개선 완료 |
| 3 | component-architecture | OK | Frontmatter 개선 완료 |
| 4 | deploy-with-cloudflare | OK | Frontmatter 개선 완료 |
| 5 | error-handling-system | OK | Frontmatter 개선 + body 트리거 목록 제거 |
| 6 | git-pr-workflow | OK | Frontmatter 개선 완료 |
| 7 | handoff | OK | Frontmatter 개선 완료 |
| 8 | mcp-builder | OK | Frontmatter 개선 완료 |
| 9 | mece-writing | OK | Frontmatter 개선 완료 |
| 10 | mermaid-diagram-creator | OK | Frontmatter 개선 완료 |
| 11 | modal-system-generator | OK | Frontmatter 개선 완료 |
| 12 | modern-python | OK | Frontmatter 대폭 개선 |
| 13 | perf-bottleneck-finder | OK | Frontmatter 개선 완료 |
| 14 | performance-improve-process | OK | Frontmatter 개선 완료 |
| 15 | ppt-design | OK | Frontmatter 개선 완료 |
| 16 | ralph-planner | OK | Frontmatter 개선 완료 |
| 17 | react-refactoring | OK | Frontmatter 개선 완료 |
| 18 | refactor-clean | OK | Frontmatter 개선 완료 |
| 19 | software-architecture | OK | Frontmatter 개선 완료 |
| 20 | supabase-database-guide | OK | Frontmatter 개선 완료 |
| 21 | supabase-storage-guide | OK | Frontmatter 개선 완료 |
| 22 | supabase-troubleshooting | OK | Frontmatter 개선 완료 |
| 23 | test-driven-development | OK | Frontmatter 대폭 개선 (트리거/제외 추가) |
| 24 | testing-principles | OK | Frontmatter 개선 완료 |
| 25 | ui-css-patterns | OK | Frontmatter 개선 완료 |
| 26 | ui-motion-guide | OK | Frontmatter 개선 완료 |
| 27 | ui-sound-design | OK | Frontmatter 개선 완료 |
| 28 | verification-loop | OK | Frontmatter 개선 완료 |
| 29 | wrap | OK | Frontmatter 개선 완료 |
| 30 | static-analysis/codeql | OK | Frontmatter 개선 + allowed-tools 필드 제거 |
| 31 | static-analysis/sarif-parsing | OK | Frontmatter 개선 + allowed-tools 필드 제거 |
| 32 | static-analysis/semgrep | OK | Frontmatter 개선 + allowed-tools 필드 제거 |

---

## 2. Deprecated 스킬 - 1개

| Skill | 이유 | 대체 스킬 |
|-------|------|-----------|
| **tdd-workflow** | test-driven-development와 중복. tdd-workflow는 간략한 한국어 버전이고, test-driven-development는 더 엄격하고 포괄적인 영어 버전. | `test-driven-development` |

---

## 3. Standalone .md 파일 (스킬 아님) - 17개

다음 파일들은 `custom/skills/` 디렉토리에 직접 놓인 `.md` 파일로, 정식 스킬(SKILL.md + 디렉토리) 형태가 아닙니다.
이들은 **레퍼런스 문서**로 분류되며, 향후 적절한 스킬의 `references/` 디렉토리로 이동하거나 별도 정리가 권장됩니다.

### 프론트엔드 프레임워크/라이브러리 가이드

| 파일 | 내용 | 관련 스킬 또는 권장 조치 |
|------|------|------------------------|
| `emotion-best-practices.md` | Emotion CSS-in-JS 가이드 | `ui-css-patterns/references/`로 이동 고려 |
| `emotion-classnames-guide.md` | Emotion + Classnames 가이드 | `ui-css-patterns/references/`로 이동 고려 |
| `tailwind-v4-guide.md` | Tailwind CSS v4 변경사항 | `ui-css-patterns/references/`로 이동 고려 |
| `tanstack-query-guide.md` | TanStack Query 가이드 | 별도 스킬 생성 또는 references 이동 |
| `zustand-guide.md` | Zustand 상태관리 가이드 | 별도 스킬 생성 또는 references 이동 |
| `use-funnel-nextjs-guide.md` | @use-funnel Next.js 가이드 | 별도 스킬 생성 또는 references 이동 |
| `use-funnel-react-router-guide.md` | @use-funnel React Router 가이드 | 별도 스킬 생성 또는 references 이동 |
| `vapor-ui-components-guide.md` | Vapor UI 컴포넌트 가이드 | 프로젝트 특화 문서, references 이동 |

### React 패턴/원칙

| 파일 | 내용 | 관련 스킬 또는 권장 조치 |
|------|------|------------------------|
| `frontend-code-principles.md` | 프론트엔드 코드 작성 원칙 | `react-refactoring/references/`로 이동 고려 |
| `react-infinite-render-prevention.md` | 무한 렌더링 방지 | `react-refactoring/references/`로 이동 고려 |
| `typescript-type-safety-guide.md` | TypeScript 타입 안전성 | 별도 스킬 생성 또는 references 이동 |

### 백엔드/DB/API

| 파일 | 내용 | 관련 스킬 또는 권장 조치 |
|------|------|------------------------|
| `postgres-best-practices.md` | Postgres 성능 최적화 | `supabase-database-guide/references/`로 이동 고려 |
| `server-side-filtering-optimization.md` | 서버사이드 필터링 최적화 | `perf-bottleneck-finder/references/`로 이동 고려 |

### 특수 도구/기술

| 파일 | 내용 | 관련 스킬 또는 권장 조치 |
|------|------|------------------------|
| `lottie-guide.md` | Lottie 애니메이션 가이드 | `ui-motion-guide/references/`로 이동 고려 |
| `threejs-marching-cubes-guide.md` | Three.js MarchingCubes | 매우 특수한 주제, references 이동 |
| `elevenlabs-conversational-ai-guide.md` | ElevenLabs AI Agent | 별도 스킬 생성 고려 |

### 문서화

| 파일 | 내용 | 관련 스킬 또는 권장 조치 |
|------|------|------------------------|
| `documentation-guidelines.md` | 문서 작성 가이드 | 정식 스킬로 변환 고려 (자동 트리거 조건 있음) |

---

## 4. 향후 개선 권장 사항

### 높은 우선순위

1. **tdd-workflow 삭제**: deprecated된 스킬 완전 제거 검토
2. **standalone .md 파일 정리**: references/ 디렉토리로 이동하여 progressive disclosure 원칙 적용
3. **documentation-guidelines.md**: 정식 스킬로 변환 (자동 트리거 조건이 이미 있음)

### 중간 우선순위

4. **error-handling-system**: SKILL.md가 매우 길음 (400줄+). 상세 템플릿 설명을 references/로 분리 권장
5. **react-refactoring**: SKILL.md가 매우 길음 (500줄+). 패턴 상세를 references/로 분리 권장
6. **mece-writing**: 내장 프레임워크 레퍼런스를 references/로 분리 권장
7. **deploy-with-cloudflare**: SKILL.md가 길음. 프레임워크별 가이드를 references/로 분리 권장

### 낮은 우선순위

8. **modal-system-generator + component-architecture**: 일부 내용 중복 (Provider/Hook 패턴). 역할 분리 명확화 권장
9. **perf-bottleneck-finder + performance-improve-process**: 잘 분리되어 있으나, performance-improve-process에서 perf-bottleneck-finder 참조 방법을 더 명확히 안내
