# Skeleton 컴포넌트 (Emotion 버전)

> Emotion (@emotion/react, @emotion/styled)을 사용하는 Skeleton 컴포넌트입니다.
> Smooth 애니메이션 (2.5s duration)이 적용되어 있습니다.

---

## 📁 파일 위치

```
src/
├── components/
│   ├── Skeleton.tsx          # 메인 Skeleton 컴포넌트
│   └── skeletons/            # Preset Skeleton 컴포넌트들
│       ├── index.ts
│       ├── SkeletonCard.tsx
│       ├── SkeletonListItem.tsx
│       └── SkeletonImageCard.tsx
```

---

## 1. Skeleton 메인 컴포넌트

```tsx
// src/components/Skeleton.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css, keyframes } from '@emotion/react';

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

// ========================================
// Smooth 애니메이션 정의 (duration: 2.5s)
// ========================================

const waveAnimation = keyframes`
  0% {
    background-position: 200% 50%;
  }
  100% {
    background-position: -200% 50%;
  }
`;

const pulseAnimation = keyframes`
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
  100% {
    opacity: 1;
  }
`;

// ========================================
// 스타일 정의
// ========================================

const baseStyle = css`
  display: inline-block;
  position: relative;
  overflow: hidden;
  background-color: rgba(0, 0, 0, 0.08); /* 낮은 대비 */
`;

const variantStyles = {
  rectangular: css`
    border-radius: 0;
  `,
  circular: css`
    border-radius: 50%;
  `,
  text: css`
    border-radius: 4px;
    transform: scale(1, 0.6);
    transform-origin: 0 60%;
  `,
  rounded: css`
    border-radius: 12px;
  `,
};

const animationStyles = {
  wave: css`
    background: linear-gradient(
      90deg,
      rgba(0, 0, 0, 0.08) 0%,
      rgba(0, 0, 0, 0.08) 40%,
      rgba(0, 0, 0, 0.05) 50%, /* 부드러운 highlight */
      rgba(0, 0, 0, 0.08) 60%,
      rgba(0, 0, 0, 0.08) 100%
    );
    background-size: 200% 100%;
    animation: ${waveAnimation} 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
  `,
  pulse: css`
    animation: ${pulseAnimation} 2.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
  `,
};

// 다크모드 지원
const darkModeStyle = css`
  @media (prefers-color-scheme: dark) {
    background-color: rgba(255, 255, 255, 0.12);
  }
`;

const darkModeWaveStyle = css`
  @media (prefers-color-scheme: dark) {
    background: linear-gradient(
      90deg,
      rgba(255, 255, 255, 0.12) 0%,
      rgba(255, 255, 255, 0.12) 40%,
      rgba(255, 255, 255, 0.08) 50%,
      rgba(255, 255, 255, 0.12) 60%,
      rgba(255, 255, 255, 0.12) 100%
    );
  }
`;

// 접근성: prefers-reduced-motion 지원
const reducedMotionStyle = css`
  @media (prefers-reduced-motion: reduce) {
    animation: none !important;
  }
`;

// ========================================
// 유틸리티 함수
// ========================================

const formatSize = (size: string | number | undefined): string | undefined => {
  if (typeof size === 'number') return `${size}px`;
  return size;
};

// ========================================
// Skeleton 컴포넌트
// ========================================

export const Skeleton: React.FC<SkeletonProps> = ({
  width = '100%',
  height = '20px',
  variant = 'rectangular',
  animation = 'wave',
  className = '',
  style = {},
}) => {
  const styles = [
    baseStyle,
    variantStyles[variant],
    animation && animationStyles[animation],
    darkModeStyle,
    animation === 'wave' && darkModeWaveStyle,
    reducedMotionStyle,
  ];

  const skeletonStyle: React.CSSProperties = {
    width: formatSize(width),
    height: formatSize(height),
    ...style,
  };

  return <span css={styles} className={className} style={skeletonStyle} />;
};

export default Skeleton;
```

---

## 2. SkeletonGroup 컴포넌트

```tsx
// src/components/SkeletonGroup.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css } from '@emotion/react';
import Skeleton from './Skeleton';

export interface SkeletonGroupProps {
  /** 스켈레톤 개수 */
  count?: number;
  /** 스켈레톤 사이의 간격 */
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
  const groupStyle = css`
    display: flex;
    flex-direction: ${vertical ? 'column' : 'row'};
    gap: ${formatSize(gap)};
  `;

  if (children) {
    return <div css={groupStyle}>{children}</div>;
  }

  return (
    <div css={groupStyle}>
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

```tsx
// src/components/skeletons/SkeletonCard.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css } from '@emotion/react';
import Skeleton from '../Skeleton';

interface SkeletonCardProps {
  className?: string;
}

const cardStyle = css`
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 0;
  width: 100%;
`;

const contentStyle = css`
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 4px;
`;

export const SkeletonCard: React.FC<SkeletonCardProps> = ({ className = '' }) => {
  return (
    <div css={cardStyle} className={className}>
      <Skeleton variant="rectangular" height={200} />
      <div css={contentStyle}>
        <Skeleton variant="text" width="60%" height={24} />
        <Skeleton variant="text" width="80%" height={16} />
        <Skeleton variant="text" width="40%" height={16} />
      </div>
    </div>
  );
};

