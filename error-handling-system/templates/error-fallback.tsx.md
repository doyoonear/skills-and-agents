# ErrorFallback 컴포넌트 템플릿

> ErrorBoundary에서 사용할 다양한 폴백 UI 컴포넌트 템플릿입니다.
> 스타일링은 프로젝트 환경에 맞게 조정하세요.

---

## 📁 파일 위치

```
src/
├── components/
│   ├── error-fallbacks/
│   │   ├── index.ts                    # export 모음
│   │   ├── ErrorFallback.tsx           # 기본 에러 폴백
│   │   ├── FullPageError.tsx           # 전체 페이지 에러
│   │   ├── InlineError.tsx             # 인라인 에러 (부분 영역)
│   │   ├── NetworkError.tsx            # 네트워크 에러
│   │   └── NotFoundError.tsx           # 404 에러
```

---

## 1. 기본 에러 폴백 (공통 구조)

```tsx
// src/components/error-fallbacks/ErrorFallback.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';

/**
 * 기본 에러 폴백 컴포넌트
 *
 * ErrorBoundary의 FallbackComponent로 사용됩니다.
 *
 * @example
 * <ErrorBoundary FallbackComponent={ErrorFallback}>
 *   <MyComponent />
 * </ErrorBoundary>
 */
export const ErrorFallback: React.FC<FallbackProps> = ({ error, resetError }) => {
  return (
    <div
      style={{
        padding: '24px',
        borderRadius: '12px',
        border: '1px solid #fee',
        backgroundColor: '#fffaf0',
        textAlign: 'center',
      }}
      // 프로젝트 스타일링 방식에 맞게 변경:
      // - Emotion: css={styles.container}
      // - CSS Modules: className={styles.container}
      // - Tailwind: className="p-6 rounded-xl border border-red-200 bg-red-50 text-center"
    >
      <div
        style={{
          fontSize: '48px',
          marginBottom: '16px',
        }}
      >
        ⚠️
      </div>

      <h2
        style={{
          fontSize: '20px',
          fontWeight: '600',
          marginBottom: '12px',
          color: '#333',
        }}
      >
        문제가 발생했습니다
      </h2>

      <p
        style={{
          fontSize: '14px',
          color: '#666',
          marginBottom: '20px',
        }}
      >
        {error.message || '알 수 없는 오류가 발생했습니다'}
      </p>

      <button
        onClick={resetError}
        style={{
          padding: '10px 20px',
          fontSize: '14px',
          fontWeight: '500',
          color: '#fff',
          backgroundColor: '#ff4444',
          border: 'none',
          borderRadius: '8px',
          cursor: 'pointer',
          transition: 'background-color 0.2s',
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.backgroundColor = '#cc0000';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.backgroundColor = '#ff4444';
        }}
      >
        다시 시도
      </button>
    </div>
  );
};

export default ErrorFallback;
```

---

## 2. 전체 페이지 에러 폴백

```tsx
// src/components/error-fallbacks/FullPageError.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';

/**
 * 전체 페이지 에러 폴백
 *
 * 전역 ErrorBoundary나 페이지별 ErrorBoundary에서 사용됩니다.
 *
 * @example
 * <ErrorBoundary FallbackComponent={FullPageError}>
 *   <App />
 * </ErrorBoundary>
 */
export const FullPageError: React.FC<FallbackProps> = ({ error, resetError }) => {
  const handleReload = () => {
    window.location.reload();
  };

  const isDevelopment = process.env.NODE_ENV === 'development';

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        padding: '20px',
        backgroundColor: '#f9fafb',
      }}
    >
      <div
        style={{
          maxWidth: '600px',
          textAlign: 'center',
        }}
      >
        {/* 에러 아이콘 */}
        <div
          style={{
            fontSize: '80px',
            marginBottom: '24px',
          }}
        >
          😵
        </div>

        {/* 제목 */}
        <h1
          style={{
            fontSize: '32px',
            fontWeight: '700',
            marginBottom: '16px',
            color: '#1f2937',
          }}
        >
          앱에 문제가 발생했습니다
        </h1>

        {/* 설명 */}
        <p
          style={{
            fontSize: '16px',
            color: '#6b7280',
            marginBottom: '32px',
            lineHeight: '1.6',
          }}
        >
          일시적인 오류일 수 있습니다. 페이지를 새로고침하거나 잠시 후 다시 시도해주세요.
          {isDevelopment && (
            <>
              <br />
              <br />
              <strong>개발 모드:</strong> 에러 상세 내용을 아래에서 확인하세요.
            </>
          )}
        </p>

        {/* 버튼 그룹 */}
        <div
          style={{
            display: 'flex',
            gap: '12px',
            justifyContent: 'center',
            marginBottom: '32px',
          }}
        >
          <button
            onClick={handleReload}
            style={{
              padding: '12px 24px',
              fontSize: '16px',
              fontWeight: '600',
              color: '#fff',
              backgroundColor: '#3b82f6',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
            }}
          >
            페이지 새로고침
          </button>

          <button
            onClick={resetError}
            style={{
              padding: '12px 24px',
              fontSize: '16px',
              fontWeight: '600',
              color: '#6b7280',
              backgroundColor: '#fff',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              cursor: 'pointer',
            }}
          >
            다시 시도
          </button>
        </div>

        {/* 개발 모드: 에러 상세 정보 */}
        {isDevelopment && (
          <details
            style={{
              textAlign: 'left',
              backgroundColor: '#fff',
              border: '1px solid #e5e7eb',
              borderRadius: '8px',
              padding: '16px',
            }}
          >
            <summary
              style={{
                cursor: 'pointer',
                fontWeight: '600',
                marginBottom: '12px',
                color: '#1f2937',
              }}
            >
              에러 상세 보기
            </summary>
            <pre
              style={{
                fontSize: '12px',
                color: '#ef4444',
                backgroundColor: '#fef2f2',
                padding: '12px',
                borderRadius: '6px',
                overflow: 'auto',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
              }}
            >
              <strong>Message:</strong> {error.message}
              {'\n\n'}
              <strong>Stack:</strong>
              {'\n'}
              {error.stack}
            </pre>
          </details>
        )}
      </div>
    </div>
  );
};

export default FullPageError;
```

