# Example Modal 템플릿

기본 모달 컴포넌트 예시입니다.

## Emotion 버전

```tsx
import { useState, useEffect } from 'react';
import { css } from '@emotion/react';
import { Backdrop } from '../Backdrop';
import { scaleIn, scaleOut, ANIMATION_DURATION } from '../animations';

interface ModalProps {
  isOpen?: boolean;
  close: (result?: boolean) => void;
  title?: string;
  children: React.ReactNode;
  closeOnBackdropClick?: boolean;
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
`;

const enterAnimation = css`
  animation: ${scaleIn} ${ANIMATION_DURATION.modal}ms ease-out forwards;
`;

const exitAnimation = css`
  animation: ${scaleOut} ${ANIMATION_DURATION.modal}ms ease-out forwards;
`;

const titleStyles = css`
  margin: 0 0 16px 0;
  font-size: 18px;
  font-weight: 600;
  color: #111827;
`;

export function Modal({
  isOpen = true,
  close,
  title,
  children,
  closeOnBackdropClick = true,
}: ModalProps) {
  const [isExiting, setIsExiting] = useState(false);

  const handleClose = (result?: boolean) => {
    setIsExiting(true);
    setTimeout(() => {
      close(result);
    }, ANIMATION_DURATION.modal);
  };

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
  );
}

// ============ 확인 모달 예시 ============
interface ConfirmModalProps {
  close: (result?: boolean) => void;
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
}

const buttonContainerStyles = css`
  display: flex;
  gap: 12px;
  margin-top: 24px;
  justify-content: flex-end;
`;

const buttonBase = css`
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
`;

const cancelButtonStyles = css`
  ${buttonBase}
  background: #f3f4f6;
  border: none;
  color: #374151;

  &:hover {
    background: #e5e7eb;
  }
`;

const confirmButtonStyles = css`
  ${buttonBase}
  background: #3b82f6;
  border: none;
  color: white;

  &:hover {
    background: #2563eb;
  }
`;

export function ConfirmModal({
  close,
  title = '확인',
  message,
  confirmText = '확인',
  cancelText = '취소',
}: ConfirmModalProps) {
  return (
    <Modal close={close} title={title}>
      <p css={css`margin: 0; color: #4b5563; line-height: 1.5;`}>
        {message}
      </p>
      <div css={buttonContainerStyles}>
        <button css={cancelButtonStyles} onClick={() => close(false)}>
          {cancelText}
        </button>
        <button css={confirmButtonStyles} onClick={() => close(true)}>
          {confirmText}
        </button>
      </div>
    </Modal>
  );
}
```

## Tailwind 버전

```tsx
import { useState } from 'react';
import { Backdrop } from '../Backdrop';

interface ModalProps {
  isOpen?: boolean;
  close: (result?: boolean) => void;
  title?: string;
  children: React.ReactNode;
  closeOnBackdropClick?: boolean;
}

const ANIMATION_DURATION = 200;

export function Modal({
  isOpen = true,
  close,
  title,
  children,
  closeOnBackdropClick = true,
}: ModalProps) {
  const [isExiting, setIsExiting] = useState(false);

  const handleClose = (result?: boolean) => {
    setIsExiting(true);
    setTimeout(() => {
      close(result);
    }, ANIMATION_DURATION);
  };

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
  );
}

// ============ 확인 모달 예시 ============
interface ConfirmModalProps {
  close: (result?: boolean) => void;
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
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
          className="px-5 py-2.5 rounded-lg text-sm font-medium bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
          onClick={() => close(false)}
        >
          {cancelText}
        </button>
        <button
          className="px-5 py-2.5 rounded-lg text-sm font-medium bg-blue-500 text-white hover:bg-blue-600 transition-colors"
          onClick={() => close(true)}
        >
          {confirmText}
        </button>
      </div>
    </Modal>
  );
}
```

## 사용 예시

```tsx
import { overlay } from '@/providers/overlay';
import { ConfirmModal } from '@/providers/overlay/examples/Modal';

async function handleDelete() {
  const confirmed = await overlay.open(({ close }) => (
    <ConfirmModal
      close={close}
      title="삭제 확인"
      message="이 항목을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
      confirmText="삭제"
      cancelText="취소"
    />
  ));

  if (confirmed) {
    // 삭제 로직 실행
    await deleteItem();
  }
}
```
