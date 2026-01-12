---
name: react-refactoring
description: |
  React 컴포넌트 코드를 분석하고 개선점을 찾아 리팩토링합니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "리팩토링해줘"
  - "코드 개선해줘"
  - "코드 정리해줘"
  - "코드 최적화해줘"
  - "클린 코드로 바꿔줘"
  - "코드 품질 개선해줘"
  - "refactor"
---

# React Refactoring Skill

React 컴포넌트의 코드를 분석하고, 개선 가능한 패턴을 찾아 순차적으로 리팩토링하는 skill입니다.

## 워크플로우

### 1단계: 대상 파일/범위 확인

사용자에게 리팩토링 대상을 확인하세요:
- 특정 파일이 지정되었는지
- 특정 디렉토리 범위인지
- 프로젝트 전체인지

### 2단계: 코드 분석

대상 코드를 읽고 다음 리팩토링 패턴들을 체크하세요:

#### 체크리스트

| # | 패턴 | 설명 | 우선순위 |
|---|------|------|----------|
| 1 | URL 상태 관리 | useState + useEffect로 관리하는 UI 상태를 URL searchParams로 변경 | 높음 |
| 2 | setState 내부 side effect 분리 | setState updater 함수 내부의 side effect를 외부로 분리 | 높음 |
| 3 | 중복 핸들러 통합 | 동일한 로직의 핸들러 함수들을 하나로 통합 | 높음 |
| 4 | 중복 로직 useMemo 추출 | 여러 곳에서 반복되는 계산 로직을 useMemo로 추출 | 높음 |
| 5 | 타입 가드 함수 적용 | 반복되는 타입 캐스팅(as)을 타입 가드 함수로 개선 | 중간 |
| 6 | Zustand 셀렉터 최적화 | 컴포넌트 내에서 액션만 사용 시 직접 export된 actions 사용 | 중간 |
| 7 | 유틸리티 함수 추출 | 반복되는 패턴(Toast 표시 등)을 유틸리티 함수로 추출 | 중간 |
| 8 | 조건부 비활성화 처리 | 빈 상태, 로딩 상태 등에서 버튼/액션 비활성화 | 중간 |
| 9 | 성공 후 정리 로직 추가 | 작업 성공 후 필요한 정리 로직(clearCart 등) 누락 확인 | 중간 |
| 10 | 컴포넌트 분리 | 큰 컴포넌트에서 독립적인 UI 단위를 별도 컴포넌트로 분리 | 중간 |
| 11 | 불필요한 래퍼 함수 제거 | 단순히 다른 함수를 호출하기만 하는 래퍼 함수 제거 | 낮음 |
| 12 | 타입 개선 | 암묵적 any 제거, 더 정확한 타입 사용 | 낮음 |
| 13 | 불필요한 코멘트 제거 | 코드로 이미 명확한 내용을 설명하는 코멘트 제거 | 낮음 |
| 14 | 코드 스페이싱 정리 | 객체 내부나 JSX에서 불필요한 빈 줄 제거 | 낮음 |

#### 병렬 분석 전략 (Sub-agent 활용)

분석 대상 규모에 따라 분석 방식을 선택하세요:

**단일/소수 파일 (1~3개):**
- 직접 순차 분석 수행
- Sub-agent 오버헤드가 더 클 수 있음

**다수 파일 (4개 이상) 또는 프로젝트 전체:**
- Task tool로 Explore sub-agent를 병렬 호출하여 분석 시간 단축
- 각 agent가 독립적인 컨텍스트에서 작업하므로 메인 컨텍스트 보존

**병렬 분석 예시:**
```
# 3개의 Explore agent를 동시에 호출
Task 1 (Explore): "src/pages/ 디렉토리의 모든 컴포넌트에서 리팩토링 패턴 체크리스트 분석"
Task 2 (Explore): "src/components/ 디렉토리의 모든 컴포넌트에서 리팩토링 패턴 체크리스트 분석"
Task 3 (Explore): "src/hooks/ 디렉토리의 모든 훅에서 리팩토링 패턴 체크리스트 분석"
```