---

## 3. 인라인 에러 폴백 (부분 영역)

```tsx
// src/components/error-fallbacks/InlineError.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';

/**
 * 인라인 에러 폴백 (부분 영역용)
 *
 * 컴포넌트별 ErrorBoundary에서 사용됩니다.
 * 에러 발생 영역만 폴백 UI로 대체하고, 나머지는 정상 표시됩니다.
 *
 * @example
 * <ErrorBoundary FallbackComponent={InlineError}>
 *   <Suspense fallback={<Skeleton />}>
 *     <UserComments />
 *   </Suspense>
 * </ErrorBoundary>
 */
export const InlineError: React.FC<FallbackProps> = ({ error, resetError }) => {
  return (
    <div
      style={{
        padding: '20px',
        margin: '16px 0',
        borderRadius: '8px',
        border: '1px solid #fee2e2',
        backgroundColor: '#fef2f2',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-start',
          gap: '12px',
        }}
      >
        {/* 아이콘 */}
        <div
          style={{
            fontSize: '24px',
            flexShrink: 0,
          }}
        >
          ⚠️
        </div>

        {/* 내용 */}
        <div style={{ flex: 1 }}>
          <h3
            style={{
              fontSize: '16px',
              fontWeight: '600',
              marginBottom: '8px',
              color: '#991b1b',
            }}
          >
            데이터를 불러올 수 없습니다
          </h3>

          <p
            style={{
              fontSize: '14px',
              color: '#7f1d1d',
              marginBottom: '12px',
            }}
          >
            {error.message || '일시적인 오류가 발생했습니다'}
          </p>

          <button
            onClick={resetError}
            style={{
              padding: '8px 16px',
              fontSize: '14px',
              fontWeight: '500',
              color: '#fff',
              backgroundColor: '#dc2626',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
            }}
          >
            다시 시도
          </button>
        </div>
      </div>
    </div>
  );
};

export default InlineError;
```

---

## 4. 네트워크 에러 폴백

```tsx
// src/components/error-fallbacks/NetworkError.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';

/**
 * 네트워크 에러 폴백
 *
 * 네트워크 오류 발생 시 사용되는 전용 폴백 UI입니다.
 */
export const NetworkError: React.FC<FallbackProps> = ({ error, resetError }) => {
  return (
    <div
      style={{
        padding: '32px',
        textAlign: 'center',
        backgroundColor: '#f0f9ff',
        borderRadius: '12px',
        border: '1px solid #bfdbfe',
      }}
    >
      {/* 아이콘 */}
      <div
        style={{
          fontSize: '64px',
          marginBottom: '16px',
        }}
      >
        🌐
      </div>

      {/* 제목 */}
      <h2
        style={{
          fontSize: '20px',
          fontWeight: '600',
          marginBottom: '12px',
          color: '#1e40af',
        }}
      >
        네트워크 연결 오류
      </h2>

      {/* 설명 */}
      <p
        style={{
          fontSize: '14px',
          color: '#1e3a8a',
          marginBottom: '8px',
        }}
      >
        인터넷 연결을 확인하고 다시 시도해주세요.
      </p>

      <p
        style={{
          fontSize: '12px',
          color: '#60a5fa',
          marginBottom: '24px',
        }}
      >
        {error.message}
      </p>

      {/* 버튼 */}
      <button
        onClick={resetError}
        style={{
          padding: '10px 20px',
          fontSize: '14px',
          fontWeight: '500',
          color: '#fff',
          backgroundColor: '#3b82f6',
          border: 'none',
          borderRadius: '8px',
          cursor: 'pointer',
        }}
      >
        다시 시도
      </button>

      {/* 추가 도움말 */}
      <div
        style={{
          marginTop: '24px',
          fontSize: '12px',
          color: '#64748b',
        }}
      >
        <p>다음 사항을 확인해보세요:</p>
        <ul
          style={{
            listStyle: 'none',
            padding: 0,
            marginTop: '8px',
          }}
        >
          <li>• Wi-Fi 또는 모바일 데이터 연결 상태</li>
          <li>• VPN 또는 프록시 설정</li>
          <li>• 방화벽 설정</li>
        </ul>
      </div>
    </div>
  );
};

export default NetworkError;
```

