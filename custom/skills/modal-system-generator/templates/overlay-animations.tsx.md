# Overlay Animations 템플릿

애니메이션 keyframes와 스타일을 정의하는 파일입니다.

## Emotion 버전

```tsx
import { css, keyframes } from '@emotion/react';

// ============ Keyframes ============

// Fade
export const fadeIn = keyframes`
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
`;

export const fadeOut = keyframes`
  from {
    opacity: 1;
  }
  to {
    opacity: 0;
  }
`;

// Scale (모달용)
export const scaleIn = keyframes`
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
`;

export const scaleOut = keyframes`
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.95);
  }
`;

// Slide (바텀시트용)
export const slideUp = keyframes`
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
`;

export const slideDown = keyframes`
  from {
    transform: translateY(0);
  }
  to {
    transform: translateY(100%);
  }
`;

// ============ Animation Styles ============

export const backdropAnimation = {
  enter: css`
    animation: ${fadeIn} 0.2s ease-out forwards;
  `,
  exit: css`
    animation: ${fadeOut} 0.2s ease-out forwards;
  `,
};

export const modalAnimation = {
  enter: css`
    animation: ${scaleIn} 0.2s ease-out forwards;
  `,
  exit: css`
    animation: ${scaleOut} 0.15s ease-out forwards;
  `,
};

export const bottomSheetAnimation = {
  enter: css`
    animation: ${slideUp} 0.3s ease-out forwards;
  `,
  exit: css`
    animation: ${slideDown} 0.25s ease-out forwards;
  `,
};

// ============ Duration Constants ============
export const ANIMATION_DURATION = {
  backdrop: 200,
  modal: 200,
  bottomSheet: 300,
} as const;
```

## styled-components 버전

```tsx
import { keyframes, css } from 'styled-components';

// Keyframes는 동일
export const fadeIn = keyframes`
  from { opacity: 0; }
  to { opacity: 1; }
`;

export const fadeOut = keyframes`
  from { opacity: 1; }
  to { opacity: 0; }
`;

export const scaleIn = keyframes`
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
`;

export const scaleOut = keyframes`
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.95);
  }
`;

export const slideUp = keyframes`
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
`;

export const slideDown = keyframes`
  from { transform: translateY(0); }
  to { transform: translateY(100%); }
`;

// Animation mixins
export const backdropEnter = css`
  animation: ${fadeIn} 0.2s ease-out forwards;
`;

export const backdropExit = css`
  animation: ${fadeOut} 0.2s ease-out forwards;
`;

export const modalEnter = css`
  animation: ${scaleIn} 0.2s ease-out forwards;
`;

export const modalExit = css`
  animation: ${scaleOut} 0.15s ease-out forwards;
`;

export const bottomSheetEnter = css`
  animation: ${slideUp} 0.3s ease-out forwards;
`;

export const bottomSheetExit = css`
  animation: ${slideDown} 0.25s ease-out forwards;
`;
```

## Tailwind 버전 (CSS 파일)

```css
/* animations.css - Tailwind 프로젝트에서 global CSS에 추가 */

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}

@keyframes scaleIn {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes scaleOut {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.95);
  }
}

@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

@keyframes slideDown {
  from { transform: translateY(0); }
  to { transform: translateY(100%); }
}

/* Utility classes */
.animate-fade-in {
  animation: fadeIn 0.2s ease-out forwards;
}

.animate-fade-out {
  animation: fadeOut 0.2s ease-out forwards;
}

.animate-scale-in {
  animation: scaleIn 0.2s ease-out forwards;
}

.animate-scale-out {
  animation: scaleOut 0.15s ease-out forwards;
}

.animate-slide-up {
  animation: slideUp 0.3s ease-out forwards;
}

.animate-slide-down {
  animation: slideDown 0.25s ease-out forwards;
}
```

또는 Tailwind config에 추가:

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeOut: {
          '0%': { opacity: '1' },
          '100%': { opacity: '0' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        slideUp: {
          '0%': { transform: 'translateY(100%)' },
          '100%': { transform: 'translateY(0)' },
        },
        slideDown: {
          '0%': { transform: 'translateY(0)' },
          '100%': { transform: 'translateY(100%)' },
        },
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out forwards',
        'fade-out': 'fadeOut 0.2s ease-out forwards',
        'scale-in': 'scaleIn 0.2s ease-out forwards',
        'slide-up': 'slideUp 0.3s ease-out forwards',
        'slide-down': 'slideDown 0.25s ease-out forwards',
      },
    },
  },
};
```
