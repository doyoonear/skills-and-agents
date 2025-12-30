# ErrorBoundary 컴포넌트 템플릿

> React 18/19에서 사용 가능한 ErrorBoundary 클래스 컴포넌트 템플릿입니다.
> 스타일링과 무관하게 사용할 수 있습니다.

---

## 📁 파일 위치

```
src/
├── components/
│   ├── ErrorBoundary.tsx          # 기본 ErrorBoundary
│   ├── GlobalErrorBoundary.tsx    # 전역 ErrorBoundary (App.tsx용)
│   └── types/
│       └── error-boundary.ts      # TypeScript 타입 정의
```

---

## 1. TypeScript 타입 정의

```typescript
// src/components/types/error-boundary.ts

import { ReactNode } from 'react';

/**
 * ErrorBoundary Props 인터페이스
 */
export interface ErrorBoundaryProps {
  /** 에러 발생 시 표시할 폴백 UI */
  fallback?: ReactNode;
  /** 에러 발생 시 렌더링할 컴포넌트 (fallback보다 우선) */
  FallbackComponent?: React.ComponentType<FallbackProps>;
  /** 에러 발생 시 실행될 콜백 */
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
  /** 재시도 버튼 클릭 시 실행될 콜백 */
  onReset?: () => void;
  /** children */
  children: ReactNode;
}

/**
 * ErrorBoundary State 인터페이스
 */
export interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

/**
 * FallbackComponent에 전달되는 Props
 */
export interface FallbackProps {
  error: Error;
  resetError: () => void;
}
```

---

## 2. 기본 ErrorBoundary 컴포넌트

```tsx
// src/components/ErrorBoundary.tsx

import React, { Component, ReactNode } from 'react';
import type {
  ErrorBoundaryProps,
  ErrorBoundaryState,
  FallbackProps
} from './types/error-boundary';

/**
 * ErrorBoundary 컴포넌트
 *
 * React 18/19에서 에러를 포착하고 폴백 UI를 표시합니다.
 *
 * @example
 * // 기본 사용법
 * <ErrorBoundary fallback={<div>에러가 발생했습니다</div>}>
 *   <MyComponent />
 * </ErrorBoundary>
 *
 * @example
 * // FallbackComponent 사용
 * <ErrorBoundary FallbackComponent={ErrorFallback}>
 *   <MyComponent />
 * </ErrorBoundary>
 */
class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  /**
   * 에러 발생 시 상태 업데이트
   * 렌더링 중 호출되므로 부수 효과 금지
   */
  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return {
      hasError: true,
      error,
    };
  }

  /**
   * 에러 로깅 및 분석 서비스 연동
   * 렌더링 후 호출되므로 부수 효과 허용
   */
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    // 에러 로깅 (콘솔)
    console.error('ErrorBoundary caught an error:', error, errorInfo);

    // 외부 로깅 서비스 연동 (예: Sentry, LogRocket)
    // logErrorToService(error, errorInfo.componentStack);

    // onError 콜백 실행
    this.props.onError?.(error, errorInfo);
  }

  /**
   * 에러 상태 초기화 (재시도)
   */
  resetError = (): void => {
    this.setState({
      hasError: false,
      error: null,
    });

    // onReset 콜백 실행 (예: 데이터 재요청)
    this.props.onReset?.();
  };

  render(): ReactNode {
    const { hasError, error } = this.state;
    const { children, fallback, FallbackComponent } = this.props;

    if (hasError && error) {
      // FallbackComponent가 있으면 우선 사용
      if (FallbackComponent) {
        return <FallbackComponent error={error} resetError={this.resetError} />;
      }

      // fallback이 있으면 사용
      if (fallback) {
        return fallback;
      }

      // 기본 폴백 UI
      return (
        <div style={{ padding: '20px', textAlign: 'center' }}>
          <h2>문제가 발생했습니다</h2>
          <p>{error.message}</p>
          <button onClick={this.resetError}>다시 시도</button>
        </div>
      );
    }

    return children;
  }
}

export default ErrorBoundary;
```

---

## 3. 전역 ErrorBoundary (App.tsx용)

