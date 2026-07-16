# TanStack Query & Query Key Factory Best Practices

## 목차
- [개요](#개요)
- [라이브러리 설치](#라이브러리-설치)
- [아키텍처 구조](#아키텍처-구조)
- [설계 목표](#설계-목표)
- [패턴 선택 가이드](#패턴-선택-가이드)
- [파일 구조](#파일-구조)
- [사용 방법](#사용-방법)
- [고급 패턴](#고급-패턴)
- [마이그레이션 가이드](#마이그레이션-가이드)
- [레퍼런스](#레퍼런스)

---

## 개요

이 문서는 **`@lukemorales/query-key-factory`** 라이브러리를 활용하여 TanStack Query를 타입 안전하게 관리하는 best practice를 설명합니다.

### 핵심 원칙

1. **타입 안전성**: 컴파일 타임에 query key 오류 방지
2. **자동 완성**: IDE에서 query key 구조 자동 완성
3. **도메인별 응집**: API 함수, QueryKey, Query Options를 도메인별로 관리
4. **스코프 기반 무효화**: 계층적 key 구조로 효율적인 캐시 무효화

### 왜 Query Key Factory가 필요한가?

**문제 1: 수동 Key 관리의 휴먼 에러**
```typescript
// ❌ 오타 위험, 타입 안전성 없음
queryKey: ['comments', castId]
queryKey: ['comment', castId]  // 실수로 단수형 사용
queryKey: ['casts', 'detail', id]
queryKey: ['cast', 'details', id]  // 구조 불일치
```

**문제 2: 캐시 무효화 시 Key 불일치**
```typescript
// ❌ 무효화할 때 다른 key 사용
useQuery({ queryKey: ['users', 'list'] })
queryClient.invalidateQueries({ queryKey: ['user', 'list'] })  // 동작 안함
```

**해결: Query Key Factory로 단일 진실 공급원(Single Source of Truth) 확보**
```typescript
// ✅ 타입 안전, 자동 완성, 일관성 보장
const queries = createQueryKeyStore({
  users: {
    list: null,
    detail: (id: string) => ({ queryKey: [id] }),
  },
});

// 사용
useQuery(queries.users.detail(id));
queryClient.invalidateQueries({ queryKey: queries.users.list.queryKey });
```

---

## 라이브러리 설치

```bash
# pnpm (권장)
pnpm add @lukemorales/query-key-factory

# npm
npm install @lukemorales/query-key-factory

# yarn
yarn add @lukemorales/query-key-factory
```

---

## 아키텍처 구조

### 전체 구조도

```
┌─────────────────────────────────────────────────────────┐
│                      Component Layer                     │
│  - useQuery(queries.casts.detail(id))                   │
│  - useInfiniteQuery(queries.casts.infinite())           │
│  - useMutation({ mutationFn: CommentService.create })   │
└────────────────────┬────────────────────────────────────┘
                     │ 직접 사용
┌────────────────────▼────────────────────────────────────┐
│               Query Key Store Layer                      │
│              (app/queries/index.ts)                      │
│                                                          │
│  export const queries = createQueryKeyStore({           │
│    casts: { ... },                                       │
│    comments: { ... },                                    │
│  });                                                     │
│                                                          │
│  또는 Modular 방식:                                      │
│  export const queries = mergeQueryKeys(                 │
│    castsQueries,                                        │
│    commentsQueries                                      │
│  );                                                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Service Layer                         │
│                  (app/services/)                         │
│                                                          │
│  export const CastService = {                           │
│    getCast: async (id) => fetch(`/api/cast/${id}`),    │
│    getCasts: async (page) => fetch(`/api/casts?...`),  │
│  };                                                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    API Routes                            │
│  - GET /api/casts                                       │
│  - GET /api/cast/:id                                    │
└─────────────────────────────────────────────────────────┘
```

### Before vs After

```
┌─────────────── Before (수동 관리) ────────────────┐
│ Component                                        │
│      ↓                                           │
│ queryKey: ['casts', 'detail', id]  // 하드코딩   │
│ queryFn: () => fetch(...)          // 인라인     │
│                                                  │
│ 문제점:                                          │
│ • 오타 위험 (휴먼 에러)                          │
│ • 타입 안전성 없음                               │
│ • 캐시 무효화 시 key 불일치                      │
│ • 리팩토링 어려움                                │
└──────────────────────────────────────────────────┘

┌─────────────── After (Factory 패턴) ─────────────┐
│ Component                                        │
│      ↓                                           │
│ useQuery(queries.casts.detail(id))  // 타입 안전 │
│                                                  │
│ queries/casts.ts:                                │
│ export const casts = createQueryKeys('casts', { │
│   detail: (id) => ({                            │
│     queryKey: [id],                             │
│     queryFn: () => CastService.getCast(id),     │
│   }),                                            │
│ });                                              │
│                                                  │
│ 장점:                                            │
│ • 타입 안전 (컴파일 타임 오류 감지)              │
│ • IDE 자동 완성                                  │
│ • 일관된 캐시 무효화                             │
│ • 리팩토링 용이                                  │
└──────────────────────────────────────────────────┘
```

---

## 설계 목표

### 1. 타입 안전성 확보

**문제**: 수동으로 작성한 query key는 타입 체크 불가
```typescript
// ❌ Before - 컴파일러가 오류 감지 못함
queryKey: ['cast', id]
queryKey: ['casts', id]  // 오타 발생해도 컴파일 성공
```

**해결**: Factory 함수로 타입 추론
```typescript
// ✅ After - TypeScript가 타입 체크
queries.casts.detail(id)  // 자동 완성, 타입 안전
queries.casts.detial(id)  // ❌ 컴파일 에러
```

### 2. 계층적 Key 구조

**문제**: Flat한 key 구조는 부분 무효화 불가
```typescript
// ❌ Before - 세밀한 제어 어려움
queryKey: ['casts', 'detail', id]
```

**해결**: 계층적 구조로 스코프 기반 무효화
```typescript
// ✅ After
queries.casts._def           // ['casts'] - 모든 casts 쿼리 무효화
queries.casts.detail._def    // ['casts', 'detail'] - 모든 detail 쿼리 무효화
queries.casts.detail(1)      // ['casts', 'detail', 1] - 특정 쿼리만 무효화
```

### 3. 응집도 향상

**문제**: API 함수와 Query 설정이 분리되어 관리 어려움
```typescript
// ❌ Before
- app/api/cast.ts          // API 함수
- app/hooks/useCast.ts     // Query 설정
- components/Cast.tsx      // 사용처 - queryKey 하드코딩
```

**해결**: 도메인별 응집
```typescript
// ✅ After
- app/queries/casts.ts     // QueryKey + QueryFn + Options 모두 포함
- app/services/cast.ts     // API 함수만
```

---

## 패턴 선택 가이드

### 패턴 1: createQueryKeyStore (모놀리식)

**언제 사용?**
- 작은 프로젝트 (5-10개 도메인 이하)
- 팀원이 적고 코드 충돌이 적은 경우
- 빠른 프로토타이핑이 필요한 경우

**장점**
- 단일 파일에서 모든 query 확인 가능
- 설정이 간단함
- import 경로 단순

**단점**
- 파일이 커질수록 관리 어려움
- 여러 개발자가 동시 수정 시 merge conflict
- 도메인 간 의존성 분리 어려움

**예시**
```typescript
// app/queries/index.ts
import { createQueryKeyStore } from '@lukemorales/query-key-factory';
import { CastService } from '@/app/services/cast';
import { CommentService } from '@/app/services/comment';

export const queries = createQueryKeyStore({
  casts: {
    detail: (id: number) => ({
      queryKey: [id],
      queryFn: () => CastService.getCast(id),
      staleTime: 5 * 60 * 1000,
    }),
    list: (page: number) => ({
      queryKey: [page],
      queryFn: () => CastService.getCasts(page),
    }),
  },
  comments: {
    list: (castId: number) => ({
      queryKey: [castId],
      queryFn: () => CommentService.getComments(castId),
    }),
  },
});

// 사용
import { queries } from '@/app/queries';
const { data } = useQuery(queries.casts.detail(1));
```

---

### 패턴 2: createQueryKeys + mergeQueryKeys (모듈식)

**언제 사용?**
- 중대형 프로젝트 (10개 이상 도메인)
- 여러 개발자가 동시에 작업하는 경우
- 도메인별로 독립적인 관리가 필요한 경우

**장점**
- 도메인별 파일 분리로 merge conflict 최소화
- 코드 소유권 명확 (팀별로 파일 분담 가능)
- Tree-shaking 최적화 유리
- 대규모 코드베이스에서 탐색 용이

**단점**
- 초기 설정이 복잡
- import 경로가 상대적으로 길어질 수 있음

**예시**
```typescript
// app/queries/casts.ts
import { createQueryKeys } from '@lukemorales/query-key-factory';
import { CastService } from '@/app/services/cast';

export const castsQueries = createQueryKeys('casts', {
  detail: (id: number) => ({
    queryKey: [id],
    queryFn: () => CastService.getCast(id),
    staleTime: 5 * 60 * 1000,
  }),
  list: (page: number) => ({
    queryKey: [page],
    queryFn: () => CastService.getCasts(page),
  }),
  infinite: () => ({
    queryKey: null,
    queryFn: ({ pageParam = 1 }) => CastService.getCasts(pageParam),
  }),
});

// app/queries/comments.ts
import { createQueryKeys } from '@lukemorales/query-key-factory';
import { CommentService } from '@/app/services/comment';

export const commentsQueries = createQueryKeys('comments', {
  list: (castId: number) => ({
    queryKey: [castId],
    queryFn: () => CommentService.getComments(castId),
  }),
});

// app/queries/index.ts
import { mergeQueryKeys } from '@lukemorales/query-key-factory';
import { castsQueries } from './casts';
import { commentsQueries } from './comments';

export const queries = mergeQueryKeys(castsQueries, commentsQueries);

// 사용 (동일한 API)
import { queries } from '@/app/queries';
const { data } = useQuery(queries.casts.detail(1));
```

---

## 파일 구조

### 모놀리식 패턴 (작은 프로젝트)

```
app/
├── queries/
│   └── index.ts              # 모든 query 정의 (createQueryKeyStore)
├── services/
│   ├── cast.ts               # CastService (API 호출 함수)
│   └── comment.ts            # CommentService
└── components/
    └── CastDetail.tsx        # queries 직접 사용
```

### 모듈식 패턴 (큰 프로젝트) - **권장**

```
app/
├── queries/
│   ├── index.ts              # mergeQueryKeys로 통합
│   ├── casts.ts              # castsQueries (createQueryKeys)
│   ├── comments.ts           # commentsQueries
│   ├── users.ts              # usersQueries
│   └── notifications.ts      # notificationsQueries
├── services/
│   ├── cast.ts               # CastService
│   ├── comment.ts            # CommentService
│   ├── user.ts               # UserService
│   └── notification.ts       # NotificationService
└── components/
    └── CastDetail.tsx        # queries 직접 사용
```

---

## 사용 방법

### 1. Service Layer 작성 (API 호출 함수)

```typescript
// app/services/cast.ts
export interface Cast {
  id: number;
  title: string;
  content: string;
}

export interface CastsResponse {
  casts: Cast[];
  nextCursor?: number;
}

export const CastService = {
  getCast: async (id: number): Promise<Cast> => {
    const response = await fetch(`/api/cast/${id}`);
    if (!response.ok) throw new Error('Failed to fetch cast');
    return response.json();
  },

  getCasts: async (page: number): Promise<CastsResponse> => {
    const response = await fetch(`/api/casts?page=${page}`);
    if (!response.ok) throw new Error('Failed to fetch casts');
    return response.json();
  },

  likeCast: async (castId: number): Promise<void> => {
    const response = await fetch(`/api/cast/${castId}/like`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to like cast');
  },
};
```

### 2. Query Keys 정의 (모듈식 패턴)

```typescript
// app/queries/casts.ts
import { createQueryKeys } from '@lukemorales/query-key-factory';
import { CastService } from '@/app/services/cast';

export const castsQueries = createQueryKeys('casts', {
  // 단일 캐스트 조회
  detail: (id: number) => ({
    queryKey: [id],
    queryFn: () => CastService.getCast(id),
    staleTime: 5 * 60 * 1000,      // 5분간 fresh
    gcTime: 10 * 60 * 1000,        // 10분간 캐시 유지
  }),

  // 페이지네이션 리스트
  list: (page: number) => ({
    queryKey: [page],
    queryFn: () => CastService.getCasts(page),
    staleTime: 5 * 60 * 1000,
    placeholderData: (previousData) => previousData,  // 이전 데이터 유지
  }),

  // 무한 스크롤
  infinite: () => ({
    queryKey: null,  // 파라미터 없음
    queryFn: ({ pageParam = 1 }) => CastService.getCasts(pageParam),
    initialPageParam: 1,
    getNextPageParam: (lastPage: CastsResponse) => lastPage.nextCursor,
  }),

  // 인기 캐스트 (고정된 첫 페이지)
  popular: () => ({
    queryKey: null,
    queryFn: () => CastService.getCasts(1),
    staleTime: 10 * 60 * 1000,     // 10분간 fresh
    refetchOnWindowFocus: false,    // 포커스 시 재조회 안함
  }),
});

// 생성되는 key 구조:
// castsQueries.detail(1).queryKey      → ['casts', 'detail', 1]
// castsQueries.list(2).queryKey        → ['casts', 'list', 2]
// castsQueries.infinite().queryKey     → ['casts', 'infinite']
// castsQueries.popular().queryKey      → ['casts', 'popular']
```

```typescript
// app/queries/comments.ts
import { createQueryKeys } from '@lukemorales/query-key-factory';
import { CommentService } from '@/app/services/comment';

export const commentsQueries = createQueryKeys('comments', {
  list: (castId: number) => ({
    queryKey: [castId],
    queryFn: () => CommentService.getComments(castId),
    staleTime: 1 * 60 * 1000,
    gcTime: 5 * 60 * 1000,
  }),
});

// 생성되는 key 구조:
// commentsQueries.list(1).queryKey → ['comments', 'list', 1]
```

### 3. Query Keys 통합

```typescript
// app/queries/index.ts
import { mergeQueryKeys } from '@lukemorales/query-key-factory';
import { castsQueries } from './casts';
import { commentsQueries } from './comments';

export const queries = mergeQueryKeys(castsQueries, commentsQueries);

// 사용:
// queries.casts.detail(1)
// queries.comments.list(1)
```

### 4. Component에서 사용

#### Query 사용 (데이터 조회)

```typescript
// components/CastDetail.tsx
import { useQuery } from '@tanstack/react-query';
import { queries } from '@/app/queries';

export function CastDetail({ castId }: { castId: number }) {
  const { data, isLoading, isError, refetch } = useQuery(
    queries.casts.detail(castId)
  );

  if (isLoading) return <Skeleton />;
  if (isError) return <Error onRetry={refetch} />;

  return (
    <div>
      <h1>{data.title}</h1>
      <p>{data.content}</p>
    </div>
  );
}
```

#### InfiniteQuery 사용 (무한 스크롤)

```typescript
// components/CastList.tsx
import { useInfiniteQuery } from '@tanstack/react-query';
import { queries } from '@/app/queries';

export function CastList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery(queries.casts.infinite());

  const allCasts = data?.pages.flatMap((page) => page.casts) || [];

  return (
    <div>
      {allCasts.map((cast) => (
        <CastCard key={cast.id} cast={cast} />
      ))}
      {hasNextPage && (
        <button
          onClick={() => fetchNextPage()}
          disabled={isFetchingNextPage}
        >
          {isFetchingNextPage ? '로딩 중...' : '더보기'}
        </button>
      )}
    </div>
  );
}
```

#### Mutation 사용 (데이터 변경)

```typescript
// components/CommentSection.tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { queries } from '@/app/queries';
import { CommentService } from '@/app/services/comment';

export function CommentSection({ castId }: { castId: number }) {
  const queryClient = useQueryClient();

  // 댓글 목록 조회
  const { data: comments } = useQuery(queries.comments.list(castId));

  // 댓글 작성 mutation
  const createCommentMutation = useMutation({
    mutationFn: ({ content, author }: { content: string; author: string }) =>
      CommentService.createComment(castId, content, author),
    onSuccess: () => {
      // 댓글 목록만 무효화
      queryClient.invalidateQueries({
        queryKey: queries.comments.list(castId).queryKey,
      });
    },
  });

  // 댓글 삭제 mutation
  const deleteCommentMutation = useMutation({
    mutationFn: (commentId: number) =>
      CommentService.deleteComment(castId, commentId),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: queries.comments.list(castId).queryKey,
      });
    },
  });

  const handleSubmit = (content: string) => {
    createCommentMutation.mutate({
      content,
      author: 'current-user',
    });
  };

  return (
    <div>
      <CommentList
        comments={comments}
        onDelete={(id) => deleteCommentMutation.mutate(id)}
      />
      <CommentInput
        onSubmit={handleSubmit}
        isSubmitting={createCommentMutation.isPending}
      />
    </div>
  );
}
```

---

## 고급 패턴

### 1. Context Queries (계층적 쿼리)

Context Queries는 **부모 쿼리에 종속적인 자식 쿼리**를 정의할 때 사용합니다.

**사용 사례**
- 사용자 상세 → 사용자 좋아요 목록
- 게시물 상세 → 게시물 댓글
- 프로젝트 상세 → 프로젝트 태스크

```typescript
// app/queries/casts.ts
export const castsQueries = createQueryKeys('casts', {
  detail: (id: number) => ({
    queryKey: [id],
    queryFn: () => CastService.getCast(id),
    // 👇 Context Queries: detail에 종속된 하위 쿼리들
    contextQueries: {
      // 특정 캐스트의 댓글
      comments: {
        queryKey: null,
        queryFn: () => CommentService.getComments(id),
      },
      // 특정 캐스트의 좋아요 목록
      likes: {
        queryKey: null,
        queryFn: () => CastService.getLikes(id),
      },
      // 특정 캐스트의 조회수
      views: {
        queryKey: null,
        queryFn: () => CastService.getViews(id),
      },
    },
  }),
});

// 생성되는 key 구조:
// queries.casts.detail(1)._ctx.comments.queryKey  → ['casts', 'detail', 1, 'comments']
// queries.casts.detail(1)._ctx.likes.queryKey     → ['casts', 'detail', 1, 'likes']
// queries.casts.detail(1)._ctx.views.queryKey     → ['casts', 'detail', 1, 'views']
```

**Component에서 사용**
```typescript
export function CastDetailPage({ castId }: { castId: number }) {
  // 캐스트 상세 정보
  const { data: cast } = useQuery(queries.casts.detail(castId));

  // 캐스트에 종속된 댓글 (contextQuery)
  const { data: comments } = useQuery(
    queries.casts.detail(castId)._ctx.comments
  );

  // 캐스트에 종속된 좋아요 목록
  const { data: likes } = useQuery(
    queries.casts.detail(castId)._ctx.likes
  );

  return (
    <div>
      <CastContent cast={cast} />
      <LikesList likes={likes} />
      <CommentsList comments={comments} />
    </div>
  );
}
```

**장점**
- 쿼리 간 계층 관계가 명확함
- 부모 쿼리 무효화 시 자식도 함께 무효화 가능
- DevTools에서 관계를 시각적으로 확인 가능

---

### 2. Scope-based Invalidation (스코프 기반 무효화)

`._def`를 사용하면 **특정 스코프의 모든 쿼리**를 한 번에 무효화할 수 있습니다.

```typescript
// app/queries/casts.ts
export const castsQueries = createQueryKeys('casts', {
  detail: (id: number) => ({ ... }),
  list: (page: number) => ({ ... }),
  infinite: () => ({ ... }),
  popular: () => ({ ... }),
});

// ._def 구조:
// queries.casts._def                 → ['casts']
// queries.casts.detail._def          → ['casts', 'detail']
// queries.casts.list._def            → ['casts', 'list']
```

**세밀한 무효화 전략**
```typescript
const queryClient = useQueryClient();

// 1️⃣ 특정 캐스트 1개만 무효화
queryClient.invalidateQueries({
  queryKey: queries.casts.detail(1).queryKey,  // ['casts', 'detail', 1]
});

// 2️⃣ 모든 detail 쿼리 무효화 (id와 무관하게)
queryClient.invalidateQueries({
  queryKey: queries.casts.detail._def,  // ['casts', 'detail']
});
// 👆 detail(1), detail(2), detail(3) 등 모두 무효화

// 3️⃣ 모든 list 쿼리 무효화
queryClient.invalidateQueries({
  queryKey: queries.casts.list._def,  // ['casts', 'list']
});
// 👆 list(1), list(2), list(3) 등 모두 무효화

// 4️⃣ casts 도메인 전체 무효화
queryClient.invalidateQueries({
  queryKey: queries.casts._def,  // ['casts']
});
// 👆 detail, list, infinite, popular 등 모든 casts 쿼리 무효화
```

**실전 예시: 캐스트 수정 후 무효화**
```typescript
const updateCastMutation = useMutation({
  mutationFn: (data: { id: number; title: string }) =>
    CastService.updateCast(data.id, data),
  onSuccess: (_, variables) => {
    // 1. 수정한 캐스트의 detail 무효화
    queryClient.invalidateQueries({
      queryKey: queries.casts.detail(variables.id).queryKey,
    });

    // 2. 모든 list 쿼리도 무효화 (목록에 제목이 표시되므로)
    queryClient.invalidateQueries({
      queryKey: queries.casts.list._def,
    });

    // 3. infinite 쿼리도 무효화
    queryClient.invalidateQueries({
      queryKey: queries.casts.infinite().queryKey,
    });
  },
});
```

---

### 3. Optimistic Updates (낙관적 업데이트)

캐시를 직접 조작하여 UX를 개선하는 패턴입니다.

```typescript
// 좋아요 토글 mutation
const toggleLikeMutation = useMutation({
  mutationFn: (castId: number) => CastService.likeCast(castId),

  // 서버 응답 전에 UI 먼저 업데이트
  onMutate: async (castId) => {
    // 1. 진행 중인 쿼리 취소 (race condition 방지)
    await queryClient.cancelQueries({
      queryKey: queries.casts.detail(castId).queryKey,
    });

    // 2. 현재 캐시 데이터 백업
    const previousCast = queryClient.getQueryData(
      queries.casts.detail(castId).queryKey
    );

    // 3. 낙관적으로 캐시 업데이트
    queryClient.setQueryData(
      queries.casts.detail(castId).queryKey,
      (old: Cast) => ({
        ...old,
        likes: old.likes + 1,
        isLiked: true,
      })
    );

    // 4. 롤백용 데이터 반환
    return { previousCast };
  },

  // 에러 발생 시 롤백
  onError: (err, castId, context) => {
    queryClient.setQueryData(
      queries.casts.detail(castId).queryKey,
      context?.previousCast
    );
  },

  // 성공 시 서버 데이터로 동기화
  onSettled: (_, __, castId) => {
    queryClient.invalidateQueries({
      queryKey: queries.casts.detail(castId).queryKey,
    });
  },
});
```

---

### 4. Dependent Queries (종속 쿼리)

한 쿼리의 결과가 다른 쿼리의 입력이 되는 경우입니다.

```typescript
export function UserProfile({ username }: { username: string }) {
  // 1️⃣ 먼저 사용자 ID 조회
  const { data: user } = useQuery(queries.users.byUsername(username));

  // 2️⃣ 사용자 ID로 게시물 조회 (user가 있을 때만 실행)
  const { data: posts } = useQuery({
    ...queries.posts.byUser(user?.id),
    enabled: !!user?.id,  // 👈 user가 로드된 후에만 실행
  });

  return (
    <div>
      <h1>{user?.name}</h1>
      <PostList posts={posts} />
    </div>
  );
}
```

---

### 5. Prefetching (사전 로딩)

사용자가 요청하기 전에 데이터를 미리 로드합니다.

```typescript
export function CastListItem({ cast }: { cast: Cast }) {
  const queryClient = useQueryClient();

  // 마우스 호버 시 상세 페이지 데이터 미리 로드
  const handleMouseEnter = () => {
    queryClient.prefetchQuery(queries.casts.detail(cast.id));
  };

  return (
    <Link
      to={`/cast/${cast.id}`}
      onMouseEnter={handleMouseEnter}
    >
      {cast.title}
    </Link>
  );
}
```

**Server Component에서 Prefetching (Next.js App Router)**
```typescript
// app/cast/[id]/page.tsx
import { QueryClient, dehydrate, HydrationBoundary } from '@tanstack/react-query';
import { queries } from '@/app/queries';

export default async function CastPage({ params }: { params: { id: string } }) {
  const queryClient = new QueryClient();
  const castId = Number(params.id);

  // 서버에서 미리 데이터 로드
  await queryClient.prefetchQuery(queries.casts.detail(castId));

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <CastDetail castId={castId} />
    </HydrationBoundary>
  );
}
```

---

## 마이그레이션 가이드

### Step 1: 라이브러리 설치

```bash
pnpm add @lukemorales/query-key-factory
```

### Step 2: 기존 Service Layer 유지

```typescript
// ✅ 기존 코드 그대로 유지
// app/services/cast.ts
export const CastService = {
  getCast: async (id: number) => { ... },
  getCasts: async (page: number) => { ... },
};
```

### Step 3: Query Keys 정의

```typescript
// 🆕 app/queries/casts.ts
import { createQueryKeys } from '@lukemorales/query-key-factory';
import { CastService } from '@/app/services/cast';

export const castsQueries = createQueryKeys('casts', {
  detail: (id: number) => ({
    queryKey: [id],
    queryFn: () => CastService.getCast(id),
  }),
  list: (page: number) => ({
    queryKey: [page],
    queryFn: () => CastService.getCasts(page),
  }),
});
```

### Step 4: 통합

```typescript
// 🆕 app/queries/index.ts
import { mergeQueryKeys } from '@lukemorales/query-key-factory';
import { castsQueries } from './casts';

export const queries = mergeQueryKeys(castsQueries);
```

### Step 5: Component 마이그레이션

```typescript
// ❌ Before
import { useQuery } from '@tanstack/react-query';
import { CastService } from '@/app/services/cast';

const { data } = useQuery({
  queryKey: ['casts', 'detail', id],  // 하드코딩
  queryFn: () => CastService.getCast(id),
});

// ✅ After
import { useQuery } from '@tanstack/react-query';
import { queries } from '@/app/queries';

const { data } = useQuery(queries.casts.detail(id));
```

### Step 6: 캐시 무효화 마이그레이션

```typescript
// ❌ Before
queryClient.invalidateQueries({ queryKey: ['casts', 'detail', id] });

// ✅ After
queryClient.invalidateQueries({
  queryKey: queries.casts.detail(id).queryKey,
});
```

---

## 최신 문서 조회: TanStack CLI 사용

> **중요**: TanStack 관련 최신 문서를 참조할 때는 TanStack MCP 서버가 아닌 **TanStack CLI**를 사용합니다.

### 설치

```bash
# npx로 즉시 사용 (설치 불필요)
npx @tanstack/cli <command>

# 또는 전역 설치
pnpm add -g @tanstack/cli
```

### 문서 조회 명령어

```bash
# 특정 라이브러리의 문서 페이지 가져오기
npx @tanstack/cli doc <library> <path>

# 예시: TanStack Query의 개요 문서
npx @tanstack/cli doc query framework/react/overview

# 예시: TanStack Router의 데이터 로딩 가이드
npx @tanstack/cli doc router framework/react/guide/data-loading
```

### 문서 검색

```bash
# 키워드로 문서 검색
npx @tanstack/cli search-docs "<query>"

# 특정 라이브러리로 범위 제한
npx @tanstack/cli search-docs "query key factory" --library query

# 예시: server functions 관련 문서 검색
npx @tanstack/cli search-docs "server functions" --library start
```

### 라이브러리 목록 확인

```bash
# 사용 가능한 TanStack 라이브러리 목록
npx @tanstack/cli libraries
```

### JSON 출력 (프로그래밍 활용)

모든 명령어에 `--json` 플래그를 추가하면 기계 판독 가능한 JSON 형식으로 출력됩니다.

```bash
npx @tanstack/cli search-docs "invalidation" --library query --json
```

---

## 레퍼런스

### 공식 문서
- **[@lukemorales/query-key-factory GitHub](https://github.com/lukemorales/query-key-factory)**
  공식 라이브러리 저장소, 최신 기능 및 API 문서

- **[TanStack Query - Query Key Factory](https://tanstack.com/query/v4/docs/framework/react/community/lukemorales-query-key-factory)**
  TanStack 공식 문서의 커뮤니티 라이브러리 섹션

- **[TanStack CLI 공식 문서](https://tanstack.com/cli/latest)**
  TanStack CLI 설치, 명령어 레퍼런스, 문서 조회 기능

### 커뮤니티 Best Practices
- **[React Query: How to organize your keys (DEV Community)](https://dev.to/syeo66/react-query-how-to-organize-your-keys-4mg4)**
  Factory 패턴과 계층적 key 구조에 대한 실용적 가이드

- **[TanStack Query Discussions - Best Practice for Query Keys](https://github.com/TanStack/query/discussions/3362)**
  공식 Discussion에서의 커뮤니티 best practice 논의

### 패턴 및 아키텍처
- **[TanStack Query Discussions - Cache Keys Best Practice](https://github.com/TanStack/query/discussions/1437)**
  캐시 key 설계 원칙 및 계층 구조 논의

---

## 요약

### 핵심 장점

| 항목 | Before (수동) | After (Factory) | 효과 |
|------|--------------|----------------|------|
| **타입 안전성** | ❌ 없음 | ✅ 컴파일 타임 체크 | 런타임 에러 방지 |
| **자동 완성** | ❌ 없음 | ✅ IDE 지원 | 개발 속도 향상 |
| **오타 방지** | ❌ 휴먼 에러 | ✅ 타입 에러 | 버그 감소 |
| **캐시 무효화** | ❌ 수동 일치 | ✅ 자동 일치 | 캐시 일관성 |
| **리팩토링** | ❌ 어려움 | ✅ 쉬움 | 유지보수성 ↑ |
| **스코프 무효화** | ❌ 불가능 | ✅ ._def 지원 | 세밀한 제어 |

### 언제 사용하는가?

✅ **추천하는 경우**
- TypeScript 프로젝트
- 중대형 애플리케이션 (10+ 쿼리)
- 여러 개발자가 협업하는 프로젝트
- 복잡한 캐시 무효화 로직이 필요한 경우

⚠️ **고려가 필요한 경우**
- 매우 작은 프로토타입 (5개 이하 쿼리)
- JavaScript 프로젝트 (타입 안전성 이점 감소)
- 학습 곡선이 부담스러운 팀

### 다음 단계

1. 프로젝트 규모에 따라 **모놀리식** vs **모듈식** 패턴 선택
2. Service Layer와 Query Layer 분리
3. 기존 하드코딩된 queryKey를 Factory로 점진적 마이그레이션
4. Context Queries와 Scope-based Invalidation 활용
5. Prefetching과 Optimistic Updates로 UX 개선
