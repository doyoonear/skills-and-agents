# Example BottomSheet 템플릿

바텀시트 컴포넌트 예시입니다. 화면 하단에서 위로 슬라이드되어 나타납니다.

## Emotion 버전

```tsx
import { useState } from 'react';
import { css } from '@emotion/react';
import { slideUp, slideDown, fadeIn, fadeOut, ANIMATION_DURATION } from '../animations';

interface BottomSheetProps {
  isOpen?: boolean;
  close: <T>(result?: T) => void;
  title?: string;
  children: React.ReactNode;
  closeOnBackdropClick?: boolean;
}

const backdropStyles = css`
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background-color: rgba(0, 0, 0, 0.5);
`;

const backdropEnter = css`
  animation: ${fadeIn} ${ANIMATION_DURATION.backdrop}ms ease-out forwards;
`;

const backdropExit = css`
  animation: ${fadeOut} ${ANIMATION_DURATION.backdrop}ms ease-out forwards;
`;

const sheetContainerStyles = css`
  background: white;
  border-radius: 16px 16px 0 0;
  width: 100%;
  max-width: 480px;
  max-height: 85vh;
  overflow-y: auto;
  box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.15);
`;

const sheetEnter = css`
  animation: ${slideUp} ${ANIMATION_DURATION.bottomSheet}ms ease-out forwards;
`;

const sheetExit = css`
  animation: ${slideDown} ${ANIMATION_DURATION.bottomSheet}ms ease-out forwards;
`;

const handleStyles = css`
  display: flex;
  justify-content: center;
  padding: 12px 0 8px;
`;

const handleBarStyles = css`
  width: 36px;
  height: 4px;
  background: #d1d5db;
  border-radius: 2px;
`;

const headerStyles = css`
  padding: 0 20px 16px;
  border-bottom: 1px solid #f3f4f6;
`;

const titleStyles = css`
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #111827;
`;

const contentStyles = css`
  padding: 20px;
`;

export function BottomSheet({
  isOpen = true,
  close,
  title,
  children,
  closeOnBackdropClick = true,
}: BottomSheetProps) {
  const [isExiting, setIsExiting] = useState(false);

  const handleClose = <T,>(result?: T) => {
    setIsExiting(true);
    setTimeout(() => {
      close(result);
    }, ANIMATION_DURATION.bottomSheet);
  };

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && closeOnBackdropClick) {
      handleClose();
    }
  };

  if (!isOpen && !isExiting) return null;

  return (
    <div
      css={[backdropStyles, isExiting ? backdropExit : backdropEnter]}
      onClick={handleBackdropClick}
      role="dialog"
      aria-modal="true"
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
    </div>
  );
}

// ============ 액션 시트 예시 ============
interface ActionSheetOption<T> {
  label: string;
  value: T;
  variant?: 'default' | 'destructive';
}

interface ActionSheetProps<T> {
  close: (result?: T) => void;
  title?: string;
  options: ActionSheetOption<T>[];
}

const optionButtonStyles = css`
  width: 100%;
  padding: 16px 20px;
  background: none;
  border: none;
  text-align: left;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.2s;

  &:hover {
    background: #f9fafb;
  }

  &:not(:last-child) {
    border-bottom: 1px solid #f3f4f6;
  }
`;

const destructiveStyles = css`
  color: #ef4444;
`;

export function ActionSheet<T>({
  close,
  title,
  options,
}: ActionSheetProps<T>) {
  return (
    <BottomSheet close={close} title={title}>
      <div css={css`margin: -20px;`}>
        {options.map((option, index) => (
          <button
            key={index}
            css={[
              optionButtonStyles,
              option.variant === 'destructive' && destructiveStyles,
            ]}
            onClick={() => close(option.value)}
          >
            {option.label}
          </button>
        ))}
      </div>
    </BottomSheet>
  );
}
```

## Tailwind 버전

