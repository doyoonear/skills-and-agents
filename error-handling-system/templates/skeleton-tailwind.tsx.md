# Skeleton 컴포넌트 (Tailwind CSS 버전)

> Tailwind CSS utility classes를 사용하는 Skeleton 컴포넌트입니다.
> tailwind.config.js에 커스텀 애니메이션을 추가하여 smooth 효과를 구현합니다.

---

## 📁 파일 위치

```
├── tailwind.config.js           # Tailwind 설정 (커스텀 애니메이션)
└── src/
    └── components/
        ├── Skeleton.tsx
        ├── SkeletonGroup.tsx
        └── skeletons/
            ├── index.ts
            ├── SkeletonCard.tsx
            ├── SkeletonListItem.tsx
            └── SkeletonImageCard.tsx
```

---

## 1. Tailwind 설정 (tailwind.config.js)

```javascript
// tailwind.config.js

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      // Smooth Wave Animation (duration: 2.5s)
      keyframes: {
        skeletonWave: {
          '0%': { backgroundPosition: '200% 50%' },
          '100%': { backgroundPosition: '-200% 50%' },
        },
        skeletonPulse: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.5' },
        },
      },
      animation: {
        'skeleton-wave': 'skeletonWave 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite',
        'skeleton-pulse': 'skeletonPulse 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite',
      },
      backgroundSize: {
        'skeleton': '200% 100%',
      },
      backgroundImage: {
        'skeleton-gradient': 'linear-gradient(90deg, rgba(0,0,0,0.08) 0%, rgba(0,0,0,0.08) 40%, rgba(0,0,0,0.05) 50%, rgba(0,0,0,0.08) 60%, rgba(0,0,0,0.08) 100%)',
        'skeleton-gradient-dark': 'linear-gradient(90deg, rgba(255,255,255,0.12) 0%, rgba(255,255,255,0.12) 40%, rgba(255,255,255,0.08) 50%, rgba(255,255,255,0.12) 60%, rgba(255,255,255,0.12) 100%)',
      },
    },
  },
  plugins: [],
};
```

---

## 2. Skeleton 메인 컴포넌트

```tsx
// src/components/Skeleton.tsx

import React from 'react';
import { cn } from '@/lib/utils'; // classnames utility (선택사항)

export interface SkeletonProps {
  /** 스켈레톤의 너비 (Tailwind class 또는 inline) */
  width?: string;
  /** 스켈레톤의 높이 (Tailwind class 또는 inline) */
  height?: string;
  /** 스켈레톤 형태 variant */
  variant?: 'rectangular' | 'circular' | 'text' | 'rounded';
  /** 애니메이션 여부 */
  animation?: 'wave' | 'pulse' | false;
  /** 추가 className */
  className?: string;
}

// classnames utility (없으면 직접 구현)
const cn = (...classes: (string | undefined | false)[]) => {
  return classes.filter(Boolean).join(' ');
};

const formatSize = (size?: string): string => {
  if (!size) return '';
  // Tailwind class인 경우 그대로 반환
  if (size.startsWith('w-') || size.startsWith('h-')) return size;
  // 숫자만 있으면 px 단위 추가
  if (/^\d+$/.test(size)) return `${size}px`;
  return size;
};

export const Skeleton: React.FC<SkeletonProps> = ({
  width,
  height,
  variant = 'rectangular',
  animation = 'wave',
  className,
}) => {
  const variantClasses = {
    rectangular: 'rounded-none',
    circular: 'rounded-full',
    text: 'rounded scale-y-60 origin-[0_60%]',
    rounded: 'rounded-xl',
  };

  const animationClasses = {
    wave: 'bg-skeleton-gradient dark:bg-skeleton-gradient-dark bg-skeleton animate-skeleton-wave',
    pulse: 'bg-black/[0.08] dark:bg-white/[0.12] animate-skeleton-pulse',
  };

  const baseClasses = 'inline-block relative overflow-hidden';

  // 애니메이션 없을 때 기본 배경
  const noAnimationBg = 'bg-black/[0.08] dark:bg-white/[0.12]';

  const widthStyle = width ? { width: formatSize(width) } : { width: '100%' };
  const heightStyle = height ? { height: formatSize(height) } : { height: '20px' };

  return (
    <span
      className={cn(
        baseClasses,
        variantClasses[variant],
        animation ? animationClasses[animation] : noAnimationBg,
        'motion-reduce:animate-none', // prefers-reduced-motion 지원
        className
      )}
      style={{ ...widthStyle, ...heightStyle }}
    />
  );
};

export default Skeleton;
```