```tsx
// src/components/GlobalErrorBoundary.tsx

import React, { Component, ReactNode } from 'react';
import type { ErrorBoundaryState } from './types/error-boundary';

interface Props {
  children: ReactNode;
}

/**
 * 전역 ErrorBoundary (최후의 안전망)
 *
 * App.tsx 최상위에 배치하여 전체 앱의 크래시를 방지합니다.
 *
 * @example
 * // App.tsx
 * import GlobalErrorBoundary from '@/components/GlobalErrorBoundary';
 *
 * function App() {
 *   return (
 *     <GlobalErrorBoundary>
 *       <Router />
 *     </GlobalErrorBoundary>
 *   );
 * }
 */
class GlobalErrorBoundary extends Component<Props, ErrorBoundaryState> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    // 전역 에러는 반드시 로깅
    console.error('[Global ErrorBoundary]', error, errorInfo);

    // Sentry 등 에러 트래킹 서비스 연동
    // Sentry.captureException(error, { contexts: { react: { componentStack: errorInfo.componentStack } } });
  }

  handleReload = (): void => {
    window.location.reload();
  };

  render(): ReactNode {
    const { hasError, error } = this.state;
    const { children } = this.props;

    if (hasError && error) {
      return (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh',
          padding: '20px',
          textAlign: 'center',
        }}>
          <h1>앱에 문제가 발생했습니다</h1>
          <p style={{ color: '#666', marginTop: '10px' }}>
            문제가 지속되면 고객센터로 문의해주세요.
          </p>
          <details style={{ marginTop: '20px', maxWidth: '600px' }}>
            <summary style={{ cursor: 'pointer', marginBottom: '10px' }}>
              에러 상세 보기
            </summary>
            <pre style={{
              textAlign: 'left',
              background: '#f5f5f5',
              padding: '15px',
              borderRadius: '8px',
              overflow: 'auto',
            }}>
              {error.message}
              {'\n\n'}
              {error.stack}
            </pre>
          </details>
          <button
            onClick={this.handleReload}
            style={{
              marginTop: '30px',
              padding: '12px 24px',
              fontSize: '16px',
              cursor: 'pointer',
              backgroundColor: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
            }}
          >
            페이지 새로고침
          </button>
        </div>
      );
    }

    return children;
  }
}

export default GlobalErrorBoundary;
```

---

## 4. 컴포넌트별 ErrorBoundary (API 단위)

```tsx
// src/components/APIErrorBoundary.tsx

import React from 'react';
import ErrorBoundary from './ErrorBoundary';
import type { FallbackProps } from './types/error-boundary';

/**
 * API 에러 폴백 컴포넌트
 */
const APIErrorFallback: React.FC<FallbackProps> = ({ error, resetError }) => {
  return (
    <div style={{
      padding: '20px',
      border: '1px solid #ffcccc',
      borderRadius: '8px',
      backgroundColor: '#fff5f5',
      textAlign: 'center',
    }}>
      <h3>데이터를 불러오는 중 문제가 발생했습니다</h3>
      <p style={{ color: '#666', fontSize: '14px', marginTop: '10px' }}>
        {error.message}
      </p>
      <button
        onClick={resetError}
        style={{
          marginTop: '15px',
          padding: '8px 16px',
          cursor: 'pointer',
          backgroundColor: '#ff4444',
          color: 'white',
          border: 'none',
          borderRadius: '6px',
        }}
      >
        다시 시도
      </button>
    </div>
  );
};

/**
 * API 호출 영역을 감싸는 ErrorBoundary
 *
 * @example
 * <APIErrorBoundary>
 *   <Suspense fallback={<Skeleton />}>
 *     <UserProfile />
 *   </Suspense>
 * </APIErrorBoundary>
 */
export const APIErrorBoundary: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <ErrorBoundary FallbackComponent={APIErrorFallback}>
      {children}
    </ErrorBoundary>
  );
};

export default APIErrorBoundary;
```

---

## 5. 사용 예시

### 5-1. App.tsx (전역 ErrorBoundary)

```tsx
// src/App.tsx

import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import GlobalErrorBoundary from '@/components/GlobalErrorBoundary';
import AppRoutes from '@/routes';

function App() {
  return (
    <GlobalErrorBoundary>
      <Router>
        <AppRoutes />
      </Router>
    </GlobalErrorBoundary>
  );
}

export default App;
```

### 5-2. 페이지별 ErrorBoundary

