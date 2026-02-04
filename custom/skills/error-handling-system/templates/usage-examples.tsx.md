# 실전 사용 예시

> ErrorBoundary + Suspense + Skeleton을 TanStack Query와 함께 사용하는 실전 패턴입니다.

---

## 목차

1. [기본 패턴](#1-기본-패턴)
2. [리스트 페이지](#2-리스트-페이지)
3. [상세 페이지](#3-상세-페이지)
4. [무한 스크롤](#4-무한-스크롤)
5. [병렬 API 호출](#5-병렬-api-호출)
6. [전역 vs 로컬 에러](#6-전역-vs-로컬-에러)
7. [중첩 Suspense](#7-중첩-suspense)
8. [조건부 렌더링](#8-조건부-렌더링)

---

## 1. 기본 패턴

### ErrorBoundary > Suspense > Component

```tsx
// src/pages/UserPage.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import ErrorBoundary from '@/components/ErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import { SkeletonCard } from '@/components/skeletons';

// API 함수
async function fetchUser(userId: number) {
  const response = await fetch(`/api/users/${userId}`);
  if (!response.ok) throw new Error('Failed to fetch user');
  return response.json();
}

// 실제 데이터를 렌더링하는 컴포넌트
function UserContent({ userId }: { userId: number }) {
  const { data: user } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    suspense: true, // 🔑 Suspense 활성화
  });

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}

// ErrorBoundary + Suspense로 감싼 래퍼
export function UserPage({ userId }: { userId: number }) {
  return (
    <ErrorBoundary FallbackComponent={InlineError}>
      <Suspense fallback={<SkeletonCard />}>
        <UserContent userId={userId} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

---

## 2. 리스트 페이지

### API별 Suspense 분리

```tsx
// src/pages/ProductListPage.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import ErrorBoundary from '@/components/ErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import { SkeletonCard, SkeletonGrid } from '@/components/skeletons';

async function fetchProducts() {
  const response = await fetch('/api/products');
  if (!response.ok) throw new Error('Failed to fetch products');
  return response.json();
}

function ProductList() {
  const { data: products } = useQuery({
    queryKey: ['products'],
    queryFn: fetchProducts,
    suspense: true,
  });

  return (
    <div className="grid grid-cols-3 gap-6">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}

export function ProductListPage() {
  return (
    <div>
      <h1>상품 목록</h1>

      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonGrid columns={3} count={9} />}>
          <ProductList />
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}
```

---

## 3. 상세 페이지

### 여러 섹션으로 나눠진 페이지

```tsx
// src/pages/ProductDetailPage.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import ErrorBoundary from '@/components/ErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import {
  SkeletonCard,
  SkeletonListItem,
  SkeletonGroup,
} from '@/components/skeletons';

// API 함수들
async function fetchProduct(id: number) {
  const response = await fetch(`/api/products/${id}`);
  if (!response.ok) throw new Error('Failed to fetch product');
  return response.json();
}

async function fetchReviews(productId: number) {
  const response = await fetch(`/api/products/${productId}/reviews`);
  if (!response.ok) throw new Error('Failed to fetch reviews');
  return response.json();
}

async function fetchRelatedProducts(productId: number) {
  const response = await fetch(`/api/products/${productId}/related`);
  if (!response.ok) throw new Error('Failed to fetch related products');
  return response.json();
}

// 상품 정보 컴포넌트
function ProductInfo({ productId }: { productId: number }) {
  const { data: product } = useQuery({
    queryKey: ['product', productId],
    queryFn: () => fetchProduct(productId),
    suspense: true,
  });

  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <p className="text-2xl font-bold">{product.price}원</p>
    </div>
  );
}

// 리뷰 컴포넌트
function ProductReviews({ productId }: { productId: number }) {
  const { data: reviews } = useQuery({
    queryKey: ['reviews', productId],
    queryFn: () => fetchReviews(productId),
    suspense: true,
  });

  return (
    <div>
      <h2>리뷰</h2>
      {reviews.map((review) => (
        <div key={review.id}>
          <p>{review.content}</p>
          <p>⭐ {review.rating}</p>
        </div>
      ))}
    </div>
  );
}

// 관련 상품 컴포넌트
function RelatedProducts({ productId }: { productId: number }) {
  const { data: products } = useQuery({
    queryKey: ['relatedProducts', productId],
    queryFn: () => fetchRelatedProducts(productId),
    suspense: true,
  });

  return (
    <div>
      <h2>관련 상품</h2>
      <div className="grid grid-cols-4 gap-4">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </div>
  );
}

// 메인 페이지 (각 섹션별 ErrorBoundary + Suspense)
export function ProductDetailPage({ productId }: { productId: number }) {
  return (
    <div className="space-y-8">
      {/* 상품 정보 - 독립적인 에러 처리 */}
      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonCard />}>
          <ProductInfo productId={productId} />
        </Suspense>
      </ErrorBoundary>

      {/* 리뷰 - 독립적인 에러 처리 */}
      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonGroup count={5} gap="gap-4" />}>
          <ProductReviews productId={productId} />
        </Suspense>
      </ErrorBoundary>

      {/* 관련 상품 - 독립적인 에러 처리 */}
      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonGrid columns={4} count={4} />}>
          <RelatedProducts productId={productId} />
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}
```

**장점**:
- 한 섹션의 에러가 다른 섹션에 영향 주지 않음
- 각 섹션이 독립적으로 로딩/표시됨
- 사용자 경험 향상

---

## 4. 무한 스크롤

### InfiniteQuery + Suspense

```tsx
// src/pages/InfiniteScrollPage.tsx

import React, { Suspense } from 'react';
import { useInfiniteQuery } from '@tanstack/react-query';
import ErrorBoundary from '@/components/ErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import { SkeletonListItem } from '@/components/skeletons';

interface PostsResponse {
  posts: Post[];
  nextCursor?: number;
}

async function fetchPosts({ pageParam = 1 }): Promise<PostsResponse> {
  const response = await fetch(`/api/posts?page=${pageParam}`);
  if (!response.ok) throw new Error('Failed to fetch posts');
  return response.json();
}

function InfinitePostList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['posts'],
    queryFn: fetchPosts,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    suspense: true, // 🔑 초기 로딩은 Suspense로
  });

  const allPosts = data?.pages.flatMap((page) => page.posts) || [];

  return (
    <div>
      {allPosts.map((post) => (
        <div key={post.id}>
          <h3>{post.title}</h3>
          <p>{post.content}</p>
        </div>
      ))}

      {hasNextPage && (
        <button onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
          {isFetchingNextPage ? '로딩 중...' : '더보기'}
        </button>
      )}

      {/* 추가 로딩 중일 때 스켈레톤 */}
      {isFetchingNextPage && <SkeletonListItem />}
    </div>
  );
}

export function InfiniteScrollPage() {
  return (
    <ErrorBoundary FallbackComponent={InlineError}>
      <Suspense
        fallback={
          <div>
            {/* 초기 로딩 시 여러 개 표시 */}
            <SkeletonListItem />
            <SkeletonListItem />
            <SkeletonListItem />
          </div>
        }
      >
        <InfinitePostList />
      </Suspense>
    </ErrorBoundary>
  );
}
```

---

## 5. 병렬 API 호출

### 여러 API를 동시에 호출하고 각각 독립적인 Suspense 적용

```tsx
// src/pages/DashboardPage.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import ErrorBoundary from '@/components/ErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import { SkeletonCard, SkeletonListItem } from '@/components/skeletons';

// API 함수들
async function fetchUserStats() {
  const response = await fetch('/api/stats/user');
  if (!response.ok) throw new Error('Failed to fetch user stats');
  return response.json();
}

async function fetchRecentActivity() {
  const response = await fetch('/api/activity/recent');
  if (!response.ok) throw new Error('Failed to fetch recent activity');
  return response.json();
}

async function fetchNotifications() {
  const response = await fetch('/api/notifications');
  if (!response.ok) throw new Error('Failed to fetch notifications');
  return response.json();
}

// 사용자 통계 컴포넌트
function UserStats() {
  const { data: stats } = useQuery({
    queryKey: ['userStats'],
    queryFn: fetchUserStats,
    suspense: true,
  });

  return (
    <div>
      <h2>내 통계</h2>
      <p>게시물: {stats.postCount}</p>
      <p>팔로워: {stats.followerCount}</p>
    </div>
  );
}

// 최근 활동 컴포넌트
function RecentActivity() {
  const { data: activities } = useQuery({
    queryKey: ['recentActivity'],
    queryFn: fetchRecentActivity,
    suspense: true,
  });

  return (
    <div>
      <h2>최근 활동</h2>
      {activities.map((activity) => (
        <p key={activity.id}>{activity.description}</p>
      ))}
    </div>
  );
}

// 알림 컴포넌트
function Notifications() {
  const { data: notifications } = useQuery({
    queryKey: ['notifications'],
    queryFn: fetchNotifications,
    suspense: true,
  });

  return (
    <div>
      <h2>알림</h2>
      {notifications.map((notification) => (
        <p key={notification.id}>{notification.message}</p>
      ))}
    </div>
  );
}

// 대시보드 (병렬 로딩)
export function DashboardPage() {
  return (
    <div className="grid grid-cols-3 gap-6">
      {/* 사용자 통계 - 독립적 */}
      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonCard />}>
          <UserStats />
        </Suspense>
      </ErrorBoundary>

      {/* 최근 활동 - 독립적 */}
      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonCard />}>
          <RecentActivity />
        </Suspense>
      </ErrorBoundary>

      {/* 알림 - 독립적 */}
      <ErrorBoundary FallbackComponent={InlineError}>
        <Suspense fallback={<SkeletonCard />}>
          <Notifications />
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}
```

**장점**:
- 3개의 API가 병렬로 호출됨
- 각각 독립적으로 로딩/에러 표시
- 하나가 느려도 나머지는 먼저 표시

---

## 6. 전역 vs 로컬 에러

### App.tsx (전역 ErrorBoundary)

```tsx
// src/App.tsx

import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import GlobalErrorBoundary from '@/components/GlobalErrorBoundary';
import { FullPageError } from '@/components/error-fallbacks';
import AppRoutes from '@/routes';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      suspense: false, // 전역 설정은 false, 각 쿼리별로 활성화
      retry: 1,
    },
  },
});

