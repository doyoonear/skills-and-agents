---
name: react-refactoring
description: |
  React 컴포넌트 코드 분석 및 리팩토링. 코드 품질 개선, 클린 코드 변환, URL 상태 리팩토링, CSS/반응형 리팩토링, 최적화 수행.
  Use when refactoring React components, improving code quality, URL 상태 리팩토링, searchParams 리팩토링, useState를 URL로, TanStack Query queryKey 개선, loaderDeps 개선, CSS 브레이크포인트 리팩토링, container query 전환, responsive layout 개선, or when user mentions "리팩토링", "코드 개선", "코드 정리", "코드 최적화", "반응형 개선", "브레이크포인트 줄이기", "refactor".
  Not for removing unused code (use refactor-clean) or architecture redesign (use component-architecture).
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
| 1 | URL 상태 관리 | useState + useEffect로 관리하는 재현 가능 UI 상태를 URL searchParams로 변경 | 높음 |
| 2 | URL/Form/Server state 경계 분리 | URL은 확정 조건, form은 draft, query/loader는 서버 캐시로 분리 | 높음 |
| 3 | search params 기반 queryKey 구성 | 필터/페이지 변경 시 TanStack Query queryKey도 함께 변경 | 높음 |
| 4 | route-level search validation | 컴포넌트별 parsing 대신 route boundary에서 검증 | 높음 |
| 5 | setState 내부 side effect 분리 | setState updater 함수 내부의 side effect를 외부로 분리 | 높음 |
| 6 | 중복 핸들러 통합 | 동일한 로직의 핸들러 함수들을 하나로 통합 | 높음 |
| 7 | 중복 로직 useMemo 추출 | 여러 곳에서 반복되는 계산 로직을 useMemo로 추출 | 높음 |
| 8 | canonical URL 정규화 | 내부 fallback과 URL 불일치를 줄이기 위해 표준 URL 표현으로 정규화 | 중간 |
| 9 | 타입 가드 함수 적용 | 반복되는 타입 캐스팅(as)을 타입 가드 함수로 개선 | 중간 |
| 10 | Zustand 셀렉터 최적화 | 컴포넌트 내에서 액션만 사용 시 직접 export된 actions 사용 | 중간 |
| 11 | 유틸리티 함수 추출 | 반복되는 패턴(Toast 표시 등)을 유틸리티 함수로 추출 | 중간 |
| 12 | 조건부 비활성화 처리 | 빈 상태, 로딩 상태 등에서 버튼/액션 비활성화 | 중간 |
| 13 | 성공 후 정리 로직 추가 | 작업 성공 후 필요한 정리 로직(clearCart 등) 누락 확인 | 중간 |
| 14 | 컴포넌트 분리 | 큰 컴포넌트에서 독립적인 UI 단위를 별도 컴포넌트로 분리 | 중간 |
| 15 | CSS 브레이크포인트 리팩토링 | 뷰포트 미디어 쿼리 중심 스타일을 `clamp()`, intrinsic layout, container query로 전환 | 중간 |
| 16 | 불필요한 래퍼 함수 제거 | 단순히 다른 함수를 호출하기만 하는 래퍼 함수 제거 | 낮음 |
| 17 | 타입 개선 | 암묵적 any 제거, 더 정확한 타입 사용 | 낮음 |
| 18 | 불필요한 코멘트 제거 | 코드로 이미 명확한 내용을 설명하는 코멘트 제거 | 낮음 |
| 19 | 코드 스페이싱 정리 | 객체 내부나 JSX에서 불필요한 빈 줄 제거 | 낮음 |

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

### 0. CSS 브레이크포인트 리팩토링

반응형 UI 리팩토링은 `@media`를 모두 제거하는 작업이 아닙니다. 뷰포트 기준 분기를 기본 엔진으로 쓰던 코드를 컴포넌트가 가진 실제 공간 기준으로 바꾸는 작업입니다.

#### 적용 판단 기준

우선 기존 `@media` 규칙을 아래 네 가지로 분류합니다.

| 분류 | 예시 | 리팩토링 방향 |
|------|------|---------------|
| 스칼라 변경 | font-size, padding, gap, radius | `clamp()`, `min()`, `max()`, fluid token |
| 자연 배치 | card grid, product list, gallery | `auto-fit`, `auto-fill`, `minmax()` |
| 구조 변경 | sidebar card vs main card, compact/expanded | `container-type`, `@container` |
| 환경 대응 | hover, pointer, reduced-motion, color-scheme | `@media` 유지 |

