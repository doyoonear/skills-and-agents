# Skeleton 컴포넌트 (CSS Modules 버전)

> CSS Modules (*.module.css)을 사용하는 Skeleton 컴포넌트입니다.
> Smooth 애니메이션 (2.5s duration)이 적용되어 있습니다.

---

## 📁 파일 위치

```
src/
├── components/
│   ├── Skeleton.tsx
│   ├── Skeleton.module.css
│   ├── SkeletonGroup.tsx
│   └── skeletons/
│       ├── index.ts
│       ├── SkeletonCard.tsx
│       ├── SkeletonCard.module.css
│       ├── SkeletonListItem.tsx
│       ├── SkeletonListItem.module.css
│       ├── SkeletonImageCard.tsx
│       └── SkeletonImageCard.module.css
```

---

## 1. Skeleton 메인 컴포넌트

### Skeleton.tsx

```tsx
// src/components/Skeleton.tsx

import React from 'react';
import styles from './Skeleton.module.css';

export interface SkeletonProps {
  /** 스켈레톤의 너비 (px, %, rem 등) */
  width?: string | number;
  /** 스켈레톤의 높이 (px, %, rem 등) */
  height?: string | number;
  /** 스켈레톤 형태 variant */
  variant?: 'rectangular' | 'circular' | 'text' | 'rounded';
  /** 애니메이션 여부 */
  animation?: 'wave' | 'pulse' | false;
  /** 추가 className */
  className?: string;
  /** 인라인 스타일 */
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
  const variantClasses = {
    rectangular: styles.rectangular,
    circular: styles.circular,
    text: styles.text,
    rounded: styles.rounded,
  };

  const animationClasses = {
    wave: styles.wave,
    pulse: styles.pulse,
  };

  const classes = [
    styles.skeleton,
    variantClasses[variant],
    animation && animationClasses[animation],
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

### Skeleton.module.css

```css
/* src/components/Skeleton.module.css */

/* ========================================
   Base Styles
   ======================================== */

.skeleton {
  display: inline-block;
  position: relative;
  overflow: hidden;
  background-color: rgba(0, 0, 0, 0.08); /* 낮은 대비 */
}

/* ========================================
   Variant Styles
   ======================================== */

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

/* ========================================
   Smooth Wave Animation (duration: 2.5s)
   ======================================== */

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
    rgba(0, 0, 0, 0.08) 0%,
    rgba(0, 0, 0, 0.08) 40%,
    rgba(0, 0, 0, 0.05) 50%, /* 부드러운 highlight */
    rgba(0, 0, 0, 0.08) 60%,
    rgba(0, 0, 0, 0.08) 100%
  );
  background-size: 200% 100%;
  animation: skeletonWave 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}

/* ========================================
   Pulse Animation (duration: 2.5s)
   ======================================== */

@keyframes skeletonPulse {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
  100% {
    opacity: 1;
  }
}

.pulse {
  animation: skeletonPulse 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}

/* ========================================
   Dark Mode Support
   ======================================== */

@media (prefers-color-scheme: dark) {
  .skeleton {
    background-color: rgba(255, 255, 255, 0.12);
  }

  .wave {
    background: linear-gradient(
      90deg,
      rgba(255, 255, 255, 0.12) 0%,
      rgba(255, 255, 255, 0.12) 40%,
      rgba(255, 255, 255, 0.08) 50%,
      rgba(255, 255, 255, 0.12) 60%,
      rgba(255, 255, 255, 0.12) 100%
    );
  }
}

/* ========================================
   Accessibility: Reduced Motion
   ======================================== */

@media (prefers-reduced-motion: reduce) {
  .wave,
  .pulse {
    animation: none !important;
  }
}
```

---

## 2. SkeletonGroup 컴포넌트

```tsx
// src/components/SkeletonGroup.tsx

import React from 'react';
import Skeleton from './Skeleton';

export interface SkeletonGroupProps {
  /** 스켈레톤 개수 */
  count?: number;
  /** 스켈레톤 사이의 간격 (px, rem 등) */
  gap?: string | number;
  /** 세로 정렬 여부 */
  vertical?: boolean;
  /** 자식 컴포넌트 */
  children?: React.ReactNode;
}

const formatSize = (size: string | number | undefined): string => {
  if (typeof size === 'number') return `${size}px`;
  return size || '8px';
};