**주의사항:**
- Explore agent는 읽기 전용 (Haiku 모델, 빠르고 저렴)
- 각 agent에게 체크리스트 패턴을 명시적으로 전달
- 결과를 통합하여 사용자에게 보고

### 3단계: 개선점 보고

분석 결과를 사용자에게 보고하세요:

```
## 분석 결과

### [파일명]

1. **[패턴명]** - [현재 상태 설명]
   - 현재: [현재 코드 요약]
   - 개선: [개선 방향]

2. **[패턴명]** - [현재 상태 설명]
   ...
```

### 4단계: 순차적 리팩토링 및 커밋

**중요: 여러 개의 리팩토링을 진행할 때, 각 로직별로 커밋을 찍으면서 순차적으로 진행합니다.**

각 리팩토링 항목마다:
1. 해당 패턴의 코드 변경 수행
2. 변경사항에 대한 커밋 생성
3. 다음 리팩토링으로 이동

커밋 메시지 형식:
```
refactor([scope]): [변경 내용]

- 상세 변경 사항 1
- 상세 변경 사항 2
```

예시:
```
refactor(MenuPage): URL searchParams로 카테고리 상태 관리 변경

- useState + useEffect 제거
- useSearchParams로 카테고리 상태 관리
- 새로고침/뒤로가기 시에도 상태 유지
```

### 5단계: ESLint 실행

모든 리팩토링 완료 후 lint 에러 확인 및 수정:
```bash
yarn eslint <변경된 파일들> --fix
```

---

## 리팩토링 패턴 상세

### 1. URL 상태 관리

**Before:**
```tsx
const [activeCategory, setActiveCategory] = useState('');

useEffect(() => {
  if (categories.length > 0 && !activeCategory) {
    setActiveCategory(categories[0]);
  }
}, [categories, activeCategory]);
```

**After:**
```tsx
import { useSearchParams } from 'react-router-dom';

const [searchParams, setSearchParams] = useSearchParams();
const categoryParam = searchParams.get('category');
const activeCategory = categoryParam ?? categories[0] ?? '';

const handleCategoryChange = (category: string) => {
  setSearchParams({ category });
};
```

**장점:**
- 새로고침해도 상태 유지
- 뒤로가기 동작 지원
- URL 공유 가능

---

### 2. 불필요한 래퍼 함수 제거 / 중복 핸들러 통합

#### 2-1. 불필요한 래퍼 함수 제거

**Before:**
```tsx
const handleRemove = (id: string) => {
  removeItem(id);
};

// JSX
<Button onClick={() => handleRemove(item.id)} />
```

**After:**
```tsx
// JSX
<Button onClick={() => removeItem(item.id)} />
```

#### 2-2. 중복 핸들러 통합

동일한 로직을 가진 핸들러 함수들을 하나로 통합합니다.

**Before:**
```tsx
const handleGridChange = (optionId: number, label: string) => {
  setSelectedOptions(prev => {
    const next = new Map(prev);
    next.set(optionId, [label]);
    return next;
  });
};

const handleSelectChange = (optionId: number, label: string) => {
  setSelectedOptions(prev => {
    const next = new Map(prev);
    next.set(optionId, [label]);
    return next;
  });
};
```

**After:**
```tsx
// 동일한 로직이므로 하나로 통합, 의미를 명확히 하는 네이밍 사용
const handleSingleOptionChange = (optionId: number, label: string) => {
  setSelectedOptions(prev => {
    const next = new Map(prev);
    next.set(optionId, [label]);
    return next;
  });
};
```

**장점:**
- 코드 중복 제거
- 유지보수 용이성 향상
- 로직 변경 시 한 곳만 수정

---

### 3. setState 내부 side effect 분리

React의 setState updater 함수는 순수해야 합니다. side effect(Toast, API 호출 등)는 외부로 분리합니다.

**문제점:**
- React가 StrictMode나 Concurrent 기능에서 updater를 여러 번 호출할 수 있음
- 토스트가 여러 번 표시되는 등의 버그 발생 가능

