---
name: refactor-clean
description: |
  프로젝트에서 사용되지 않는 코드를 찾아 정리합니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "미사용 코드 정리해줘", "사용하지 않는 코드 정리"
  - "안 쓰는 코드 삭제해줘", "죽은 코드 정리"
  - "미사용 컴포넌트 찾아줘", "사용 안하는 파일 삭제"
  - "미사용 import 정리", "불필요한 코드 제거"
  - "cleanup unused code", "remove dead code"
---

# 미사용 코드 정리 (Cleanup Unused Code)

프로젝트에서 사용되지 않는 코드를 찾아 정리하는 skill입니다.

## 트리거 키워드

다음과 같은 요청에 이 skill을 사용합니다:

**한국어:**
- "미사용 코드 정리해줘"
- "사용하지 않는 코드 정리"
- "안 쓰는 코드 삭제해줘"
- "죽은 코드 정리"
- "미사용 컴포넌트 찾아줘"
- "사용 안하는 파일 삭제"
- "미사용 import 정리"
- "코드 정리해줘" (미사용 코드 맥락)
- "불필요한 코드 제거"
- "쓸모없는 코드 삭제"

**영어:**
- "cleanup unused code"
- "remove dead code"
- "find unused components"
- "delete unused files"
- "cleanup imports"

---

## 이 Skill이 감지하는 것

| 카테고리 | 도구 | 감지 항목 |
|----------|------|-----------|
| JS/TS 코드 | Knip | 미사용 파일, exports, dependencies |
| CSS Modules | check-unused-css | 미사용 CSS 클래스 (.module.css) |
| Imports | eslint-plugin-unused-imports | 미사용 import 문 |

---

## 워크플로우

### Phase 1: 환경 준비

1. **도구 설치 확인 및 자동 설치**
   ```bash
   # package.json에서 devDependencies 확인
   # 없는 도구만 설치
   pnpm add -D knip check-unused-css eslint-plugin-unused-imports
   ```

### Phase 2: 분석 실행

1. **Knip 실행** (미사용 파일, exports, dependencies)
   ```bash
   npx knip --reporter json 2>/dev/null
   ```

   결과 형식:
   ```json
   {
     "files": ["app/unused-file.tsx"],
     "dependencies": ["unused-package"],
     "exports": [{"file": "utils.ts", "symbol": "unusedFunction"}]
   }
   ```

2. **CSS Modules 분석** (미사용 CSS 클래스)
   ```bash
   npx check-unused-css 2>/dev/null
   ```

### Phase 3: 결과 요약 및 확인

1. **분석 결과 표시**
   ```
   ## 분석 결과

   ### 미사용 파일 (X개)
   - app/old-component.tsx
   - utils/deprecated.ts

   ### 미사용 exports (X개)
   - utils.ts: unusedFunction, oldHelper

   ### 미사용 CSS 클래스 (X개)
   - Button.module.css: .oldStyle, .unused

   ### 미사용 dependencies (X개)
   - unused-package
   ```

2. **AskUserQuestion으로 처리할 항목 선택**
   ```
   질문: 어떤 항목을 정리할까요?
   옵션:
   - 전체 정리 (권장)
   - 미사용 파일만
   - 미사용 imports만
   - 미사용 CSS만
   - 미사용 dependencies만
   ```

### Phase 4: 정리 실행

1. **미사용 imports 자동 수정**
   ```bash
   # ESLint로 자동 수정 (프로젝트에 플러그인 설정되어 있을 경우)
   npx eslint --fix "**/*.{ts,tsx}" --rule "unused-imports/no-unused-imports: error"
   ```

2. **미사용 파일 삭제** (사용자 확인 후)
   ```bash
   rm <unused-files>
   ```

3. **미사용 CSS 클래스 제거** (수동 또는 안내)

4. **미사용 dependencies 제거**
   ```bash
   pnpm remove <unused-packages>
   ```

---

## 주의사항

1. **Knip 결과 검토**: 동적 import나 특수한 사용 패턴은 false positive가 발생할 수 있음
2. **삭제 전 확인**: 파일 삭제 전 반드시 사용자에게 확인
3. **CSS Modules 한정**: Tailwind는 빌드 시 자동 purge되므로 별도 처리 불필요
4. **Git 확인**: 삭제 전 git status로 추적 상태 확인

---

## 토큰 효율성 원칙

- ❌ 파일을 직접 읽어서 분석하지 않음
- ✅ 도구 실행 결과(JSON/텍스트)만 파싱
- ✅ 결과 요약만 사용자에게 표시

---

## 의존 도구

| 도구 | 설치 명령 | 용도 |
|------|-----------|------|
| knip | `pnpm add -D knip` | 미사용 파일/exports/deps |
| check-unused-css | `pnpm add -D check-unused-css` | CSS Modules |
| eslint-plugin-unused-imports | `pnpm add -D eslint-plugin-unused-imports` | 미사용 imports |
