---
name: component-architecture
description: |
  React 컴포넌트 아키텍처 패턴 가이드. Provider 패턴, 계층 구조, Base/Extended 분리, 재사용 설계.
  This skill should be used when designing component architecture, splitting base and extended components, implementing Provider patterns, or when user mentions "컴포넌트 아키텍처", "컴포넌트 설계", "컴포넌트 계층 구조".
  Not for component styling (use CSS/Tailwind skills) or state management libraries.
---

# Component Architecture Guide

React 컴포넌트 설계 시 활용할 수 있는 아키텍처 패턴 모음입니다.
실제 프로젝트에서 검증된 패턴들을 기반으로 작성되었습니다.

## 패턴 목록

| 패턴 | 설명 | 적용 시나리오 |
|------|------|--------------|
| [기본 + 확장 패턴](#1-기본--확장-패턴) | 기본 컴포넌트를 확장하여 변형 생성 | Modal → ConfirmModal, Sheet → ActionSheet |
| [Provider + Hook 패턴](#2-provider--hook-패턴) | Context로 상태 관리, Hook으로 접근 | 전역 상태, 모달 시스템, 테마 |

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

## 패턴 선택 가이드

```
컴포넌트 설계 시 질문:

1. "같은 기본 구조에서 여러 변형이 필요한가?"
   → YES: 기본 + 확장 패턴 사용

2. "여러 컴포넌트에서 공유되는 상태/기능인가?"
   → YES: Provider + Hook 패턴 사용

3. "두 가지 모두 해당하는가?"
   → 조합 사용 (예: Overlay 시스템)
```

---

## 참고 사항

- 각 패턴의 상세 구현은 `patterns/` 폴더의 개별 파일 참조
- 실제 적용 예시는 `modal-system-generator` skill 참조
- 새 패턴 추가 시 이 문서와 `patterns/` 폴더에 함께 추가
