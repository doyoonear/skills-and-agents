# Emotion Best Practices Guide

## 목차
- [개요](#개요)
- [서버 컴포넌트 호환성](#서버-컴포넌트-호환성)
- [스타일 작성 방식 선택](#스타일-작성-방식-선택)
- [공통 스타일 관리 패턴](#공통-스타일-관리-패턴)
- [상황별 패턴 선택 가이드](#상황별-패턴-선택-가이드)
- [일반 원칙 및 권장사항](#일반-원칙-및-권장사항)

---

## 개요

### Emotion이란?
Emotion은 JavaScript로 CSS를 작성하기 위한 고성능 CSS-in-JS 라이브러리입니다.

### 주요 패키지
- **@emotion/react**: CSS prop 방식, React 컴포넌트에 직접 스타일 적용
- **@emotion/styled**: styled-components와 유사한 API, 재사용 가능한 스타일 컴포넌트 생성
- **@emotion/css**: 프레임워크 독립적인 스타일 생성

### 핵심 개념
- **Object Styles**: CSS 속성을 camelCase 객체로 작성 (`backgroundColor`)
- **Template Literal**: 백틱을 사용한 전통적인 CSS 문법
- **Composition**: 여러 스타일을 조합하여 재사용
- **Theme**: 전역 디자인 토큰 관리

### 이 문서의 목적
AI Agent가 Emotion을 사용하여 효율적이고 유지보수 가능한 스타일 코드를 작성할 수 있도록 실용적인 패턴과 가이드라인을 제공합니다.

---

## 서버 컴포넌트 호환성

### ❌ 기본적으로 서버 컴포넌트에서 사용 불가

Emotion은 런타임에 스타일을 주입하는 CSS-in-JS 라이브러리로, React Server Components에서 직접 사용할 수 없습니다.

#### 제약사항
- React 18의 concurrent rendering을 완전히 지원하지 않음
- 서버 컴포넌트는 클라이언트 측 런타임 코드 실행 불가
- Next.js 15 App Router에서 기본적으로 지원되지 않음

### ✅ 해결 방법 1: Client Components 사용 (권장)

```tsx
'use client'  // 파일 최상단에 추가

import { css } from '@emotion/react'

export const MyComponent = () => (
  <div css={{ color: 'blue', padding: 16 }}>
    Content
  </div>
)
```

**주의사항**:
- 파일의 첫 번째 줄에 `'use client'` 디렉티브 추가
- 해당 컴포넌트와 모든 자식 컴포넌트는 클라이언트에서 렌더링됨
- 번들 사이즈 증가 가능성 고려

### ✅ 해결 방법 2: 서버 컴포넌트에는 다른 스타일링 방법 사용

**CSS Modules** (서버 컴포넌트와 완벽 호환):
```tsx
// ServerComponent.tsx (서버 컴포넌트)
import styles from './styles.module.css'

export const ServerComponent = () => (
  <div className={styles.container}>Content</div>
)
```

**Tailwind CSS** (정적 CSS 생성):
```tsx
// ServerComponent.tsx (서버 컴포넌트)
export const ServerComponent = () => (
  <div className="bg-blue-500 p-4">Content</div>
)
```

### 권장 아키텍처

```
app/
├── (server components)
│   ├── layout.tsx          # CSS Modules 또는 Tailwind
│   └── page.tsx            # CSS Modules 또는 Tailwind
└── components/
    └── client/
        └── Button.tsx      # 'use client' + Emotion
```

**원칙**:
- 서버 컴포넌트: CSS Modules, Tailwind 등 정적 CSS
- 클라이언트 컴포넌트: Emotion 사용 가능
- 클라이언트 컴포넌트를 최소화하여 성능 최적화

---

## 스타일 작성 방식 선택

### @emotion/styled vs @emotion/react (css prop)

#### @emotion/styled (Styled Components 방식)

```tsx
import styled from '@emotion/styled'

const Button = styled.button<{ primary?: boolean }>`
  padding: 8px 16px;
  background: ${props => props.primary ? 'blue' : 'gray'};
  color: white;
`

// 사용
<Button primary>Click</Button>
```

**장점**:
- 재사용 가능한 컴포넌트 생성
- props 기반 동적 스타일링이 직관적
- TypeScript 타입 추론 우수

**단점**:
- 일회성 스타일에도 컴포넌트 생성 필요
- 코드가 더 장황할 수 있음

**사용 시기**:
- 재사용 가능한 UI 컴포넌트 라이브러리 구축
- 버튼, 카드, 모달 등 반복 사용되는 컴포넌트

#### @emotion/react (css prop 방식)

```tsx
/** @jsxImportSource @emotion/react */
import { css } from '@emotion/react'

const buttonStyles = css({
  padding: '8px 16px',
  background: 'blue',
  color: 'white'
})

// 사용
<button css={buttonStyles}>Click</button>
```

**장점**:
- 일회성 스타일에 적합
- 추가 컴포넌트 생성 불필요
- Emotion 메인테이너들이 선호하는 방식

**단점**:
- 재사용성이 낮음
- 마크업과 스타일이 섞일 수 있음

**사용 시기**:
- 페이지 레이아웃이나 일회성 스타일
- 빠른 프로토타이핑

### Object Styles vs Template Literal

#### Object Styles (권장)

```tsx
const styles = css({
  backgroundColor: 'blue',
  '&:hover': {
    backgroundColor: 'darkblue'
  },
  '@media (min-width: 768px)': {
    fontSize: 16
  }
})
```

**장점**:
- TypeScript 자동완성 지원
- 타입 안정성 (오타 방지)
- 더 나은 성능 (직렬화 최적화)

**단점**:
- CSS와 문법이 다름 (camelCase)

#### Template Literal

```tsx
const styles = css`
  background-color: blue;
  &:hover {
    background-color: darkblue;
  }
  @media (min-width: 768px) {
    font-size: 16px;
  }
`
```

**장점**:
- 기존 CSS 문법 그대로 사용
- 복사-붙여넣기 용이

**단점**:
- 타입 체크 불가
- 자동완성 제한적

### 권장사항
- **TypeScript 프로젝트**: Object Styles 사용
- **일관성 유지**: 프로젝트 전체에서 하나의 방식 선택
- **팀 선호도**: 팀원 대부분이 익숙한 방식 선택

---

## 공통 스타일 관리 패턴

### 패턴 1: 스타일 객체 정의 및 내보내기

**용도**: 전역적으로 자주 사용되는 간단한 스타일

```typescript
// styles/common.ts
import { css } from '@emotion/react'

export const errorStyles = css({
  color: '#dc3545',
  fontWeight: 'bold',
  fontSize: 14
})

export const successStyles = css({
  color: '#28a745',
  fontWeight: 'bold',
  fontSize: 14
})

export const cardStyles = css({
  padding: 20,
  borderRadius: 8,
  boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
  backgroundColor: 'white'
})
```

```typescript
// components/ErrorMessage.tsx
import { errorStyles } from '@/styles/common'

export const ErrorMessage = ({ message }: { message: string }) => (
  <div css={errorStyles}>{message}</div>
)
```

**장점**:
- 간단하고 직관적
- 한 곳에서 스타일 관리
- import/export로 재사용 용이

**단점**:
- 스타일과 컴포넌트가 분리됨
- 사용되지 않는 스타일도 번들에 포함 가능

**사용 시기**:
- 작은 프로젝트
- 전역적으로 자주 사용되는 유틸리티 스타일
- 에러, 성공, 경고 메시지 등 공통 스타일

### 패턴 2: 배열 조합 (Array Composition)

**용도**: 여러 스타일을 조합하여 우선순위 제어

```typescript
// styles/button.ts
import { css } from '@emotion/react'

export const baseButton = css({
  padding: '8px 16px',
  borderRadius: 4,
  border: 'none',
  cursor: 'pointer',
  fontSize: 14,
  fontWeight: 500,
  transition: 'all 0.2s'
})

export const primaryVariant = css({
  backgroundColor: '#007bff',
  color: 'white',
  '&:hover': {
    backgroundColor: '#0056b3'
  }
})

export const dangerVariant = css({
  backgroundColor: '#dc3545',
  color: 'white',
  '&:hover': {
    backgroundColor: '#c82333'
  }
})

export const disabledState = css({
  opacity: 0.5,
  cursor: 'not-allowed',
  pointerEvents: 'none'
})
```

```typescript
// components/Button.tsx
import { baseButton, primaryVariant, dangerVariant, disabledState } from '@/styles/button'

type ButtonProps = {
  variant?: 'primary' | 'danger'
  disabled?: boolean
  children: React.ReactNode
}

export const Button = ({ variant = 'primary', disabled, children }: ButtonProps) => {
  const variantStyle = variant === 'danger' ? dangerVariant : primaryVariant

  return (
    <button css={[baseButton, variantStyle, disabled && disabledState]}>
      {children}
    </button>
  )
}
```

**핵심**: 배열에서 **나중에 오는 스타일이 우선순위가 높음** (CSS 클래스 정의 순서 무관)

**장점**:
- 스타일 조합이 예측 가능
- `!important` 불필요
- 조건부 스타일 적용이 간편
- 베이스 스타일 재사용 용이

**단점**:
- 복잡한 조합에서는 코드가 길어질 수 있음

**사용 시기**:
- 베이스 스타일 + 변형(variant) 패턴
- 조건부 스타일이 많은 경우
- 중형 이상 프로젝트

### 패턴 3: 스타일 팩토리 함수

**용도**: 동적으로 스타일을 생성하여 재사용, 디자인 시스템 구축

```typescript
// styles/design-system.ts
import { css, SerializedStyles } from '@emotion/react'

// Spacing 시스템 (8px 그리드)
export const spacing = (multiplier: number): SerializedStyles => css({
  padding: `${multiplier * 8}px`
})

export const marginTop = (multiplier: number): SerializedStyles => css({
  marginTop: `${multiplier * 8}px`
})

// Flexbox 유틸리티
export const flexCenter = (direction: 'row' | 'column' = 'row'): SerializedStyles => css({
  display: 'flex',
  justifyContent: 'center',
  alignItems: 'center',
  flexDirection: direction
})

export const flexBetween = (): SerializedStyles => css({
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center'
})

// Elevation 시스템
export const elevation = (level: 1 | 2 | 3 | 4): SerializedStyles => {
  const shadows = {
    1: '0 2px 4px rgba(0,0,0,0.1)',
    2: '0 4px 8px rgba(0,0,0,0.15)',
    3: '0 8px 16px rgba(0,0,0,0.2)',
    4: '0 16px 32px rgba(0,0,0,0.25)'
  }

  return css({ boxShadow: shadows[level] })
}

// Typography 시스템
export const textStyle = (
  size: number,
  weight: 'normal' | 'medium' | 'bold' = 'normal'
): SerializedStyles => {
  const weights = { normal: 400, medium: 500, bold: 700 }

  return css({
    fontSize: `${size}px`,
    fontWeight: weights[weight],
    lineHeight: 1.5
  })
}

// Border Radius
export const rounded = (size: 'sm' | 'md' | 'lg' | 'full'): SerializedStyles => {
  const sizes = { sm: 4, md: 8, lg: 16, full: 9999 }
  return css({ borderRadius: sizes[size] })
}
```

```typescript
// components/Card.tsx
import { spacing, elevation, rounded, flexCenter } from '@/styles/design-system'

export const Card = ({ children }: { children: React.ReactNode }) => (
  <div css={[spacing(3), elevation(2), rounded('md'), flexCenter('column')]}>
    {children}
  </div>
)
```

**장점**:
- 매우 유연하고 재사용성 높음
- 일관된 디자인 시스템 구축 가능
- TypeScript 타입으로 잘못된 값 방지
- 코드 중복 최소화

**단점**:
- 초기 설정이 다소 복잡
- 과도한 추상화 위험

**사용 시기**:
- 디자인 시스템이 필요한 중대형 프로젝트
- 일관된 spacing, color, typography 관리
- 여러 프로젝트에서 공통 스타일 시스템 사용

### 패턴 4: 테마 기반 스타일

**용도**: 전역 테마 변경, 다크 모드, 브랜드 커스터마이징

```typescript
// styles/theme.ts
export const lightTheme = {
  colors: {
    primary: '#007bff',
    danger: '#dc3545',
    success: '#28a745',
    warning: '#ffc107',
    text: {
      primary: '#212529',
      secondary: '#6c757d',
      disabled: '#adb5bd'
    },
    background: {
      primary: '#ffffff',
      secondary: '#f8f9fa',
      tertiary: '#e9ecef'
    },
    border: '#dee2e6'
  },
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48
  },
  typography: {
    fontSize: {
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 24,
      xxl: 32
    },
    fontWeight: {
      normal: 400,
      medium: 500,
      bold: 700
    }
  },
  breakpoints: {
    mobile: '480px',
    tablet: '768px',
    desktop: '1024px',
    wide: '1280px'
  },
  borderRadius: {
    sm: 4,
    md: 8,
    lg: 16
  }
} as const

export const darkTheme = {
  ...lightTheme,
  colors: {
    ...lightTheme.colors,
    text: {
      primary: '#f8f9fa',
      secondary: '#adb5bd',
      disabled: '#6c757d'
    },
    background: {
      primary: '#212529',
      secondary: '#343a40',
      tertiary: '#495057'
    },
    border: '#495057'
  }
} as const

export type Theme = typeof lightTheme
```

```typescript
// App.tsx
import { ThemeProvider } from '@emotion/react'
import { lightTheme, darkTheme } from './styles/theme'

export const App = () => {
  const [isDark, setIsDark] = useState(false)

  return (
    <ThemeProvider theme={isDark ? darkTheme : lightTheme}>
      <YourApp />
    </ThemeProvider>
  )
}
```

```typescript
// components/Button.tsx
/** @jsxImportSource @emotion/react */
import { Theme } from '@/styles/theme'

type ButtonProps = {
  variant?: 'primary' | 'danger' | 'success'
  size?: 'sm' | 'md' | 'lg'
  children: React.ReactNode
}

export const Button = ({ variant = 'primary', size = 'md', children }: ButtonProps) => (
  <button
    css={(theme: Theme) => ({
      backgroundColor: theme.colors[variant],
      padding: `${theme.spacing.sm}px ${theme.spacing.md}px`,
      fontSize: theme.typography.fontSize[size],
      borderRadius: theme.borderRadius.md,
      border: 'none',
      color: 'white',
      cursor: 'pointer',
      transition: 'all 0.2s',

      '&:hover': {
        opacity: 0.9
      },

      [`@media (min-width: ${theme.breakpoints.tablet})`]: {
        padding: `${theme.spacing.md}px ${theme.spacing.lg}px`
      }
    })}
  >
    {children}
  </button>
)
```

**장점**:
- 전역 테마 변경 용이 (다크 모드, 브랜드 커스터마이징)
- 디자인 토큰 중앙 관리
- 반응형 디자인에 유리
- 일관성 강제

**단점**:
- 초기 설정 복잡도 높음
- 단순한 프로젝트에는 과도할 수 있음
- 모든 컴포넌트가 테마에 의존

**사용 시기**:
- 다크 모드 지원이 필요한 경우
- 멀티 브랜드 서비스 (white-label)
- 대형 프로젝트의 디자인 시스템
- 접근성 테마 (대비, 폰트 크기 조정)

### 패턴 5: 컴포넌트 외부 정의 (성능 최적화)

**용도**: 렌더링 성능 최적화, 불필요한 재계산 방지

```typescript
// components/Card.tsx
import { css } from '@emotion/react'

// ❌ 나쁜 예: 컴포넌트 내부에서 정의
export const CardBad = () => {
  const cardStyles = css({  // 매 렌더링마다 재생성!
    padding: 20,
    borderRadius: 8,
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
  })

  return <div css={cardStyles}>Content</div>
}

// ✅ 좋은 예: 컴포넌트 외부에서 정의
const cardStyles = css({  // 한 번만 생성
  padding: 20,
  borderRadius: 8,
  boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
})

export const CardGood = () => {
  return <div css={cardStyles}>Content</div>
}
```

**동적 스타일이 필요한 경우**:

```typescript
// ✅ 방법 1: 팩토리 함수 사용
const getCardStyles = (elevated: boolean) => css({
  padding: 20,
  borderRadius: 8,
  boxShadow: elevated ? '0 8px 16px rgba(0,0,0,0.15)' : '0 2px 8px rgba(0,0,0,0.1)'
})

export const Card = ({ elevated }: { elevated: boolean }) => {
  return <div css={getCardStyles(elevated)}>Content</div>
}

// ✅ 방법 2: 배열 조합 사용
const baseCardStyles = css({
  padding: 20,
  borderRadius: 8
})

const elevatedStyles = css({
  boxShadow: '0 8px 16px rgba(0,0,0,0.15)'
})

const flatStyles = css({
  boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
})

export const Card = ({ elevated }: { elevated: boolean }) => {
  return (
    <div css={[baseCardStyles, elevated ? elevatedStyles : flatStyles]}>
      Content
    </div>
  )
}

// ✅ 방법 3: useMemo 사용 (복잡한 계산이 필요한 경우만)
import { useMemo } from 'react'

export const Card = ({ color, size }: { color: string; size: number }) => {
  const dynamicStyles = useMemo(
    () => css({
      backgroundColor: color,
      padding: size * 8,
      borderRadius: size * 2
    }),
    [color, size]  // 의존성이 변경될 때만 재계산
  )

  return <div css={dynamicStyles}>Content</div>
}
```

**장점**:
- 렌더링 성능 향상
- 메모리 사용 최적화
- 스타일 재직렬화 방지

**단점**:
- 동적 스타일에는 추가 패턴 필요

**사용 시기**:
- 항상 기본으로 적용 (베스트 프랙티스)
- 특히 자주 리렌더링되는 컴포넌트

---

## 상황별 패턴 선택 가이드

### 프로젝트 규모별 권장 패턴

#### 소형 프로젝트 (1-3명, 간단한 웹사이트)

**권장 조합**:
- 패턴 1 (스타일 객체 내보내기)
- 패턴 5 (컴포넌트 외부 정의)

**이유**:
- 빠른 개발 속도
- 낮은 학습 곡선
- 최소한의 구조

**예시 구조**:
```
src/
├── styles/
│   └── common.ts          # 공통 스타일 모음
└── components/
    ├── Button.tsx
    └── Card.tsx
```

#### 중형 프로젝트 (4-10명, SaaS 제품)

**권장 조합**:
- 패턴 2 (배열 조합)
- 패턴 3 (팩토리 함수)
- 패턴 5 (컴포넌트 외부 정의)

**이유**:
- 재사용성과 유연성의 균형
- 일관된 디자인 유지 가능
- 확장성 확보

**예시 구조**:
```
src/
├── styles/
│   ├── design-system.ts   # 팩토리 함수 모음
│   ├── button.ts          # 버튼 스타일 변형
│   └── card.ts            # 카드 스타일 변형
└── components/
    ├── Button/
    │   ├── Button.tsx
    │   └── Button.styles.ts
    └── Card/
        ├── Card.tsx
        └── Card.styles.ts
```

#### 대형 프로젝트 (10명+, 엔터프라이즈)

**권장 조합**:
- 패턴 3 (팩토리 함수)
- 패턴 4 (테마 기반)
- 패턴 5 (컴포넌트 외부 정의)

**이유**:
- 완전한 디자인 시스템
- 브랜드 일관성 강제
- 다크 모드 등 테마 전환 지원

**예시 구조**:
```
src/
├── styles/
│   ├── theme/
│   │   ├── light.ts
│   │   ├── dark.ts
│   │   └── index.ts
│   ├── design-system/
│   │   ├── spacing.ts
│   │   ├── typography.ts
│   │   ├── colors.ts
│   │   └── elevation.ts
│   └── utils/
│       └── media-queries.ts
└── components/
    └── ...
```

### 사용 사례별 패턴

#### UI 라이브러리 구축
- **패턴 2** (변형 조합) + **패턴 4** (테마)
- 버튼, 인풋, 카드 등 재사용 가능한 컴포넌트

#### 랜딩 페이지 / 마케팅 사이트
- **패턴 1** (간단한 스타일 내보내기)
- 빠른 개발, 일회성 스타일 많음

#### 대시보드 / 어드민 패널
- **패턴 3** (팩토리 함수) + **패턴 4** (테마)
- 일관된 레이아웃, 반복적인 패턴

#### 다크 모드 지원 필요
- **패턴 4** (테마) 필수
- ThemeProvider로 전역 테마 전환

### 의사결정 플로우

```
1. 다크 모드가 필요한가?
   └─ 예 → 패턴 4 (테마) 사용

2. 디자인 시스템이 있는가?
   └─ 예 → 패턴 3 (팩토리 함수) 사용

3. 재사용 가능한 컴포넌트를 많이 만드는가?
   └─ 예 → 패턴 2 (배열 조합) 사용

4. 간단한 프로젝트인가?
   └─ 예 → 패턴 1 (스타일 내보내기) 사용

5. 항상 적용
   └─ 패턴 5 (컴포넌트 외부 정의)
```

---

## 일반 원칙 및 권장사항

### 성능 최적화

1. **스타일을 컴포넌트 외부에 정의** (패턴 5 참고)
   - 매 렌더링마다 재생성 방지

2. **정적 스타일과 동적 스타일 분리**
   - 정적: `css` prop 사용
   - 동적 (자주 변경): `style` prop 사용

   ```tsx
   // ❌ 나쁜 예
   <div css={{ backgroundColor: currentColor }}>  // 매 렌더마다 재계산

   // ✅ 좋은 예
   <div css={staticStyles} style={{ backgroundColor: currentColor }}>
   ```

3. **useMemo는 신중하게**
   - 복잡한 스타일 계산이 있을 때만 사용
   - 단순한 경우 오히려 오버헤드

### 코드 구조화

1. **파일 구조**
   ```
   Component.tsx        # 컴포넌트 로직
   Component.styles.ts  # 스타일 정의 (선택적)
   ```

2. **명명 규칙**
   ```typescript
   const buttonBase = css(...)      // 베이스 스타일
   const buttonPrimary = css(...)   // 변형
   const buttonDisabled = css(...)  // 상태
   ```

3. **import 순서**
   ```typescript
   // 1. React
   import { useState } from 'react'

   // 2. Emotion
   import { css } from '@emotion/react'

   // 3. 스타일
   import { buttonBase, buttonPrimary } from './Button.styles'
   ```

### 타입 안정성

1. **Theme 타입 정의**
   ```typescript
   import '@emotion/react'
   import { Theme as CustomTheme } from './styles/theme'

   declare module '@emotion/react' {
     export interface Theme extends CustomTheme {}
   }
   ```

2. **SerializedStyles 사용**
   ```typescript
   import { SerializedStyles } from '@emotion/react'

   const getStyles = (...): SerializedStyles => css(...)
   ```

### 안티 패턴 (피해야 할 것)

1. **인라인 스타일 남용**
   ```tsx
   // ❌ 나쁜 예
   <div css={{ padding: 20, margin: 10, ... }}>

   // ✅ 좋은 예
   <div css={cardStyles}>
   ```

2. **!important 사용**
   - Emotion의 배열 조합으로 우선순위 제어 가능

3. **전역 스타일 남용**
   - 컴포넌트 기반 스타일링 우선

4. **테마 없이 하드코딩된 색상**
   ```typescript
   // ❌ 나쁜 예
   css({ color: '#007bff' })

   // ✅ 좋은 예
   css(theme => ({ color: theme.colors.primary }))
   ```

5. **과도한 중첩**
   ```typescript
   // ❌ 나쁜 예
   css({
     '& > div > span > a': { ... }  // 너무 구체적
   })

   // ✅ 좋은 예
   css({
     '& a': { ... }  // 간결하게
   })
   ```

---

## 참고 자료

- [Emotion 공식 문서](https://emotion.sh/docs/introduction)
- [Emotion Best Practices](https://emotion.sh/docs/best-practices)
- [Emotion Composition](https://emotion.sh/docs/composition)

---

**문서 버전**: 1.0.0
**최종 수정일**: 2025-12-30
**작성 대상**: AI Agent 참고용