function App() {
  return (
    <GlobalErrorBoundary FallbackComponent={FullPageError}>
      <QueryClientProvider client={queryClient}>
        <Router>
          <AppRoutes />
        </Router>
      </QueryClientProvider>
    </GlobalErrorBoundary>
  );
}

export default App;
```

### 페이지별 ErrorBoundary

```tsx
// src/pages/UserProfilePage.tsx

import React, { Suspense } from 'react';
import ErrorBoundary from '@/components/ErrorBoundary';
import { ErrorFallback } from '@/components/error-fallbacks';

function UserProfilePage() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <div>
        <h1>프로필 페이지</h1>
        {/* 페이지 내용 */}
      </div>
    </ErrorBoundary>
  );
}

export default UserProfilePage;
```

---

## 7. 중첩 Suspense

### 점진적 로딩

```tsx
// src/pages/ArticlePage.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import { SkeletonCard, SkeletonListItem } from '@/components/skeletons';

function ArticleHeader({ articleId }: { articleId: number }) {
  const { data } = useQuery({
    queryKey: ['article', articleId],
    queryFn: () => fetchArticle(articleId),
    suspense: true,
  });

  return <h1>{data.title}</h1>;
}

function ArticleComments({ articleId }: { articleId: number }) {
  const { data } = useQuery({
    queryKey: ['comments', articleId],
    queryFn: () => fetchComments(articleId),
    suspense: true,
  });

  return (
    <div>
      {data.comments.map((comment) => (
        <p key={comment.id}>{comment.content}</p>
      ))}
    </div>
  );
}

