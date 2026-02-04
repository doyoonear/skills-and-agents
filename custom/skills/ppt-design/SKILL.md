---
name: ppt-design
description: |
  웹 기반 프레젠테이션 페이지 및 슬라이드 컴포넌트 디자인 가이드.
  다음 요청 시 사용: "프레젠테이션 만들어줘", "슬라이드 페이지 생성", "PPT 컴포넌트 작성", "슬라이드 디자인 리뷰", "프레젠테이션 레이아웃 확인"
  트리거 키워드: "프레젠테이션", "슬라이드", "PPT", "발표 자료", "슬라이드쇼", "presentation", "slide"
---

# Web-based Presentation Design Guide

웹 기반 프레젠테이션 페이지 및 슬라이드 컴포넌트 디자인 가이드입니다.

## Layout Guidelines

### Slide Container

전체 화면 슬라이드 구조:

```tsx
<div className="min-h-screen w-full flex items-center justify-center snap-start snap-always">
  <div className="w-full max-w-7xl px-8 py-16">
    {/* 슬라이드 콘텐츠 */}
  </div>
</div>
```

**핵심 원칙:**
- **전체 화면**: `min-h-screen w-full` - 각 슬라이드는 뷰포트 전체를 차지
- **중앙 정렬**: `flex items-center justify-center` - 콘텐츠를 화면 중앙에 배치
- **스냅 스크롤**: `snap-start snap-always` - 스크롤 시 슬라이드에 정확히 맞춤
- **콘텐츠 영역**: `max-w-7xl px-8 py-16` - 최대 너비 제한 및 적절한 여백

### Page Container

프레젠테이션 페이지 전체 구조:

```tsx
<div className="overflow-y-auto h-screen snap-y snap-mandatory">
  {/* ProgressBar */}
  {/* Slide 컴포넌트들 */}
</div>
```

**핵심 설정:**
- `overflow-y-auto`: 세로 스크롤 활성화
- `h-screen`: 뷰포트 전체 높이
- `snap-y snap-mandatory`: 세로 스냅 스크롤 강제 적용

### Spacing System

일관된 간격 시스템 사용:

- `space-y-6`: 작은 간격 (섹션 내 요소)
- `space-y-8`: 중간 간격 (관련 그룹)
- `space-y-12`: 큰 간격 (독립적인 섹션)

## Typography System

### 텍스트 계층 구조

| 용도 | 클래스 | 예시 |
|------|--------|------|
| 메인 제목 (커버) | `text-9xl font-bold text-primary` | 첫 슬라이드 제목 |
| 섹션 제목 | `text-6xl font-bold text-primary` | 각 섹션 제목 |
| 본문 | `text-2xl` | 일반 텍스트, 인용구 |
| 서브 텍스트 | `text-xl text-muted-foreground` | 출처, 부연 설명 |

**타이포그래피 원칙:**
- 제목은 `text-primary`로 강조
- 본문과 제목의 명확한 크기 대비 (3배 이상)
- 서브 텍스트는 `text-muted-foreground`로 시각적 계층 구분

## Navigation System

스크롤과 키보드 입력을 모두 지원하는 네비게이션 구현.

### Implementation Architecture

```tsx
const [currentSlide, setCurrentSlide] = useState(0);
const slideRefs = [useRef<HTMLDivElement>(null), /* ... */];

useKeyboardNavigation({ slideRefs, currentSlide, setCurrentSlide, totalSlides });
useSlideObserver({ slideRefs, setCurrentSlide });
```

### Scroll Detection (Intersection Observer)

**목적**: 스크롤로 슬라이드 변경 시 currentSlide 상태 업데이트

**구현 원칙**:
- `threshold: 0.5` - 슬라이드가 50% 이상 보일 때 활성화
- `root: null` - 뷰포트 기준
- 양방향 스크롤 지원 (앞→뒤, 뒤→앞)

**참고**: [references/slide-observer.ts](references/slide-observer.ts)