```tsx
// src/pages/UserPage.tsx

import React from 'react';
import ErrorBoundary from '@/components/ErrorBoundary';
import ErrorFallback from '@/components/ErrorFallback'; // 별도 파일 참고

function UserPage() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <div>
        <h1>사용자 페이지</h1>
        {/* 페이지 컨텐츠 */}
      </div>
    </ErrorBoundary>
  );
}

export default UserPage;
```

### 5-3. 컴포넌트별 ErrorBoundary (API 단위)

```tsx
// src/components/UserProfile.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import APIErrorBoundary from '@/components/APIErrorBoundary';
import ProfileSkeleton from '@/components/skeletons/ProfileSkeleton';

function UserProfileContent() {
  // TanStack Query with suspense
  const { data: user } = useQuery({
    queryKey: ['user'],
    queryFn: fetchUser,
    suspense: true, // Suspense 활성화
  });

  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}

export function UserProfile() {
  return (
    <APIErrorBoundary>
      <Suspense fallback={<ProfileSkeleton />}>
        <UserProfileContent />
      </Suspense>
    </APIErrorBoundary>
  );
}
```

### 5-4. 여러 API 영역 격리

```tsx
// src/pages/DashboardPage.tsx

import React, { Suspense } from 'react';
import APIErrorBoundary from '@/components/APIErrorBoundary';
import { UserProfile } from '@/components/UserProfile';
import { UserPosts } from '@/components/UserPosts';
import { UserComments } from '@/components/UserComments';
import ProfileSkeleton from '@/components/skeletons/ProfileSkeleton';
import PostsSkeleton from '@/components/skeletons/PostsSkeleton';
import CommentsSkeleton from '@/components/skeletons/CommentsSkeleton';

function DashboardPage() {
  return (
    <div>
      <h1>대시보드</h1>

      {/* 프로필 영역 - 독립적인 에러 처리 */}
      <APIErrorBoundary>
        <Suspense fallback={<ProfileSkeleton />}>
          <UserProfile />
        </Suspense>
      </APIErrorBoundary>

      {/* 게시물 영역 - 독립적인 에러 처리 */}
      <APIErrorBoundary>
        <Suspense fallback={<PostsSkeleton />}>
          <UserPosts />
        </Suspense>
      </APIErrorBoundary>

      {/* 댓글 영역 - 독립적인 에러 처리 */}
      <APIErrorBoundary>
        <Suspense fallback={<CommentsSkeleton />}>
          <UserComments />
        </Suspense>
      </APIErrorBoundary>
    </div>
  );
}

export default DashboardPage;
```

---

## 6. 재시도 로직 통합

### 6-1. ErrorBoundary with onReset

```tsx
// TanStack Query의 refetch와 연동
import { useQueryClient } from '@tanstack/react-query';

function MyComponent() {
  const queryClient = useQueryClient();

  const handleReset = () => {
    // 에러가 발생한 쿼리 무효화
    queryClient.invalidateQueries({ queryKey: ['user'] });
  };

  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onReset={handleReset}
    >
      <Suspense fallback={<Skeleton />}>
        <UserProfile />
      </Suspense>
    </ErrorBoundary>
  );
}
```

### 6-2. ErrorBoundary with Key Reset

```tsx
// Key를 변경하여 ErrorBoundary 리셋
function MyComponent() {
  const [resetKey, setResetKey] = React.useState(0);

  const handleReset = () => {
    setResetKey((prev) => prev + 1);
  };

  return (
    <ErrorBoundary
      key={resetKey}
      FallbackComponent={ErrorFallback}
      onReset={handleReset}
    >
      <Suspense fallback={<Skeleton />}>
        <UserProfile />
      </Suspense>
    </ErrorBoundary>
  );
}
```

---

## 7. 에러 타입별 처리