```tsx
import { useState } from 'react';

interface BottomSheetProps {
  isOpen?: boolean;
  close: <T>(result?: T) => void;
  title?: string;
  children: React.ReactNode;
  closeOnBackdropClick?: boolean;
}

const ANIMATION_DURATION = 300;

export function BottomSheet({
  isOpen = true,
  close,
  title,
  children,
  closeOnBackdropClick = true,
}: BottomSheetProps) {
  const [isExiting, setIsExiting] = useState(false);

  const handleClose = <T,>(result?: T) => {
    setIsExiting(true);
    setTimeout(() => {
      close(result);
    }, ANIMATION_DURATION);
  };

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && closeOnBackdropClick) {
      handleClose();
    }
  };

  if (!isOpen && !isExiting) return null;

  return (
    <div
      className={`
        fixed inset-0 z-[1000] flex items-end justify-center
        bg-black/50
        ${isExiting ? 'animate-fade-out' : 'animate-fade-in'}
      `}
      onClick={handleBackdropClick}
      role="dialog"
      aria-modal="true"
    >
      <div
        className={`
          bg-white rounded-t-2xl w-full max-w-[480px] max-h-[85vh]
          overflow-y-auto shadow-[0_-10px_40px_rgba(0,0,0,0.15)]
          ${isExiting ? 'animate-slide-down' : 'animate-slide-up'}
        `}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Handle bar */}
        <div className="flex justify-center py-3">
          <div className="w-9 h-1 bg-gray-300 rounded-full" />
        </div>

        {/* Header */}
        {title && (
          <div className="px-5 pb-4 border-b border-gray-100">
            <h2 className="m-0 text-lg font-semibold text-gray-900">{title}</h2>
          </div>
        )}

        {/* Content */}
        <div className="p-5">{children}</div>
      </div>
    </div>
  );
}

// ============ 액션 시트 예시 ============
interface ActionSheetOption<T> {
  label: string;
  value: T;
  variant?: 'default' | 'destructive';
}

interface ActionSheetProps<T> {
  close: (result?: T) => void;
  title?: string;
  options: ActionSheetOption<T>[];
}

export function ActionSheet<T>({
  close,
  title,
  options,
}: ActionSheetProps<T>) {
  return (
    <BottomSheet close={close} title={title}>
      <div className="-m-5">
        {options.map((option, index) => (
          <button
            key={index}
            className={`
              w-full px-5 py-4 bg-transparent border-0 text-left text-base
              cursor-pointer transition-colors hover:bg-gray-50
              ${index !== options.length - 1 ? 'border-b border-gray-100' : ''}
              ${option.variant === 'destructive' ? 'text-red-500' : 'text-gray-900'}
            `}
            onClick={() => close(option.value)}
          >
            {option.label}
          </button>
        ))}
      </div>
    </BottomSheet>
  );
}
```

## 사용 예시

```tsx
import { overlay } from '@/providers/overlay';
import { ActionSheet, BottomSheet } from '@/providers/overlay/examples/BottomSheet';

// 액션 시트 사용
async function handleOptions() {
  const action = await overlay.open(({ close }) => (
    <ActionSheet
      close={close}
      title="옵션 선택"
      options={[
        { label: '수정하기', value: 'edit' },
        { label: '공유하기', value: 'share' },
        { label: '삭제하기', value: 'delete', variant: 'destructive' },
        { label: '취소', value: null },
      ]}
    />
  ));

  switch (action) {
    case 'edit':
      // 수정 로직
      break;
    case 'share':
      // 공유 로직
      break;
    case 'delete':
      // 삭제 로직
      break;
  }
}

// 커스텀 바텀시트 사용
async function handleFilter() {
  const filters = await overlay.open(({ close }) => (
    <BottomSheet close={close} title="필터">
      <div>
        {/* 필터 UI */}
        <button onClick={() => close({ category: 'all', sort: 'newest' })}>
          적용
        </button>
      </div>
    </BottomSheet>
  ));

  if (filters) {
    applyFilters(filters);
  }
}
```
