# Sheet 템플릿

기본 시트(바텀시트) 컴포넌트입니다. Backdrop을 wrapper로 사용하며 (alignBottom), children으로 내용을 확장할 수 있습니다.

## 컴포넌트 계층

```
Sheet (기본 컴포넌트)
├── Backdrop 사용 (하단 정렬, alignBottom)
├── 흰색 박스 UI (상단 모서리 둥글게)
├── 드래그 핸들
├── 제목 영역 (옵션)
└── children 영역
```

## Tailwind 버전

```tsx
'use client'

import { useState } from 'react'
import { Backdrop } from './Backdrop'

interface SheetProps<T = unknown> {
    isOpen?: boolean
    close: (result?: T) => void
    title?: string
    children: React.ReactNode
    closeOnBackdropClick?: boolean
}

const ANIMATION_DURATION = 300

export function Sheet<T = unknown>({
    isOpen = true,
    close,
    title,
    children,
    closeOnBackdropClick = true,
}: SheetProps<T>) {
    const [isExiting, setIsExiting] = useState(false)

    const handleClose = (result?: T) => {
        setIsExiting(true)
        setTimeout(() => {
            close(result)
        }, ANIMATION_DURATION)
    }

    return (
        <Backdrop
            isOpen={isOpen}
            onClick={() => handleClose()}
            closeOnClick={closeOnBackdropClick}
            alignBottom
        >
            <div
                className={`
                    bg-white rounded-t-2xl
                    w-full max-w-lg
                    max-h-[85vh] overflow-y-auto
                    shadow-xl
                    ${isExiting ? 'animate-slide-down' : 'animate-slide-up'}
                `}
                onClick={(e) => e.stopPropagation()}
            >
                {/* 드래그 핸들 */}
                <div className="flex justify-center pt-3 pb-2">
                    <div className="w-10 h-1 bg-gray-300 rounded-full" />
                </div>

                {title && (
                    <h2 className="px-6 pb-4 text-lg font-semibold text-gray-900 border-b border-gray-100">
                        {title}
                    </h2>
                )}

                <div className="p-6">{children}</div>
            </div>
        </Backdrop>
    )
}
```

## Emotion 버전

```tsx
import { useState } from 'react'
import { css } from '@emotion/react'
import { Backdrop } from './Backdrop'
import { slideUp, slideDown, ANIMATION_DURATION } from './animations'

interface SheetProps<T = unknown> {
    isOpen?: boolean
    close: (result?: T) => void
    title?: string
    children: React.ReactNode
    closeOnBackdropClick?: boolean
}

const sheetContainerStyles = css`
    background: white;
    border-radius: 16px 16px 0 0;
    width: 100%;
    max-width: 480px;
    max-height: 85vh;
    overflow-y: auto;
    box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.15);
`

const sheetEnter = css`
    animation: ${slideUp} ${ANIMATION_DURATION.bottomSheet}ms ease-out forwards;
`

const sheetExit = css`
    animation: ${slideDown} ${ANIMATION_DURATION.bottomSheet}ms ease-out forwards;
`

const handleStyles = css`
    display: flex;
    justify-content: center;
    padding: 12px 0 8px;
`

const handleBarStyles = css`
    width: 36px;
    height: 4px;
    background: #d1d5db;
    border-radius: 2px;
`

const headerStyles = css`
    padding: 0 24px 16px;
    border-bottom: 1px solid #f3f4f6;
`

const titleStyles = css`
    margin: 0;
    font-size: 18px;
    font-weight: 600;
    color: #111827;
`

const contentStyles = css`
    padding: 24px;
`

export function Sheet<T = unknown>({
    isOpen = true,
    close,
    title,
    children,
    closeOnBackdropClick = true,
}: SheetProps<T>) {
    const [isExiting, setIsExiting] = useState(false)

    const handleClose = (result?: T) => {
        setIsExiting(true)
        setTimeout(() => {
            close(result)
        }, ANIMATION_DURATION.bottomSheet)
    }

    return (
        <Backdrop
            isOpen={isOpen}
            onClick={() => handleClose()}
            closeOnClick={closeOnBackdropClick}
            alignBottom
        >
            <div
                css={[sheetContainerStyles, isExiting ? sheetExit : sheetEnter]}
                onClick={(e) => e.stopPropagation()}
            >
                <div css={handleStyles}>
                    <div css={handleBarStyles} />
                </div>
                {title && (
                    <div css={headerStyles}>
                        <h2 css={titleStyles}>{title}</h2>
                    </div>
                )}
                <div css={contentStyles}>{children}</div>
            </div>
        </Backdrop>
    )
}
```

## 사용 예시

```tsx
import { useOverlay, Sheet } from '@/providers/overlay'

function MyComponent() {
    const { open } = useOverlay()

    const handleOpenSheet = async () => {
        const result = await open(({ close }) => (
            <Sheet close={close} title="필터">
                <div>
                    {/* 필터 UI */}
                    <button onClick={() => close({ category: 'all' })}>
                        적용
                    </button>
                </div>
            </Sheet>
        ))

        if (result) {
            applyFilters(result)
        }
    }

    return <button onClick={handleOpenSheet}>필터 열기</button>
}
```