**Before:**
```tsx
const handleListToggle = (optionId: number, label: string, maxCount: number) => {
  setSelectedOptions(prev => {
    const current = prev.get(optionId) || [];

    if (current.includes(label)) {
      // 제거 로직...
    } else {
      if (current.length >= maxCount) {
        // ⚠️ setState 내부에서 side effect
        overlay.open(({ isOpen, close }) => (
          <Toast isOpen={isOpen} close={close} type="warn" message="최대 선택 갯수입니다" />
        ));
        return prev;
      }
      // 추가 로직...
    }
    return next;
  });
};
```

**After:**
```tsx
const handleListToggle = (optionId: number, label: string, maxCount: number) => {
  const current = selectedOptions.get(optionId) || [];
  const isSelected = current.includes(label);

  // 1. 먼저 조건 체크 및 side effect 처리 (외부에서)
  if (!isSelected && current.length >= maxCount) {
    overlay.open(({ isOpen, close }) => (
      <Toast isOpen={isOpen} close={close} type="warn" message="최대 선택 갯수입니다" />
    ));
    return;
  }

  // 2. 순수한 상태 업데이트만 수행
  setSelectedOptions(prev => {
    const next = new Map(prev);
    const prevCurrent = prev.get(optionId) || [];

    if (prevCurrent.includes(label)) {
      next.set(optionId, prevCurrent.filter(l => l !== label));
    } else if (prevCurrent.length < maxCount) {
      next.set(optionId, [...prevCurrent, label]);
    }
    return next;
  });
};
```

**장점:**
- React 권장 패턴 준수 (updater 순수성)
- StrictMode/Concurrent 환경에서 안전
- side effect 중복 실행 방지

---

### 4. 중복 로직 useMemo 추출

여러 곳에서 동일한 계산 로직이 반복되면 useMemo로 추출하여 재사용합니다.

**Before:**
```tsx
// totalPrice 계산에서
const totalPrice = useMemo(() => {
  const orderOptions = Array.from(selectedOptions.entries())
    .filter(([, labels]) => labels.length > 0)
    .map(([optionId, labels]) => ({ optionId, labels }));

  return calculateTotalPrice(orderOptions);
}, [selectedOptions]);

// handleAddToCart에서 동일 로직 반복
const handleAddToCart = () => {
  const orderOptions = Array.from(selectedOptions.entries())
    .filter(([, labels]) => labels.length > 0)
    .map(([optionId, labels]) => ({ optionId, labels }));

  addItem({ options: orderOptions, ... });
};
```

**After:**
```tsx
// 별도 useMemo로 추출
const orderOptions = useMemo(
  () =>
    Array.from(selectedOptions.entries())
      .filter(([, labels]) => labels.length > 0)
      .map(([optionId, labels]) => ({ optionId, labels })),
  [selectedOptions]
);

// 재사용
const totalPrice = useMemo(() => {
  return calculateTotalPrice(orderOptions);
}, [orderOptions]);

const handleAddToCart = () => {
  addItem({ options: orderOptions, ... });
};
```

**장점:**
- 코드 중복 제거
- 계산 결과 캐싱으로 성능 최적화
- 로직 변경 시 한 곳만 수정

---

### 5. 타입 가드 함수 적용

반복되는 타입 캐스팅(as)을 타입 가드 함수로 개선합니다.

**Before:**
```tsx
// 여러 곳에서 반복되는 타입 캐스팅
if (option.type === 'list') {
  const listOpt = option as ListOption;
  if (selected.length < listOpt.minCount) { ... }
}

// JSX에서도 반복
{option.type === 'list' && (
  <ListOptionRenderer
    option={option as ListOption}
    onToggle={() => handleToggle((option as ListOption).maxCount)}
  />
)}
```

**After:**
```tsx
// 타입 가드 함수 정의
const isListOption = (option: MenuOption): option is ListOption => option.type === 'list';
const isGridOption = (option: MenuOption): option is GridOption => option.type === 'grid';
const isSelectOption = (option: MenuOption): option is SelectOption => option.type === 'select';

// 사용 - TypeScript가 자동으로 타입 추론
if (isListOption(option)) {
  if (selected.length < option.minCount) { ... }  // option이 ListOption으로 추론됨
}

// JSX에서도 깔끔하게
{isListOption(option) && (
  <ListOptionRenderer
    option={option}  // 이미 ListOption 타입
    onToggle={() => handleToggle(option.maxCount)}
  />
)}
```

