# Route URL State Boundary Pattern

어드민 검색, 필터, 정렬, 페이지네이션처럼 URL로 다시 열었을 때 같은 화면이 재현되어야 하는 상태는 React state보다 URL search params를 원천으로 둡니다.

## 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **URL state는 화면 조건의 SSOT** | 검색어, 필터, 정렬, 페이지 같은 확정 조건은 URL search params에 둡니다. |
| **Form state는 draft** | 사용자가 입력 중인 값은 submit 전까지 실제 결과 조건이 아닙니다. |
| **Server state는 URL에서 파생** | TanStack Query cache나 loader data는 URL search params에서 파생된 결과입니다. |
| **Route boundary에서 검증** | URL parsing, validation, defaulting, canonicalization은 라우트 최상단에 모읍니다. |
| **중복 truth 금지** | 같은 값을 URL, form, context, zustand, query cache에 동시에 진실처럼 저장하지 않습니다. |

## 권장 레이어

```txt
Route layer
- validateSearch 또는 schema parse로 URL 값을 검증합니다.
- 기본값과 타입 변환 규칙을 한 곳에 모읍니다.
- 필요하면 canonical URL로 redirect합니다.
- loaderDeps 또는 queryKey에 검증된 search 값을 연결합니다.

Form layer
- 검증된 search 값을 defaultValues로 받습니다.
- 사용자의 입력 중 draft 상태만 관리합니다.
- submit 시 form 값을 URL search params로 변환해 navigate합니다.

Data layer
- URL search params에서 파생된 queryKey 또는 loaderDeps로 서버 데이터를 가져옵니다.
- 서버 응답 변환은 queryOptions select 또는 view model 함수로 모읍니다.
- fetchQuery, ensureQueryData, invalidate, revalidate의 역할을 구분합니다.

Submit boundary
- form values를 URL search params 또는 서버 payload로 명시적으로 변환합니다.
- submit은 직접 refetch보다 URL state 변경을 통해 데이터 의존성이 바뀌게 만듭니다.
```

## 잘못된 패턴

### 컴포넌트마다 URL parsing

```tsx
function StatusFilter() {
  const [searchParams] = useSearchParams()
  const status = searchParams.get('status') ?? 'all'
  // 각 컴포넌트가 기본값과 parsing 규칙을 따로 가짐
}
```

문제점:

- 기본값과 타입 변환 규칙이 흩어집니다.
- 컴포넌트마다 URL 해석 결과가 달라질 수 있습니다.
- loader, queryKey, form defaultValues가 같은 규칙을 공유하기 어렵습니다.

### URL과 내부 fallback 불일치

```tsx
const page = Number(searchParams.get('page') ?? '1')
const keyword = searchParams.get('keyword') ?? ''
```

`/users`를 내부에서는 `/users?page=1&keyword=`처럼 취급하지만 URL에는 그 사실이 없습니다. URL을 SSOT로 삼는 화면이라면 한 화면 상태에 대한 canonical URL을 정하고, 라우트 경계에서 정규화하는 편이 안전합니다.

### form 값을 서버 상태처럼 사용

```tsx
const keyword = watch('keyword')
const usersQuery = useQuery({
  queryKey: ['users', keyword],
  queryFn: () => fetchUsers({ keyword }),
})
```

입력 중인 draft가 곧바로 결과 조건이 되면, submit 전후의 의미가 흐려집니다. submit 기반 검색 화면에서는 form draft와 URL 확정 조건을 분리합니다.

## TanStack Router 예시

```tsx
const usersSearchSchema = z.object({
  keyword: z.string().default(''),
  status: z.enum(['all', 'active', 'inactive']).default('all'),
  page: z.coerce.number().int().min(1).default(1),
})

export const Route = createFileRoute('/admin/users')({
  validateSearch: usersSearchSchema,
  loaderDeps: ({ search }) => ({
    keyword: search.keyword,
    status: search.status,
    page: search.page,
  }),
  loader: ({ deps, context }) => {
    return context.queryClient.fetchQuery(usersQueryOptions(deps))
  },
  component: UsersPage,
})
```

컴포넌트는 검증된 search만 사용합니다.

```tsx
function UsersPage() {
  const search = Route.useSearch()
  const navigate = Route.useNavigate()
  const form = useForm({ defaultValues: search })

  const onSubmit = form.handleSubmit((values) => {
    navigate({
      search: (prev) => ({ ...prev, ...values, page: 1 }),
    })
  })

  return <UsersSearchForm form={form} onSubmit={onSubmit} />
}
```

## React Router 예시

```tsx
function parseUsersSearch(searchParams: URLSearchParams) {
  return usersSearchSchema.parse({
    keyword: searchParams.get('keyword') ?? undefined,
    status: searchParams.get('status') ?? undefined,
    page: searchParams.get('page') ?? undefined,
  })
}

function UsersPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const search = parseUsersSearch(searchParams)
  const form = useForm({ defaultValues: search })

  const usersQuery = useQuery(usersQueryOptions(search))

  const onSubmit = form.handleSubmit((values) => {
    setSearchParams(createUsersSearchParams({ ...values, page: 1 }))
  })

  return <UsersSearchForm form={form} onSubmit={onSubmit} />
}
```

React Router만 쓰는 환경에서도 parsing 함수를 route/page boundary에 모으고, leaf 컴포넌트에는 검증된 값을 전달합니다.

## TanStack Query 연결

```tsx
function usersQueryOptions(search: UsersSearch) {
  return queryOptions({
    queryKey: ['users', search],
    queryFn: () => fetchUsers(search),
  })
}
```

필터, 정렬, 페이지네이션이 바뀌면 queryKey도 함께 바뀌어야 합니다. URL state가 데이터 요청 조건이면 queryKey는 URL state에서 파생되어야 합니다.

## 재검증 역할 구분

| API | 역할 |
|-----|------|
| `fetchQuery` | stale 여부를 고려해 fetch하고 결과를 반환합니다. 최신 fetch가 중요한 loader 흐름에 적합합니다. |
| `ensureQueryData` | 캐시가 있으면 우선 반환하고, 없으면 fetch합니다. stale 데이터를 즉시 반환할 수 있음을 고려합니다. |
| `invalidateQueries` | query를 stale로 표시하고 활성 query를 background refetch하게 합니다. |
| `router.invalidate` / `useRevalidator` | 라우트 loader 데이터를 다시 검증합니다. |

mutation 이후에는 query cache만 invalidate할지, route loader까지 revalidate할지 흐름을 명확히 정합니다.

## 적용 시나리오

- 어드민 목록 페이지의 검색, 필터, 정렬, 페이지네이션
- 공유 가능한 대시보드 뷰 상태
- QA 재현이 중요한 데이터 테이블 화면
- 뒤로 가기와 새로고침에서 같은 화면이 유지되어야 하는 화면

## 피해야 할 적용 시나리오

- hover, popover open 여부처럼 URL로 공유할 필요가 없는 일시적 UI 상태
- submit 전 입력 중인 폼 draft
- 서버 응답 데이터 자체
- 보안상 URL에 노출하면 안 되는 값
