# Backdrop 템플릿

모달/바텀시트 뒤에 표시되는 어두운 배경 컴포넌트입니다.

## Emotion 버전

```tsx
import { useState, useEffect } from 'react';
import { css } from '@emotion/react';
import { fadeIn, fadeOut, ANIMATION_DURATION } from './animations';

interface BackdropProps {
  isOpen: boolean;
  onClick?: () => void;
  closeOnClick?: boolean;
  children: React.ReactNode;
}

const backdropStyles = css`
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgba(0, 0, 0, 0.5);
`;

const enterAnimation = css`
  animation: ${fadeIn} ${ANIMATION_DURATION.backdrop}ms ease-out forwards;
`;

const exitAnimation = css`
  animation: ${fadeOut} ${ANIMATION_DURATION.backdrop}ms ease-out forwards;
`;

export function Backdrop({
  isOpen,
  onClick,
  closeOnClick = true,
  children,
}: BackdropProps) {
  const [shouldRender, setShouldRender] = useState(isOpen);
  const [isAnimating, setIsAnimating] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setShouldRender(true);
      setIsAnimating(false);
    } else if (shouldRender) {
      setIsAnimating(true);
      const timer = setTimeout(() => {
        setShouldRender(false);
        setIsAnimating(false);
      }, ANIMATION_DURATION.backdrop);
      return () => clearTimeout(timer);
    }
  }, [isOpen, shouldRender]);

  if (!shouldRender) return null;

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && closeOnClick && onClick) {
      onClick();
    }
  };

  return (
    <div
      css={[backdropStyles, isAnimating ? exitAnimation : enterAnimation]}
      onClick={handleBackdropClick}
      role="dialog"
      aria-modal="true"
    >
      {children}
    </div>
  );
}
```

## styled-components 버전

```tsx
import { useState, useEffect } from 'react';
import styled, { css } from 'styled-components';
import { fadeIn, fadeOut } from './animations';

interface BackdropProps {
  isOpen: boolean;
  onClick?: () => void;
  closeOnClick?: boolean;
  children: React.ReactNode;
}

const ANIMATION_DURATION = 200;

const StyledBackdrop = styled.div<{ $isExiting: boolean }>`
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgba(0, 0, 0, 0.5);

  ${({ $isExiting }) =>
    $isExiting
      ? css`animation: ${fadeOut} ${ANIMATION_DURATION}ms ease-out forwards;`
      : css`animation: ${fadeIn} ${ANIMATION_DURATION}ms ease-out forwards;`}
`;

export function Backdrop({
  isOpen,
  onClick,
  closeOnClick = true,
  children,
}: BackdropProps) {
  const [shouldRender, setShouldRender] = useState(isOpen);
  const [isExiting, setIsExiting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setShouldRender(true);
      setIsExiting(false);
    } else if (shouldRender) {
      setIsExiting(true);
      const timer = setTimeout(() => {
        setShouldRender(false);
        setIsExiting(false);
      }, ANIMATION_DURATION);
      return () => clearTimeout(timer);
    }
  }, [isOpen, shouldRender]);

  if (!shouldRender) return null;

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && closeOnClick && onClick) {
      onClick();
    }
  };

  return (
    <StyledBackdrop
      $isExiting={isExiting}
      onClick={handleBackdropClick}
      role="dialog"
      aria-modal="true"
    >
      {children}
    </StyledBackdrop>
  );
}
```

## Tailwind 버전

```tsx
import { useState, useEffect } from 'react';

interface BackdropProps {
  isOpen: boolean;
  onClick?: () => void;
  closeOnClick?: boolean;
  children: React.ReactNode;
}

const ANIMATION_DURATION = 200;

export function Backdrop({
  isOpen,
  onClick,
  closeOnClick = true,
  children,
}: BackdropProps) {
  const [shouldRender, setShouldRender] = useState(isOpen);
  const [isExiting, setIsExiting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setShouldRender(true);
      setIsExiting(false);
    } else if (shouldRender) {
      setIsExiting(true);
      const timer = setTimeout(() => {
        setShouldRender(false);
        setIsExiting(false);
      }, ANIMATION_DURATION);
      return () => clearTimeout(timer);
    }
  }, [isOpen, shouldRender]);

  if (!shouldRender) return null;

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && closeOnClick && onClick) {
      onClick();
    }
  };

  return (
    <div
      className={`
        fixed inset-0 z-[1000] flex items-center justify-center
        bg-black/50
        ${isExiting ? 'animate-fade-out' : 'animate-fade-in'}
      `}
      onClick={handleBackdropClick}
      role="dialog"
      aria-modal="true"
    >
      {children}
    </div>
  );
}
```

## 바텀시트용 Backdrop (하단 정렬)

```tsx
// Emotion 버전 - 바텀시트용
const bottomSheetBackdropStyles = css`
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;  /* 하단 정렬 */
  justify-content: center;
  background-color: rgba(0, 0, 0, 0.5);
`;
```
