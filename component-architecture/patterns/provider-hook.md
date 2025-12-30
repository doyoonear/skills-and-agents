# Provider + Hook 패턴

React Context를 활용하여 상태를 관리하고, Custom Hook으로 접근하는 패턴입니다.

## 핵심 원칙

### 1. 전역 객체 사용 금지

```tsx
// ❌ 잘못된 예: 전역 객체로 접근
let globalOpen: OpenFn | null = null

export const overlay = {
    open: (render) => globalOpen?.(render),
}

// 사용처에서 어디서든 호출 가능 → 추적 어려움
overlay.open(({ close }) => <Modal />)
```

```tsx
// ✅ 올바른 예: Hook으로만 접근
export function useOverlay() {
    const context = useContext(OverlayContext)
    if (!context) {
        throw new Error('useOverlay must be used within OverlayProvider')
    }
    return context
}

// 사용처에서 의존성이 명확함
function MyComponent() {
    const { open } = useOverlay()  // 의존성 명시
    // ...
}
```

**전역 객체 금지 이유:**
- 코드 추적 어려움 (어디서 호출되는지 파악 불가)
- 테스트 어려움 (mock 설정 복잡)
- 암묵적 의존성 (컴포넌트가 무엇에 의존하는지 불명확)

### 2. Provider 설계

```tsx
// OverlayProvider.tsx
'use client'

import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { createPortal } from 'react-dom'

// 1. 타입 정의
type RenderFn<T> = (props: { close: (result?: T) => void; isOpen: boolean }) => ReactNode
type OverlayElement = { id: string; element: ReactNode }

type OverlayContextType = {
    open: <T>(render: RenderFn<T>) => Promise<T | undefined>
    close: (id: string) => void
    closeAll: () => void
}

// 2. Context 생성 (null 초기값)
const OverlayContext = createContext<OverlayContextType | null>(null)

// 3. Provider 구현
export function OverlayProvider({ children }: { children: ReactNode }) {
    const [overlays, setOverlays] = useState<OverlayElement[]>([])
    const [mounted, setMounted] = useState(false)

    // 클라이언트에서만 마운트
    useEffect(() => {
        setMounted(true)
    }, [])

    // Promise 기반 open
    const open = useCallback(<T,>(render: RenderFn<T>): Promise<T | undefined> => {
        return new Promise((resolve) => {
            const id = crypto.randomUUID()

            const close = (result?: T) => {
                setOverlays((prev) => prev.filter((o) => o.id !== id))
                resolve(result)
            }

            setOverlays((prev) => [
                ...prev,
                { id, element: render({ close, isOpen: true }) }
            ])
        })
    }, [])

    const close = useCallback((id: string) => {
        setOverlays((prev) => prev.filter((o) => o.id !== id))
    }, [])

    const closeAll = useCallback(() => {
        setOverlays([])
    }, [])

    return (
        <OverlayContext.Provider value={{ open, close, closeAll }}>
            {children}
            {mounted && createPortal(
                overlays.map((overlay) => (
                    <div key={overlay.id}>{overlay.element}</div>
                )),
                document.body
            )}
        </OverlayContext.Provider>
    )
}
```

### 3. Hook 설계

```tsx
// useOverlay Hook
export function useOverlay() {
    const context = useContext(OverlayContext)

    if (!context) {
        throw new Error(
            'useOverlay must be used within OverlayProvider. ' +
            'Wrap your app with <OverlayProvider> in the root layout.'
        )
    }

    return context
}
```

**Hook 설계 원칙:**
- Context가 없을 때 명확한 에러 메시지
- 해결 방법을 에러 메시지에 포함
- 반환 타입이 명확 (null 가능성 제거)

---

## 파일 구조

```
providers/
└── overlay/
    ├── OverlayProvider.tsx   # Provider + Context + Hook
    ├── Backdrop.tsx          # UI 컴포넌트
    ├── Modal.tsx             # UI 컴포넌트
    ├── Sheet.tsx             # UI 컴포넌트
    └── index.ts              # Export
```

### 단일 파일 vs 분리

**단일 파일 (권장):**
```tsx
// OverlayProvider.tsx
const OverlayContext = createContext<...>(null)

export function OverlayProvider() { /* ... */ }
export function useOverlay() { /* ... */ }
```