export const SkeletonGroup: React.FC<SkeletonGroupProps> = ({
  count = 1,
  gap = '8px',
  vertical = true,
  children,
}) => {
  const groupStyle: React.CSSProperties = {
    display: 'flex',
    flexDirection: vertical ? 'column' : 'row',
    gap: formatSize(gap),
  };

  if (children) {
    return <div style={groupStyle}>{children}</div>;
  }

  return (
    <div style={groupStyle}>
      {Array.from({ length: count }).map((_, index) => (
        <Skeleton key={index} />
      ))}
    </div>
  );
};

export default SkeletonGroup;
```

---

## 3. Preset: SkeletonCard

### SkeletonCard.tsx

```tsx
// src/components/skeletons/SkeletonCard.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import styles from './SkeletonCard.module.css';

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

### SkeletonCard.module.css

```css
/* src/components/skeletons/SkeletonCard.module.css */

.card {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 0;
  width: 100%;
}

.content {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 4px;
}
```

---

## 4. Preset: SkeletonListItem

### SkeletonListItem.tsx

```tsx
// src/components/skeletons/SkeletonListItem.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import styles from './SkeletonListItem.module.css';

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

### SkeletonListItem.module.css

```css
/* src/components/skeletons/SkeletonListItem.module.css */

.listItem {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 0;
}

.content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
```

---

## 5. Preset: SkeletonImageCard

### SkeletonImageCard.tsx

```tsx
// src/components/skeletons/SkeletonImageCard.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import SkeletonGroup from '../SkeletonGroup';
import styles from './SkeletonImageCard.module.css';

interface SkeletonImageCardProps {
  className?: string;
}

export const SkeletonImageCard: React.FC<SkeletonImageCardProps> = ({ className = '' }) => {
  return (
    <div className={`${styles.imageCard} ${className}`}>
      <Skeleton variant="rounded" height={240} />
      <div className={styles.content}>
        <SkeletonGroup gap={6}>
          <Skeleton variant="text" width="70%" height={18} />
          <Skeleton variant="text" width="50%" height={14} />
          <Skeleton variant="text" width="30%" height={14} />
        </SkeletonGroup>
      </div>
    </div>
  );
};

export default SkeletonImageCard;
```

### SkeletonImageCard.module.css

```css
/* src/components/skeletons/SkeletonImageCard.module.css */

.imageCard {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
}

.content {
  padding: 0 2px;
}
```

---

## 6. index.ts (Export 모음)

```typescript
// src/components/skeletons/index.ts

export { default as Skeleton } from '../Skeleton';
export { default as SkeletonGroup } from '../SkeletonGroup';
export { default as SkeletonCard } from './SkeletonCard';
export { default as SkeletonListItem } from './SkeletonListItem';
export { default as SkeletonImageCard } from './SkeletonImageCard';
```

---

## 7. 사용 예시

### 7-1. 기본 사용법

```tsx
import { Skeleton } from '@/components/skeletons';

function MyComponent() {
  return (
    <div>
      {/* 기본 Skeleton */}
      <Skeleton />

      {/* 너비/높이 지정 */}
      <Skeleton width={200} height={40} />

      {/* variant 지정 */}
      <Skeleton variant="circular" width={48} height={48} />
      <Skeleton variant="rounded" width="100%" height={200} />

      {/* 애니메이션 변경 */}
      <Skeleton animation="pulse" />
      <Skeleton animation={false} /> {/* 애니메이션 없음 */}
    </div>
  );
}
```

### 7-2. Preset 사용

```tsx
import { SkeletonCard, SkeletonListItem, SkeletonImageCard } from '@/components/skeletons';

function MyPage() {
  return (
    <div>
      {/* 카드 스켈레톤 */}
      <SkeletonCard />

      {/* 리스트 아이템 스켈레톤 */}
      <SkeletonListItem avatar />

      {/* 이미지 카드 스켈레톤 */}
      <SkeletonImageCard />
    </div>
  );
}
```

### 7-3. Suspense fallback으로 사용

```tsx
import { Suspense } from 'react';
import { SkeletonCard } from '@/components/skeletons';
import { useQuery } from '@tanstack/react-query';

function ProductCard({ productId }: { productId: number }) {
  const { data } = useQuery({
    queryKey: ['product', productId],
    queryFn: () => fetchProduct(productId),
    suspense: true,
  });

  return <div>{/* 실제 카드 렌더링 */}</div>;
}

function ProductCardWrapper({ productId }: { productId: number }) {
  return (
    <Suspense fallback={<SkeletonCard />}>
      <ProductCard productId={productId} />
    </Suspense>
  );
}
```

---

## 8. 그리드 레이아웃 Skeleton

### SkeletonGrid.tsx

```tsx
// src/components/skeletons/SkeletonGrid.tsx

