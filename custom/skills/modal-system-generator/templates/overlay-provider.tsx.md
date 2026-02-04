# OverlayProvider 템플릿

Provider + Context + useOverlay 훅을 구현하는 파일입니다.

> **Note**: 전역 `overlay` 객체는 제거되었습니다. 모든 모달 호출은 `useOverlay` 훅을 통해 이루어집니다.
> 이를 통해 코드 추적이 용이해지고, 명시적인 의존성을 가지며, 테스트가 쉬워집니다.

> **⚠️ 중요**: `resolvers`는 반드시 `useRef`로 관리해야 합니다. `useState`를 사용하면 빈번한 리렌더링 시 Stale Closure 버그가 발생합니다. 자세한 내용은 SKILL.md의 "Stale Closure 버그 방지" 섹션을 참고하세요.

## Tailwind 버전

```tsx
'use client'

import {
    createContext,
    useContext,
    useState,
    useCallback,
    useRef,
    ReactNode,
} from 'react'
import { createPortal } from 'react-dom'

// ============ Types ============
type OverlayElement = {
    id: string
    element: ReactNode
}

type OverlayContextType = {
    open: <T>(
        render: (props: {
            close: (result?: T) => void
            isOpen: boolean
        }) => ReactNode
    ) => Promise<T | undefined>
    close: (id: string) => void
    closeAll: () => void
}

// ============ Context ============
const OverlayContext = createContext<OverlayContextType | null>(null)

// ============ Provider ============
interface OverlayProviderProps {
    children: ReactNode
}

export function OverlayProvider({ children }: OverlayProviderProps) {
    const [overlays, setOverlays] = useState<OverlayElement[]>([])
    // ⚠️ useRef 사용 필수! useState 사용 시 Stale Closure 버그 발생
    const resolversRef = useRef<Map<string, (value: unknown) => void>>(new Map())
    const [isMounted, setIsMounted] = useState(false)

    // 클라이언트 마운트 확인
    useState(() => {
        setIsMounted(true)
    })

    const generateId = useCallback(() => {
        return Math.random().toString(36).slice(2) + Date.now().toString(36)
    }, [])

    // ⚠️ 의존성 배열이 비어있어야 함 (useRef 사용으로 항상 최신 참조 보장)
    const close = useCallback((id: string, result?: unknown) => {
        const resolver = resolversRef.current.get(id)
        if (resolver) {
            resolver(result)
            resolversRef.current.delete(id)
        }
        setOverlays((prev) => prev.filter((overlay) => overlay.id !== id))
    }, [])

    const closeAll = useCallback(() => {
        resolversRef.current.forEach((resolver) => resolver(undefined))
        resolversRef.current.clear()
        setOverlays([])
    }, [])

    const open = useCallback(
        <T,>(
            render: (props: {
                close: (result?: T) => void
                isOpen: boolean
            }) => ReactNode
        ): Promise<T | undefined> => {
            return new Promise((resolve) => {
                const id = generateId()

                const handleClose = (result?: T) => {
                    close(id, result)
                }

                // useRef로 직접 set (setState 불필요)
                resolversRef.current.set(id, resolve as (value: unknown) => void)
                setOverlays((prev) => [
                    ...prev,
                    {
                        id,
                        element: render({ close: handleClose, isOpen: true }),
                    },
                ])
            })
        },
        [generateId, close]
    )

    const contextValue: OverlayContextType = {
        open,
        close,
        closeAll,
    }

    return (
        <OverlayContext.Provider value={contextValue}>
            {children}
            {isMounted &&
                overlays.length > 0 &&
                createPortal(
                    <>
                        {overlays.map((overlay) => (
                            <div key={overlay.id} data-overlay-id={overlay.id}>
                                {overlay.element}
                            </div>
                        ))}
                    </>,
                    document.body
                )}
        </OverlayContext.Provider>
    )
}

// ============ Hook ============
export function useOverlay() {
    const context = useContext(OverlayContext)
    if (!context) {
        throw new Error('useOverlay must be used within OverlayProvider')
    }
    return context
}
```

## Emotion 버전

위 코드와 동일합니다. Provider와 Hook 로직은 스타일링 방식과 무관합니다.

## index.ts (export 파일)

```tsx
// 코어
export { OverlayProvider, useOverlay } from './OverlayProvider'
export { Backdrop } from './Backdrop'

// 기본 컴포넌트
export { Modal } from './Modal'
export { Sheet } from './Sheet'

// 확장 컴포넌트
export { ConfirmModal } from './modals/ConfirmModal'
export { ActionSheet } from './sheets/ActionSheet'
```

## 사용 예시

```tsx
import { useOverlay, ConfirmModal } from '@/providers/overlay'

function MyComponent() {
    const { open } = useOverlay()

    const handleDelete = async () => {
        const confirmed = await open(({ close }) => (
            <ConfirmModal
                close={close}
                title="삭제 확인"
                message="이 항목을 삭제하시겠습니까?"
            />
        ))

        if (confirmed) {
            await deleteItem()
        }
    }

    return <button onClick={handleDelete}>삭제</button>
}
```
