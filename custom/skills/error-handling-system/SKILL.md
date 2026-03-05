---
name: error-handling-system
description: |
  React ErrorBoundary & Suspense 전역 처리 시스템. 에러 경계, 로딩 스켈레톤, 전역 에러 핸들링 구현.
  This skill should be used when setting up global error handling with ErrorBoundary, implementing Suspense with skeleton loading, or when user mentions "에러 시스템", "에러바운더리", "ErrorBoundary", "Suspense", "스켈레톤 로딩".
  Not for try-catch error handling in server-side code or API error responses.
---

# React ErrorBoundary & Suspense 전역 처리 시스템

## 이 스킬이 제공하는 것

1. **React 18/19 ErrorBoundary 클래스 컴포넌트** 템플릿
2. **세부 영역별 ErrorBoundary 배치 전략** (전역 / 페이지 / 컴포넌트 단위)
3. **API별 Suspense 분리 패턴** (중첩 Suspense, 점진적 로딩)
4. **Smooth 애니메이션 Skeleton 컴포넌트** (4가지 스타일링 버전)
5. **TanStack Query 통합 예시** (suspense: true 옵션)
6. **실전 적용 가이드 및 체크리스트**

---

## 🔍 환경 자동 감지 및 템플릿 선택

Skills 실행 시 **자동으로 프로젝트 환경을 분석**하여 적절한 템플릿을 제공합니다.

### 1단계: 패키지 관리자 감지

```typescript
// 우선순위 순서로 감지
1. package.json의 packageManager 필드 확인
2. Lock 파일 확인:
   - yarn.lock → yarn
   - pnpm-lock.yaml → pnpm
   - package-lock.json → npm
```

### 2단계: 스타일링 방식 감지

```typescript
// package.json dependencies 확인
if (dependencies['@emotion/react'] || dependencies['@emotion/styled']) {
  → skeleton-emotion.tsx.md 템플릿 사용
}
else if (dependencies['tailwindcss']) {
  → skeleton-tailwind.tsx.md 템플릿 사용
}
// 파일 패턴 확인 (프로젝트 내 검색)
else if (파일명 패턴: *.module.scss) {
  → skeleton-scss-modules.tsx.md 템플릿 사용
}
else if (파일명 패턴: *.module.css) {
  → skeleton-css-modules.tsx.md 템플릿 사용
}
// 기본값
else {
  → CSS Modules 템플릿 사용 (가장 범용적)
}
```

### 3단계: 데이터 페칭 라이브러리 확인

```typescript
// TanStack Query 설치 여부 확인
if (dependencies['@tanstack/react-query']) {
  → TanStack Query 통합 예시 제공
}
else {
  → 일반 Suspense 패턴 예시 제공
}
```

---

## 📚 React 18/19 Best Practices 요약

### ErrorBoundary 핵심 원칙

> React 18과 19에서 ErrorBoundary 사용법은 **동일**합니다.

#### 1. 클래스 컴포넌트 필수
- ErrorBoundary는 **반드시 클래스 컴포넌트**로 작성
- 함수 컴포넌트에서는 사용 불가
- 두 가지 정적 메서드 필요:
  - `static getDerivedStateFromError(error)`: 상태 업데이트
  - `componentDidCatch(error, info)`: 에러 로깅

#### 2. 세부 영역별 적용 (Granular ErrorBoundaries)
- **모든 컴포넌트**를 감싸지 말 것
- **의미 있는 지점**에만 배치:
  - 전역 ErrorBoundary: App 최상위 (최후의 안전망)
  - 페이지별 ErrorBoundary: 페이지 단위 에러 격리
  - 컴포넌트별 ErrorBoundary: API 호출 영역별 적용

#### 3. 에러 격리 전략
- 한 영역의 에러가 **다른 영역에 영향 주지 않도록** 설계
- 예: 댓글 로딩 실패 시 → 댓글만 에러 UI, 게시물은 정상 표시

### Suspense 핵심 원칙

#### 1. 중첩 Suspense (Nested Suspense)
- **API별로 독립적인 Suspense 경계** 설정
- 부모-자식 관계에서 **점진적 로딩** 구현
- 가장 가까운 부모 Suspense가 fallback 표시