### Keyboard Navigation

**지원 키**:
- `ArrowDown` / `ArrowRight`: 다음 슬라이드
- `ArrowUp` / `ArrowLeft`: 이전 슬라이드

**구현 원칙**:
- `e.preventDefault()` - 기본 스크롤 동작 방지
- `scrollIntoView({ behavior: 'auto', block: 'start' })` - 즉시 이동
- 경계 체크 (`currentSlide > 0`, `currentSlide < totalSlides - 1`)

**참고**: [references/keyboard-nav.ts](references/keyboard-nav.ts)

### Progress Bar

**위치**: 화면 상단 고정 (`fixed top-0 z-50`)

**동작**:
- `currentSlide` 상태 변경 시 자동 업데이트
- 스크롤/키보드 네비게이션 모두 반영
- `transition-all duration-300` - 부드러운 애니메이션

**참고**: [references/progressbar.tsx](references/progressbar.tsx)

## Component Architecture

### Slide Wrapper

**역할**: 공통 레이아웃과 ref 전달

**핵심 기능**:
- `forwardRef`로 ref 전달 (Intersection Observer용)
- 전체 화면 및 중앙 정렬 레이아웃 제공
- `snap-start snap-always` 적용

**참고**: [references/slide-wrapper.tsx](references/slide-wrapper.tsx)

### Individual Slides

**원칙**:
- 콘텐츠만 포함하는 순수 컴포넌트
- 레이아웃은 Slide 래퍼가 담당
- 재사용 가능한 구조

**예시**:

```tsx
export function Slide1() {
  return (
    <div className="text-center space-y-8">
      <p className="text-2xl text-muted-foreground">부제목</p>
      <h1 className="text-9xl font-bold text-primary">메인 제목</h1>
    </div>
  );
}
```

### Page Structure

**기본 구조**:

```tsx
export default function PresentationPage() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const slideRefs = [useRef<HTMLDivElement>(null), /* ... */];

  useKeyboardNavigation({ slideRefs, currentSlide, setCurrentSlide, totalSlides });
  useSlideObserver({ slideRefs, setCurrentSlide });

  return (
    <div className="overflow-y-auto h-screen snap-y snap-mandatory">
      <ProgressBar current={currentSlide + 1} total={totalSlides} />
      <Slide ref={slideRefs[0]}><Slide1 /></Slide>
      <Slide ref={slideRefs[1]}><Slide2 /></Slide>
      {/* ... */}
    </div>
  );
}
```

**상태 관리**:
- `currentSlide`: 현재 슬라이드 인덱스 (0-based)
- `slideRefs`: 각 슬라이드 DOM ref 배열
- 두 hooks가 같은 `setCurrentSlide`를 공유하여 상태 동기화

## Best Practices

### Layout
- 각 슬라이드는 독립적인 전체 화면 단위
- 콘텐츠는 `max-w-7xl` 내에서 중앙 정렬
- 일관된 `px-8 py-16` 여백 사용

### Typography
- 제목과 본문의 명확한 크기 대비 유지
- `text-primary`로 중요 텍스트 강조
- `text-muted-foreground`로 서브 정보 구분

### Navigation
- **필수**: Intersection Observer와 키보드 네비게이션 모두 구현
- ProgressBar로 진행 상태 시각화
- 양방향 네비게이션 (앞→뒤, 뒤→앞) 지원

### Component Structure
- Slide 래퍼로 공통 레이아웃 관리
- 개별 슬라이드는 콘텐츠만 포함
- ref 배열과 2개 hooks로 상태 관리

## Reference Files

- **[slide-wrapper.tsx](references/slide-wrapper.tsx)**: Slide 컴포넌트 구현
- **[slide-observer.ts](references/slide-observer.ts)**: useSlideObserver hook
- **[keyboard-nav.ts](references/keyboard-nav.ts)**: useKeyboardNavigation hook
- **[progressbar.tsx](references/progressbar.tsx)**: ProgressBar 컴포넌트
