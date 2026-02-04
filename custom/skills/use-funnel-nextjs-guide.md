# @use-funnel Next.js 가이드

> **문서 범위**: Next.js 환경에서의 @use-funnel 사용법
> **다른 환경**: React Router, Remix 등은 별도 문서 참조 예정

## 개요

@use-funnel은 토스에서 개발한 **다단계 UI 흐름(퍼널)을 구현하기 위한 React Hook** 라이브러리입니다. 회원가입, 설문조사, 결제 플로우 등 단계별 입력이 필요한 UI를 타입 안전하게 구현할 수 있습니다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Step** | 사용자가 거쳐야 할 개별 화면/입력 단계 |
| **Context** | 각 단계에서 입력한 데이터를 저장하는 상태 객체 |
| **History** | step 이동과 context 변경 기록을 담은 배열 |

### 주요 특징

- **타입 안전성**: 각 단계별 필수 상태를 타입으로 강제
- **히스토리 관리**: 뒤로가기/앞으로가기 시 상태 자동 복원
- **오버레이 지원**: 모달, 바텀시트를 퍼널 단계로 처리 가능

---

## 설치

### Next.js (App Router)

```bash
pnpm add @use-funnel/next
```

### Next.js (Pages Router)

```bash
pnpm add @use-funnel/next
```

> **참고**: `@use-funnel/next`는 App Router와 Pages Router 모두 지원합니다.

---

## 기본 사용법

### 1. 단계별 Context 타입 정의

```typescript
// types/signup-funnel.ts
export interface SignupSteps {
  이메일입력: { email?: string };
  비밀번호입력: { email: string; password?: string };
  완료: { email: string; password: string };
}
```

### 2. 퍼널 컴포넌트 구현

```tsx
// app/signup/page.tsx
'use client';

import { useFunnel } from '@use-funnel/next';
import type { SignupSteps } from '@/types/signup-funnel';

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

### 3. History API

| 메서드 | 설명 |
|--------|------|
| `history.push(step, context)` | 다음 단계로 이동, 히스토리 추가 |
| `history.replace(step, context)` | 현재 단계 덮어쓰기, 히스토리 유지 |
| `history.back()` | 이전 단계로 이동 |
| `history.go(delta)` | delta만큼 히스토리 이동 |

---

## Context 정의 방법

### 방법 1: 제네릭 타입 직접 정의

```typescript
interface MyFunnelSteps {
  A: { a?: string };
  B: { a: string; b?: number };
  C: { a: string; b: number };
}

const funnel = useFunnel<MyFunnelSteps>({
  id: 'my-funnel',
  initial: { step: 'A', context: {} },
});
```

### 방법 2: createFunnelSteps 유틸리티

```typescript
import { createFunnelSteps } from '@use-funnel/next';

const steps = createFunnelSteps<{
  name?: string;
  email?: string;
  phone?: string;
}>()
  .extends('이름입력')
  .extends('이메일입력', { requiredKeys: 'name' })
  .extends('전화번호입력', { requiredKeys: ['name', 'email'] })
  .extends('완료', { requiredKeys: ['name', 'email', 'phone'] })
  .build();

const funnel = useFunnel({
  id: 'profile-funnel',
  steps,
  initial: { step: '이름입력', context: {} },
});
```

### 방법 3: guard/parse로 런타임 검증

```typescript
import { FunnelStepOption } from '@use-funnel/next';

const steps = {
  이메일입력: {
    guard: (ctx): ctx is { email: string } => typeof ctx.email === 'string',
  },
  비밀번호입력: {
    parse: (ctx) => {
      if (!ctx.email || !ctx.password) throw new Error('필수값 누락');
      return ctx as { email: string; password: string };
    },
  },
} satisfies Record<string, FunnelStepOption>;
```

### 방법 4: Zod 스키마 연동

```typescript
import { z } from 'zod';

const baseSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
}).partial();

const steps = {
  이메일입력: { parse: baseSchema.parse },
  비밀번호입력: {
    parse: baseSchema.required({ email: true }).parse
  },
  완료: {
    parse: baseSchema.required().parse
  },
};
```

---

## 고급 기능

### Transition Event (조건부 분기)

한 단계에서 여러 경로로 분기해야 할 때 사용합니다.

```tsx
const funnel = useFunnel<{
  이메일확인: { email?: string };
  인증성공: { email: string; verified: true };
  인증실패: { email: string; errorMessage: string };
}>({
  id: 'email-verify',
  initial: { step: '이메일확인', context: {} },
});

