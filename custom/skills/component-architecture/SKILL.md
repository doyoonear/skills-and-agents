---
name: component-architecture
description: |
  React 컴포넌트 아키텍처 패턴 가이드. Provider 패턴, 계층 구조, Base/Extended 분리, 재사용 설계, URL state architecture.
  Use when designing component architecture, splitting base and extended components, implementing Provider patterns, URL state architecture, search params 상태관리, 라우팅 상태관리, TanStack Router 설계, 어드민 필터 상태관리, or when user mentions "컴포넌트 아키텍처", "컴포넌트 설계", "컴포넌트 계층 구조".
  Not for component styling (use CSS/Tailwind skills) or library-specific state store implementation.
---

# Component Architecture Guide

React 컴포넌트 설계 시 활용할 수 있는 아키텍처 패턴 모음입니다.
실제 프로젝트에서 검증된 패턴들을 기반으로 작성되었습니다.

## 패턴 목록

| 패턴 | 설명 | 적용 시나리오 |
|------|------|--------------|
| [기본 + 확장 패턴](#1-기본--확장-패턴) | 기본 컴포넌트를 확장하여 변형 생성 | Modal → ConfirmModal, Sheet → ActionSheet |
| [Provider + Hook 패턴](#2-provider--hook-패턴) | Context로 상태 관리, Hook으로 접근 | 전역 상태, 모달 시스템, 테마 |
| [Route URL State Boundary 패턴](#3-route-url-state-boundary-패턴) | URL search params 기반 화면 상태 경계 설계 | 어드민 검색, 필터, 정렬, 페이지네이션 |

> 💡 상세 가이드는 `patterns/` 폴더의 개별 파일을 참조하세요.

---

## 1. 기본 + 확장 패턴

**파일:** `patterns/base-extension.md`

### 핵심 개념

```
기본 컴포넌트 (Base)
├── 최소한의 공통 기능만 포함
├── children으로 내용 확장 가능
└── 제네릭 타입으로 타입 안전성 확보

확장 컴포넌트 (Extension)
├── 기본 컴포넌트를 import하여 사용
├── 특화된 UI/로직 추가
└── 별도 폴더에 그룹화 (예: modals/, sheets/)
```

### 적용 시나리오

- **모달 시스템**: `Modal` → `ConfirmModal`, `AlertModal`, `FormModal`
- **시트 시스템**: `Sheet` → `ActionSheet`, `FilterSheet`, `ShareSheet`
- **카드 시스템**: `Card` → `ProductCard`, `UserCard`, `ArticleCard`
- **버튼 시스템**: `Button` → `IconButton`, `LoadingButton`, `SocialButton`

### 폴더 구조

```
components/
├── Modal.tsx           # 기본 모달
├── Sheet.tsx           # 기본 시트
├── modals/             # 모달 확장 컴포넌트들
│   ├── ConfirmModal.tsx
│   └── AlertModal.tsx
└── sheets/             # 시트 확장 컴포넌트들
    ├── ActionSheet.tsx
    └── FilterSheet.tsx
```

### 빠른 예시

```tsx
// 기본 컴포넌트 - 제네릭 타입 사용
interface SheetProps<T = unknown> {
    close: (result?: T) => void
    title?: string
    children: React.ReactNode
}

export function Sheet<T = unknown>({ close, title, children }: SheetProps<T>) {
    return (
        <Backdrop onClick={() => close()} alignBottom>
            <div className="bg-white rounded-t-2xl">
                {title && <h2>{title}</h2>}
                {children}
            </div>
        </Backdrop>
    )
}

// 확장 컴포넌트 - 기본 컴포넌트 래핑
interface ActionSheetProps<T> {
    close: (result?: T | null) => void
    title?: string
    options: Array<{ label: string; value: T; destructive?: boolean }>
}

export function ActionSheet<T>({ close, title, options }: ActionSheetProps<T>) {
    return (
        <Sheet close={close} title={title}>
            {options.map((option) => (
                <button key={String(option.value)} onClick={() => close(option.value)}>
                    {option.label}
                </button>
            ))}
            <button onClick={() => close(null)}>취소</button>
        </Sheet>
    )
}
```

---

## 2. Provider + Hook 패턴

**파일:** `patterns/provider-hook.md`

### 핵심 개념

```
OverlayProvider (Context Provider)
├── 상태 및 로직 캡슐화
├── createPortal로 DOM 렌더링
└── 앱 최상위에서 래핑

useOverlay (Custom Hook)
├── Context 접근 유일한 방법
├── 타입 안전한 API 제공
└── 코드 추적 용이 (전역 객체 없음)
```

### 설계 원칙

| 원칙 | 설명 |
|------|------|
| **전역 객체 금지** | `overlay.open()` 같은 전역 접근 금지 → 코드 추적 어려움 |
| **Hook 전용 접근** | 컴포넌트 내에서 `useOverlay()` 훅으로만 접근 |
| **명시적 의존성** | Provider 없이 Hook 사용 시 명확한 에러 메시지 |

### 적용 시나리오

- **모달/오버레이 시스템**: Promise 기반 열기/닫기
- **토스트/알림 시스템**: 전역 알림 표시
- **테마 시스템**: 다크모드 토글
- **인증 시스템**: 로그인 상태 관리

### 빠른 예시

```tsx
// Context 정의
type OverlayContextType = {
    open: <T>(render: (props: { close: (result?: T) => void }) => ReactNode) => Promise<T | undefined>
    close: (id: string) => void
    closeAll: () => void
}

const OverlayContext = createContext<OverlayContextType | null>(null)

// Provider 구현
export function OverlayProvider({ children }: { children: ReactNode }) {
    const [overlays, setOverlays] = useState<OverlayElement[]>([])

    const open = useCallback(<T,>(render: RenderFn<T>): Promise<T | undefined> => {
        return new Promise((resolve) => {
            const id = crypto.randomUUID()
            const close = (result?: T) => {
                setOverlays((prev) => prev.filter((o) => o.id !== id))
                resolve(result)
            }
            setOverlays((prev) => [...prev, { id, element: render({ close, isOpen: true }) }])
        })
    }, [])

    return (
        <OverlayContext.Provider value={{ open, close, closeAll }}>
            {children}
            {mounted && createPortal(/* overlay 렌더링 */, document.body)}
        </OverlayContext.Provider>
    )
}

// Hook 구현
export function useOverlay() {
    const context = useContext(OverlayContext)
    if (!context) {
        throw new Error('useOverlay must be used within OverlayProvider')
    }
    return context
}
```

---

## 3. Route URL State Boundary 패턴

**파일:** `patterns/route-url-state-boundary.md`

### 핵심 개념

```
Route layer
├── validateSearch 또는 schema parse로 URL 검증
├── 기본값, 타입 변환, canonical URL 정규화
└── loaderDeps 또는 queryKey에 검증된 search 연결

Form layer
├── URL search 값을 defaultValues로 사용
├── 입력 중인 draft만 관리
└── submit 시 URL search params로 변환

Data layer
├── URL search에서 파생된 queryKey 또는 loaderDeps 사용
├── 서버 응답은 query cache 또는 loader data로 관리
└── fetchQuery, ensureQueryData, invalidate, revalidate 역할 구분
```

### 설계 원칙

| 원칙 | 설명 |
|------|------|
| **URL state는 SSOT** | 검색어, 필터, 정렬, 페이지처럼 재현 가능한 화면 조건은 URL search params에 둠 |
| **Form state는 draft** | submit 전 입력 중인 값은 실제 결과 조건이 아니라 임시 상태로 취급 |
| **Server state는 파생값** | query cache와 loader data는 URL state에서 파생된 서버 응답으로 취급 |
| **Route boundary 검증** | URL parsing, validation, defaulting을 leaf 컴포넌트에 흩뿌리지 않음 |
| **중복 truth 금지** | 같은 값을 URL, form, context, zustand, query cache에 동시에 진실처럼 저장하지 않음 |

### 적용 시나리오

- **어드민 목록 화면**: 검색, 필터, 정렬, 페이지네이션
- **데이터 테이블**: 공유 가능한 링크와 QA 재현이 필요한 화면
- **대시보드 뷰**: 탭, 기간, 뷰 모드가 URL로 재현되어야 하는 화면
- **TanStack Router 화면**: `validateSearch`, `loaderDeps`, `loader`가 데이터 fetching과 연결되는 화면

### 빠른 예시

```tsx
const usersSearchSchema = z.object({
    keyword: z.string().default(''),
    status: z.enum(['all', 'active', 'inactive']).default('all'),
    page: z.coerce.number().int().min(1).default(1),
})

export const Route = createFileRoute('/admin/users')({
    validateSearch: usersSearchSchema,
    loaderDeps: ({ search }) => ({
        keyword: search.keyword,
        status: search.status,
        page: search.page,
    }),
    loader: ({ deps, context }) => context.queryClient.fetchQuery(usersQueryOptions(deps)),
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

---

## 패턴 선택 가이드

```
컴포넌트 설계 시 질문:

1. "같은 기본 구조에서 여러 변형이 필요한가?"
   → YES: 기본 + 확장 패턴 사용

2. "여러 컴포넌트에서 공유되는 상태/기능인가?"
   → YES: Provider + Hook 패턴 사용

3. "검색, 필터, 정렬, 페이지네이션이 URL로 재현되어야 하는가?"
   → YES: Route URL State Boundary 패턴 사용

4. "두 가지 이상 해당하는가?"
   → 조합 사용 (예: URL state를 route boundary에 두고, form draft는 Provider + Hook으로 공유)
```

---

## 참고 사항

- 각 패턴의 상세 구현은 `patterns/` 폴더의 개별 파일 참조
- 실제 적용 예시는 `modal-system-generator` skill 참조
- 새 패턴 추가 시 이 문서와 `patterns/` 폴더에 함께 추가