import React from 'react';
import SkeletonCard from './SkeletonCard';
import styles from './SkeletonGrid.module.css';

interface SkeletonGridProps {
  columns?: 2 | 3 | 4;
  count?: number;
}

export const SkeletonGrid: React.FC<SkeletonGridProps> = ({ columns = 3, count = 9 }) => {
  const gridClass = {
    2: styles.grid2,
    3: styles.grid3,
    4: styles.grid4,
  }[columns];

  return (
    <div className={`${styles.grid} ${gridClass}`}>
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} />
      ))}
    </div>
  );
};

export default SkeletonGrid;
```

### SkeletonGrid.module.css

```css
/* src/components/skeletons/SkeletonGrid.module.css */

.grid {
  display: grid;
  gap: 24px;
}

.grid2 {
  grid-template-columns: repeat(2, 1fr);
}

.grid3 {
  grid-template-columns: repeat(3, 1fr);
}

.grid4 {
  grid-template-columns: repeat(4, 1fr);
}

/* Responsive */

@media (max-width: 1280px) {
  .grid4 {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 1024px) {
  .grid4,
  .grid3 {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .grid4,
  .grid3,
  .grid2 {
    grid-template-columns: 1fr;
  }
}
```

---

## 9. 커스텀 Skeleton Preset 제작 가이드

### SkeletonUserProfile.tsx

```tsx
// src/components/skeletons/SkeletonUserProfile.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import styles from './SkeletonUserProfile.module.css';

export const SkeletonUserProfile: React.FC = () => {
  return (
    <div className={styles.profile}>
      {/* 프로필 이미지 */}
      <Skeleton variant="circular" width={120} height={120} />

      {/* 사용자 정보 */}
      <div className={styles.info}>
        <Skeleton variant="text" width={180} height={28} />
        <Skeleton variant="text" width={220} height={20} />
        <Skeleton variant="text" width={160} height={16} />
      </div>

      {/* 버튼들 */}
      <div className={styles.buttons}>
        <Skeleton variant="rounded" width={100} height={36} />
        <Skeleton variant="rounded" width={100} height={36} />
      </div>
    </div>
  );
};

export default SkeletonUserProfile;
```

### SkeletonUserProfile.module.css

```css
/* src/components/skeletons/SkeletonUserProfile.module.css */

.profile {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 24px;
}

.info {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.buttons {
  display: flex;
  gap: 12px;
}
```

---

## 10. 테마 커스터마이징

CSS Variables를 활용하여 프로젝트 전체의 Skeleton 색상을 쉽게 변경할 수 있습니다.

### Skeleton.module.css (수정)

```css
/* CSS Variables 추가 */
.skeleton {
  display: inline-block;
  position: relative;
  overflow: hidden;
  background-color: var(--skeleton-bg, rgba(0, 0, 0, 0.08));
}

.wave {
  background: linear-gradient(
    90deg,
    var(--skeleton-bg, rgba(0, 0, 0, 0.08)) 0%,
    var(--skeleton-bg, rgba(0, 0, 0, 0.08)) 40%,
    var(--skeleton-highlight, rgba(0, 0, 0, 0.05)) 50%,
    var(--skeleton-bg, rgba(0, 0, 0, 0.08)) 60%,
    var(--skeleton-bg, rgba(0, 0, 0, 0.08)) 100%
  );
  background-size: 200% 100%;
  animation: skeletonWave 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}
```

### globals.css (또는 App.css)

```css
/* src/globals.css */

:root {
  /* Light mode */
  --skeleton-bg: rgba(0, 0, 0, 0.08);
  --skeleton-highlight: rgba(0, 0, 0, 0.05);
}

@media (prefers-color-scheme: dark) {
  :root {
    /* Dark mode */
    --skeleton-bg: rgba(255, 255, 255, 0.12);
    --skeleton-highlight: rgba(255, 255, 255, 0.08);
  }
}
```

---

## 11. TypeScript Tips

### 타입 안전한 variant 확장

```typescript
// src/components/types/skeleton.ts

export type SkeletonVariant = 'rectangular' | 'circular' | 'text' | 'rounded';
export type SkeletonAnimation = 'wave' | 'pulse' | false;

export interface SkeletonProps {
  width?: string | number;
  height?: string | number;
  variant?: SkeletonVariant;
  animation?: SkeletonAnimation;
  className?: string;
  style?: React.CSSProperties;
}
```

---

## 참고 자료

- [CSS Modules 공식 문서](https://github.com/css-modules/css-modules)
- [React + CSS Modules](https://create-react-app.dev/docs/adding-a-css-modules-stylesheet/)
