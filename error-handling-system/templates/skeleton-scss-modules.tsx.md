# Skeleton 컴포넌트 (SCSS Modules 버전)

> SCSS Modules (*.module.scss)을 사용하는 Skeleton 컴포넌트입니다.
> SCSS의 변수, mixin, 중첩 구문을 활용하여 유지보수성을 높였습니다.

---

## 📁 파일 위치

```
src/
├── components/
│   ├── Skeleton.tsx
│   ├── Skeleton.module.scss
│   ├── SkeletonGroup.tsx
│   └── skeletons/
│       ├── index.ts
│       ├── SkeletonCard.tsx
│       ├── SkeletonCard.module.scss
│       ├── SkeletonListItem.tsx
│       ├── SkeletonListItem.module.scss
│       ├── SkeletonImageCard.tsx
│       └── SkeletonImageCard.module.scss
```

---

## 1. Skeleton 메인 컴포넌트

### Skeleton.tsx

```tsx
// src/components/Skeleton.tsx

import React from 'react';
import styles from './Skeleton.module.scss';

export interface SkeletonProps {
  width?: string | number;
  height?: string | number;
  variant?: 'rectangular' | 'circular' | 'text' | 'rounded';
  animation?: 'wave' | 'pulse' | false;
  className?: string;
  style?: React.CSSProperties;
}

const formatSize = (size: string | number | undefined): string | undefined => {
  if (typeof size === 'number') return `${size}px`;
  return size;
};

export const Skeleton: React.FC<SkeletonProps> = ({
  width = '100%',
  height = '20px',
  variant = 'rectangular',
  animation = 'wave',
  className = '',
  style = {},
}) => {
  const classes = [
    styles.skeleton,
    styles[variant],
    animation && styles[animation],
    className,
  ]
    .filter(Boolean)
    .join(' ');

  const skeletonStyle: React.CSSProperties = {
    width: formatSize(width),
    height: formatSize(height),
    ...style,
  };

  return <span className={classes} style={skeletonStyle} />;
};

export default Skeleton;
```

### Skeleton.module.scss

```scss
// src/components/Skeleton.module.scss

// ========================================
// Variables
// ========================================

$skeleton-bg-light: rgba(0, 0, 0, 0.08);
$skeleton-highlight-light: rgba(0, 0, 0, 0.05);
$skeleton-bg-dark: rgba(255, 255, 255, 0.12);
$skeleton-highlight-dark: rgba(255, 255, 255, 0.08);

$animation-duration: 2.5s;
$animation-timing: cubic-bezier(0.4, 0, 0.2, 1);

// ========================================
// Mixins
// ========================================

@mixin smooth-animation($name, $duration: $animation-duration, $timing: $animation-timing) {
  animation: $name $duration $timing infinite;
}

// ========================================
// Base Styles
// ========================================

.skeleton {
  display: inline-block;
  position: relative;
  overflow: hidden;
  background-color: $skeleton-bg-light;

  // Dark mode
  @media (prefers-color-scheme: dark) {
    background-color: $skeleton-bg-dark;
  }

  // Reduced motion
  @media (prefers-reduced-motion: reduce) {
    animation: none !important;
  }
}

// ========================================
// Variant Styles
// ========================================

.rectangular {
  border-radius: 0;
}

.circular {
  border-radius: 50%;
}

.text {
  border-radius: 4px;
  transform: scale(1, 0.6);
  transform-origin: 0 60%;
}

.rounded {
  border-radius: 12px;
}

// ========================================
// Smooth Wave Animation
// ========================================

@keyframes skeletonWave {
  0% {
    background-position: 200% 50%;
  }
  100% {
    background-position: -200% 50%;
  }
}

.wave {
  background: linear-gradient(
    90deg,
    $skeleton-bg-light 0%,
    $skeleton-bg-light 40%,
    $skeleton-highlight-light 50%,
    $skeleton-bg-light 60%,
    $skeleton-bg-light 100%
  );
  background-size: 200% 100%;
  @include smooth-animation(skeletonWave);

  // Dark mode
  @media (prefers-color-scheme: dark) {
    background: linear-gradient(
      90deg,
      $skeleton-bg-dark 0%,
      $skeleton-bg-dark 40%,
      $skeleton-highlight-dark 50%,
      $skeleton-bg-dark 60%,
      $skeleton-bg-dark 100%
    );
  }
}

// ========================================
// Pulse Animation
// ========================================

@keyframes skeletonPulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.pulse {
  @include smooth-animation(skeletonPulse);
}
```

---

## 2. Preset: SkeletonCard

### SkeletonCard.tsx