---

## 3. SkeletonGroup 컴포넌트

```tsx
// src/components/SkeletonGroup.tsx

import React from 'react';
import Skeleton from './Skeleton';

export interface SkeletonGroupProps {
  /** 스켈레톤 개수 */
  count?: number;
  /** 스켈레톤 사이의 간격 (Tailwind gap class) */
  gap?: string;
  /** 세로 정렬 여부 */
  vertical?: boolean;
  /** 자식 컴포넌트 */
  children?: React.ReactNode;
}

export const SkeletonGroup: React.FC<SkeletonGroupProps> = ({
  count = 1,
  gap = 'gap-2',
  vertical = true,
  children,
}) => {
  const direction = vertical ? 'flex-col' : 'flex-row';

  if (children) {
    return <div className={`flex ${direction} ${gap}`}>{children}</div>;
  }

  return (
    <div className={`flex ${direction} ${gap}`}>
      {Array.from({ length: count }).map((_, index) => (
        <Skeleton key={index} />
      ))}
    </div>
  );
};

export default SkeletonGroup;
```

---

## 4. Preset: SkeletonCard

```tsx
// src/components/skeletons/SkeletonCard.tsx

import React from 'react';
import Skeleton from '../Skeleton';

interface SkeletonCardProps {
  className?: string;
}

export const SkeletonCard: React.FC<SkeletonCardProps> = ({ className = '' }) => {
  return (
    <div className={`flex flex-col gap-4 w-full ${className}`}>
      <Skeleton variant="rectangular" height="200px" />
      <div className="flex flex-col gap-2 px-1">
        <Skeleton variant="text" width="60%" height="24px" />
        <Skeleton variant="text" width="80%" height="16px" />
        <Skeleton variant="text" width="40%" height="16px" />
      </div>
    </div>
  );
};

export default SkeletonCard;
```

---

## 5. Preset: SkeletonListItem

```tsx
// src/components/skeletons/SkeletonListItem.tsx

import React from 'react';
import Skeleton from '../Skeleton';

interface SkeletonListItemProps {
  avatar?: boolean;
  className?: string;
}

export const SkeletonListItem: React.FC<SkeletonListItemProps> = ({
  avatar = false,
  className = '',
}) => {
  return (
    <div className={`flex items-center gap-4 py-3 ${className}`}>
      {avatar && <Skeleton variant="circular" width="40px" height="40px" />}
      <div className="flex-1 flex flex-col gap-2">
        <Skeleton variant="text" width="30%" height="20px" />
        <Skeleton variant="text" width="90%" height="16px" />
      </div>
    </div>
  );
};

export default SkeletonListItem;
```

---

## 6. Preset: SkeletonImageCard

```tsx
// src/components/skeletons/SkeletonImageCard.tsx

import React from 'react';
import Skeleton from '../Skeleton';
import SkeletonGroup from '../SkeletonGroup';

interface SkeletonImageCardProps {
  className?: string;
}

export const SkeletonImageCard: React.FC<SkeletonImageCardProps> = ({ className = '' }) => {
  return (
    <div className={`flex flex-col gap-3 w-full ${className}`}>
      <Skeleton variant="rounded" height="240px" />
      <div className="px-0.5">
        <SkeletonGroup gap="gap-1.5">
          <Skeleton variant="text" width="70%" height="18px" />
          <Skeleton variant="text" width="50%" height="14px" />
          <Skeleton variant="text" width="30%" height="14px" />
        </SkeletonGroup>
      </div>
    </div>
  );
};

export default SkeletonImageCard;
```

---

## 7. 그리드 레이아웃 Skeleton

```tsx
// src/components/skeletons/SkeletonGrid.tsx

import React from 'react';
import SkeletonCard from './SkeletonCard';

interface SkeletonGridProps {
  columns?: 2 | 3 | 4;
  count?: number;
}

const gridClasses = {
  2: 'grid grid-cols-2 gap-6 max-md:grid-cols-1',
  3: 'grid grid-cols-3 gap-6 max-lg:grid-cols-2 max-md:grid-cols-1',
  4: 'grid grid-cols-4 gap-6 max-xl:grid-cols-3 max-lg:grid-cols-2 max-md:grid-cols-1',
};

export const SkeletonGrid: React.FC<SkeletonGridProps> = ({ columns = 3, count = 9 }) => {
  return (
    <div className={gridClasses[columns]}>
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} />
      ))}
    </div>
  );
};

export default SkeletonGrid;
```