return (
  <funnel.Render
    이메일확인={{
      events: {
        인증성공: (payload, { history }) => {
          history.push('인증성공', { verified: true, ...payload });
        },
        인증실패: (payload, { history }) => {
          history.push('인증실패', payload);
        },
      },
      render({ context, dispatch }) {
        const handleVerify = async (email: string) => {
          try {
            await verifyEmail(email);
            dispatch('인증성공', { email });
          } catch (e) {
            dispatch('인증실패', { email, errorMessage: e.message });
          }
        };
        return <EmailForm onSubmit={handleVerify} />;
      },
    }}
    인증성공={({ context }) => <SuccessView email={context.email} />}
    인증실패={({ context }) => <FailureView message={context.errorMessage} />}
  />
);
```

> **주의**: events 정의 시 render 함수에서 `history`를 직접 사용할 수 없습니다. 반드시 events 내부에서 history를 사용하세요.

### Overlay (모달/바텀시트)

이전 단계 UI를 유지하면서 오버레이를 표시합니다.

```tsx
<funnel.Render
  날짜선택={({ history }) => (
    <DateSelector onOpenCalendar={() => history.push('캘린더팝업')} />
  )}
  캘린더팝업={funnel.Render.overlay({
    render({ history, close }) {
      return (
        <CalendarBottomSheet
          onSelect={(date) => {
            history.push('다음단계', { selectedDate: date });
          }}
          onClose={() => close()}
        />
      );
    },
  })}
/>
```

> **중요**: 뒤로가기가 아닌 방식으로 오버레이를 닫을 때는 반드시 `close()`를 호출해야 합니다.

### Sub-funnel (중첩 퍼널)

복잡한 퍼널을 작은 단위로 분리하거나 재사용할 때 사용합니다.

```tsx
// 메인 퍼널
function MainFunnel() {
  const funnel = useFunnel<MainSteps>({
    id: 'main-funnel',
    initial: { step: 'A', context: {} },
  });

  return (
    <funnel.Render
      A={({ history }) => (
        <StepA onNext={() => history.push('B')} />
      )}
      B={({ context, history }) => (
        <SubFunnel
          initialData={context}
          onComplete={(result) => history.push('C', result)}
        />
      )}
      C={({ context }) => <Complete data={context} />}
    />
  );
}

// 서브 퍼널 (다른 id 사용)
function SubFunnel({ initialData, onComplete }) {
  const funnel = useFunnel<SubSteps>({
    id: 'sub-funnel', // 반드시 다른 id
    initial: { step: 'X', context: initialData },
  });

  return (
    <funnel.Render
      X={({ history }) => <StepX onNext={(data) => history.push('Y', data)} />}
      Y={({ context }) => <StepY data={context} onDone={() => onComplete(context)} />}
    />
  );
}
```

---

## Custom Router 구현

기본 제공 라우터 대신 직접 구현할 때 사용합니다.

```typescript
// hooks/useMemoryFunnel.ts
import { createUseFunnel } from '@use-funnel/core';
import { useState } from 'react';

export const useMemoryFunnel = createUseFunnel(({ id, initialState }) => {
  const [history, setHistory] = useState([initialState]);
  const [currentIndex, setCurrentIndex] = useState(0);

  return [
    history[currentIndex],
    {
      push(state) {
        setHistory((prev) => [...prev.slice(0, currentIndex + 1), state]);
        setCurrentIndex((prev) => prev + 1);
      },
      replace(state) {
        setHistory((prev) => {
          const next = [...prev];
          next[currentIndex] = state;
          return next;
        });
      },
      go(delta) {
        setCurrentIndex((prev) =>
          Math.max(0, Math.min(prev + delta, history.length - 1))
        );
      },
    },
  ];
});
```

---

## 패턴 및 권장사항

### 1. 단계 이름은 한글로

```typescript
// 권장: 가독성 향상
interface Steps {
  이메일입력: { ... };
  비밀번호설정: { ... };
}

// 비권장: 파악 어려움
interface Steps {
  step1: { ... };
  step2: { ... };
}
```

### 2. Context 타입은 점진적 확장

```typescript
interface Steps {
  A: { a?: string };           // a는 선택
  B: { a: string; b?: string }; // a는 필수, b는 선택
  C: { a: string; b: string };  // 모두 필수
}
```

### 3. 퍼널 ID는 고유하게

```typescript
// 같은 페이지에 여러 퍼널이 있는 경우
const mainFunnel = useFunnel({ id: 'main-funnel', ... });
const subFunnel = useFunnel({ id: 'sub-funnel', ... });
```

### 4. 복잡한 분기는 events 활용

```typescript
// 권장: events로 분기 처리
이메일입력={{
  events: {
    성공: (p, { history }) => history.push('다음', p),
    실패: (p, { history }) => history.push('에러', p),
  },
  render({ dispatch }) { ... }
}}

// 비권장: render 내부에서 직접 분기
이메일입력={({ history }) => {
  // history.push를 조건문 안에서 사용하면 복잡해짐
}}
```

---

## 참고 자료

- [공식 문서](https://use-funnel.slash.page/ko/docs/overview)
- [GitHub 저장소](https://github.com/toss/use-funnel)
- [토스 기술 블로그 - use-funnel 리팩토링](https://toss.tech/article/use-funnel-1)

---

## 관련 문서

- [use-funnel-react-router-guide.md](./use-funnel-react-router-guide.md) - React Router 환경 가이드
- `use-funnel-advanced-patterns.md` (예정)
