# Modal 템플릿

기본 모달 컴포넌트입니다. Backdrop을 wrapper로 사용하며, children으로 내용을 확장할 수 있습니다.

## 컴포넌트 계층

```
Modal (기본 컴포넌트)
├── Backdrop 사용 (중앙 정렬)
├── 흰색 박스 UI
├── 제목 영역 (옵션)
└── children 영역
```

## Tailwind 버전

```tsx
'use client'

import { useState } from 'react'
import { Backdrop } from './Backdrop'

interface ModalProps {
    isOpen?: boolean
    close: (result?: boolean) => void
    title?: string
    children: React.ReactNode
    closeOnBackdropClick?: boolean
}

const ANIMATION_DURATION = 200

export function Modal({
    isOpen = true,
    close,
    title,
    children,
    closeOnBackdropClick = true,
}: ModalProps) {
    const [isExiting, setIsExiting] = useState(false)

    const handleClose = (result?: boolean) => {
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
        >
            <div
                className={`
                    bg-white rounded-xl p-6
                    min-w-[320px] max-w-[480px] max-h-[80vh]
                    overflow-y-auto shadow-xl
                    ${isExiting ? 'animate-scale-out' : 'animate-scale-in'}
                `}
                onClick={(e) => e.stopPropagation()}
            >
                {title && (
                    <h2 className="m-0 mb-4 text-lg font-semibold text-gray-900">
                        {title}
                    </h2>
                )}
                {children}
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
import { scaleIn, scaleOut, ANIMATION_DURATION } from './animations'

interface ModalProps {
    isOpen?: boolean
    close: (result?: boolean) => void
    title?: string
    children: React.ReactNode
    closeOnBackdropClick?: boolean
}

const modalContainerStyles = css`
    background: white;
    border-radius: 12px;
    padding: 24px;
    min-width: 320px;
    max-width: 480px;
    max-height: 80vh;
    overflow-y: auto;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1),
                0 10px 10px -5px rgba(0, 0, 0, 0.04);
`

const enterAnimation = css`
    animation: ${scaleIn} ${ANIMATION_DURATION.modal}ms ease-out forwards;
`

const exitAnimation = css`
    animation: ${scaleOut} ${ANIMATION_DURATION.modal}ms ease-out forwards;
`

const titleStyles = css`
    margin: 0 0 16px 0;
    font-size: 18px;
    font-weight: 600;
    color: #111827;
`

export function Modal({
    isOpen = true,
    close,
    title,
    children,
    closeOnBackdropClick = true,
}: ModalProps) {
    const [isExiting, setIsExiting] = useState(false)

    const handleClose = (result?: boolean) => {
        setIsExiting(true)
        setTimeout(() => {
            close(result)
        }, ANIMATION_DURATION.modal)
    }

    return (
        <Backdrop
            isOpen={isOpen}
            onClick={() => handleClose()}
            closeOnClick={closeOnBackdropClick}
        >
            <div
                css={[modalContainerStyles, isExiting ? exitAnimation : enterAnimation]}
                onClick={(e) => e.stopPropagation()}
            >
                {title && <h2 css={titleStyles}>{title}</h2>}
                {children}
            </div>
        </Backdrop>
    )
}
```

## 사용 예시

```tsx
import { useOverlay, Modal } from '@/providers/overlay'

function MyComponent() {
    const { open } = useOverlay()

    const handleOpenModal = async () => {
        await open(({ close }) => (
            <Modal close={close} title="커스텀 모달">
                <p>원하는 내용을 넣으세요</p>
                <button onClick={() => close(true)}>확인</button>
            </Modal>
        ))
    }

    return <button onClick={handleOpenModal}>모달 열기</button>
}
```