#### Before: viewport breakpoint 중심

```css
.product-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

@media (min-width: 768px) {
  .product-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
  }
}

@media (min-width: 1024px) {
  .product-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;
  }
}
```

#### After: intrinsic layout + fluid scalar

```css
.product-grid {
  display: grid;
  gap: clamp(1rem, 2vw, 1.5rem);
  grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
}
```

#### 컨테이너 기준 컴포넌트 전환

같은 컴포넌트가 사이드바, 모달, 본문에 재사용된다면 뷰포트보다 컨테이너 기준이 적합합니다.

```css
.article-card-shell {
  container-type: inline-size;
}

.article-card {
  padding: clamp(1rem, 5cqi, 2rem);
  border-radius: clamp(0.5rem, 4cqi, 1.5rem);
}

.article-card__body {
  display: grid;
  gap: 1rem;
}

@container (min-width: 36rem) {
  .article-card__body {
    grid-template-columns: 12rem 1fr;
    align-items: center;
  }
}
```

#### 리팩토링 체크리스트

- [ ] `@media`가 레이아웃 분기인지, 환경 대응인지 먼저 분리합니다.
- [ ] 폰트/간격/패딩/radius 단계 조정은 `clamp()`, `min()`, `max()`로 바꿉니다.
- [ ] 고정 열 수 그리드는 `repeat(auto-fit|auto-fill, minmax(..., 1fr))`로 바꿀 수 있는지 확인합니다.
- [ ] 재사용 컴포넌트에는 필요한 경우 `container-type: inline-size`를 추가합니다.
- [ ] 내부 구조 변경에만 `@container`를 사용합니다.
- [ ] `@media`는 페이지 셸 전환, hover/pointer, reduced-motion, color-scheme, contrast 같은 환경 대응에 남깁니다.
- [ ] 사이드바, 모달, 본문, 모바일 폭에서 같은 컴포넌트를 확인합니다.

#### 피해야 할 패턴

- 컴포넌트 내부 레이아웃을 전역 `768px`, `1024px` 기준에 강하게 묶기
- 단순 spacing 조정마다 breakpoint 추가하기
- `vw`로 재사용 컴포넌트 크기를 계산해 사이드바/모달에서 과도하게 커지게 만들기
- `@container`로 해결할 문제와 `clamp()`로 해결할 문제를 구분하지 않기

### 1. URL 상태 관리

검색어, 필터, 정렬, 페이지네이션처럼 URL로 다시 열었을 때 같은 화면이 재현되어야 하는 상태는 React state보다 URL search params를 원천으로 둡니다.

#### 적용 판단 기준

URL state로 옮기기 좋은 상태:

- 검색어: `keyword`
- 필터: `status`, `category`, `startDate`, `endDate`
- 정렬: `sort`
- 페이지네이션: `page`, `pageSize`
- 탭 또는 뷰 모드: `view`

URL state로 옮기지 않는 상태:

- hover, popover open 여부 같은 일시적 UI 상태
- submit 전 입력 중인 form draft
- 서버 응답 데이터 자체
- URL에 노출하면 안 되는 민감 정보

#### URL / Form / Server state 분리

| 상태 | 역할 | 저장 위치 |
|------|------|----------|
| URL state | 현재 결과 화면을 결정하는 확정 조건 | search params |
| Form state | 사용자가 입력 중인 draft | React Hook Form 또는 local state |
| Server state | URL 조건으로 가져온 서버 응답 | TanStack Query cache 또는 loader data |

submit 기반 검색 화면에서는 form 값으로 직접 refetch하지 말고, submit 시 URL을 바꿔서 queryKey 또는 loaderDeps가 자연스럽게 바뀌게 만듭니다.

#### Before: local state와 effect로 화면 조건 관리

```tsx
const [activeCategory, setActiveCategory] = useState('')

useEffect(() => {
  if (categories.length > 0 && !activeCategory) {
    setActiveCategory(categories[0])
  }
}, [categories, activeCategory])
```

문제점:

- 새로고침하면 상태가 사라집니다.
- 뒤로 가기와 공유 링크가 화면 상태를 재현하지 못합니다.
- 기본값이 URL에 드러나지 않아 실제 URL과 내부 상태가 달라질 수 있습니다.

#### After: React Router search params 사용

```tsx
import { useSearchParams } from 'react-router-dom'

const [searchParams, setSearchParams] = useSearchParams()
const categoryParam = searchParams.get('category')
const activeCategory = categoryParam ?? categories[0] ?? ''

const handleCategoryChange = (category: string) => {
  setSearchParams({ category })
}
```

