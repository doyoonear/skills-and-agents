# Emotion + Classnames 스타일링 Best Practice 가이드

## 목차

1. [개요](#개요)
2. [설치 및 설정](#설치-및-설정)
3. [@emotion/react - CSS Prop 사용법](#emotionreact---css-prop-사용법)
4. [@emotion/styled - Styled Components 사용법](#emotionstyled---styled-components-사용법)
5. [emotion-normalize 사용법](#emotion-normalize-사용법)
6. [classnames 라이브러리 사용법](#classnames-라이브러리-사용법)
7. [통합 사용 패턴](#통합-사용-패턴)
8. [Best Practices](#best-practices)
9. [성능 최적화](#성능-최적화)
10. [실전 예제](#실전-예제)

---

## 개요

### 각 라이브러리의 역할

- **@emotion/react**: CSS-in-JS를 위한 핵심 라이브러리, `css` prop 제공
- **@emotion/styled**: styled-components와 유사한 API 제공
- **emotion-normalize**: 브라우저 기본 스타일 정규화 (normalize.css의 Emotion 버전)
- **classnames**: 조건부 클래스명 결합을 위한 유틸리티

### 왜 Emotion인가?

- **성능**: styled-components보다 빠름, 작은 번들 사이즈
- **React Concurrent Mode 지원**: 최신 React 기능과 호환
- **유연성**: css prop과 styled 두 가지 접근 방식 제공
- **TypeScript 지원**: 우수한 타입 추론

---

## 설치 및 설정

### 패키지 설치

```bash
# Emotion 핵심 패키지
pnpm add @emotion/react @emotion/styled

# 정규화 CSS
pnpm add emotion-normalize

# 동적 클래스명 유틸리티
pnpm add classnames
```

### TypeScript 설정

`tsconfig.json`:
```json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "@emotion/react"
  }
}
```

또는 파일 최상단에 JSX pragma 추가:
```typescript
/** @jsxImportSource @emotion/react */
```

---

## @emotion/react - CSS Prop 사용법

### 기본 사용법

#### Object Styles (권장)

```typescript
/** @jsxImportSource @emotion/react */
import { css } from '@emotion/react';

// ✅ TypeScript Intellisense와 타입 체킹 지원
const Button = () => (
  <button
    css={{
      backgroundColor: 'hotpink',
      fontSize: 16,
      padding: '10px 20px',
      border: 'none',
      borderRadius: 4,
      '&:hover': {
        backgroundColor: 'darkpink',
      },
    }}
  >
    Click me
  </button>
);
```

#### Template Literal Styles

```typescript
const Button = () => (
  <button
    css={css`
      background-color: hotpink;
      font-size: 16px;
      padding: 10px 20px;
      border: none;
      border-radius: 4px;

      &:hover {
        background-color: darkpink;
      }
    `}
  >
    Click me
  </button>
);
```

### 스타일 재사용

#### 외부 정의 (권장)

```typescript
// ✅ 컴포넌트 외부에 정의하면 리렌더링마다 재생성되지 않음
const buttonStyles = css({
  backgroundColor: 'hotpink',
  fontSize: 16,
  padding: '10px 20px',
  border: 'none',
  borderRadius: 4,
  '&:hover': {
    backgroundColor: 'darkpink',
  },
});

const Button = () => <button css={buttonStyles}>Click me</button>;
```

### 조건부 스타일링

```typescript
const Button = ({ variant, disabled }: ButtonProps) => (
  <button
    css={[
      baseButtonStyles,
      variant === 'primary' && primaryStyles,
      variant === 'secondary' && secondaryStyles,
      disabled && disabledStyles,
    ]}
  >
    Click me
  </button>
);
```

### 스타일 컴포지션

```typescript
const baseStyles = css({
  padding: 10,
  borderRadius: 4,
});

const primaryStyles = css({
  backgroundColor: 'blue',
  color: 'white',
});

// 스타일 조합
const PrimaryButton = () => (
  <button css={[baseStyles, primaryStyles]}>Primary</button>
);
```

### cx 유틸리티로 동적 컴포지션

```typescript
import { css, cx } from '@emotion/react';

const cls1 = css({ background: 'green' });
const cls2 = css({ background: 'blue' });

const Component = ({ useBlue }: { useBlue: boolean }) => (
  <div className={cx({ [cls1]: !useBlue, [cls2]: useBlue })} />
);
```

---

## @emotion/styled - Styled Components 사용법

### 기본 사용법

```typescript
import styled from '@emotion/styled';

const Button = styled.button({
  backgroundColor: 'hotpink',
  fontSize: 16,
  padding: '10px 20px',
  border: 'none',
  borderRadius: 4,
  '&:hover': {
    backgroundColor: 'darkpink',
  },
});

// 사용
<Button>Click me</Button>
```

### Props 기반 스타일링

```typescript
interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'small' | 'medium' | 'large';
}

const Button = styled.button<ButtonProps>(({ variant = 'primary', size = 'medium' }) => ({
  padding: size === 'small' ? '5px 10px' : size === 'large' ? '15px 30px' : '10px 20px',
  fontSize: size === 'small' ? 12 : size === 'large' ? 18 : 14,
  backgroundColor: variant === 'primary' ? 'blue' : 'gray',
  color: 'white',
  border: 'none',
  borderRadius: 4,
  cursor: 'pointer',

  '&:hover': {
    opacity: 0.8,
  },

  '&:disabled': {
    opacity: 0.5,
    cursor: 'not-allowed',
  },
}));
```

### 스타일 상속

```typescript
const BaseButton = styled.button({
  padding: '10px 20px',
  border: 'none',
  borderRadius: 4,
  cursor: 'pointer',
});

const PrimaryButton = styled(BaseButton)({
  backgroundColor: 'blue',
  color: 'white',
});

const SecondaryButton = styled(BaseButton)({
  backgroundColor: 'gray',
  color: 'white',
});
```

### 커스텀 컴포넌트 스타일링

```typescript
interface CustomComponentProps {
  className?: string;
  children: React.ReactNode;
}

const CustomComponent = ({ className, children }: CustomComponentProps) => (
  <div className={className}>{children}</div>
);

const StyledCustomComponent = styled(CustomComponent)({
  backgroundColor: 'lightblue',
  padding: 20,
});
```

### as 프롭으로 엘리먼트 변경

```typescript
const Text = styled.p({
  fontSize: 14,
  color: 'gray',
});

// p 태그 대신 span으로 렌더링
<Text as="span">This is a span</Text>
```

---

## emotion-normalize 사용법

### 기본 설정

```typescript
import { Global, css } from '@emotion/react';
import emotionNormalize from 'emotion-normalize';

const App = () => (
  <>
    <Global
      styles={css`
        ${emotionNormalize}

        /* 추가 글로벌 스타일 */
        html, body {
          padding: 0;
          margin: 0;
          background: white;
          min-height: 100%;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
                       'Helvetica Neue', Arial, sans-serif;
        }

        * {
          box-sizing: border-box;
        }
      `}
    />
    {/* 앱 컴포넌트들 */}
  </>
);
```

### Object Styles 사용

```typescript
import { Global } from '@emotion/react';
import emotionNormalize from 'emotion-normalize';

const App = () => (
  <>
    <Global
      styles={[
        emotionNormalize,
        {
          'html, body': {
            padding: 0,
            margin: 0,
            minHeight: '100%',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto',
          },
          '*': {
            boxSizing: 'border-box',
          },
        },
      ]}
    />
    {/* 앱 컴포넌트들 */}
  </>
);
```

### 루트 컴포넌트에 배치

```typescript
// _app.tsx (Next.js) 또는 main.tsx/App.tsx (Vite/CRA)
import { Global, css } from '@emotion/react';
import emotionNormalize from 'emotion-normalize';

function MyApp({ Component, pageProps }) {
  return (
    <>
      <Global
        styles={css`
          ${emotionNormalize}
          /* 글로벌 스타일 */
        `}
      />
      <Component {...pageProps} />
    </>
  );
}
```

---

## classnames 라이브러리 사용법

### 기본 사용법

```typescript
import classNames from 'classnames';

// 문자열 결합
classNames('foo', 'bar'); // => 'foo bar'

// 객체로 조건부 클래스
classNames('foo', { bar: true, baz: false }); // => 'foo bar'

// 혼합 사용
classNames('foo', { bar: true }, ['baz', { qux: true }]);
// => 'foo bar baz qux'
```

### React에서 조건부 클래스명

```typescript
import classNames from 'classnames';

interface ButtonProps {
  isPressed: boolean;
  isHovered: boolean;
  disabled?: boolean;
}

const Button = ({ isPressed, isHovered, disabled }: ButtonProps) => {
  const btnClass = classNames({
    btn: true,
    'btn-pressed': isPressed,
    'btn-hover': !isPressed && isHovered,
    'btn-disabled': disabled,
  });

  return <button className={btnClass}>Click me</button>;
};
```

### 동적 클래스명 생성 (ES6)

```typescript
const buttonType = 'primary';
const buttonSize = 'large';

const className = classNames({
  [`btn-${buttonType}`]: true,
  [`btn-${buttonSize}`]: true,
});
// => 'btn-primary btn-large'
```

### props.className 처리

```typescript
interface ComponentProps {
  className?: string;
  isActive: boolean;
}

const Component = ({ className, isActive }: ComponentProps) => (
  <div className={classNames('base-class', className, { active: isActive })}>
    Content
  </div>
);
```

### 배열 평탄화

```typescript
const classes = ['btn', 'btn-primary'];
const conditionalClasses = { 'btn-active': isActive };

classNames(classes, conditionalClasses);
// => 'btn btn-primary btn-active'
```

### Falsy 값 무시

```typescript
classNames(null, false, 'bar', undefined, 0, { baz: null }, '');
// => 'bar'

// 안전하게 선택적 클래스 추가
classNames('base', someCondition && 'conditional-class');
```

---

## 통합 사용 패턴

### 1. Emotion + classnames 조합

```typescript
import { css } from '@emotion/react';
import classNames from 'classnames';

const baseStyles = css({
  padding: 10,
  borderRadius: 4,
});

const primaryStyles = css({
  backgroundColor: 'blue',
  color: 'white',
});

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  className?: string;
}

const Button = ({ variant, className }: ButtonProps) => (
  <button
    css={[
      baseStyles,
      variant === 'primary' && primaryStyles,
    ]}
    className={classNames('custom-button', className)}
  >
    Click me
  </button>
);
```

### 2. Styled Components + classnames

```typescript
import styled from '@emotion/styled';
import classNames from 'classnames';

const StyledButton = styled.button({
  padding: 10,
  borderRadius: 4,
  border: 'none',
});

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'small' | 'large';
  className?: string;
}

const Button = ({ variant, size, className, ...props }: ButtonProps) => (
  <StyledButton
    className={classNames(
      className,
      { [`variant-${variant}`]: variant },
      { [`size-${size}`]: size }
    )}
    {...props}
  />
);
```

### 3. CSS Prop + cx 유틸리티

```typescript
import { css, cx } from '@emotion/react';

const baseStyles = css({ padding: 10 });
const activeStyles = css({ backgroundColor: 'blue' });
const disabledStyles = css({ opacity: 0.5 });

interface ComponentProps {
  isActive: boolean;
  disabled?: boolean;
}

const Component = ({ isActive, disabled }: ComponentProps) => (
  <div
    className={cx(
      css(baseStyles),
      { [css(activeStyles)]: isActive },
      { [css(disabledStyles)]: disabled }
    )}
  />
);
```

### 4. 전역 스타일 + 컴포넌트 스타일

```typescript
import { Global, css } from '@emotion/react';
import styled from '@emotion/styled';
import emotionNormalize from 'emotion-normalize';

// 전역 스타일 정의
const globalStyles = css`
  ${emotionNormalize}

  :root {
    --color-primary: #007bff;
    --color-secondary: #6c757d;
    --spacing-unit: 8px;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
    margin: 0;
    padding: 0;
  }
`;

// CSS 변수 활용
const Button = styled.button({
  backgroundColor: 'var(--color-primary)',
  padding: 'calc(var(--spacing-unit) * 2)',
});

const App = () => (
  <>
    <Global styles={globalStyles} />
    <Button>Click me</Button>
  </>
);
```

---

## Best Practices

### 1. TypeScript와 Object Styles 사용

```typescript
// ✅ 권장: TypeScript Intellisense와 타입 체킹
const buttonStyles = css({
  backgroundColor: 'hotpink',
  fontSize: 16, // ✅ 타입 안전
  // fontSize: '16', // ❌ 타입 에러
});

// ❌ 비권장: 문자열은 타입 체킹 없음
const buttonStyles = css`
  background-color: hotpink;
  font-size: 16px;
`;
```

### 2. 스타일을 컴포넌트 외부에 정의

```typescript
// ✅ 권장: 한 번만 생성됨
const buttonStyles = css({
  padding: 10,
  backgroundColor: 'blue',
});

const Button = () => <button css={buttonStyles}>Click</button>;

// ❌ 비권장: 렌더링마다 재생성
const Button = () => {
  const buttonStyles = css({
    padding: 10,
    backgroundColor: 'blue',
  });

  return <button css={buttonStyles}>Click</button>;
};
```

### 3. 스타일과 컴포넌트 코로케이션

```typescript
// ✅ 권장: 같은 파일에 스타일과 컴포넌트
// Button.tsx
const buttonStyles = css({
  padding: 10,
  backgroundColor: 'blue',
});

export const Button = () => <button css={buttonStyles}>Click</button>;

// ❌ 비권장: 별도 파일로 분리 (유지보수 어려움)
// Button.styles.ts
// Button.tsx
```

### 4. 진짜 동적 값에만 inline style 사용

```typescript
// ✅ 권장: CSS 변수로 동적 값 처리
const Component = ({ color }: { color: string }) => (
  <div
    css={{
      backgroundColor: 'var(--dynamic-color)',
    }}
    style={{
      '--dynamic-color': color,
    } as React.CSSProperties}
  />
);

// ❌ 비권장: 매번 새로운 CSS 생성
const Component = ({ color }: { color: string }) => (
  <div css={{ backgroundColor: color }} />
);
```

### 5. css prop vs styled 일관성 있게 선택

```typescript
// ✅ 옵션 1: css prop 주로 사용
const Component = () => (
  <div css={containerStyles}>
    <button css={buttonStyles}>Click</button>
  </div>
);

// ✅ 옵션 2: styled 주로 사용
const Container = styled.div(containerStyles);
const Button = styled.button(buttonStyles);

const Component = () => (
  <Container>
    <Button>Click</Button>
  </Container>
);

// ❌ 비권장: 혼용 (프로젝트 전체에서)
```

### 6. 상수로 스타일 값 추출

```typescript
// ✅ 권장: 재사용 가능한 상수
const COLORS = {
  primary: '#007bff',
  secondary: '#6c757d',
  danger: '#dc3545',
} as const;

const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
} as const;

const buttonStyles = css({
  backgroundColor: COLORS.primary,
  padding: SPACING.md,
});
```

### 7. 테마는 멀티 테마 지원 시에만 사용

```typescript
// ✅ 단일 테마: 상수 사용
const THEME = {
  colors: { primary: 'blue' },
  spacing: { unit: 8 },
};

// ✅ 멀티 테마: ThemeProvider 사용
import { ThemeProvider } from '@emotion/react';

const lightTheme = { background: 'white', text: 'black' };
const darkTheme = { background: 'black', text: 'white' };

<ThemeProvider theme={isDark ? darkTheme : lightTheme}>
  <App />
</ThemeProvider>
```

### 8. classnames는 동적 클래스명 전용

```typescript
// ✅ 권장: 조건부 클래스명
const className = classNames({
  'btn': true,
  'btn-active': isActive,
  'btn-disabled': disabled,
});

// ❌ 비권장: 정적 클래스명
const className = classNames('btn', 'btn-primary');
// => 그냥 'btn btn-primary' 문자열 사용
```

---

## 성능 최적화

### 1. 스타일 메모이제이션

```typescript
import { useMemo } from 'react';
import { css } from '@emotion/react';

const Component = ({ size, variant }: ComponentProps) => {
  // ✅ 의존성이 변경될 때만 재계산
  const styles = useMemo(
    () => css({
      padding: size === 'large' ? 20 : 10,
      backgroundColor: variant === 'primary' ? 'blue' : 'gray',
    }),
    [size, variant]
  );

  return <div css={styles}>Content</div>;
};
```

### 2. classnames 메모이제이션

```typescript
import { useMemo } from 'react';
import classNames from 'classnames';

const Component = ({ isActive, disabled }: ComponentProps) => {
  // ✅ 복잡한 클래스명 계산 메모이제이션
  const className = useMemo(
    () => classNames({
      'component': true,
      'component--active': isActive,
      'component--disabled': disabled,
    }),
    [isActive, disabled]
  );

  return <div className={className}>Content</div>;
};
```

### 3. CSS 변수로 동적 스타일 최적화

```typescript
// ✅ 권장: CSS 변수 사용
const Component = ({ width, height }: { width: number; height: number }) => (
  <div
    css={css({
      width: 'var(--width)',
      height: 'var(--height)',
    })}
    style={{
      '--width': `${width}px`,
      '--height': `${height}px`,
    } as React.CSSProperties}
  />
);

// ❌ 비권장: 매번 새로운 스타일 객체 생성
const Component = ({ width, height }: { width: number; height: number }) => (
  <div css={css({ width, height })} />
);
```

### 4. 스타일 분리로 재사용성 향상

```typescript
// ✅ 공통 스타일 분리
const baseButtonStyles = css({
  padding: '10px 20px',
  border: 'none',
  borderRadius: 4,
  cursor: 'pointer',
});

const primaryStyles = css({ backgroundColor: 'blue', color: 'white' });
const secondaryStyles = css({ backgroundColor: 'gray', color: 'white' });

// 조합해서 사용
const PrimaryButton = () => <button css={[baseButtonStyles, primaryStyles]} />;
const SecondaryButton = () => <button css={[baseButtonStyles, secondaryStyles]} />;
```

---

## 실전 예제

### 예제 1: 복합 버튼 컴포넌트

```typescript
import { css } from '@emotion/react';
import classNames from 'classnames';

// 스타일 상수
const COLORS = {
  primary: '#007bff',
  secondary: '#6c757d',
  danger: '#dc3545',
} as const;

// 기본 스타일
const baseButtonStyles = css({
  padding: '10px 20px',
  fontSize: 14,
  fontWeight: 600,
  border: 'none',
  borderRadius: 4,
  cursor: 'pointer',
  transition: 'all 0.2s ease',

  '&:focus': {
    outline: 'none',
    boxShadow: '0 0 0 3px rgba(0, 123, 255, 0.25)',
  },

  '&:disabled': {
    opacity: 0.5,
    cursor: 'not-allowed',
  },
});

// 변형별 스타일
const variantStyles = {
  primary: css({
    backgroundColor: COLORS.primary,
    color: 'white',
    '&:hover:not(:disabled)': {
      backgroundColor: '#0056b3',
    },
  }),
  secondary: css({
    backgroundColor: COLORS.secondary,
    color: 'white',
    '&:hover:not(:disabled)': {
      backgroundColor: '#545b62',
    },
  }),
  danger: css({
    backgroundColor: COLORS.danger,
    color: 'white',
    '&:hover:not(:disabled)': {
      backgroundColor: '#c82333',
    },
  }),
};

// 사이즈별 스타일
const sizeStyles = {
  small: css({ padding: '5px 10px', fontSize: 12 }),
  medium: css({ padding: '10px 20px', fontSize: 14 }),
  large: css({ padding: '15px 30px', fontSize: 16 }),
};

interface ButtonProps {
  variant?: keyof typeof variantStyles;
  size?: keyof typeof sizeStyles;
  disabled?: boolean;
  className?: string;
  children: React.ReactNode;
  onClick?: () => void;
}

export const Button = ({
  variant = 'primary',
  size = 'medium',
  disabled = false,
  className,
  children,
  onClick,
}: ButtonProps) => {
  return (
    <button
      css={[
        baseButtonStyles,
        variantStyles[variant],
        sizeStyles[size],
      ]}
      className={classNames('btn', className)}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

### 예제 2: 카드 컴포넌트

```typescript
import { css } from '@emotion/react';
import classNames from 'classnames';

const cardStyles = css({
  backgroundColor: 'white',
  borderRadius: 8,
  boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
  overflow: 'hidden',
  transition: 'box-shadow 0.3s ease',

  '&:hover': {
    boxShadow: '0 4px 8px rgba(0, 0, 0, 0.15)',
  },
});

const cardHeaderStyles = css({
  padding: 16,
  borderBottom: '1px solid #e0e0e0',
});

const cardBodyStyles = css({
  padding: 16,
});

const cardFooterStyles = css({
  padding: 16,
  borderTop: '1px solid #e0e0e0',
  backgroundColor: '#f5f5f5',
});

interface CardProps {
  className?: string;
  children: React.ReactNode;
  hoverable?: boolean;
}

export const Card = ({ className, children, hoverable = true }: CardProps) => (
  <div
    css={cardStyles}
    className={classNames('card', className, { 'card--hoverable': hoverable })}
  >
    {children}
  </div>
);

Card.Header = ({ className, children }: Omit<CardProps, 'hoverable'>) => (
  <div css={cardHeaderStyles} className={classNames('card-header', className)}>
    {children}
  </div>
);

Card.Body = ({ className, children }: Omit<CardProps, 'hoverable'>) => (
  <div css={cardBodyStyles} className={classNames('card-body', className)}>
    {children}
  </div>
);

Card.Footer = ({ className, children }: Omit<CardProps, 'hoverable'>) => (
  <div css={cardFooterStyles} className={classNames('card-footer', className)}>
    {children}
  </div>
);

// 사용 예시
const Example = () => (
  <Card>
    <Card.Header>Card Title</Card.Header>
    <Card.Body>Card content goes here</Card.Body>
    <Card.Footer>Card footer</Card.Footer>
  </Card>
);
```

### 예제 3: 반응형 그리드 시스템

```typescript
import { css } from '@emotion/react';
import classNames from 'classnames';

const BREAKPOINTS = {
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
} as const;

const containerStyles = css({
  width: '100%',
  marginLeft: 'auto',
  marginRight: 'auto',
  paddingLeft: 16,
  paddingRight: 16,

  [`@media (min-width: ${BREAKPOINTS.sm}px)`]: {
    maxWidth: BREAKPOINTS.sm,
  },
  [`@media (min-width: ${BREAKPOINTS.md}px)`]: {
    maxWidth: BREAKPOINTS.md,
  },
  [`@media (min-width: ${BREAKPOINTS.lg}px)`]: {
    maxWidth: BREAKPOINTS.lg,
  },
  [`@media (min-width: ${BREAKPOINTS.xl}px)`]: {
    maxWidth: BREAKPOINTS.xl,
  },
});

const rowStyles = css({
  display: 'flex',
  flexWrap: 'wrap',
  marginLeft: -8,
  marginRight: -8,
});

const getColStyles = (span: number) => css({
  flex: `0 0 ${(span / 12) * 100}%`,
  maxWidth: `${(span / 12) * 100}%`,
  paddingLeft: 8,
  paddingRight: 8,
});

interface ContainerProps {
  className?: string;
  children: React.ReactNode;
}

export const Container = ({ className, children }: ContainerProps) => (
  <div css={containerStyles} className={classNames('container', className)}>
    {children}
  </div>
);

export const Row = ({ className, children }: ContainerProps) => (
  <div css={rowStyles} className={classNames('row', className)}>
    {children}
  </div>
);

interface ColProps extends ContainerProps {
  span?: number;
  sm?: number;
  md?: number;
  lg?: number;
}

export const Col = ({ span = 12, sm, md, lg, className, children }: ColProps) => {
  const colStyles = css([
    getColStyles(span),
    sm && {
      [`@media (min-width: ${BREAKPOINTS.sm}px)`]: getColStyles(sm),
    },
    md && {
      [`@media (min-width: ${BREAKPOINTS.md}px)`]: getColStyles(md),
    },
    lg && {
      [`@media (min-width: ${BREAKPOINTS.lg}px)`]: getColStyles(lg),
    },
  ]);

  return (
    <div css={colStyles} className={classNames('col', className)}>
      {children}
    </div>
  );
};

// 사용 예시
const Example = () => (
  <Container>
    <Row>
      <Col span={12} md={6} lg={4}>Column 1</Col>
      <Col span={12} md={6} lg={4}>Column 2</Col>
      <Col span={12} md={12} lg={4}>Column 3</Col>
    </Row>
  </Container>
);
```

### 예제 4: 폼 컴포넌트

```typescript
import { css } from '@emotion/react';
import classNames from 'classnames';
import { useState } from 'react';

const formGroupStyles = css({
  marginBottom: 16,
});

const labelStyles = css({
  display: 'block',
  marginBottom: 8,
  fontSize: 14,
  fontWeight: 600,
  color: '#333',
});

const inputStyles = css({
  width: '100%',
  padding: '10px 12px',
  fontSize: 14,
  border: '1px solid #d0d0d0',
  borderRadius: 4,
  transition: 'border-color 0.2s ease',

  '&:focus': {
    outline: 'none',
    borderColor: '#007bff',
    boxShadow: '0 0 0 3px rgba(0, 123, 255, 0.1)',
  },

  '&:disabled': {
    backgroundColor: '#f5f5f5',
    cursor: 'not-allowed',
  },
});

const errorStyles = css({
  borderColor: '#dc3545',

  '&:focus': {
    borderColor: '#dc3545',
    boxShadow: '0 0 0 3px rgba(220, 53, 69, 0.1)',
  },
});

const helperTextStyles = css({
  marginTop: 4,
  fontSize: 12,
  color: '#666',
});

const errorTextStyles = css({
  marginTop: 4,
  fontSize: 12,
  color: '#dc3545',
});

interface InputProps {
  label?: string;
  error?: string;
  helperText?: string;
  className?: string;
  type?: string;
  placeholder?: string;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  disabled?: boolean;
}

export const Input = ({
  label,
  error,
  helperText,
  className,
  type = 'text',
  placeholder,
  value,
  onChange,
  disabled,
}: InputProps) => {
  return (
    <div css={formGroupStyles} className={classNames('form-group', className)}>
      {label && <label css={labelStyles}>{label}</label>}
      <input
        css={[inputStyles, error && errorStyles]}
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        disabled={disabled}
      />
      {error && <p css={errorTextStyles}>{error}</p>}
      {!error && helperText && <p css={helperTextStyles}>{helperText}</p>}
    </div>
  );
};

// 사용 예시
const LoginForm = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState({ email: '', password: '' });

  return (
    <form>
      <Input
        label="이메일"
        type="email"
        placeholder="email@example.com"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={errors.email}
        helperText="계정에 사용한 이메일을 입력하세요"
      />
      <Input
        label="비밀번호"
        type="password"
        placeholder="비밀번호"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={errors.password}
      />
    </form>
  );
};
```

---

## 요약

### 핵심 원칙

1. **TypeScript + Object Styles** 사용으로 타입 안전성 확보
2. **스타일은 컴포넌트 외부에 정의**하여 성능 최적화
3. **css prop 또는 styled 중 하나를 일관되게 사용**
4. **진짜 동적인 값만 inline style 사용**, CSS 변수 활용
5. **classnames는 조건부 클래스명 전용**으로 사용
6. **emotion-normalize로 브라우저 정규화** 적용
7. **상수로 색상, 간격 등 추출**하여 재사용성 향상

### 성능 최적화

- 스타일 메모이제이션 (`useMemo`)
- CSS 변수로 동적 값 처리
- 스타일 분리 및 재사용
- classnames 계산 메모이제이션

이 가이드를 따르면 확장 가능하고 유지보수하기 쉬운 스타일링 시스템을 구축할 수 있습니다.
