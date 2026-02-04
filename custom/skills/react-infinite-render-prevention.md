# React 무한 렌더링 방지 가이드

## 개요
React 컴포넌트가 무한히 렌더링되는 현상은 대부분 **상태 업데이트와 useEffect의 잘못된 조합**에서 발생한다. 이 가이드는 무한 렌더링을 예방하는 코드 작성 패턴을 다룬다.

---

## 1. useEffect 의존성 배열 관리

### 객체/배열을 의존성에 포함하지 않기

```tsx
// BAD: 매 렌더링마다 새 객체 생성 → useEffect 무한 실행
useEffect(() => {
  fetchData(filters);
}, [{ search, category }]); // 객체는 매번 새 참조

// GOOD: 프리미티브 값으로 분리
useEffect(() => {
  fetchData({ search, category });
}, [search, category]);
```

### router 객체 전체를 의존성에 넣지 않기

```tsx
// BAD: router 객체는 매 렌더링마다 새 참조 가능
useEffect(() => {
  // ...
}, [router]);

// GOOD: 필요한 속성만 의존성에 포함
useEffect(() => {
  // ...
}, [router.isReady, router.pathname]);
```

---

## 2. 양방향 데이터 동기화 패턴

로컬 상태 ↔ 글로벌 상태(스토어) 간 양방향 동기화 시 순환 발생 주의.

### 문제 패턴

```tsx
// BAD: 순환 루프 발생
const [localValue, setLocalValue] = useState("");
const { storeValue, setStoreValue } = useStore();

// Effect 1: 로컬 → 스토어
useEffect(() => {
  setStoreValue(localValue);
}, [localValue]);

// Effect 2: 스토어 → 로컬
useEffect(() => {
  setLocalValue(storeValue); // 이게 localValue를 변경 → Effect 1 트리거 → 순환
}, [storeValue]);
```

### 해결 방법 1: 조건부 동기화

```tsx
// GOOD: 실제 변경이 있을 때만 업데이트
useEffect(() => {
  if (storeValue !== localValue) {
    setLocalValue(storeValue);
  }
}, [storeValue]); // localValue는 의존성에서 제외
```

### 해결 방법 2: 플래그로 동기화 방향 제어

```tsx
const isUpdatingFromStore = useRef(false);

// 스토어 → 로컬 (외부 변경 감지)
useEffect(() => {
  isUpdatingFromStore.current = true;
  setLocalValue(storeValue);
  requestAnimationFrame(() => {
    isUpdatingFromStore.current = false;
  });
}, [storeValue]);

// 로컬 → 스토어 (사용자 입력)
useEffect(() => {
  if (isUpdatingFromStore.current) return;
  setStoreValue(localValue);
}, [localValue]);
```

### 해결 방법 3: 단방향 데이터 흐름 유지

```tsx
// BEST: 양방향 동기화 자체를 피하기
// 스토어를 Single Source of Truth로 사용
const { value, setValue } = useStore();

const handleChange = (e) => {
  setValue(e.target.value); // 직접 스토어 업데이트
};

return <input value={value} onChange={handleChange} />;
```

---

## 3. URL ↔ State 동기화

URL과 상태 간 양방향 바인딩은 특히 순환에 취약하다.

### 문제 패턴

```tsx
// BAD: URL 변경 → 상태 변경 → URL 변경 → 무한 루프
useEffect(() => {
  setFilters(parseFromUrl(router.query));
}, [router.query]); // URL 변경마다 실행

useEffect(() => {
  router.push({ query: serializeToUrl(filters) });
}, [filters]); // 상태 변경마다 URL 업데이트
```

### 해결 방법: skipNextUpdate 플래그