**장점:**
- 명시적 타입 캐스팅(as) 제거로 타입 안전성 향상
- TypeScript 자동 타입 추론 활용
- 코드 가독성 향상
- 타입 체크 로직 재사용

---

### 6. Zustand 셀렉터 최적화

**Before:**
```tsx
const addItem = useCartStore(state => state.addItem);
const removeItem = useCartStore(state => state.removeItem);
```

**After (store 파일):**
```tsx
// 액션 직접 export (구독 불필요)
export const cartActions = {
  addItem: (item: Omit<CartItem, 'id'>) => useCartStore.getState().addItem(item),
  removeItem: (id: string) => useCartStore.getState().removeItem(id),
};
```

**After (컴포넌트):**
```tsx
import { cartActions } from '../stores/useCartStore';

// 직접 사용
cartActions.removeItem(item.id);
```

**장점:**
- 액션은 상태가 아니므로 불필요한 리렌더링 방지
- 컴포넌트 외부에서도 사용 가능

---

### 7. 유틸리티 함수 추출

**Before:**
```tsx
// 여러 파일에서 반복
overlay.open(({ isOpen, close }) => (
  <Toast isOpen={isOpen} close={close} type="warn" message={error} delay={1500} />
));
```

**After (utils/toast.tsx):**
```tsx
import { overlay } from 'overlay-kit';
import { Toast } from 'tosslib';

type ToastType = 'success' | 'warn' | 'info';

interface ShowToastOptions {
  type?: ToastType;
  delay?: number;
}

export function showToast(message: string, options: ShowToastOptions = {}) {
  const { type = 'warn', delay = 1500 } = options;
  return overlay.open(({ isOpen, close }) => (
    <Toast isOpen={isOpen} close={close} type={type} message={message} delay={delay} />
  ));
}
```

**사용:**
```tsx
import { showToast } from '../utils/toast';

showToast('오류가 발생했습니다');
showToast('성공!', { type: 'success' });
```

---

### 8. 조건부 비활성화 처리

**Before:**
```tsx
<FixedBottomCTA onClick={handleCheckout} disabled={isPending}>
  결제하기
</FixedBottomCTA>
```

**After:**
```tsx
<FixedBottomCTA onClick={handleCheckout} disabled={isPending || items.length === 0}>
  결제하기
</FixedBottomCTA>
```

---

### 9. 성공 후 정리 로직

**Before:**
```tsx
createOrder(orderRequest, {
  onSuccess: data => {
    navigate(`/order-complete/${data.orderId}`);
  },
});
```

**After:**
```tsx
createOrder(orderRequest, {
  onSuccess: data => {
    cartActions.clearCart(); // 장바구니 비우기
    navigate(`/order-complete/${data.orderId}`);
  },
});
```

---

### 10. 컴포넌트 분리

**Before:**
```tsx
function CartPage() {
  // ... 많은 로직

  return (
    <div>
      {items.map(item => (
        <div key={item.id}>
          <ListRow contents={...} />
          <NumericSpinner ... />
        </div>
      ))}
    </div>
  );
}
```

**After:**
```tsx
function CartPage() {
  // ... 페이지 로직만

  return (
    <div>
      {items.map(item => (
        <CartItemRow key={item.id} item={item} />
      ))}
    </div>
  );
}

interface CartItemRowProps {
  item: CartItem;
}

function CartItemRow({ item }: CartItemRowProps) {
  return (
    <div>
      <ListRow contents={...} />
      <NumericSpinner ... />
    </div>
  );
}
```

---

### 11. 타입 개선

**Before:**
```tsx
function handleChange(value: any) {
  setValue(value);
}
```

**After:**
```tsx
function handleChange(value: string) {
  setValue(value);
}
```

---

### 12. 불필요한 코멘트 제거

코드 자체로 의도가 명확한 경우 코멘트는 오히려 노이즈가 됩니다.

#### 제거 대상 코멘트

**1. 함수명/변수명으로 이미 충분한 경우:**
```tsx
// Before
// 역 선택 핸들러
const handleStationSelect = (station: Station) => { ... };

// 뒤로가기 핸들러
const handleBack = () => { ... };

// After
const handleStationSelect = (station: Station) => { ... };
const handleBack = () => { ... };
```