#### route-level search validation

URL은 사용자가 직접 수정할 수 있는 문자열 입력입니다. 컴포넌트마다 `searchParams.get()`과 fallback을 반복하지 말고, route 또는 page boundary에서 검증된 search object로 바꿉니다.

```tsx
const usersSearchSchema = z.object({
  keyword: z.string().default(''),
  status: z.enum(['all', 'active', 'inactive']).default('all'),
  page: z.coerce.number().int().min(1).default(1),
})

function parseUsersSearch(searchParams: URLSearchParams) {
  return usersSearchSchema.parse({
    keyword: searchParams.get('keyword') ?? undefined,
    status: searchParams.get('status') ?? undefined,
    page: searchParams.get('page') ?? undefined,
  })
}
```

leaf 컴포넌트는 `URLSearchParams`를 직접 파싱하지 않고, 검증된 값을 props나 route hook으로 받도록 리팩토링합니다.

#### TanStack Router 리팩토링 예시

```tsx
export const Route = createFileRoute('/admin/users')({
  validateSearch: usersSearchSchema,
  loaderDeps: ({ search }) => ({
    keyword: search.keyword,
    status: search.status,
    page: search.page,
  }),
  loader: ({ deps, context }) => {
    return context.queryClient.fetchQuery(usersQueryOptions(deps))
  },
  component: UsersPage,
})

function UsersPage() {
  const search = Route.useSearch()
  const navigate = Route.useNavigate()
  const form = useForm({ defaultValues: search })

  const onSubmit = form.handleSubmit((values) => {
    navigate({ search: (prev) => ({ ...prev, ...values, page: 1 }) })
  })

  return <UsersSearchForm form={form} onSubmit={onSubmit} />
}
```

핵심은 `validateSearch → loaderDeps → queryKey/server fetch` 흐름을 단방향으로 만드는 것입니다.

#### TanStack Query queryKey 연결

search params가 서버 요청 조건이면 queryKey에도 반드시 포함합니다.

```tsx
function usersQueryOptions(search: UsersSearch) {
  return queryOptions({
    queryKey: ['users', search],
    queryFn: () => fetchUsers(search),
  })
}
```

잘못된 예:

```tsx
const usersQuery = useQuery({
  queryKey: ['users'],
  queryFn: () => fetchUsers({ status, page }),
})
```

`status`, `page`가 바뀌어도 queryKey가 같으면 캐시와 refetch 흐름을 추론하기 어렵습니다.

#### mutation 이후 재검증

| API | 역할 |
|-----|------|
| `fetchQuery` | stale 여부를 고려해 fetch하고 결과를 반환합니다. 최신 fetch가 중요한 loader 흐름에 적합합니다. |
| `ensureQueryData` | 캐시가 있으면 우선 반환하고, 없으면 fetch합니다. stale 데이터를 즉시 반환할 수 있음을 고려합니다. |
| `invalidateQueries` | query를 stale로 표시하고 활성 query를 background refetch하게 합니다. |
| `router.invalidate` / `useRevalidator` | 라우트 loader 데이터를 다시 검증합니다. |

mutation 후에는 query cache만 invalidate할지, route loader까지 revalidate할지 명확히 정합니다.

#### canonical URL 정규화

내부 fallback이 URL과 다른 숨은 상태를 만들면 안 됩니다.

```txt
/users
```

내부에서만 `page = 1`, `keyword = ''`로 취급하면 실제 URL과 앱 상태가 다릅니다. URL을 SSOT로 삼는 화면에서는 다음 중 하나를 표준으로 정합니다.

- 기본값을 URL에서 생략하는 것을 표준으로 삼기
- `/users?page=1&keyword=`처럼 명시하는 것을 표준으로 삼고 route boundary에서 redirect하기

중요한 것은 같은 화면 상태가 여러 URL로 표현되지 않게 하는 것입니다.

#### 피해야 할 패턴

- 컴포넌트마다 search params parsing과 defaulting을 반복
- URL state를 zustand/context/local state에 복사해 또 다른 truth로 관리
- form `watch` 값을 submit 전부터 서버 queryKey로 사용
- search params 변경 없이 수동 refetch로 화면 조건 변경
- loader에서 `URLSearchParams`를 임의로 읽고 `loaderDeps`에는 누락

**장점:**

- 새로고침해도 상태 유지
- 뒤로 가기 동작 지원
- URL 공유와 QA 재현 가능
- query cache와 loader dependency를 명확하게 추적 가능

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