---

## 8. 사용 예시

### 8-1. 기본 사용법

```tsx
import { Skeleton } from '@/components/skeletons';

function MyComponent() {
  return (
    <div>
      {/* 기본 Skeleton */}
      <Skeleton />

      {/* Tailwind width/height classes */}
      <Skeleton width="w-48" height="h-10" />

      {/* 인라인 width/height */}
      <Skeleton width="200px" height="40px" />

      {/* variant 지정 */}
      <Skeleton variant="circular" width="w-12" height="h-12" />
      <Skeleton variant="rounded" width="w-full" height="h-48" />

      {/* 애니메이션 변경 */}
      <Skeleton animation="pulse" />
      <Skeleton animation={false} />
    </div>
  );
}
```

### 8-2. Preset 사용

```tsx
import { SkeletonCard, SkeletonListItem, SkeletonImageCard } from '@/components/skeletons';

function MyPage() {
  return (
    <div className="p-6 space-y-4">
      <SkeletonCard />
      <SkeletonListItem avatar />
      <SkeletonImageCard />
    </div>
  );
}
```

### 8-3. Suspense fallback으로 사용

```tsx
import { Suspense } from 'react';
import { SkeletonCard } from '@/components/skeletons';

function ProductCardWrapper({ productId }: { productId: number }) {
  return (
    <Suspense fallback={<SkeletonCard />}>
      <ProductCard productId={productId} />
    </Suspense>
  );
}
```

---

## 9. 커스텀 Skeleton Preset

```tsx
// src/components/skeletons/SkeletonUserProfile.tsx

import React from 'react';
import Skeleton from '../Skeleton';

export const SkeletonUserProfile: React.FC = () => {
  return (
    <div className="flex flex-col items-center gap-4 p-6">
      {/* 프로필 이미지 */}
      <Skeleton variant="circular" width="w-30" height="h-30" />

      {/* 사용자 정보 */}
      <div className="w-full flex flex-col items-center gap-2">
        <Skeleton variant="text" width="w-45" height="h-7" />
        <Skeleton variant="text" width="w-55" height="h-5" />
        <Skeleton variant="text" width="w-40" height="h-4" />
      </div>

      {/* 버튼들 */}
      <div className="flex gap-3">
        <Skeleton variant="rounded" width="w-25" height="h-9" />
        <Skeleton variant="rounded" width="w-25" height="h-9" />
      </div>
    </div>
  );
};

export default SkeletonUserProfile;
```

---

## 10. 다크모드 지원

Tailwind의 `dark:` prefix를 사용하여 자동으로 다크모드를 지원합니다.

```tsx
// tailwind.config.js에서 darkMode 설정
module.exports = {
  darkMode: 'class', // 또는 'media'
  // ...
};

// HTML에 dark 클래스 추가로 다크모드 활성화
<html class="dark">
  {/* ... */}
</html>
```

---

## 11. 접근성 (Reduced Motion)

Tailwind의 `motion-reduce:` prefix로 자동 지원됩니다.

```tsx
<Skeleton className="motion-reduce:animate-none" />
```

---

## 12. classnames Utility (선택사항)

### 방법 1: clsx 라이브러리 사용

```bash
npm install clsx
```

```typescript
// src/lib/utils.ts
import clsx, { ClassValue } from 'clsx';

export const cn = (...classes: ClassValue[]) => {
  return clsx(classes);
};
```

### 방법 2: 직접 구현

```typescript
// src/lib/utils.ts
export const cn = (...classes: (string | undefined | false)[]) => {
  return classes.filter(Boolean).join(' ');
};
```

---

## 13. index.ts (Export 모음)

```typescript
// src/components/skeletons/index.ts

export { default as Skeleton } from '../Skeleton';
export { default as SkeletonGroup } from '../SkeletonGroup';
export { default as SkeletonCard } from './SkeletonCard';
export { default as SkeletonListItem } from './SkeletonListItem';
export { default as SkeletonImageCard } from './SkeletonImageCard';
export { default as SkeletonGrid } from './SkeletonGrid';
```

---

## 참고 자료

- [Tailwind CSS 공식 문서](https://tailwindcss.com/docs)
- [Tailwind CSS Animation](https://tailwindcss.com/docs/animation)
- [Tailwind CSS Dark Mode](https://tailwindcss.com/docs/dark-mode)