```tsx
<Suspense fallback={<PageSkeleton />}>
  <Header />
  <Suspense fallback={<PostSkeleton />}>
    <Post />
  </Suspense>
  <Suspense fallback={<CommentsSkeleton />}>
    <Comments />
  </Suspense>
</Suspense>
```

#### 2. Fallback UI 설계
- **가벼운 플레이스홀더**: 스켈레톤 또는 스피너
- **디자이너와 협력**: 로딩 상태 위치 결정
- **성급한 세분화 금지**: 모든 컴포넌트에 개별 Suspense 설정하지 말 것

#### 3. startTransition으로 기존 콘텐츠 보호
- 갑작스러운 fallback 표시 방지
- 사용자 경험 향상

```tsx
function navigate(url) {
  startTransition(() => {
    setPage(url);
  });
}
```

### ErrorBoundary + Suspense 조합 패턴

```tsx
// 권장 구조
<ErrorBoundary fallback={<ErrorUI />}>
  <Suspense fallback={<SkeletonUI />}>
    <Component />
  </Suspense>
</ErrorBoundary>
```

**이유:**
- 로딩 중: Suspense fallback 표시
- 에러 발생: ErrorBoundary fallback 표시
- 명확한 책임 분리

---

## 🏗️ 전역 에러처리 아키텍처

### 3단계 ErrorBoundary 전략

```
┌─────────────────────────────────────────┐
│   1. 전역 ErrorBoundary (App.tsx)       │  ← 최후의 안전망
│   ├─────────────────────────────────┐   │
│   │ 2. 페이지별 ErrorBoundary        │   │  ← 페이지 단위 격리
│   │ ├─────────────────────────────┐ │   │
│   │ │ 3. 컴포넌트별 ErrorBoundary  │ │   │  ← API 단위 격리
│   │ │   <Suspense>                │ │   │
│   │ │     <Component />           │ │   │
│   │ │   </Suspense>               │ │   │
│   │ └─────────────────────────────┘ │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### API별 Suspense 분리 전략

```tsx
// ❌ 나쁜 예: 모든 API를 하나의 Suspense로
<Suspense fallback={<FullPageSkeleton />}>
  <UserProfile />      {/* API 1 */}
  <UserPosts />        {/* API 2 */}
  <UserComments />     {/* API 3 */}
</Suspense>
// 문제: 하나의 API라도 로딩 중이면 전체가 skeleton

// ✅ 좋은 예: API별로 독립적인 Suspense
<div>
  <Suspense fallback={<ProfileSkeleton />}>
    <UserProfile />    {/* API 1 */}
  </Suspense>
  <Suspense fallback={<PostsSkeleton />}>
    <UserPosts />      {/* API 2 */}
  </Suspense>
  <Suspense fallback={<CommentsSkeleton />}>
    <UserComments />   {/* API 3 */}
  </Suspense>
</div>
// 장점: 각 API가 독립적으로 로딩/표시
```

---

## 📂 템플릿 파일 가이드

### 공통 템플릿 (스타일링 무관)

#### 1. `error-boundary.tsx.md`
- ErrorBoundary 클래스 컴포넌트
- Props: `fallback`, `onReset`, `onError`, `FallbackComponent`
- 전역 / 페이지 / 컴포넌트별 ErrorBoundary 예시
- 재시도 로직 통합

#### 2. `error-fallback.tsx.md`
- 다양한 에러 폴백 UI 템플릿
- 전체 페이지 에러 / 부분 영역 에러
- 재시도 버튼 컴포넌트
- 에러 타입별 메시지 커스터마이징

### 스타일링별 Skeleton 템플릿

감지된 스타일링 방식에 따라 **자동으로 선택**됩니다:

#### 1. `skeleton-emotion.tsx.md` (Emotion)
- `@emotion/react`, `@emotion/styled` 사용
- CSS-in-JS 방식
- Smooth 애니메이션 (2.5s duration)

#### 2. `skeleton-css-modules.tsx.md` (CSS Modules)
- `*.module.css` 파일
- className 기반 스타일
- @keyframes 애니메이션

#### 3. `skeleton-scss-modules.tsx.md` (SCSS Modules)
- `*.module.scss` 파일
- SCSS mixin, variables 활용
- 중첩 구문 지원

#### 4. `skeleton-tailwind.tsx.md` (Tailwind CSS)
- Tailwind utility classes
- `tailwind.config.js` 커스텀 keyframes
- className 조합

### 실전 예시

#### 5. `usage-examples.tsx.md`
- TanStack Query + Suspense + ErrorBoundary 통합
- 리스트 페이지 예시
- 상세 페이지 예시
- 무한 스크롤 (InfiniteQuery) 예시
- 병렬 API 호출 예시

---

## 🎨 Skeleton 디자인 원칙 (Smooth 버전)

### 기존 vs 개선

| 항목 | 기존 (반짝임) | 개선 (Smooth) |
|------|--------------|--------------|
| **애니메이션 duration** | 1.5s | **2.5s** |
| **opacity gradient** | 높은 대비 (0.11 → 0.04) | **낮은 대비 (0.08 → 0.05)** |
| **easing** | ease-in-out | **cubic-bezier(0.4, 0, 0.2, 1)** |

### 애니메이션 원칙

```css
/* Smooth wave 애니메이션 */
@keyframes skeleton-wave {
  0% {
    background-position: 200% 50%;
  }
  100% {
    background-position: -200% 50%;
  }
}

