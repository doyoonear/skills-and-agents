# @use-funnel React Router 가이드

> **문서 범위**: React Router 환경에서의 @use-funnel 사용법
> **기본 개념**: [use-funnel-nextjs-guide.md](./use-funnel-nextjs-guide.md) 참조

## 개요

이 문서는 React Router (v6+) 환경에서 @use-funnel을 사용하는 방법을 다룹니다. 핵심 개념(Step, Context, History)과 고급 기능(Transition Event, Overlay, Sub-funnel)은 Next.js 가이드와 동일하므로 해당 문서를 참조하세요.

---

## 설치

### react-router-dom 사용 시

```bash
pnpm add @use-funnel/react-router-dom
```

### Peer Dependencies

| 패키지 | 최소 버전 |
|--------|-----------|
| `react` | >= 16.8 |
| `react-router-dom` | >= 6 |

> **참고**: React Router v5 이하는 지원되지 않습니다.

---

## 프로젝트 설정

### 1. Router 설정 확인

use-funnel은 React Router의 URL 기반 상태 관리를 활용합니다. BrowserRouter 또는 createBrowserRouter가 설정되어 있어야 합니다.

```tsx
// main.tsx
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import SignupPage from './pages/SignupPage';

const router = createBrowserRouter([
  {
    path: '/signup',
    element: <SignupPage />,
  },
]);

function App() {
  return <RouterProvider router={router} />;
}
```

### 2. 기본 사용법

```tsx
// pages/SignupPage.tsx
import { useFunnel } from '@use-funnel/react-router-dom';

interface SignupSteps {
  이메일입력: { email?: string };
  비밀번호입력: { email: string; password?: string };
  완료: { email: string; password: string };
}

export default function SignupPage() {
  const funnel = useFunnel<SignupSteps>({
    id: 'signup-funnel',
    initial: {
      step: '이메일입력',
      context: {},
    },
  });

  return (
    <funnel.Render
      이메일입력={({ history }) => (
        <EmailStep
          onNext={(email) => history.push('비밀번호입력', { email })}
        />
      )}
      비밀번호입력={({ context, history }) => (
        <PasswordStep
          email={context.email}
          onNext={(password) => history.push('완료', { password })}
          onBack={() => history.back()}
        />
      )}
      완료={({ context }) => (
        <CompleteStep email={context.email} password={context.password} />
      )}
    />
  );
}
```

---

## Next.js와의 차이점

### URL 상태 관리

| 항목 | Next.js | React Router |
|------|---------|--------------|
| 패키지 | `@use-funnel/next` | `@use-funnel/react-router-dom` |
| 라우터 | Next.js Router | react-router-dom |
| SSR 지원 | 기본 지원 | 별도 설정 필요 |
| URL 동기화 | 자동 | 자동 |

### import 경로만 변경

```tsx
// Next.js
import { useFunnel } from '@use-funnel/next';

// React Router
import { useFunnel } from '@use-funnel/react-router-dom';
```

> 나머지 API는 동일합니다.

---

## React Router 특화 패턴

### 1. Outlet과 함께 사용

중첩 라우팅에서 Outlet과 함께 사용할 수 있습니다.

```tsx
// routes.tsx
const router = createBrowserRouter([
  {
    path: '/onboarding',
    element: <OnboardingLayout />,
    children: [
      {
        index: true,
        element: <OnboardingFunnel />,
      },
    ],
  },
]);

// OnboardingLayout.tsx
import { Outlet } from 'react-router-dom';

function OnboardingLayout() {
  return (
    <div className="onboarding-container">
      <header>온보딩</header>
      <main>
        <Outlet />
      </main>
    </div>
  );
}
```

### 2. useNavigate와 조합

퍼널 완료 후 다른 페이지로 이동할 때 useNavigate를 활용합니다.

```tsx
import { useNavigate } from 'react-router-dom';
import { useFunnel } from '@use-funnel/react-router-dom';

function SignupFunnel() {
  const navigate = useNavigate();
  const funnel = useFunnel<SignupSteps>({
    id: 'signup',
    initial: { step: '이메일입력', context: {} },
  });

  return (
    <funnel.Render
      // ... 다른 단계들
      완료={({ context }) => (
        <CompleteStep
          onGoHome={() => navigate('/')}
          onGoProfile={() => navigate('/profile')}
        />
      )}
    />
  );
}
```

### 3. useSearchParams 활용

퍼널 외부에서 현재 단계를 확인하거나 조작할 때 사용합니다.

```tsx
import { useSearchParams } from 'react-router-dom';

function FunnelProgress() {
  const [searchParams] = useSearchParams();
  const currentStep = searchParams.get('funnel.signup.step');

  const steps = ['이메일입력', '비밀번호입력', '완료'];
  const currentIndex = steps.indexOf(currentStep || '');

  return (
    <div className="progress-bar">
      {steps.map((step, index) => (
        <div
          key={step}
          className={index <= currentIndex ? 'active' : ''}
        />
      ))}
    </div>
  );
}
```