**분리 (대규모 프로젝트):**
```
overlay/
├── context.ts         # Context 정의
├── provider.tsx       # Provider 구현
├── hooks.ts           # useOverlay 등 hooks
└── types.ts           # 타입 정의
```

---

## 적용 시나리오별 예시

### 1. 모달/오버레이 시스템

```tsx
// Promise 기반으로 결과 반환
const confirmed = await open(({ close }) => (
    <ConfirmModal
        close={close}
        title="삭제 확인"
        message="정말 삭제하시겠습니까?"
    />
))

if (confirmed) {
    await deleteItem()
}
```

### 2. 토스트 시스템

```tsx
// ToastProvider.tsx
type ToastContextType = {
    show: (message: string, type?: 'success' | 'error' | 'info') => void
    hide: (id: string) => void
}

export function useToast() {
    const context = useContext(ToastContext)
    if (!context) throw new Error('useToast must be used within ToastProvider')
    return context
}

// 사용
const { show } = useToast()
show('저장되었습니다', 'success')
```

### 3. 테마 시스템

```tsx
// ThemeProvider.tsx
type ThemeContextType = {
    theme: 'light' | 'dark'
    toggleTheme: () => void
}

export function useTheme() {
    const context = useContext(ThemeContext)
    if (!context) throw new Error('useTheme must be used within ThemeProvider')
    return context
}

// 사용
const { theme, toggleTheme } = useTheme()
```

### 4. 인증 시스템

```tsx
// AuthProvider.tsx
type AuthContextType = {
    user: User | null
    login: (credentials: Credentials) => Promise<void>
    logout: () => Promise<void>
    isAuthenticated: boolean
}

export function useAuth() {
    const context = useContext(AuthContext)
    if (!context) throw new Error('useAuth must be used within AuthProvider')
    return context
}
```

---

## Provider 중첩 순서

```tsx
// app/layout.tsx
export default function RootLayout({ children }) {
    return (
        <html>
            <body>
                {/* 순서 중요: 의존성 순서대로 */}
                <ThemeProvider>
                    <AuthProvider>
                        <ToastProvider>
                            <OverlayProvider>
                                {children}
                            </OverlayProvider>
                        </ToastProvider>
                    </AuthProvider>
                </ThemeProvider>
            </body>
        </html>
    )
}
```

**중첩 순서 원칙:**
1. 다른 Provider가 의존하는 Provider가 바깥에 위치
2. UI 관련 Provider (Toast, Overlay)는 안쪽에 위치
3. 테마, 인증 등 전역 상태는 바깥에 위치

---

## SSR 고려사항

### Next.js에서 'use client' 필수

```tsx
'use client'  // 필수!

import { createContext, useContext } from 'react'
```

### document 접근 시 마운트 체크

```tsx
export function OverlayProvider({ children }) {
    const [mounted, setMounted] = useState(false)

    useEffect(() => {
        setMounted(true)
    }, [])

    return (
        <Context.Provider value={...}>
            {children}
            {mounted && createPortal(/* ... */, document.body)}
        </Context.Provider>
    )
}
```

---

## 테스트

### Mock Provider 제공

```tsx
// test-utils.tsx
export function MockOverlayProvider({ children, mockOpen }) {
    return (
        <OverlayContext.Provider value={{
            open: mockOpen ?? jest.fn(),
            close: jest.fn(),
            closeAll: jest.fn(),
        }}>
            {children}
        </OverlayContext.Provider>
    )
}

// 테스트
it('opens confirm modal on delete', async () => {
    const mockOpen = jest.fn().mockResolvedValue(true)

    render(
        <MockOverlayProvider mockOpen={mockOpen}>
            <DeleteButton />
        </MockOverlayProvider>
    )

    fireEvent.click(screen.getByText('삭제'))
    expect(mockOpen).toHaveBeenCalled()
})
```

---

## 체크리스트

Provider + Hook 패턴 구현 시:

- [ ] 전역 객체 없이 Hook으로만 접근
- [ ] Context 초기값 `null`, Hook에서 에러 처리
- [ ] 'use client' 지시어 추가 (Next.js)
- [ ] createPortal 사용 시 마운트 체크
- [ ] 명확한 에러 메시지 (해결 방법 포함)
- [ ] Provider, Hook 같은 파일에서 export