.skeleton-wave {
  background: linear-gradient(
    90deg,
    rgba(0, 0, 0, 0.08) 0%,      /* 낮은 대비 */
    rgba(0, 0, 0, 0.08) 40%,
    rgba(0, 0, 0, 0.05) 50%,     /* 부드러운 highlight */
    rgba(0, 0, 0, 0.08) 60%,
    rgba(0, 0, 0, 0.08) 100%
  );
  background-size: 200% 100%;
  animation: skeleton-wave 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}
```

---

## ✅ 실전 적용 체크리스트

### 1단계: 환경 확인
- [ ] package.json에서 패키지 관리자 확인
- [ ] 스타일링 라이브러리 확인 (Emotion/CSS Modules/SCSS/Tailwind)
- [ ] TanStack Query 설치 여부 확인

### 2단계: ErrorBoundary 적용
- [ ] `error-boundary.tsx.md` 템플릿 복사
- [ ] App.tsx에 **전역 ErrorBoundary** 설정
- [ ] 각 페이지에 **페이지별 ErrorBoundary** 설정
- [ ] API 호출 컴포넌트에 **컴포넌트별 ErrorBoundary** 설정

### 3단계: Skeleton UI 적용
- [ ] 감지된 스타일링에 맞는 Skeleton 템플릿 복사
- [ ] 각 컴포넌트별 **커스텀 Skeleton** 제작
- [ ] Preset 컴포넌트 활용 (SkeletonCard, SkeletonListItem 등)

### 4단계: Suspense 적용
- [ ] TanStack Query 사용 시 `suspense: true` 옵션 추가
- [ ] 각 API 호출별 **독립적인 Suspense** 설정
- [ ] Suspense fallback에 Skeleton 컴포넌트 연결

### 5단계: ErrorBoundary + Suspense 조합
- [ ] ErrorBoundary > Suspense > Component 순서 확인
- [ ] 에러 발생 시 재시도 버튼 동작 확인
- [ ] 로딩 → 성공 / 에러 플로우 테스트

### 6단계: 실전 패턴 적용
- [ ] `usage-examples.tsx.md` 참고하여 프로젝트에 맞게 커스터마이징
- [ ] 리스트 페이지 적용
- [ ] 상세 페이지 적용
- [ ] 무한 스크롤 적용 (필요 시)

---

## 🚀 빠른 시작 가이드

### 1. Skills 실행

사용자가 다음 중 하나를 요청:
```
"에러바운더리 적용해줘"
"서스펜스 적용해줘"
"스켈레톤 로딩 적용해줘"
```

### 2. Agent 자동 처리

```typescript
// 1. 환경 감지
const packageManager = detectPackageManager(); // yarn/pnpm/npm
const styling = detectStyling(); // emotion/css-modules/scss-modules/tailwind
const hasReactQuery = checkReactQuery(); // boolean

// 2. 템플릿 선택
const skeletonTemplate = {
  emotion: 'skeleton-emotion.tsx.md',
  'css-modules': 'skeleton-css-modules.tsx.md',
  'scss-modules': 'skeleton-scss-modules.tsx.md',
  tailwind: 'skeleton-tailwind.tsx.md',
}[styling];