### 4. 뒤로가기 가드

브라우저 뒤로가기 시 확인 다이얼로그를 표시합니다.

```tsx
import { useBlocker } from 'react-router-dom';
import { useFunnel } from '@use-funnel/react-router-dom';

function SignupFunnel() {
  const funnel = useFunnel<SignupSteps>({
    id: 'signup',
    initial: { step: '이메일입력', context: {} },
  });

  // 첫 단계가 아닐 때 페이지 이탈 방지
  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      funnel.step !== '이메일입력' &&
      !nextLocation.pathname.startsWith('/signup')
  );

  return (
    <>
      <funnel.Render
        // ... 단계들
      />
      {blocker.state === 'blocked' && (
        <ConfirmDialog
          message="작성 중인 내용이 사라집니다. 나가시겠습니까?"
          onConfirm={() => blocker.proceed()}
          onCancel={() => blocker.reset()}
        />
      )}
    </>
  );
}
```

---

## SPA 라우팅 고려사항

### URL 구조

use-funnel은 쿼리 파라미터로 상태를 관리합니다:

```
/signup?funnel.signup-funnel.step=비밀번호입력&funnel.signup-funnel.context=...
```

### 딥링크 처리

특정 단계로 직접 접근 시 초기 상태로 리다이렉트할 수 있습니다:

```tsx
import { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';

function SignupFunnel() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const funnel = useFunnel<SignupSteps>({
    id: 'signup',
    initial: { step: '이메일입력', context: {} },
  });

  // 잘못된 단계 접근 시 리다이렉트
  useEffect(() => {
    const stepParam = searchParams.get('funnel.signup.step');
    if (stepParam && stepParam !== '이메일입력') {
      // context 없이 중간 단계 접근 시 처음으로
      if (!funnel.context.email) {
        navigate('/signup', { replace: true });
      }
    }
  }, []);

  return <funnel.Render ... />;
}
```

---

## 전체 예시: 회원가입 퍼널

```tsx
// pages/SignupPage.tsx
import { useFunnel } from '@use-funnel/react-router-dom';
import { useNavigate } from 'react-router-dom';

interface SignupSteps {
  이메일입력: { email?: string };
  비밀번호입력: { email: string; password?: string };
  프로필설정: { email: string; password: string; nickname?: string };
  완료: { email: string; password: string; nickname: string };
}

export default function SignupPage() {
  const navigate = useNavigate();

  const funnel = useFunnel<SignupSteps>({
    id: 'signup',
    initial: {
      step: '이메일입력',
      context: {},
    },
  });

  const handleSignup = async (data: SignupSteps['완료']) => {
    await api.signup(data);
    navigate('/welcome');
  };

  return (
    <div className="signup-container">
      <ProgressBar currentStep={funnel.step} />

      <funnel.Render
        이메일입력={({ history }) => (
          <EmailStep
            onNext={(email) => history.push('비밀번호입력', { email })}
            onCancel={() => navigate('/')}
          />
        )}
        비밀번호입력={({ context, history }) => (
          <PasswordStep
            email={context.email}
            onNext={(password) => history.push('프로필설정', { password })}
            onBack={() => history.back()}
          />
        )}
        프로필설정={({ context, history }) => (
          <ProfileStep
            onNext={(nickname) => history.push('완료', { nickname })}
            onBack={() => history.back()}
          />
        )}
        완료={({ context }) => (
          <CompleteStep
            data={context}
            onSubmit={() => handleSignup(context)}
          />
        )}
      />
    </div>
  );
}
```

---

## 트러블슈팅

### 1. "Cannot read property 'push' of undefined"

Router가 올바르게 설정되지 않았습니다.

```tsx
// 잘못된 예
function App() {
  return <SignupFunnel />; // Router 없음
}

// 올바른 예
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/signup" element={<SignupFunnel />} />
      </Routes>
    </BrowserRouter>
  );
}
```

### 2. 새로고침 시 상태 유실

URL에 저장되므로 기본적으로 유지되지만, context가 복잡한 경우 직렬화 문제가 발생할 수 있습니다.

```tsx
// 복잡한 객체는 피하기
interface BadContext {
  user: User;      // 클래스 인스턴스
  date: Date;      // Date 객체
  callback: () => void;  // 함수
}

// 직렬화 가능한 형태로
interface GoodContext {
  userId: string;
  dateString: string;  // ISO 문자열
}
```

### 3. react-router v5 사용 시

v5는 지원되지 않습니다. v6로 마이그레이션하거나 `@use-funnel/browser`를 사용하세요.

```bash
# 브라우저 히스토리 직접 사용
pnpm add @use-funnel/browser
```

---

## 참고 자료

- [공식 문서](https://use-funnel.slash.page/ko/docs/overview)
- [React Router v6 문서](https://reactrouter.com/en/main)
- [use-funnel-nextjs-guide.md](./use-funnel-nextjs-guide.md) - 핵심 개념 및 고급 기능