```tsx
// src/components/SmartErrorBoundary.tsx

import React, { Component, ReactNode } from 'react';
import type { ErrorBoundaryState } from './types/error-boundary';

interface Props {
  children: ReactNode;
}

// 커스텀 에러 타입
export class NetworkError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NetworkError';
  }
}

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

class SmartErrorBoundary extends Component<Props, ErrorBoundaryState> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    console.error('SmartErrorBoundary:', error, errorInfo);
  }

  resetError = (): void => {
    this.setState({ hasError: false, error: null });
  };

  render(): ReactNode {
    const { hasError, error } = this.state;
    const { children } = this.props;

    if (hasError && error) {
      // 에러 타입별 처리
      if (error instanceof NetworkError) {
        return (
          <div>
            <h3>네트워크 오류</h3>
            <p>인터넷 연결을 확인해주세요.</p>
            <button onClick={this.resetError}>다시 시도</button>
          </div>
        );
      }

      if (error instanceof AuthError) {
        return (
          <div>
            <h3>인증 오류</h3>
            <p>로그인이 필요합니다.</p>
            <button onClick={() => window.location.href = '/login'}>
              로그인하기
            </button>
          </div>
        );
      }

      // 기본 에러 처리
      return (
        <div>
          <h3>오류 발생</h3>
          <p>{error.message}</p>
          <button onClick={this.resetError}>다시 시도</button>
        </div>
      );
    }

    return children;
  }
}

export default SmartErrorBoundary;
```

---

## 8. 개발 vs 프로덕션 환경 분리

```tsx
// src/components/EnvAwareErrorBoundary.tsx

import React, { Component, ReactNode } from 'react';
import type { ErrorBoundaryState } from './types/error-boundary';

const isDevelopment = process.env.NODE_ENV === 'development';

class EnvAwareErrorBoundary extends Component<{ children: ReactNode }, ErrorBoundaryState> {
  constructor(props: { children: ReactNode }) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    if (isDevelopment) {
      console.error('ErrorBoundary:', error, errorInfo);
    } else {
      // 프로덕션: 에러 트래킹 서비스로 전송
      // sendToErrorTracking(error, errorInfo);
    }
  }

  render(): ReactNode {
    const { hasError, error } = this.state;
    const { children } = this.props;

    if (hasError && error) {
      if (isDevelopment) {
        // 개발 환경: 상세한 에러 정보 표시
        return (
          <div style={{ padding: '20px', backgroundColor: '#ffe6e6' }}>
            <h2>개발 모드 에러</h2>
            <pre style={{
              backgroundColor: '#f5f5f5',
              padding: '10px',
              overflow: 'auto'
            }}>
              {error.message}
              {'\n\n'}
              {error.stack}
            </pre>
          </div>
        );
      } else {
        // 프로덕션: 사용자 친화적 메시지
        return (
          <div style={{ padding: '20px', textAlign: 'center' }}>
            <h2>문제가 발생했습니다</h2>
            <p>잠시 후 다시 시도해주세요.</p>
            <button onClick={() => window.location.reload()}>
              새로고침
            </button>
          </div>
        );
      }
    }

    return children;
  }
}

export default EnvAwareErrorBoundary;
```

---

## 9. Best Practices 요약

### ✅ DO (권장)

1. **전역 ErrorBoundary 필수**: App.tsx 최상위에 배치
2. **세부 영역별 적용**: 페이지 / 컴포넌트 / API 단위로 격리
3. **onReset 활용**: 데이터 재요청 로직 연결
4. **에러 로깅**: 개발/프로덕션 환경별 로깅 전략
5. **Suspense와 조합**: ErrorBoundary > Suspense > Component

### ❌ DON'T (비권장)

1. **모든 컴포넌트 감싸기**: 의미 없는 세분화
2. **함수 컴포넌트로 구현**: React 18/19 미지원
3. **비동기 에러 무시**: try-catch로 별도 처리 필요
4. **사용자에게 기술 용어 노출**: 프로덕션에서 친화적 메시지 제공

---

## 10. TypeScript Tips

```typescript
// 타입 안전한 ErrorBoundary 래퍼
import { ComponentType } from 'react';
import ErrorBoundary from './ErrorBoundary';
import type { FallbackProps } from './types/error-boundary';

export function withErrorBoundary<P extends object>(
  Component: ComponentType<P>,
  FallbackComponent: ComponentType<FallbackProps>
) {
  return (props: P) => (
    <ErrorBoundary FallbackComponent={FallbackComponent}>
      <Component {...props} />
    </ErrorBoundary>
  );
}

// 사용 예시
const SafeUserProfile = withErrorBoundary(UserProfile, ErrorFallback);
```

---

## 참고 자료

- [React 공식 문서 - Error Boundaries](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)
- [React Error Boundaries Best Practices (2025)](https://react.dev/learn/error-boundaries)