// 3. 파일 생성
- src/components/ErrorBoundary.tsx (error-boundary.tsx.md 기반)
- src/components/ErrorFallback.tsx (error-fallback.tsx.md 기반)
- src/components/Skeleton.tsx (skeletonTemplate 기반)

// 4. 사용 예시 제공
- usage-examples.tsx.md 기반으로 적용 가이드 제공
```

### 3. 사용자 확인 및 적용

Agent가 생성한 파일을 확인하고 프로젝트에 맞게 커스터마이징

---

## 📖 참고 자료

### React 공식 문서
- [React Suspense](https://react.dev/reference/react/Suspense)
- [ErrorBoundary (Class Component)](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)

### 웹 검색 결과 (2025 Best Practices)
- **React 19 Suspense Deep Dive** (DEV Community)
- **React 19 Resilience: Retry, Suspense & Error Boundaries** (Medium)
- **Suspense and Error Boundary in React Explained** (Reetesh Kumar)

### 핵심 인사이트
1. **React 18/19는 ErrorBoundary, Suspense 사용법 동일**
2. **ErrorBoundary + Suspense 조합 필수**: 각각 에러/로딩 담당
3. **세분화된 경계**: 모든 컴포넌트가 아닌 의미 있는 지점에만 적용
4. **TanStack Query**: `suspense: true` 옵션으로 간편하게 통합

---

## 💡 자주 묻는 질문 (FAQ)

### Q1. 함수 컴포넌트로 ErrorBoundary를 만들 수 없나요?
A1. React 18/19 모두 **클래스 컴포넌트만 지원**합니다. 함수 컴포넌트에서 사용하려면 `react-error-boundary` 패키지를 활용하세요.

### Q2. 모든 컴포넌트에 ErrorBoundary를 감싸야 하나요?
A2. 아니요. **의미 있는 지점**에만 배치하세요:
- 전역 (App.tsx)
- 페이지별
- API 호출 컴포넌트별

### Q3. Suspense를 사용하려면 TanStack Query가 필수인가요?
A3. 아니요. 하지만 TanStack Query를 사용하면 **훨씬 간편**합니다:
```tsx
// TanStack Query 없이
const resource = fetchData(); // Suspense 지원 래퍼 필요
<Suspense fallback={<Skeleton />}>
  <Component resource={resource} />
</Suspense>

// TanStack Query 사용
const { data } = useQuery({
  queryKey: ['data'],
  queryFn: fetchData,
  suspense: true  // 한 줄로 해결
});
<Suspense fallback={<Skeleton />}>
  <Component />
</Suspense>
```

### Q4. Skeleton 애니메이션을 끌 수 있나요?
A4. 네, `animation={false}` prop을 전달하면 됩니다:
```tsx
<Skeleton animation={false} />
```

또는 사용자 환경설정 고려:
```css
/* prefers-reduced-motion 지원 */
@media (prefers-reduced-motion: reduce) {
  .skeleton-wave {
    animation: none;
  }
}
```

### Q5. 다크모드 지원이 되나요?
A5. 네, 모든 Skeleton 템플릿에 다크모드 스타일이 포함되어 있습니다:
```css
@media (prefers-color-scheme: dark) {
  .skeleton {
    background-color: rgba(255, 255, 255, 0.12);
  }
}
```

---

## 🎓 학습 경로

### 초보자
1. `error-boundary.tsx.md` 템플릿으로 기본 ErrorBoundary 생성
2. App.tsx에 전역 ErrorBoundary 적용
3. 간단한 Skeleton 컴포넌트 적용

### 중급자
1. 페이지별, 컴포넌트별 ErrorBoundary 세분화
2. TanStack Query + Suspense 통합
3. 커스텀 Skeleton Preset 제작

### 고급자
1. 중첩 Suspense로 점진적 로딩 구현
2. startTransition으로 UX 최적화
3. 에러 타입별 폴백 UI 커스터마이징
4. Context Queries와 연계한 세밀한 캐시 무효화

---

## 📋 버전 히스토리

- **v1.0.0** (2025-12-30): 초기 Skills 제작
  - React 18/19 Best Practices 기반
  - 4가지 스타일링 방식 지원 (Emotion, CSS Modules, SCSS Modules, Tailwind)
  - Smooth 애니메이션 Skeleton (2.5s duration)
  - TanStack Query 통합 가이드