export function ArticlePage({ articleId }: { articleId: number }) {
  return (
    <Suspense fallback={<div>전체 로딩 중...</div>}>
      {/* 먼저 헤더가 표시됨 */}
      <ArticleHeader articleId={articleId} />

      {/* 헤더 로딩 후 댓글 로딩 시작 */}
      <Suspense fallback={<SkeletonListItem />}>
        <ArticleComments articleId={articleId} />
      </Suspense>
    </Suspense>
  );
}
```

---

## 8. 조건부 렌더링

### 로그인 여부에 따라 다른 컴포넌트

```tsx
// src/pages/HomePage.tsx

import React, { Suspense } from 'react';
import { useQuery } from '@tanstack/react-query';
import ErrorBoundary from '@/components/ErrorBoundary';
import { InlineError } from '@/components/error-fallbacks';
import { SkeletonCard } from '@/components/skeletons';

function useAuth() {
  const { data: user } = useQuery({
    queryKey: ['currentUser'],
    queryFn: fetchCurrentUser,
    suspense: true,
  });
  return { user, isLoggedIn: !!user };
}

function LoggedInContent() {
  const { user } = useAuth();

  return (
    <div>
      <h1>환영합니다, {user.name}님!</h1>
      {/* 로그인 사용자 전용 콘텐츠 */}
    </div>
  );
}

function LoggedOutContent() {
  return (
    <div>
      <h1>로그인이 필요합니다</h1>
      <button>로그인하기</button>
    </div>
  );
}

export function HomePage() {
  return (
    <ErrorBoundary FallbackComponent={InlineError}>
      <Suspense fallback={<SkeletonCard />}>
        <AuthCheck />
      </Suspense>
    </ErrorBoundary>
  );
}

function AuthCheck() {
  const { isLoggedIn } = useAuth();
  return isLoggedIn ? <LoggedInContent /> : <LoggedOutContent />;
}
```

---

## 참고 자료

- [TanStack Query - Suspense](https://tanstack.com/query/latest/docs/framework/react/guides/suspense)
- [React Suspense for Data Fetching](https://react.dev/reference/react/Suspense)
- [Error Boundaries](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)