```tsx
// src/components/skeletons/SkeletonCard.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import styles from './SkeletonCard.module.scss';

interface SkeletonCardProps {
  className?: string;
}

export const SkeletonCard: React.FC<SkeletonCardProps> = ({ className = '' }) => {
  return (
    <div className={`${styles.card} ${className}`}>
      <Skeleton variant="rectangular" height={200} />
      <div className={styles.content}>
        <Skeleton variant="text" width="60%" height={24} />
        <Skeleton variant="text" width="80%" height={16} />
        <Skeleton variant="text" width="40%" height={16} />
      </div>
    </div>
  );
};

export default SkeletonCard;
```

### SkeletonCard.module.scss

```scss
// src/components/skeletons/SkeletonCard.module.scss

$card-gap: 16px;
$content-gap: 8px;

.card {
  display: flex;
  flex-direction: column;
  gap: $card-gap;
  padding: 0;
  width: 100%;

  .content {
    display: flex;
    flex-direction: column;
    gap: $content-gap;
    padding: 0 4px;
  }
}
```

---

## 3. Preset: SkeletonListItem

### SkeletonListItem.tsx

```tsx
// src/components/skeletons/SkeletonListItem.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import styles from './SkeletonListItem.module.scss';

interface SkeletonListItemProps {
  avatar?: boolean;
  className?: string;
}

export const SkeletonListItem: React.FC<SkeletonListItemProps> = ({
  avatar = false,
  className = '',
}) => {
  return (
    <div className={`${styles.listItem} ${className}`}>
      {avatar && <Skeleton variant="circular" width={40} height={40} />}
      <div className={styles.content}>
        <Skeleton variant="text" width="30%" height={20} />
        <Skeleton variant="text" width="90%" height={16} />
      </div>
    </div>
  );
};

export default SkeletonListItem;
```

### SkeletonListItem.module.scss

```scss
// src/components/skeletons/SkeletonListItem.module.scss

.listItem {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 0;

  .content {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
}
```

---

## 4. 그리드 레이아웃 Skeleton

### SkeletonGrid.module.scss

```scss
// src/components/skeletons/SkeletonGrid.module.scss

$grid-gap: 24px;
$breakpoint-tablet: 1024px;
$breakpoint-mobile: 768px;

.grid {
  display: grid;
  gap: $grid-gap;

  &.grid2 {
    grid-template-columns: repeat(2, 1fr);

    @media (max-width: $breakpoint-mobile) {
      grid-template-columns: 1fr;
    }
  }

  &.grid3 {
    grid-template-columns: repeat(3, 1fr);

    @media (max-width: $breakpoint-tablet) {
      grid-template-columns: repeat(2, 1fr);
    }

    @media (max-width: $breakpoint-mobile) {
      grid-template-columns: 1fr;
    }
  }

  &.grid4 {
    grid-template-columns: repeat(4, 1fr);

    @media (max-width: 1280px) {
      grid-template-columns: repeat(3, 1fr);
    }

    @media (max-width: $breakpoint-tablet) {
      grid-template-columns: repeat(2, 1fr);
    }

    @media (max-width: $breakpoint-mobile) {
      grid-template-columns: 1fr;
    }
  }
}
```

---

## 5. 테마 시스템 (SCSS Variables)

### _variables.scss

```scss
// src/styles/_variables.scss

// Skeleton Colors
$skeleton-bg-light: rgba(0, 0, 0, 0.08) !default;
$skeleton-highlight-light: rgba(0, 0, 0, 0.05) !default;
$skeleton-bg-dark: rgba(255, 255, 255, 0.12) !default;
$skeleton-highlight-dark: rgba(255, 255, 255, 0.08) !default;

// Animation
$skeleton-animation-duration: 2.5s !default;
$skeleton-animation-timing: cubic-bezier(0.4, 0, 0.2, 1) !default;

// Spacing
$skeleton-gap-small: 8px !default;
$skeleton-gap-medium: 16px !default;
$skeleton-gap-large: 24px !default;
```

### Skeleton.module.scss (수정 버전)

```scss
// src/components/Skeleton.module.scss

@import '../styles/variables';

.skeleton {
  display: inline-block;
  position: relative;
  overflow: hidden;
  background-color: $skeleton-bg-light;

  @media (prefers-color-scheme: dark) {
    background-color: $skeleton-bg-dark;
  }

  @media (prefers-reduced-motion: reduce) {
    animation: none !important;
  }
}

// ... 나머지 코드
```

---

## 6. 사용 예시

CSS Modules 버전과 동일하게 사용하면 됩니다.

```tsx
import { Skeleton, SkeletonCard, SkeletonListItem } from '@/components/skeletons';

function MyComponent() {
  return (
    <div>
      <Skeleton variant="rounded" width="100%" height={200} />
      <SkeletonCard />
      <SkeletonListItem avatar />
    </div>
  );
}
```

---

## 참고 자료

- [SCSS/Sass 공식 문서](https://sass-lang.com/documentation)
- [CSS Modules with SCSS](https://github.com/css-modules/css-modules#css-modules-with-scss)