---

## 5. 404 Not Found 에러

```tsx
// src/components/error-fallbacks/NotFoundError.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';

/**
 * 404 Not Found 에러 폴백
 */
export const NotFoundError: React.FC<FallbackProps & { onGoHome?: () => void }> = ({
  error,
  resetError,
  onGoHome,
}) => {
  const handleGoHome = () => {
    if (onGoHome) {
      onGoHome();
    } else {
      window.location.href = '/';
    }
  };

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '400px',
        padding: '20px',
        textAlign: 'center',
      }}
    >
      {/* 404 텍스트 */}
      <div
        style={{
          fontSize: '120px',
          fontWeight: '700',
          color: '#e5e7eb',
          lineHeight: '1',
          marginBottom: '24px',
        }}
      >
        404
      </div>

      {/* 제목 */}
      <h1
        style={{
          fontSize: '24px',
          fontWeight: '600',
          marginBottom: '12px',
          color: '#1f2937',
        }}
      >
        페이지를 찾을 수 없습니다
      </h1>

      {/* 설명 */}
      <p
        style={{
          fontSize: '16px',
          color: '#6b7280',
          marginBottom: '32px',
          maxWidth: '400px',
        }}
      >
        요청하신 페이지가 존재하지 않거나 이동되었을 수 있습니다.
      </p>

      {/* 버튼 그룹 */}
      <div
        style={{
          display: 'flex',
          gap: '12px',
        }}
      >
        <button
          onClick={handleGoHome}
          style={{
            padding: '12px 24px',
            fontSize: '16px',
            fontWeight: '600',
            color: '#fff',
            backgroundColor: '#3b82f6',
            border: 'none',
            borderRadius: '8px',
            cursor: 'pointer',
          }}
        >
          홈으로 이동
        </button>

        <button
          onClick={resetError}
          style={{
            padding: '12px 24px',
            fontSize: '16px',
            fontWeight: '600',
            color: '#6b7280',
            backgroundColor: '#fff',
            border: '1px solid #d1d5db',
            borderRadius: '8px',
            cursor: 'pointer',
          }}
        >
          이전 페이지
        </button>
      </div>
    </div>
  );
};

export default NotFoundError;
```

---

## 6. 컴팩트 에러 폴백 (작은 영역용)

```tsx
// src/components/error-fallbacks/CompactError.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';

/**
 * 컴팩트 에러 폴백 (작은 영역용)
 *
 * 카드나 사이드바 같은 작은 영역에서 사용됩니다.
 */
export const CompactError: React.FC<FallbackProps> = ({ resetError }) => {
  return (
    <div
      style={{
        padding: '16px',
        backgroundColor: '#fef2f2',
        borderRadius: '8px',
        textAlign: 'center',
      }}
    >
      <div style={{ fontSize: '24px', marginBottom: '8px' }}>⚠️</div>
      <p
        style={{
          fontSize: '12px',
          color: '#991b1b',
          marginBottom: '12px',
        }}
      >
        로딩 실패
      </p>
      <button
        onClick={resetError}
        style={{
          padding: '6px 12px',
          fontSize: '12px',
          color: '#fff',
          backgroundColor: '#dc2626',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer',
        }}
      >
        재시도
      </button>
    </div>
  );
};

export default CompactError;
```

---

## 7. 에러 타입별 라우팅

```tsx
// src/components/error-fallbacks/SmartErrorFallback.tsx

import React from 'react';
import type { FallbackProps } from '@/components/types/error-boundary';
import { NetworkError } from './NetworkError';
import { NotFoundError } from './NotFoundError';
import { ErrorFallback } from './ErrorFallback';

// 커스텀 에러 클래스
export class NetworkErrorClass extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NetworkError';
  }
}

export class NotFoundErrorClass extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NotFoundError';
  }
}

/**
 * 에러 타입에 따라 적절한 폴백을 자동 선택
 */
export const SmartErrorFallback: React.FC<FallbackProps> = (props) => {
  const { error } = props;

  // 네트워크 에러
  if (error instanceof NetworkErrorClass || error.name === 'NetworkError') {
    return <NetworkError {...props} />;
  }

  // 404 에러
  if (error instanceof NotFoundErrorClass || error.name === 'NotFoundError') {
    return <NotFoundError {...props} />;
  }

  // 기본 에러
  return <ErrorFallback {...props} />;
};

export default SmartErrorFallback;
```