export default SkeletonCard;
```

---

## 4. Preset: SkeletonListItem

```tsx
// src/components/skeletons/SkeletonListItem.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css } from '@emotion/react';
import Skeleton from '../Skeleton';

interface SkeletonListItemProps {
  avatar?: boolean;
  className?: string;
}

const listItemStyle = css`
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 0;
`;

const contentStyle = css`
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
`;

export const SkeletonListItem: React.FC<SkeletonListItemProps> = ({
  avatar = false,
  className = '',
}) => {
  return (
    <div css={listItemStyle} className={className}>
      {avatar && <Skeleton variant="circular" width={40} height={40} />}
      <div css={contentStyle}>
        <Skeleton variant="text" width="30%" height={20} />
        <Skeleton variant="text" width="90%" height={16} />
      </div>
    </div>
  );
};

export default SkeletonListItem;
```

---

## 5. Preset: SkeletonImageCard

```tsx
// src/components/skeletons/SkeletonImageCard.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css } from '@emotion/react';
import Skeleton from '../Skeleton';
import SkeletonGroup from '../SkeletonGroup';

interface SkeletonImageCardProps {
  className?: string;
}

const imageCardStyle = css`
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
`;

const contentStyle = css`
  padding: 0 2px;
`;

export const SkeletonImageCard: React.FC<SkeletonImageCardProps> = ({ className = '' }) => {
  return (
    <div css={imageCardStyle} className={className}>
      <Skeleton variant="rounded" height={240} />
      <div css={contentStyle}>
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

### 7-2. SkeletonGroup 사용

```tsx
import { SkeletonGroup } from '@/components/skeletons';

function MyList() {
  return (
    <SkeletonGroup count={5} gap={16} vertical>
      {/* 자동으로 5개의 Skeleton 생성 */}
    </SkeletonGroup>
  );
}
```

### 7-3. Preset 사용

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

### 7-4. Suspense fallback으로 사용

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

## 8. 커스텀 Skeleton Preset 제작 가이드

```tsx
// src/components/skeletons/SkeletonUserProfile.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css } from '@emotion/react';
import Skeleton from '../Skeleton';

const profileStyle = css`
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 24px;
`;

const infoStyle = css`
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
`;

export const SkeletonUserProfile: React.FC = () => {
  return (
    <div css={profileStyle}>
      {/* 프로필 이미지 */}
      <Skeleton variant="circular" width={120} height={120} />

      {/* 사용자 정보 */}
      <div css={infoStyle}>
        <Skeleton variant="text" width={180} height={28} />
        <Skeleton variant="text" width={220} height={20} />
        <Skeleton variant="text" width={160} height={16} />
      </div>

      {/* 버튼들 */}
      <div css={css`display: flex; gap: 12px;`}>
        <Skeleton variant="rounded" width={100} height={36} />
        <Skeleton variant="rounded" width={100} height={36} />
      </div>
    </div>
  );
};

export default SkeletonUserProfile;
```

---

## 9. 그리드 레이아웃 Skeleton

```tsx
// src/components/skeletons/SkeletonGrid.tsx

/** @jsxImportSource @emotion/react */
import React from 'react';
import { css } from '@emotion/react';
import SkeletonCard from './SkeletonCard';

interface SkeletonGridProps {
  columns?: 2 | 3 | 4;
  count?: number;
}

const gridStyles = {
  2: css`
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;

    @media (max-width: 768px) {
      grid-template-columns: 1fr;
    }
  `,
  3: css`
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;

    @media (max-width: 1024px) {
      grid-template-columns: repeat(2, 1fr);
    }

    @media (max-width: 768px) {
      grid-template-columns: 1fr;
    }
  `,
  4: css`
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 24px;

    @media (max-width: 1280px) {
      grid-template-columns: repeat(3, 1fr);
    }

    @media (max-width: 1024px) {
      grid-template-columns: repeat(2, 1fr);
    }

    @media (max-width: 768px) {
      grid-template-columns: 1fr;
    }
  `,
};

export const SkeletonGrid: React.FC<SkeletonGridProps> = ({ columns = 3, count = 9 }) => {
  return (
    <div css={gridStyles[columns]}>
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} />
      ))}
    </div>
  );
};

export default SkeletonGrid;
```

---

## 10. 성능 최적화 팁

### 10-1. memo 사용

```tsx
import React, { memo } from 'react';

export const SkeletonCard = memo(() => {
  return (
    <div css={cardStyle}>
      {/* ... */}
    </div>
  );
});
```

### 10-2. 애니메이션 조건부 적용

```tsx
// 사용자 환경설정에 따라 애니메이션 비활성화
const useReducedMotion = () => {
  const [prefersReducedMotion, setPrefersReducedMotion] = React.useState(false);

  React.useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);

    const handleChange = () => {
      setPrefersReducedMotion(mediaQuery.matches);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  return prefersReducedMotion;
};

export const Skeleton = ({ animation = 'wave', ...props }) => {
  const prefersReducedMotion = useReducedMotion();
  const finalAnimation = prefersReducedMotion ? false : animation;

  return <span css={styles} {...props} />;
};
```

---

## 참고 자료

- [Emotion 공식 문서](https://emotion.sh/docs/introduction)
- [CSS-in-JS Performance](https://emotion.sh/docs/best-practices)