**2. 코드 구조로 명확한 경우:**
```tsx
// Before
interface SearchState {
  // State
  departureStation: string | null;
  arrivalStation: string | null;

  // Actions Namespace
  actions: { ... };
}

// After
interface SearchState {
  departureStation: string | null;
  arrivalStation: string | null;

  actions: { ... };
}
```

**3. 섹션 레이블:**
```tsx
// Before
// Types
export const TRIP_TYPE = { ... };

// Type Guard
export function isTripType(value: string): value is TripType { ... }

// 직접 export된 Actions (hook 없이 사용 가능)
export const searchActions = { ... };

// After
export const TRIP_TYPE = { ... };

export function isTripType(value: string): value is TripType { ... }

export const searchActions = { ... };
```

**4. 제거된 코드에 대한 설명:**
```tsx
// Before
// Note: useSearchActions는 제거됨.
// 액션 사용은 stores에서 직접 export된 searchActions를 사용하세요.

// After
// (코멘트 자체를 삭제)
```

#### 유지해야 할 코멘트

**1. 타입 힌트:**
```tsx
const stationType = searchParams.get('type'); // 'departure' | 'arrival'
```

**2. 긴 JSX 섹션 구분 (선택적):**
```tsx
{/* 출발역 선택 */}
<ListRow ... />

{/* 가는 날 선택 */}
<ListRow ... />
```

**3. 비즈니스 로직의 "왜":**
```tsx
// 편도로 전환 시 오는 날 초기화 (사용자가 왕복 → 편도로 변경하면 오는 날 선택이 의미 없음)
returnDate: tripType === TRIP_TYPE.ONE_WAY ? null : state.returnDate,
```

**4. TODO, FIXME:**
```tsx
// TODO: API 응답 형식 변경 후 수정 필요
// FIXME: 엣지 케이스 처리 필요
```

#### 코멘트 필요성 판단 기준

| 질문 | Yes → 유지 | No → 제거 |
|-----|-----------|----------|
| 코드만 읽고 의도를 파악하기 어려운가? | ✅ | ❌ |
| 비즈니스 규칙이나 "왜"를 설명하는가? | ✅ | ❌ |
| 외부 시스템/API와의 관계를 설명하는가? | ✅ | ❌ |
| 함수명/변수명이 이미 동일한 내용을 전달하는가? | ❌ | ✅ |
| 코드 구조로 이미 명확한가? | ❌ | ✅ |

---

### 14. 코드 스페이싱 정리

JS 코드에서 불필요한 줄 바꿈을 정리합니다.

**허용되는 빈 줄**: 용도별 그룹화 (훅 → 파생 상태 → 핸들러)

**제거해야 할 빈 줄**:
- 객체 리터럴 내부 프로퍼티 사이
- JSX return문 내부 요소 사이

**Before:**
```tsx
export const useStore = create(set => ({
  ...initialState,

  actions: {
    doSomething: () => set({ ... }),

    doAnotherThing: () => set({ ... }),
  },
}));

// JSX도 마찬가지
return (
  <>
    <Header />

    <Content />

    <Footer />
  </>
);
```

**After:**
```tsx
export const useStore = create(set => ({
  ...initialState,
  actions: {
    doSomething: () => set({ ... }),
    doAnotherThing: () => set({ ... }),
  },
}));

// JSX도 연속으로
return (
  <>
    <Header />
    <Content />
    <Footer />
  </>
);
```

**장점:**
- 불필요한 시각적 노이즈 제거
- 객체/JSX는 이미 구조적으로 구분되어 있음
- 코드가 더 compact하고 읽기 쉬워짐

---

## 주의사항

1. **점진적 변경**: 한 번에 모든 것을 바꾸지 말고, 각 패턴별로 순차적으로 진행
2. **커밋 단위**: 각 리팩토링 패턴마다 별도 커밋 생성
3. **테스트 확인**: 변경 후 기능이 정상 동작하는지 확인
4. **기존 패턴 존중**: 프로젝트의 기존 코드 스타일과 패턴을 따름
5. **과도한 추상화 금지**: 한 번만 사용되는 코드는 추출하지 않음
