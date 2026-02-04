# 프론트엔드 코드 작성 원칙

> 이 문서는 [Frontend Fundamentals](https://frontend-fundamentals.com/code-quality/code/)의 원칙을 기반으로,
> AI Agent가 React 컴포넌트를 생성할 때 참고할 수 있도록 정리한 가이드입니다.

## 1. 개요

### 좋은 코드란?
**"변경하기 쉬운 코드"**가 좋은 코드입니다. 요구사항은 항상 변하므로, 수정이 용이한 구조가 중요합니다.

### 4가지 평가 기준

| 원칙 | 정의 | 핵심 질문 |
|-----|-----|----------|
| **가독성** | 코드를 이해하기 쉬운 정도 | "한 번에 파악해야 할 맥락이 적은가?" |
| **예측가능성** | 동작을 예측할 수 있는 정도 | "이름만 보고 동작을 알 수 있는가?" |
| **응집도** | 함께 수정될 코드가 모여있는 정도 | "관련 코드가 함께 변경되는가?" |
| **결합도** | 수정 시 영향 범위 | "변경 영향이 최소화되는가?" |

### 기술 선택의 원칙

> 기술 스택의 단순한 경험보다 **'왜' 그 기술을 선택했는지**에 대한 논리적 근거가 중요합니다.

**핵심 질문**:
- 이 기술이 현재 비즈니스 요구사항을 해결하는가?
- 기술적 한계와 트레이드오프를 이해하고 있는가?
- 유행하는 기술이 아닌, 상황에 맞는 기술인가?

```tsx
// 기술 선택 의사결정 예시
// ❌ 나쁜 예: "React Query가 유행하니까 사용"
// ✅ 좋은 예: "서버 상태 관리가 복잡해지고, 캐싱과 자동 리패치가 필요해서 React Query 도입"

// ❌ 나쁜 예: "Next.js가 좋다고 해서 사용"
// ✅ 좋은 예: "SEO가 중요하고 SSR이 필요하며, 파일 기반 라우팅이 팀 생산성에 도움되어 Next.js 선택"
```

**기술 선택 체크리스트**:
- [ ] 문제를 명확히 정의했는가?
- [ ] 여러 대안을 비교 검토했는가?
- [ ] 팀의 학습 곡선을 고려했는가?
- [ ] 유지보수성과 생태계를 검토했는가?
- [ ] 기존 시스템과의 통합 비용을 고려했는가?

### 원칙 간 상충 관계
4가지 기준을 모두 만족시키기는 어렵습니다. 특히 **가독성**과 **응집도**는 자주 상충합니다.
응집도를 높이려면 추상화가 필요하지만, 이는 가독성을 낮출 수 있습니다.

---

## 2. 가독성 (Readability)

**정의**: 읽는 사람이 한 번에 고려할 맥락을 줄이고, 위에서 아래로 자연스럽게 흐르는 코드

> 인간이 한 번에 기억할 수 있는 정보는 약 6개 정도입니다.
> 코드를 읽을 때도 동시에 고려해야 할 맥락을 줄여야 합니다.

### 2.1 맥락 줄이기

#### A. 같이 실행되지 않는 코드 분리하기

조건에 따라 다른 동작을 하는 코드가 한 곳에 섞여있으면 이해하기 어렵습니다.

```tsx
// Before: 모든 조건이 한 컴포넌트에 혼재
function SubmitButton() {
  const isViewer = useRole() === "viewer";

  useEffect(() => {
    if (isViewer) {
      return;
    }
    showButtonAnimation();
  }, [isViewer]);

  return isViewer ? (
    <TextButton disabled>Submit</TextButton>
  ) : (
    <Button type="submit">Submit</Button>
  );
}
```

```tsx
// After: 역할별로 컴포넌트 분리
function SubmitButton() {
  const isViewer = useRole() === "viewer";
  return isViewer ? <ViewerSubmitButton /> : <AdminSubmitButton />;
}

function ViewerSubmitButton() {
  return <TextButton disabled>Submit</TextButton>;
}

function AdminSubmitButton() {
  useEffect(() => {
    showButtonAnimation();
  }, []);
  return <Button type="submit">Submit</Button>;
}
```

**개선 효과**:
- 분기 조건이 한 곳으로 통합
- 각 컴포넌트가 단일 상태만 관리
- 독자가 이해해야 할 맥락 감소

#### B. 구현 상세 추상화하기

불필요한 구현 세부사항을 추상화하여 핵심 로직에 집중할 수 있게 합니다.

```tsx
// Before: 인증 로직이 노출됨
function LoginStartPage() {
  const { status } = useCheckLogin();

  if (status === "LOGGED_IN") {
    return <Redirect to="/home" />;
  }

  return <LoginForm />;
}
```

```tsx
// After: AuthGuard로 추상화
function LoginStartPage() {
  return (
    <AuthGuard>
      <LoginForm />
    </AuthGuard>
  );
}

// AuthGuard 컴포넌트가 인증 로직 담당
function AuthGuard({ children }: { children: React.ReactNode }) {
  const { status } = useCheckLogin();

  if (status === "LOGGED_IN") {
    return <Redirect to="/home" />;
  }

  return <>{children}</>;
}
```

**HOC 패턴 대안**:
```tsx
// Higher-Order Component로 추상화
const LoginStartPage = withAuthGuard(() => <LoginForm />);
```

#### C. 함수 쪼개기

여러 책임을 가진 훅은 분리하는 것이 좋습니다. 자세한 내용은 [5.1 책임을 하나씩 관리](#51-책임을-하나씩-관리)를 참조하세요.

### 2.2 이름 붙이기

#### A. 복잡한 조건에 이름 부여하기

익명 함수와 조건이 중첩되면 로직을 파악하기 어렵습니다.

```tsx
// Before: 중첩된 익명 조건
const result = products.filter((product) =>
  product.categories.some(
    (category) =>
      category.id === targetCategory.id &&
      product.prices.some((price) => price >= minPrice && price <= maxPrice)
  )
);
```

```tsx
// After: 조건에 이름 부여
const matchedProducts = products.filter((product) => {
  return product.categories.some((category) => {
    const isSameCategory = category.id === targetCategory.id;
    const isPriceInRange = product.prices.some(
      (price) => price >= minPrice && price <= maxPrice
    );
    return isSameCategory && isPriceInRange;
  });
});
```

**이름을 붙여야 할 때**:
- 복잡한 로직이 여러 줄에 걸쳐 있을 때
- 코드 재사용이 필요할 때
- 단위 테스트가 필요할 때

**이름이 불필요할 때**:
- 단순하고 자명한 로직 (예: `arr.map(x => x * 2)`)
- 한 번만 사용되는 간단한 표현식

#### B. 매직 넘버에 이름 붙이기

매직 넘버 관련 내용은 [6. 상수와 매직 넘버](#6-상수와-매직-넘버-통합-섹션)를 참조하세요.

### 2.3 위에서 아래로 읽히게 하기

#### A. 시점 이동 줄이기

코드를 읽을 때 여러 위치를 왕복해야 하면 이해가 어렵습니다.

```tsx
// Before: POLICY_SET을 참조하며 왕복 필요
const POLICY_SET = {
  admin: { canInvite: true, canView: true },
  viewer: { canInvite: false, canView: true },
};

function getPolicyByRole(role: string) {
  return POLICY_SET[role];
}

function UserActions({ role }: { role: string }) {
  const policy = getPolicyByRole(role);
  return (
    <>
      <Button disabled={!policy.canInvite}>Invite</Button>
      <Button disabled={!policy.canView}>View</Button>
    </>
  );
}
```

```tsx
// After: 조건을 직접 노출 (switch 문)
function UserActions({ role }: { role: string }) {
  const getButtonStates = () => {
    switch (role) {
      case "admin":
        return { canInvite: true, canView: true };
      case "viewer":
        return { canInvite: false, canView: true };
      default:
        return { canInvite: false, canView: false };
    }
  };

  const { canInvite, canView } = getButtonStates();

  return (
    <>
      <Button disabled={!canInvite}>Invite</Button>
      <Button disabled={!canView}>View</Button>
    </>
  );
}
```

#### B. 중첩 삼항 연산자 단순화

```tsx
// Before: 중첩 삼항 연산자
const status =
  ACondition && BCondition
    ? "BOTH"
    : ACondition || BCondition
      ? ACondition
        ? "A"
        : "B"
      : "NONE";
```

```tsx
// After: IIFE + if문으로 명확하게
const status = (() => {
  if (ACondition && BCondition) return "BOTH";
  if (ACondition) return "A";
  if (BCondition) return "B";
  return "NONE";
})();
```

### 2.4 코드 스페이싱 (줄 바꿈)

변수/함수 선언을 용도별로 그룹화하기 위한 빈 줄은 가독성에 도움이 됩니다.
단, 다음 상황에서는 빈 줄이 오히려 코드를 읽기 어렵게 만들므로 자제합니다.

#### 권장: 용도별 그룹화

```tsx
// ✅ 좋은 예: 훅 호출, 파생 상태, 변환값으로 그룹화
const departureStation = useDepartureStation();
const arrivalStation = useArrivalStation();
const tripType = useTripType();
const selectionPhase = useSelectionPhase();
const { getStationId } = useStationIdMap();

const isReturnPhase = selectionPhase === SELECTION_PHASE.RETURN;

const currentDepartureStation = isReturnPhase ? arrivalStation : departureStation;
const currentArrivalStation = isReturnPhase ? departureStation : arrivalStation;

const departureStationId = getStationId(currentDepartureStation);
const arrivalStationId = getStationId(currentArrivalStation);
```

#### 비권장: 객체 프로퍼티 사이

```tsx
// ❌ 나쁜 예: 객체 내부 프로퍼티 사이 불필요한 빈 줄
export const useSearchStore = create<SearchState>(set => ({
  ...initialState,

  actions: {
    selectDepartureStation: station => set({ departureStation: station }),

    selectArrivalStation: station => set({ arrivalStation: station }),

    selectTripType: tripType => set({ tripType }),
  },
}));

// ✅ 좋은 예: 객체 프로퍼티는 연속으로
export const useSearchStore = create<SearchState>(set => ({
  ...initialState,
  actions: {
    selectDepartureStation: station => set({ departureStation: station }),
    selectArrivalStation: station => set({ arrivalStation: station }),
    selectTripType: tripType => set({ tripType }),
  },
}));
```

#### 비권장: JSX 요소 사이

```tsx
// ❌ 나쁜 예: JSX 요소 사이 불필요한 빈 줄
return (
  <>
    <NavigationBar title="기차 예매" />

    <Spacing size={16} />

    <ListRow onClick={() => navigate('/station')} contents={...} />

    <Flex justifyContent="center">
      <Assets.Icon name="icon-arrow-down" />
    </Flex>
  </>
);

// ✅ 좋은 예: JSX 요소는 연속으로
return (
  <>
    <NavigationBar title="기차 예매" />
    <Spacing size={16} />
    <ListRow onClick={() => navigate('/station')} contents={...} />
    <Flex justifyContent="center">
      <Assets.Icon name="icon-arrow-down" />
    </Flex>
  </>
);
```

#### 스페이싱 판단 기준

| 상황 | 빈 줄 사용 |
|-----|----------|
| 훅 호출 그룹 → 파생 상태 그룹 → 핸들러 그룹 | ✅ 권장 |
| 객체 리터럴 내부 프로퍼티 사이 | ❌ 비권장 |
| JSX return문 내부 요소 사이 | ❌ 비권장 |
| 서로 다른 관심사의 코드 블록 사이 | ✅ 권장 |

---

## 3. 예측가능성 (Predictability)

**정의**: 이름, 매개변수, 반환값만으로 동작을 예측할 수 있는 코드

> 예측 가능한 코드는 일관된 규칙을 따릅니다.
> 함수명만 보고도 동작을 알 수 있어야 합니다.

### 3.1 이름 겹치지 않게 관리

같은 이름을 가진 함수/변수는 같은 동작을 해야 합니다.

```tsx
// Before: 같은 이름 http가 다른 동작
// @some-library/http 에서 가져온 원본
import { http } from "@some-library/http";

// 프로젝트 내 래퍼 (토큰 추가)
export const http = {
  get: (url: string) => originalHttp.get(url, { token: getToken() }),
};
```

```tsx
// After: 명확한 이름으로 구분
import { http as originalHttp } from "@some-library/http";

export const httpService = {
  getWithAuth: (url: string) =>
    originalHttp.get(url, { headers: { Authorization: getToken() } }),
};
```

**래퍼 함수 명명 규칙**:
- 원본과 다른 동작이면 다른 이름 사용
- 추가 기능을 이름에 반영 (예: `getWithAuth`, `fetchWithRetry`)

### 3.2 같은 종류 함수는 반환 타입 통일

```tsx
// Before: 유사한 훅이 다른 반환 타입
function useUser() {
  return useQuery({ queryKey: ["user"], queryFn: fetchUser });
  // Query 객체 반환
}

function useServerTime() {
  const query = useQuery({ queryKey: ["time"], queryFn: fetchServerTime });
  return query.data; // 데이터만 반환
}
```

```tsx
// After: 반환 타입 통일
function useUser() {
  return useQuery({ queryKey: ["user"], queryFn: fetchUser });
}

function useServerTime() {
  return useQuery({ queryKey: ["time"], queryFn: fetchServerTime });
}
// 둘 다 Query 객체 반환
```

**검증 함수의 반환 타입 통일 (Discriminated Union)**:

```tsx
// Before: 반환 타입이 다름
function checkIsNameValid(name: string): boolean {
  return name.length > 0;
}

function checkIsAgeValid(age: number): { ok: boolean; reason?: string } {
  if (age < 0) return { ok: false, reason: "나이는 0 이상이어야 합니다" };
  return { ok: true };
}
```

```tsx
// After: Discriminated Union으로 통일
type ValidationResult =
  | { ok: true }
  | { ok: false; reason: string };

function checkIsNameValid(name: string): ValidationResult {
  if (name.length === 0) {
    return { ok: false, reason: "이름을 입력해주세요" };
  }
  return { ok: true };
}

function checkIsAgeValid(age: number): ValidationResult {
  if (age < 0) {
    return { ok: false, reason: "나이는 0 이상이어야 합니다" };
  }
  return { ok: true };
}
```

### 3.3 숨은 로직 드러내기

함수명에서 예측할 수 없는 부수 효과(Side Effect)는 분리해야 합니다.

```tsx
// Before: fetchBalance 내부에 로깅이 숨어있음
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("/api/balance");
  logging.log("balance_fetched"); // 숨은 로직!
  return balance;
}
```

```tsx
// After: 로깅을 호출 지점으로 이동
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("/api/balance");
  return balance;
}

// 사용처에서 명시적으로 로깅
<Button
  onClick={async () => {
    const balance = await fetchBalance();
    logging.log("balance_fetched");
    await syncBalance(balance);
  }}
>
  잔액 조회
</Button>
```

**부수 효과 처리 원칙**:
- 함수명으로 예측 가능한 동작만 구현
- 로깅, 분석, 알림 등은 호출 지점에서 명시적으로 처리
- 필요시 별도 함수로 분리 (예: `fetchBalanceWithLogging`)

---

## 4. 응집도 (Cohesion)

**정의**: 함께 수정되어야 할 코드가 실제로 함께 수정되는 구조

> 응집도가 높으면 한 곳을 수정할 때 관련 코드도 자연스럽게 함께 수정됩니다.
> 응집도가 낮으면 수정을 빠뜨려 버그가 발생할 수 있습니다.

### 4.1 디렉토리 구조

> 폴더 구조는 기술적 분류보다 **비즈니스 맥락**과 **'지우기 쉬운 구조'**를 우선해 응집도를 높여야 합니다.

#### "지우기 쉬운 구조"란?

기능이 더 이상 필요 없을 때, **디렉토리 하나만 삭제하면 깔끔하게 제거되는 구조**입니다.
이는 좋은 응집도의 핵심 지표입니다.

```tsx
// 지우기 쉬운 구조의 장점
// 1. 기능 삭제 시 관련 코드를 찾아 헤매지 않음
// 2. 삭제 후 남은 코드에 영향이 없음
// 3. 기능의 경계가 명확하여 유지보수가 쉬움
```

#### 타입별 구조 (비권장)

```
src/
├── components/
│   ├── UserProfile.tsx
│   ├── ProductCard.tsx
│   └── ...100개 이상의 파일
├── hooks/
│   ├── useUser.ts
│   ├── useProduct.ts
│   └── ...
├── utils/
│   └── ...
└── constants/
    └── ...
```

**문제점**:
- 프로젝트 성장 시 디렉토리가 비대해짐
- 관련 파일 간 의존성 파악 어려움
- 기능 삭제 시 관련 파일 찾기 어려움 (여러 폴더에 흩어져 있음)
- **"지우기 어려운 구조"** - User 기능을 제거하려면 components, hooks, utils, constants 모두 확인해야 함

#### 도메인별 구조 (권장)

```
src/
├── components/   # 공통 컴포넌트
├── hooks/        # 공통 훅
├── utils/        # 공통 유틸
└── domains/
    ├── user/
    │   ├── components/
    │   │   └── UserProfile.tsx
    │   ├── hooks/
    │   │   └── useUser.ts
    │   └── utils/
    └── product/
        ├── components/
        │   └── ProductCard.tsx
        ├── hooks/
        │   └── useProduct.ts
        └── utils/
```

**장점**:
- 관련 코드가 물리적으로 가까이 위치
- **"지우기 쉬운 구조"** - `rm -rf domains/user/` 한 번으로 깔끔한 제거
- 잘못된 import 경로를 쉽게 발견
- 비즈니스 맥락 기반으로 코드를 이해하기 쉬움

```tsx
// 잘못된 참조가 명확하게 드러남
import { useFoo } from "../../../product/hooks/useFoo";
// → user 도메인에서 product 도메인을 직접 참조하는 것이 맞는지 검토 필요
```

#### 디렉토리 구조 설계 체크리스트

- [ ] 특정 기능을 삭제할 때, 몇 개의 폴더를 확인해야 하는가? (1개가 이상적)
- [ ] 새 기능을 추가할 때, 어디에 파일을 만들어야 할지 명확한가?
- [ ] 관련 없는 기능끼리 같은 폴더에 섞여 있지 않은가?
- [ ] 공통 모듈과 도메인 모듈의 경계가 명확한가?

### 4.2 폼의 응집도

폼 검증은 **필드 레벨**과 **폼 레벨** 두 가지 접근 방식이 있습니다.

#### 필드 레벨 응집도

각 필드가 독립적으로 검증 로직을 관리합니다.

```tsx
// react-hook-form 개별 validate
function SignupForm() {
  const { register, handleSubmit } = useForm();

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input
        {...register("name", {
          validate: (value) => value.length > 0 || "이름을 입력해주세요",
        })}
      />
      <input
        {...register("email", {
          validate: (value) =>
            /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) || "올바른 이메일 형식이 아닙니다",
        })}
      />
    </form>
  );
}
```

**장점**: 필드별 수정 범위 최소화, 재사용성 높음

#### 폼 레벨 응집도

모든 검증 로직을 스키마로 중앙 관리합니다.

```tsx
// Zod 스키마 + zodResolver
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";

const signupSchema = z.object({
  name: z.string().min(1, "이름을 입력해주세요"),
  email: z.string().email("올바른 이메일 형식이 아닙니다"),
  password: z.string().min(8, "비밀번호는 8자 이상이어야 합니다"),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "비밀번호가 일치하지 않습니다",
  path: ["confirmPassword"],
});

function SignupForm() {
  const { register, handleSubmit } = useForm({
    resolver: zodResolver(signupSchema),
  });
  // ...
}
```

**장점**: 검증 로직 중앙 관리, 필드 간 의존성 처리 용이

#### 선택 기준

| 상황 | 권장 접근법 |
|-----|-----------|
| 복잡한 비동기 검증 (이메일 중복 확인 등) | 필드 레벨 |
| 필드 재사용이 많은 경우 | 필드 레벨 |
| 단일 목적 폼 (결제, 로그인) | 폼 레벨 |
| 필드 간 의존성 (비밀번호 확인) | 폼 레벨 |
| 단계별 폼 (wizard) | 폼 레벨 |

---

## 5. 결합도 (Coupling)

**정의**: 코드 수정 시 영향 범위를 최소화하는 구조

> 결합도가 낮을수록 한 곳을 수정해도 다른 곳에 미치는 영향이 적습니다.
> 수정 영향을 예측하기 쉬워 안전하게 변경할 수 있습니다.

### 5.1 책임을 하나씩 관리

여러 책임을 가진 훅은 수정 시 영향 범위가 넓어집니다.

```tsx
// Before: 모든 쿼리 파라미터를 한 훅에서 관리
export function usePageState() {
  const [query, setQuery] = useQueryParams({
    cardId: NumberParam,
    statementId: NumberParam,
    dateFrom: DateParam,
    dateTo: DateParam,
    statusList: ArrayParam,
  });

  return useMemo(
    () => ({
      values: {
        cardId: query.cardId ?? undefined,
        statementId: query.statementId ?? undefined,
        dateFrom: query.dateFrom ?? defaultDateFrom,
        dateTo: query.dateTo ?? defaultDateTo,
        statusList: query.statusList as StatementStatusType[],
      },
      controls: {
        setCardId: (id: number) => setQuery({ cardId: id }),
        setStatementId: (id: number) => setQuery({ statementId: id }),
        // ...
      },
    }),
    [query, setQuery]
  );
}
```

**문제점**:
- 훅의 책임 범위가 무한정 확장될 수 있음
- 하나의 파라미터만 사용하는 컴포넌트도 전체 훅에 의존
- 어떤 파라미터가 변경되어도 모든 사용처가 리렌더링

```tsx
// After: 각 파라미터별 개별 훅
export function useCardIdQueryParam() {
  const [cardId, setCardId] = useQueryParam("cardId", NumberParam);

  const updateCardId = useCallback(
    (id: number) => setCardId(id, "replaceIn"),
    [setCardId]
  );

  return [cardId ?? undefined, updateCardId] as const;
}

export function useDateRangeQueryParam() {
  const [dateFrom, setDateFrom] = useQueryParam("dateFrom", DateParam);
  const [dateTo, setDateTo] = useQueryParam("dateTo", DateParam);

  // dateFrom과 dateTo는 함께 수정되는 경우가 많으므로 하나의 훅으로 관리
  return {
    dateFrom: dateFrom ?? defaultDateFrom,
    dateTo: dateTo ?? defaultDateTo,
    setDateRange: useCallback(
      (from: Date, to: Date) => {
        setDateFrom(from, "replaceIn");
        setDateTo(to, "replaceIn");
      },
      [setDateFrom, setDateTo]
    ),
  };
}
```

**개선 효과**:
- 각 훅의 책임 범위 명확화
- 필요한 파라미터만 구독하여 리렌더링 최적화
- 수정 시 영향 범위 최소화

### 5.2 성급한 공통화 피하기 (중복 허용)

> **성급한 공통화보다 변경 가능성을 고려한 의미 있는 단위 분리**가 중요합니다.

과도한 추상화는 오히려 결합도를 높일 수 있습니다.
"DRY(Don't Repeat Yourself)" 원칙을 맹목적으로 따르면, 오히려 유지보수가 어려워질 수 있습니다.

#### 성급한 공통화의 징후

```tsx
// ❌ 성급한 공통화: 조건문이 점점 늘어나는 공통 컴포넌트
function CommonButton({
  variant,
  page,
  isHome,
  isCheckout,
  showIcon,
  // ... 점점 늘어나는 props
}: Props) {
  const getStyle = () => {
    if (page === 'home' && isCheckout) return homeCheckoutStyle;
    if (page === 'product' && showIcon) return productIconStyle;
    // ... 끝없는 조건문
  };

  return <button style={getStyle()}>{/* ... */}</button>;
}

// ✅ 각 페이지에 맞는 버튼을 개별 구현
function HomeButton() { /* ... */ }
function ProductButton() { /* ... */ }
function CheckoutButton() { /* ... */ }
```

#### 공통화 시점 판단 기준

| 질문 | Yes → 공통화 | No → 중복 허용 |
|-----|-------------|---------------|
| 동작이 **완전히** 동일한가? | ✅ | ❌ |
| 향후 변경 시 **모든 곳에서 동일하게** 변경되어야 하는가? | ✅ | ❌ |
| 공통화 시 조건문이 **3개 이상** 필요한가? | ❌ | ✅ |
| 각 사용처에서 **미세한 차이**가 있거나 생길 예정인가? | ❌ | ✅ |

```tsx
// Before: 모든 페이지에서 공유하는 훅
function useOpenMaintenanceBottomSheet() {
  const { maintenance } = useSystemStatus();
  const { openBottomSheet, closeBottomSheet } = useBottomSheet();
  const { exitCurrentScreen } = useNavigation();

  useEffect(() => {
    if (maintenance.isActive) {
      openBottomSheet({
        content: <MaintenanceNotice />,
        onConfirm: () => {
          logging.log("maintenance_confirmed");
          closeBottomSheet();
          exitCurrentScreen();
        },
      });
    }
  }, [maintenance.isActive]);
}
```

**문제점**:
- 페이지마다 로깅 값이 다를 수 있음
- 일부 페이지는 화면 종료를 원하지 않을 수 있음
- 훅 수정 시 모든 사용처 테스트 필요

**해결 방안**:
- 동작이 완전히 동일하고 향후 변경이 없을 때만 통합
- 미세한 차이가 있다면 중복을 허용

```tsx
// After: 각 페이지에서 개별 구현
function HomePage() {
  const { maintenance } = useSystemStatus();
  const { openBottomSheet } = useBottomSheet();

  useEffect(() => {
    if (maintenance.isActive) {
      openBottomSheet({
        content: <MaintenanceNotice />,
        onConfirm: () => {
          logging.log("home_maintenance_confirmed");
          // 이 페이지는 화면 종료 안 함
        },
      });
    }
  }, [maintenance.isActive]);
}
```

**추상화 vs 중복 판단 기준**:
| 상황 | 권장 |
|-----|-----|
| 동작이 완전히 동일, 변경 가능성 낮음 | 추상화 |
| 미세한 차이 존재 또는 변경 가능성 있음 | 중복 허용 |
| 추상화 시 조건문이 많아짐 | 중복 허용 |

### 5.3 Props Drilling 제거

Props가 여러 단계를 거쳐 전달되면 결합도가 높아집니다.

```tsx
// Before: Props Drilling
function ItemEditModal({
  keyword,
  items,
  recommendedItems,
  onConfirm,
  onClose,
}: Props) {
  return (
    <Modal onClose={onClose}>
      <ItemEditBody
        keyword={keyword}
        items={items}
        recommendedItems={recommendedItems}
        onConfirm={onConfirm}
      />
    </Modal>
  );
}

function ItemEditBody({ keyword, items, recommendedItems, onConfirm }: BodyProps) {
  return (
    <div>
      <SearchInput value={keyword} />
      <ItemEditList items={items} recommendedItems={recommendedItems} />
      <Button onClick={onConfirm}>확인</Button>
    </div>
  );
}
```

**문제점**: `recommendedItems` 제거 시 3개 파일 수정 필요

```tsx
// After: Composition 패턴
function ItemEditModal({ onClose, children }: ModalProps) {
  return <Modal onClose={onClose}>{children}</Modal>;
}

// 사용처에서 직접 구성
<ItemEditModal onClose={handleClose}>
  <SearchInput value={keyword} />
  <ItemEditList items={items} />
  <RecommendedItems items={recommendedItems} />
  <Button onClick={handleConfirm}>확인</Button>
</ItemEditModal>
```

**Context 사용 시점**:
- Props가 3단계 이상 전달될 때
- 여러 컴포넌트가 동일한 데이터를 필요로 할 때
- Composition으로 해결하기 어려운 구조일 때

---

## 6. 상수와 매직 넘버 (통합 섹션)

매직 넘버는 **가독성**과 **응집도** 두 관점에서 문제가 됩니다.

### 매직 넘버란?
의미를 명시하지 않고 코드에 직접 삽입된 숫자값입니다.

```tsx
// Before: 매직 넘버
async function onLikeClick() {
  await postLike(url);
  await delay(300); // 300이 무엇을 의미하는지 불명확
  await refetchPostLike();
}
```

### 가독성 관점
`300`이 무엇을 의미하는지 알 수 없습니다:
- 애니메이션 완료 대기 시간?
- API 응답 대기 시간?
- 테스트용 코드?

### 응집도 관점
애니메이션 시간이 변경되면:
- CSS의 애니메이션 duration 수정
- JavaScript의 delay 값 수정

두 곳을 함께 수정해야 하는데, `300`이라는 숫자만으로는 관계를 파악하기 어렵습니다.

```tsx
// After: 상수로 정의
const ANIMATION_DELAY_MS = 300;

async function onLikeClick() {
  await postLike(url);
  await delay(ANIMATION_DELAY_MS);
  await refetchPostLike();
}
```

### 상수 정의 위치 가이드

| 사용 범위 | 위치 |
|----------|-----|
| 단일 파일 | 파일 상단 |
| 단일 도메인 | `domains/[domain]/constants.ts` |
| 전역 | `src/constants/` |

### 상수 정의 방식 선택

```tsx
// 1. const: 단순 값
const MAX_RETRY_COUNT = 3;
const API_TIMEOUT_MS = 5000;

// 2. as const: 객체/배열의 리터럴 타입 유지
const STATUS = {
  PENDING: "pending",
  SUCCESS: "success",
  ERROR: "error",
} as const;

// 3. enum: 관련 상수 그룹화 (TypeScript)
enum HttpStatus {
  OK = 200,
  NOT_FOUND = 404,
  SERVER_ERROR = 500,
}
```

**선택 기준**:
- 단순 값 → `const`
- 객체/배열 + 타입 추론 필요 → `as const`
- 관련 상수 그룹 + IDE 자동완성 → `enum`

---

## 7. 원칙 간 상충 관계

### 가독성 vs 응집도

**시나리오**: 두 컴포넌트에서 동일한 계산 로직 사용

```tsx
// 가독성 우선: 각 컴포넌트에 로직 직접 작성
function ComponentA() {
  const price = basePrice * (1 - discount);
  // ...
}

function ComponentB() {
  const price = basePrice * (1 - discount);
  // ...
}
```

```tsx
// 응집도 우선: 공통 함수로 추출
function calculatePrice(basePrice: number, discount: number) {
  return basePrice * (1 - discount);
}

function ComponentA() {
  const price = calculatePrice(basePrice, discount);
  // ...
}
```

**판단 기준**:
- 로직이 단순하고 변경 가능성 낮음 → 가독성 우선 (중복 허용)
- 로직이 복잡하거나 변경 시 동기화 필요 → 응집도 우선 (추상화)

### 결합도 vs DRY (Don't Repeat Yourself)

**시나리오**: 여러 페이지에서 유사한 에러 처리

| 선택 | 장점 | 단점 |
|-----|-----|-----|
| 공통 훅으로 추상화 | 중복 제거 | 결합도 증가, 수정 영향 범위 확대 |
| 각 페이지에서 개별 구현 | 결합도 낮음, 독립적 수정 가능 | 중복 코드 |

### 우선순위 의사결정 트리

```
수정 시 함께 변경되어야 하는가?
├─ Yes → 응집도 우선 (추상화)
└─ No
    └─ 독립적으로 변경될 가능성이 있는가?
        ├─ Yes → 결합도 우선 (중복 허용)
        └─ No → 가독성 우선 (상황에 맞게)
```

---

## 8. 최적화 원칙

> 프로파일링을 통한 **객관적 수치 측정**이 선행되어야 합니다.
> 단순한 속도 향상을 넘어 **'전략적 균형'과 '사용자 경험 극대화'**가 목표입니다.

### 8.1 측정 기반 최적화

**"추측하지 말고, 측정하라"** - 최적화는 반드시 데이터에 기반해야 합니다.

```tsx
// ❌ 나쁜 예: 추측 기반 최적화
// "이 컴포넌트가 느릴 것 같으니까 useMemo로 감싸자"
const MemoizedComponent = useMemo(() => <Component />, []);

// ✅ 좋은 예: 측정 기반 최적화
// 1. React DevTools Profiler로 실제 렌더링 시간 측정
// 2. 병목 지점 확인 후 해당 부분만 최적화
// 3. 최적화 후 다시 측정하여 효과 검증
```

#### 핵심 지표

| 지표 | 설명 | 측정 도구 |
|-----|-----|----------|
| **P99 응답시간** | 99%의 사용자가 경험하는 최대 응답시간 | Lighthouse, Web Vitals |
| **FCP (First Contentful Paint)** | 첫 콘텐츠가 화면에 그려지는 시간 | Chrome DevTools |
| **LCP (Largest Contentful Paint)** | 가장 큰 콘텐츠가 화면에 그려지는 시간 | Web Vitals |
| **TTI (Time to Interactive)** | 사용자가 상호작용 가능한 시점 | Lighthouse |
| **Bundle Size** | JavaScript 번들 크기 | webpack-bundle-analyzer |

### 8.2 번들 최적화

초기 로딩 속도 개선의 핵심은 **번들 사이즈 감소**입니다.

```tsx
// 1. 동적 임포트 (코드 스플리팅)
const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyComponent />
    </Suspense>
  );
}

// 2. Tree Shaking을 위한 Named Export
// ❌ import lodash from 'lodash'; // 전체 번들 포함
// ✅ import { debounce } from 'lodash-es'; // 필요한 함수만

// 3. 조건부 로딩
const AdminPanel = lazy(() =>
  user.isAdmin ? import('./AdminPanel') : Promise.resolve({ default: () => null })
);
```

### 8.3 렌더링 최적화

```tsx
// 1. 불필요한 리렌더링 방지
const MemoizedChild = memo(ChildComponent);

// 2. 무거운 계산 캐싱
const expensiveValue = useMemo(() => {
  return heavyCalculation(data);
}, [data]);

// 3. 콜백 안정성 확보
const handleClick = useCallback(() => {
  onClick(id);
}, [id, onClick]);

// 4. 상태 분리 (세밀한 구독)
// ❌ 전체 상태를 구독
const { user, products, cart } = useStore();

// ✅ 필요한 상태만 구독
const user = useStore(state => state.user);
```

### 8.4 최적화 우선순위

```
최적화 전 체크리스트:
1. 성능 문제가 실제로 존재하는가? (측정)
2. 사용자 경험에 영향을 주는가?
3. 최적화 비용 대비 효과가 있는가?

우선순위:
├─ [높음] 초기 로딩 속도 (번들 사이즈, 코드 스플리팅)
├─ [높음] 핵심 사용자 경험 (메인 인터랙션 응답 속도)
├─ [중간] 반복적인 작업의 성능 (리스트 렌더링, 검색)
└─ [낮음] 드물게 사용되는 기능의 성능
```

### 8.5 최적화 안티패턴

```tsx
// ❌ 모든 곳에 useMemo/useCallback 남발
// → 오히려 메모리 사용량 증가, 코드 복잡도 증가

// ❌ 측정 없이 "느릴 것 같아서" 최적화
// → 실제 병목이 아닌 곳에 시간 낭비

// ❌ 미시 최적화에 집중 (0.1ms → 0.05ms)
// → 사용자는 차이를 느끼지 못함

// ❌ 가독성을 크게 해치는 최적화
// → 유지보수 비용이 성능 이득보다 클 수 있음
```

---

## 9. AI Agent 실전 가이드

### 9.1 컴포넌트 생성 체크리스트

#### 코드 크기 제한 (필수)
- [ ] **파일 크기**: 200-400줄 권장, **800줄 초과 금지**
- [ ] **함수 크기**: **50줄 초과 금지**
- [ ] **중첩 깊이**: **4단계 초과 금지**

#### 가독성
- [ ] 조건부 렌더링이 3개 이상인가? → 컴포넌트 분리 검토
- [ ] JSX 내 복잡한 조건문이 있는가? → 변수로 추출하고 이름 부여
- [ ] 중첩 삼항 연산자가 있는가? → if문 또는 early return으로 변경
- [ ] 인증/권한 체크 로직이 노출되어 있는가? → Guard 컴포넌트로 추상화

#### 예측가능성
- [ ] 컴포넌트명이 역할을 명확히 설명하는가?
- [ ] Props 이름이 일관성 있는가? (예: `onXxx`는 이벤트 핸들러)
- [ ] 부수 효과가 컴포넌트 외부에서 예측 가능한가?

#### 응집도
- [ ] 관련 컴포넌트가 같은 디렉토리에 있는가?
- [ ] 매직 넘버가 있는가? → 상수로 정의

#### 결합도
- [ ] Props가 3단계 이상 전달되는가? → Composition 또는 Context 검토
- [ ] 불필요하게 많은 Props를 받고 있는가? → 필요한 것만 전달

### 9.2 훅 생성 체크리스트

#### 가독성
- [ ] 훅 이름이 반환값을 명확히 설명하는가?
- [ ] 복잡한 로직에 주석 또는 명확한 변수명이 있는가?

#### 예측가능성
- [ ] 유사한 훅과 반환 타입이 일관되는가?
- [ ] 숨겨진 부수 효과가 없는가? (로깅, API 호출 등)

#### 응집도
- [ ] 관련 훅이 같은 디렉토리에 있는가?

#### 결합도
- [ ] 훅이 여러 책임을 담당하는가? → 분리 검토
- [ ] 훅 수정 시 영향 범위가 예측 가능한가?

### 9.3 코드 리뷰 체크리스트

| 원칙 | 확인 항목 |
|-----|----------|
| **가독성** | 한 번에 이해할 수 있는가? 시점 이동이 적은가? |
| **예측가능성** | 이름만으로 동작을 알 수 있는가? 숨은 로직이 없는가? |
| **응집도** | 관련 코드가 함께 있는가? 수정 시 누락 위험이 없는가? |
| **결합도** | 수정 영향 범위가 적절한가? 불필요한 의존성이 없는가? |

### 9.4 코드 완성 체크리스트

코드 작성 완료 전 다음 항목을 확인합니다:

```
✅ 필수 확인사항:
- [ ] 파일 800줄 이하
- [ ] 함수 50줄 이하
- [ ] 중첩 4단계 이하
- [ ] 가독성 높은 명확한 네이밍
- [ ] 적절한 오류 처리
- [ ] console.log 제거
- [ ] 하드코딩된 값 없음 (상수 사용)
- [ ] 불변 패턴 적용 (객체 수정 대신 새 객체 생성)
```

---

## 참고 자료

- [Frontend Fundamentals - Code Quality](https://frontend-fundamentals.com/code-quality/code/)
- [Frontend Fundamentals - English Version](https://frontend-fundamentals.com/code-quality/en/code/)
- 토스 모닥불 시리즈:
  - EP.8: 기술 선택의 정당성 - "왜" 그 기술을 선택했는지에 대한 논리적 근거
  - EP.9: 프론트엔드 서비스 최적화 - 측정 기반 접근, P99 지표, 번들 최적화
  - EP.10: 폴더 구조와 추상화 - "지우기 쉬운 구조", 성급한 공통화 피하기