---

## 8. index.ts (Export 모음)

```typescript
// src/components/error-fallbacks/index.ts

export { ErrorFallback } from './ErrorFallback';
export { FullPageError } from './FullPageError';
export { InlineError } from './InlineError';
export { NetworkError } from './NetworkError';
export { NotFoundError } from './NotFoundError';
export { CompactError } from './CompactError';
export { SmartErrorFallback } from './SmartErrorFallback';
```

---

## 9. 사용 예시

### 9-1. 전역 ErrorBoundary

```tsx
// src/App.tsx
import GlobalErrorBoundary from '@/components/GlobalErrorBoundary';
import { FullPageError } from '@/components/error-fallbacks';

function App() {
  return (
    <GlobalErrorBoundary FallbackComponent={FullPageError}>
      <Router />
    </GlobalErrorBoundary>
  );
}
```

### 9-2. 페이지별 ErrorBoundary

```tsx
// src/pages/UserPage.tsx
import ErrorBoundary from '@/components/ErrorBoundary';
import { ErrorFallback } from '@/components/error-fallbacks';

function UserPage() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <div>{/* 페이지 내용 */}</div>
    </ErrorBoundary>
  );
}
```

### 9-3. 컴포넌트별 ErrorBoundary (인라인)

```tsx
// src/components/UserComments.tsx
import { Suspense } from 'react';
import APIErrorBoundary from '@/components/APIErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import CommentsSkeleton from '@/components/skeletons/CommentsSkeleton';

export function UserComments() {
  return (
    <ErrorBoundary FallbackComponent={InlineError}>
      <Suspense fallback={<CommentsSkeleton />}>
        <CommentsContent />
      </Suspense>
    </ErrorBoundary>
  );
}
```

### 9-4. Smart Error (자동 라우팅)

```tsx
// src/components/DataFetcher.tsx
import ErrorBoundary from '@/components/ErrorBoundary';
import { SmartErrorFallback } from '@/components/error-fallbacks';

function DataFetcher() {
  return (
    <ErrorBoundary FallbackComponent={SmartErrorFallback}>
      <Suspense fallback={<Skeleton />}>
        <DataContent />
      </Suspense>
    </ErrorBoundary>
  );
}
```

---

## 10. 스타일링 커스터마이징 가이드

### Emotion 버전

```tsx
/** @jsxImportSource @emotion/react */
import { css } from '@emotion/react';

const containerStyle = css`
  padding: 24px;
  border-radius: 12px;
  border: 1px solid #fee;
  background-color: #fffaf0;
  text-align: center;
`;

export const ErrorFallback = ({ error, resetError }) => {
  return <div css={containerStyle}>{/* ... */}</div>;
};
```

### CSS Modules 버전

```tsx
// ErrorFallback.module.css
.container {
  padding: 24px;
  border-radius: 12px;
  border: 1px solid #fee;
  background-color: #fffaf0;
  text-align: center;
}

// ErrorFallback.tsx
import styles from './ErrorFallback.module.css';

export const ErrorFallback = ({ error, resetError }) => {
  return <div className={styles.container}>{/* ... */}</div>;
};
```

### Tailwind 버전

```tsx
export const ErrorFallback = ({ error, resetError }) => {
  return (
    <div className="p-6 rounded-xl border border-red-100 bg-orange-50 text-center">
      {/* ... */}
    </div>
  );
};
```

---

## 11. 접근성 (Accessibility) 개선

```tsx
// 접근성을 고려한 ErrorFallback
export const AccessibleErrorFallback: React.FC<FallbackProps> = ({ error, resetError }) => {
  return (
    <div
      role="alert"
      aria-live="assertive"
      aria-atomic="true"
      style={{
        padding: '24px',
        borderRadius: '12px',
        border: '1px solid #fee',
        backgroundColor: '#fffaf0',
      }}
    >
      <h2 id="error-title">문제가 발생했습니다</h2>
      <p id="error-description">{error.message}</p>
      <button
        onClick={resetError}
        aria-label="에러 복구 다시 시도"
        aria-describedby="error-description"
      >
        다시 시도
      </button>
    </div>
  );
};
```

---

## 참고 자료

- [WCAG 2.1 - Error Identification](https://www.w3.org/WAI/WCAG21/Understanding/error-identification.html)
- [React Error Boundaries](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)