```tsx
const skipNextUrlUpdate = useRef(false);
const isInitialized = useRef(false);

// URL → State (이벤트 기반으로 처리)
useEffect(() => {
  if (!router.isReady) return;

  const handleRouteChange = () => {
    skipNextUrlUpdate.current = true;
    setFilters(parseFromUrl(router.query));
    requestAnimationFrame(() => {
      skipNextUrlUpdate.current = false;
    });
  };

  // 초기화는 한 번만
  if (!isInitialized.current) {
    handleRouteChange();
    isInitialized.current = true;
  }

  // 브라우저 뒤로가기/앞으로가기는 이벤트로 처리
  router.events.on("routeChangeComplete", handleRouteChange);
  return () => router.events.off("routeChangeComplete", handleRouteChange);
}, [router.isReady, router.events]); // router.query 제외!

// State → URL
useEffect(() => {
  if (!isInitialized.current) return;
  if (skipNextUrlUpdate.current) {
    skipNextUrlUpdate.current = false;
    return;
  }

  const newQuery = serializeToUrl(filters);
  if (JSON.stringify(newQuery) !== JSON.stringify(router.query)) {
    router.push({ query: newQuery }, undefined, { shallow: true });
  }
}, [filters]);
```

---

## 4. React Query / SWR 쿼리 키

### 문제 패턴

```tsx
// BAD: filters 객체가 매번 새로 생성되면 쿼리 무한 재실행
const filters = { search, categories };
useQuery({ queryKey: ["products", filters], queryFn: fetchProducts });
```

### 해결 방법

```tsx
// GOOD 1: useMemo로 객체 메모이제이션
const filters = useMemo(
  () => ({ search, categories: categories.join(",") }),
  [search, categories]
);

// GOOD 2: 쿼리 키를 프리미티브로 분리
useQuery({
  queryKey: ["products", search, categories.join(",")],
  queryFn: () => fetchProducts({ search, categories }),
});
```

---

## 5. Zustand/Redux 셀렉터 최적화

### 문제 패턴

```tsx
// BAD: 전체 스토어 반환 → 어떤 상태가 변경되어도 리렌더링
const store = useStore();
const { search, categories } = store;
```

### 해결 방법

```tsx
// GOOD: 필요한 상태만 개별 선택
const search = useStore((state) => state.search);
const categories = useStore((state) => state.categories);

// 또는 shallow 비교 사용
import { shallow } from "zustand/shallow";
const { search, categories } = useStore(
  (state) => ({ search: state.search, categories: state.categories }),
  shallow
);
```

---

## 6. useCallback/useMemo 의존성

### Observer 패턴에서 콜백 안정화

```tsx
// BAD: fetchNextPage가 변경되면 observer 재설정 → 즉시 콜백 실행 가능
const handleObserver = useCallback((entries) => {
  if (entries[0].isIntersecting) fetchNextPage();
}, [fetchNextPage]); // fetchNextPage가 매번 새 참조일 수 있음

// GOOD: ref로 최신 함수 참조 유지
const fetchNextPageRef = useRef(fetchNextPage);
fetchNextPageRef.current = fetchNextPage;

const handleObserver = useCallback((entries) => {
  if (entries[0].isIntersecting) fetchNextPageRef.current();
}, []); // 의존성 없음 → 콜백 안정적
```

---

## 체크리스트

무한 렌더링 디버깅 시 확인할 항목:

- [ ] useEffect 의존성에 객체/배열이 직접 포함되어 있는가?
- [ ] 양방향 동기화(로컬↔스토어, URL↔상태)가 순환 루프를 형성하는가?
- [ ] router 객체 전체가 의존성에 포함되어 있는가?
- [ ] React Query 쿼리 키에 매번 새로 생성되는 객체가 있는가?
- [ ] Zustand/Redux에서 전체 스토어를 가져오고 있는가?
- [ ] useCallback 의존성에 불안정한 참조가 포함되어 있는가?

---

## 디버깅 팁

```tsx
// 렌더링 횟수 추적
const renderCount = useRef(0);
useEffect(() => {
  renderCount.current += 1;
  console.log(`Rendered ${renderCount.current} times`);
});

// React DevTools Profiler의 "Why did this render?" 기능 활용
// React.StrictMode에서 이중 렌더링 확인 (개발 모드)
```

---

## 관련 이슈

- 해결 사례: `kurly-practice` 프로젝트의 `useUrlSync.ts` 무한 렌더링
- 원인: URL↔State 양방향 바인딩에서 `router.query`를 의존성에 포함
- 해결: `skipNextUrlUpdate` 플래그 + `router.query` 의존성 제거
