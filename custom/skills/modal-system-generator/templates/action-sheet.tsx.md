# ActionSheet 템플릿

Sheet를 확장한 액션 시트 컴포넌트입니다. 여러 옵션 중 하나를 선택할 때 사용합니다.

## 컴포넌트 계층

```
ActionSheet (확장 컴포넌트)
└── Sheet 사용 (기본 컴포넌트)
    └── 옵션 버튼 목록
```

## 파일 위치

`overlay/sheets/ActionSheet.tsx`

## Tailwind 버전

```tsx
'use client'

import { Sheet } from '../Sheet'

interface ActionSheetOption<T> {
    label: string
    value: T
    destructive?: boolean
}

interface ActionSheetProps<T> {
    close: (result?: T) => void
    title?: string
    options: ActionSheetOption<T>[]
}

export function ActionSheet<T>({
    close,
    title,
    options,
}: ActionSheetProps<T>) {
    return (
        <Sheet close={close} title={title}>
            <div className="flex flex-col gap-2">
                {options.map((option, index) => (
                    <button
                        key={index}
                        className={`
                            w-full px-4 py-3 rounded-lg text-left
                            transition-colors cursor-pointer
                            ${
                                option.destructive
                                    ? 'text-red-500 hover:bg-red-50'
                                    : 'text-gray-900 hover:bg-gray-100'
                            }
                        `}
                        onClick={() => close(option.value)}
                    >
                        {option.label}
                    </button>
                ))}
            </div>
        </Sheet>
    )
}
```

## Emotion 버전

```tsx
import { css } from '@emotion/react'
import { Sheet } from '../Sheet'

interface ActionSheetOption<T> {
    label: string
    value: T
    destructive?: boolean
}

interface ActionSheetProps<T> {
    close: (result?: T) => void
    title?: string
    options: ActionSheetOption<T>[]
}

const optionListStyles = css`
    display: flex;
    flex-direction: column;
    gap: 8px;
`

const optionButtonStyles = css`
    width: 100%;
    padding: 12px 16px;
    border-radius: 8px;
    text-align: left;
    background: none;
    border: none;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.2s;
    color: #111827;

    &:hover {
        background: #f3f4f6;
    }
`

const destructiveStyles = css`
    color: #ef4444;

    &:hover {
        background: #fef2f2;
    }
`

export function ActionSheet<T>({
    close,
    title,
    options,
}: ActionSheetProps<T>) {
    return (
        <Sheet close={close} title={title}>
            <div css={optionListStyles}>
                {options.map((option, index) => (
                    <button
                        key={index}
                        css={[
                            optionButtonStyles,
                            option.destructive && destructiveStyles,
                        ]}
                        onClick={() => close(option.value)}
                    >
                        {option.label}
                    </button>
                ))}
            </div>
        </Sheet>
    )
}
```

## 사용 예시

```tsx
import { useOverlay, ActionSheet } from '@/providers/overlay'

function MyComponent() {
    const { open } = useOverlay()

    const handleOptions = async () => {
        const action = await open(({ close }) => (
            <ActionSheet
                close={close}
                title="옵션 선택"
                options={[
                    { label: '수정하기', value: 'edit' },
                    { label: '공유하기', value: 'share' },
                    { label: '삭제하기', value: 'delete', destructive: true },
                    { label: '취소', value: null },
                ]}
            />
        ))

        switch (action) {
            case 'edit':
                // 수정 로직
                break
            case 'share':
                // 공유 로직
                break
            case 'delete':
                // 삭제 로직
                break
        }
    }

    return <button onClick={handleOptions}>옵션</button>
}
```
