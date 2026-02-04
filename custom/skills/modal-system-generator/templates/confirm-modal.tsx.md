# ConfirmModal 템플릿

Modal을 확장한 확인 다이얼로그 컴포넌트입니다.

## 컴포넌트 계층

```
ConfirmModal (확장 컴포넌트)
└── Modal 사용 (기본 컴포넌트)
    ├── 메시지 영역
    └── 확인/취소 버튼
```

## 파일 위치

`overlay/modals/ConfirmModal.tsx`

## Tailwind 버전

```tsx
'use client'

import { Modal } from '../Modal'

interface ConfirmModalProps {
    close: (result?: boolean) => void
    title?: string
    message: string
    confirmText?: string
    cancelText?: string
}

export function ConfirmModal({
    close,
    title = '확인',
    message,
    confirmText = '확인',
    cancelText = '취소',
}: ConfirmModalProps) {
    return (
        <Modal close={close} title={title}>
            <p className="m-0 text-gray-600 leading-relaxed">{message}</p>
            <div className="flex gap-3 mt-6 justify-end">
                <button
                    className="px-5 py-2.5 rounded-lg text-sm font-medium bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors cursor-pointer"
                    onClick={() => close(false)}
                >
                    {cancelText}
                </button>
                <button
                    className="px-5 py-2.5 rounded-lg text-sm font-medium bg-blue-500 text-white hover:bg-blue-600 transition-colors cursor-pointer"
                    onClick={() => close(true)}
                >
                    {confirmText}
                </button>
            </div>
        </Modal>
    )
}
```

## Emotion 버전

```tsx
import { css } from '@emotion/react'
import { Modal } from '../Modal'

interface ConfirmModalProps {
    close: (result?: boolean) => void
    title?: string
    message: string
    confirmText?: string
    cancelText?: string
}

const messageStyles = css`
    margin: 0;
    color: #4b5563;
    line-height: 1.5;
`

const buttonContainerStyles = css`
    display: flex;
    gap: 12px;
    margin-top: 24px;
    justify-content: flex-end;
`

const buttonBase = css`
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
    border: none;
`

const cancelButtonStyles = css`
    ${buttonBase}
    background: #f3f4f6;
    color: #374151;

    &:hover {
        background: #e5e7eb;
    }
`

const confirmButtonStyles = css`
    ${buttonBase}
    background: #3b82f6;
    color: white;

    &:hover {
        background: #2563eb;
    }
`

export function ConfirmModal({
    close,
    title = '확인',
    message,
    confirmText = '확인',
    cancelText = '취소',
}: ConfirmModalProps) {
    return (
        <Modal close={close} title={title}>
            <p css={messageStyles}>{message}</p>
            <div css={buttonContainerStyles}>
                <button css={cancelButtonStyles} onClick={() => close(false)}>
                    {cancelText}
                </button>
                <button css={confirmButtonStyles} onClick={() => close(true)}>
                    {confirmText}
                </button>
            </div>
        </Modal>
    )
}
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
                message="이 항목을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
                confirmText="삭제"
                cancelText="취소"
            />
        ))

        if (confirmed) {
            await deleteItem()
        }
    }

    return <button onClick={handleDelete}>삭제</button>
}
```
