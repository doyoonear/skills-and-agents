# Zustand Best Practices Guide

## 목차
- [개요](#개요)
- [라이브러리 설치](#라이브러리-설치)
- [핵심 원칙](#핵심-원칙)
- [스토어 구조 설계](#스토어-구조-설계)
- [파일 구조](#파일-구조)
- [기본 사용 방법](#기본-사용-방법)
- [고급 패턴](#고급-패턴)
- [TypeScript 통합](#typescript-통합)
- [성능 최적화](#성능-최적화)
- [Anti-Patterns (피해야 할 것들)](#anti-patterns-피해야-할-것들)
- [마이그레이션 가이드](#마이그레이션-가이드)
- [레퍼런스](#레퍼런스)
- [요약](#요약)

---

## 개요

이 문서는 **Zustand**를 사용하여 React 애플리케이션의 상태 관리를 효과적으로 수행하는 best practice를 설명합니다.

### 핵심 원칙

1. **Custom Hooks 우선**: 스토어를 직접 노출하지 않고 항상 custom hook으로 감싸기
2. **Atomic Selectors**: 개별 값을 반환하여 불필요한 리렌더링 방지
3. **Actions 분리**: 상태와 액션을 명확히 구분하여 관리
4. **Event-driven Actions**: Setter가 아닌 사용자 의도를 표현하는 액션 설계
5. **작은 스토어**: 하나의 거대한 스토어보다 여러 개의 특화된 스토어 선호

### 왜 Zustand인가?

**문제 1: Redux의 복잡성**
```typescript
// ❌ Redux: 보일러플레이트가 많음
// actions.ts, reducers.ts, store.ts, types.ts 등 여러 파일 필요
const INCREMENT = 'counter/increment';
export const increment = () => ({ type: INCREMENT });
const counterReducer = (state = 0, action) => {
  switch (action.type) {
    case INCREMENT: return state + 1;
    default: return state;
  }
};
```

**문제 2: Context API의 성능 문제**
```typescript
// ❌ Context: 값이 하나만 바뀌어도 모든 consumer가 리렌더링
const AppContext = createContext();
// theme만 필요한 컴포넌트도 user가 바뀌면 리렌더링됨
```

**해결: Zustand의 간결함과 성능**
```typescript
// ✅ Zustand: 간결하고 타입 안전
const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}));

// 필요한 값만 구독 → 선택적 리렌더링
const count = useCounterStore((state) => state.count);
```

---

## 라이브러리 설치

```bash
# pnpm (권장)
pnpm add zustand

# npm
npm install zustand

# yarn
yarn add zustand
```

**선택적 의존성 (Middleware 사용 시)**
```bash
# Immer (불변성 관리)
pnpm add immer

# Persist (로컬 스토리지 저장)
# zustand에 내장되어 있음
```

---

## 핵심 원칙

### 1. Export Only Custom Hooks

**문제**: 스토어를 직접 export하면 전체 스토어 구독 위험
```typescript
// ❌ 잘못된 방법: 스토어 직접 노출
export const useBearStore = create<BearState>((set) => ({
  bears: 0,
  fish: 0,
  addBear: () => set((state) => ({ bears: state.bears + 1 })),
}));

// Component에서 실수로 전체 구독
const store = useBearStore(); // ❌ bears, fish 둘 다 구독
```

**해결**: Custom hook으로 감싸서 명확한 인터페이스 제공
```typescript
// ✅ 올바른 방법: Custom hooks만 export
const useBearStoreBase = create<BearState>((set) => ({
  bears: 0,
  fish: 0,
  addBear: () => set((state) => ({ bears: state.bears + 1 })),
}));

// Custom hooks로 감싸기
export const useBears = () => useBearStoreBase((state) => state.bears);
export const useFish = () => useBearStoreBase((state) => state.fish);
export const useBearActions = () => useBearStoreBase((state) => state.addBear);
```

### 2. Atomic Selectors (개별 값 반환)

**문제**: 객체를 반환하면 매번 새 참조가 생성되어 불필요한 리렌더링 발생
```typescript
// ❌ 객체 반환 → 매번 새 객체 생성 → 항상 리렌더링
const { bears, fish } = useBearStore((state) => ({
  bears: state.bears,
  fish: state.fish,
}));
```

**해결 1**: 개별 값을 각각 선택
```typescript
// ✅ Atomic selectors: 각각 구독
const bears = useBearStore((state) => state.bears);
const fish = useBearStore((state) => state.fish);
// bears만 바뀌면 bears만 사용하는 컴포넌트만 리렌더링
```

**해결 2**: 여러 값이 필요하면 `shallow` 사용
```typescript
import { shallow } from 'zustand/shallow';

// ✅ Shallow comparison으로 실제 값 변경 시만 리렌더링
const { bears, fish } = useBearStore(
  (state) => ({ bears: state.bears, fish: state.fish }),
  shallow
);
```

### 3. Separate Actions from State

**문제**: 상태와 액션이 혼재되어 있으면 구조 파악 어려움
```typescript
// ❌ 상태와 액션이 섞여 있음
const useStore = create<State>((set) => ({
  count: 0,
  user: null,
  increment: () => set((state) => ({ count: state.count + 1 })),
  setUser: (user) => set({ user }),
}));
```

**해결**: Actions를 별도 namespace로 분리
```typescript
// ✅ 상태와 액션 명확히 구분
interface BearState {
  // State
  bears: number;
  fish: number;

  // Actions
  actions: {
    addBear: () => void;
    removeBear: () => void;
    addFish: () => void;
  };
}

const useBearStore = create<BearState>((set) => ({
  // State
  bears: 0,
  fish: 0,

  // Actions (한 번 정의되면 변하지 않음)
  actions: {
    addBear: () => set((state) => ({ bears: state.bears + 1 })),
    removeBear: () => set((state) => ({ bears: state.bears - 1 })),
    addFish: () => set((state) => ({ fish: state.fish + 1 })),
  },
}));

// Custom hooks
export const useBears = () => useBearStore((state) => state.bears);
export const useBearActions = () => useBearStore((state) => state.actions);
// actions는 절대 바뀌지 않으므로 리렌더링 없음
```

### 4. Model Actions as Events, Not Setters

**문제**: Setter 스타일은 비즈니스 로직이 컴포넌트에 분산됨
```typescript
// ❌ Setter 스타일: 컴포넌트에 로직 분산
const { setCount, setLastUpdated } = useStore();

// Component에서 비즈니스 로직 처리 → 중복 코드 위험
const handleClick = () => {
  setCount(count + 1);
  setLastUpdated(new Date());
};
```

**해결**: Event-driven actions로 의도 표현
```typescript
// ✅ Event-driven: 스토어에 비즈니스 로직 집중
interface CounterState {
  count: number;
  lastUpdated: Date | null;
  actions: {
    incrementCounter: () => void; // 의도를 명확히 표현
    resetCounter: () => void;
  };
}

const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  lastUpdated: null,
  actions: {
    // 비즈니스 로직을 스토어에 집중
    incrementCounter: () => set((state) => ({
      count: state.count + 1,
      lastUpdated: new Date(),
    })),
    resetCounter: () => set({
      count: 0,
      lastUpdated: new Date(),
    }),
  },
}));

// Component는 단순히 액션 호출
const { incrementCounter } = useCounterActions();
const handleClick = () => incrementCounter(); // 간결함
```

### 5. Keep Store Scope Small

**문제**: 하나의 거대한 스토어는 유지보수 어려움
```typescript
// ❌ 거대한 모놀리식 스토어
const useAppStore = create((set) => ({
  // User 관련
  user: null,
  setUser: () => {},

  // Theme 관련
  theme: 'light',
  setTheme: () => {},

  // Cart 관련
  cart: [],
  addToCart: () => {},

  // ... 수십 개의 상태와 액션
}));
```

**해결**: 도메인별로 스토어 분리
```typescript
// ✅ 작고 집중된 스토어들
// stores/user.ts
export const useUserStore = create<UserState>((set) => ({
  user: null,
  actions: {
    setUser: (user) => set({ user }),
    logout: () => set({ user: null }),
  },
}));

// stores/theme.ts
export const useThemeStore = create<ThemeState>((set) => ({
  theme: 'light',
  actions: {
    toggleTheme: () => set((state) => ({
      theme: state.theme === 'light' ? 'dark' : 'light',
    })),
  },
}));

// stores/cart.ts
export const useCartStore = create<CartState>((set) => ({
  items: [],
  actions: {
    addItem: (item) => set((state) => ({
      items: [...state.items, item],
    })),
    removeItem: (id) => set((state) => ({
      items: state.items.filter((item) => item.id !== id),
    })),
  },
}));

// 필요시 Custom hook으로 조합
export const useCheckout = () => {
  const user = useUserStore((state) => state.user);
  const items = useCartStore((state) => state.items);
  const { clearCart } = useCartActions();

  return { user, items, clearCart };
};
```

---

## 스토어 구조 설계

### 패턴 1: Simple Store (작은 프로젝트)

**언제 사용?**
- 단순한 상태 관리 (3-5개 이하 상태)
- 프로토타입 또는 학습 목적
- 액션이 거의 없는 경우

```typescript
// stores/counter.ts
import { create } from 'zustand';

interface CounterState {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));

// Custom hooks
export const useCount = () => useCounterStore((state) => state.count);
export const useCounterActions = () => useCounterStore((state) => ({
  increment: state.increment,
  decrement: state.decrement,
  reset: state.reset,
}));
```

### 패턴 2: Actions Namespace (중형 프로젝트) - **권장**

**언제 사용?**
- 여러 개의 상태와 액션이 있는 경우
- 상태와 액션을 명확히 구분하고 싶은 경우
- 액션이 자주 바뀌지 않는 경우

```typescript
// stores/bear.ts
import { create } from 'zustand';

interface BearState {
  // State
  bears: number;
  fish: number;

  // Actions namespace
  actions: {
    addBear: () => void;
    removeBear: () => void;
    addFish: () => void;
    eatFish: () => void;
  };
}

const useBearStore = create<BearState>((set) => ({
  // State
  bears: 0,
  fish: 0,

  // Actions
  actions: {
    addBear: () => set((state) => ({ bears: state.bears + 1 })),
    removeBear: () => set((state) => ({
      bears: Math.max(0, state.bears - 1),
    })),
    addFish: () => set((state) => ({ fish: state.fish + 1 })),
    eatFish: () => set((state) => ({
      fish: Math.max(0, state.fish - 1),
      bears: state.bears + 1, // 물고기를 먹으면 곰 증가
    })),
  },
}));

// Custom hooks
export const useBears = () => useBearStore((state) => state.bears);
export const useFish = () => useBearStore((state) => state.fish);
export const useBearActions = () => useBearStore((state) => state.actions);
```

### 패턴 3: Slices Pattern (대형 프로젝트)

**언제 사용?**
- 하나의 스토어에 여러 도메인 로직이 필요한 경우
- 각 slice를 독립적으로 관리하고 싶은 경우
- 팀원들이 동시에 작업하는 경우

```typescript
// stores/slices/userSlice.ts
import { StateCreator } from 'zustand';

export interface UserSlice {
  user: User | null;
  actions: {
    setUser: (user: User) => void;
    logout: () => void;
  };
}

export const createUserSlice: StateCreator<
  UserSlice & ThemeSlice & CartSlice,
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  actions: {
    setUser: (user) => set({ user }),
    logout: () => set({ user: null }),
  },
});

// stores/slices/themeSlice.ts
export interface ThemeSlice {
  theme: 'light' | 'dark';
  actions: {
    toggleTheme: () => void;
  };
}

export const createThemeSlice: StateCreator<
  UserSlice & ThemeSlice & CartSlice,
  [],
  [],
  ThemeSlice
> = (set) => ({
  theme: 'light',
  actions: {
    toggleTheme: () => set((state) => ({
      theme: state.theme === 'light' ? 'dark' : 'light',
    })),
  },
});

// stores/slices/cartSlice.ts
export interface CartSlice {
  items: CartItem[];
  actions: {
    addItem: (item: CartItem) => void;
    removeItem: (id: string) => void;
  };
}

export const createCartSlice: StateCreator<
  UserSlice & ThemeSlice & CartSlice,
  [],
  [],
  CartSlice
> = (set) => ({
  items: [],
  actions: {
    addItem: (item) => set((state) => ({
      items: [...state.items, item],
    })),
    removeItem: (id) => set((state) => ({
      items: state.items.filter((item) => item.id !== id),
    })),
  },
});

// stores/index.ts
import { create } from 'zustand';
import { createUserSlice, UserSlice } from './slices/userSlice';
import { createThemeSlice, ThemeSlice } from './slices/themeSlice';
import { createCartSlice, CartSlice } from './slices/cartSlice';

type AppState = UserSlice & ThemeSlice & CartSlice;

const useAppStore = create<AppState>()((...a) => ({
  ...createUserSlice(...a),
  ...createThemeSlice(...a),
  ...createCartSlice(...a),
}));

// Custom hooks
export const useUser = () => useAppStore((state) => state.user);
export const useTheme = () => useAppStore((state) => state.theme);
export const useCartItems = () => useAppStore((state) => state.items);
export const useUserActions = () => useAppStore((state) => state.actions);
```

---

## 파일 구조

### 작은 프로젝트

```
src/
├── stores/
│   ├── counter.ts          # Simple Store
│   └── theme.ts            # Simple Store
└── components/
    └── Counter.tsx
```

### 중형 프로젝트 (권장)

```
src/
├── stores/
│   ├── index.ts            # 모든 스토어 export
│   ├── user.ts             # Actions Namespace 패턴
│   ├── cart.ts             # Actions Namespace 패턴
│   └── theme.ts            # Actions Namespace 패턴
└── components/
    ├── Header.tsx
    └── Cart.tsx
```

### 대형 프로젝트

```
src/
├── stores/
│   ├── index.ts                 # Slices 통합
│   ├── slices/
│   │   ├── userSlice.ts         # User domain
│   │   ├── cartSlice.ts         # Cart domain
│   │   └── themeSlice.ts        # Theme domain
│   └── middleware/
│       ├── logger.ts            # Custom middleware
│       └── errorHandler.ts
└── components/
    ├── features/
    │   ├── user/
    │   │   └── UserProfile.tsx
    │   ├── cart/
    │   │   └── CartList.tsx
    │   └── theme/
    │       └── ThemeToggle.tsx
    └── shared/
```

---

## 기본 사용 방법

### 1. Store 생성

```typescript
// stores/todo.ts
import { create } from 'zustand';

interface Todo {
  id: string;
  text: string;
  completed: boolean;
}

interface TodoState {
  // State
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';

  // Actions
  actions: {
    addTodo: (text: string) => void;
    toggleTodo: (id: string) => void;
    removeTodo: (id: string) => void;
    setFilter: (filter: 'all' | 'active' | 'completed') => void;
  };
}

const useTodoStore = create<TodoState>((set) => ({
  // Initial State
  todos: [],
  filter: 'all',

  // Actions
  actions: {
    addTodo: (text) => set((state) => ({
      todos: [
        ...state.todos,
        {
          id: crypto.randomUUID(),
          text,
          completed: false,
        },
      ],
    })),

    toggleTodo: (id) => set((state) => ({
      todos: state.todos.map((todo) =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      ),
    })),

    removeTodo: (id) => set((state) => ({
      todos: state.todos.filter((todo) => todo.id !== id),
    })),

    setFilter: (filter) => set({ filter }),
  },
}));

// Custom hooks with selectors
export const useTodos = () => useTodoStore((state) => state.todos);
export const useFilter = () => useTodoStore((state) => state.filter);
export const useTodoActions = () => useTodoStore((state) => state.actions);

// Derived state (computed values)
export const useFilteredTodos = () => {
  const todos = useTodos();
  const filter = useFilter();

  return todos.filter((todo) => {
    if (filter === 'active') return !todo.completed;
    if (filter === 'completed') return todo.completed;
    return true;
  });
};
```

### 2. Component에서 사용

```typescript
// components/TodoList.tsx
import { useTodos, useTodoActions, useFilteredTodos } from '@/stores/todo';

export function TodoList() {
  const filteredTodos = useFilteredTodos();
  const { toggleTodo, removeTodo } = useTodoActions();

  return (
    <ul>
      {filteredTodos.map((todo) => (
        <li key={todo.id}>
          <input
            type="checkbox"
            checked={todo.completed}
            onChange={() => toggleTodo(todo.id)}
          />
          <span style={{ textDecoration: todo.completed ? 'line-through' : 'none' }}>
            {todo.text}
          </span>
          <button onClick={() => removeTodo(todo.id)}>삭제</button>
        </li>
      ))}
    </ul>
  );
}

// components/TodoInput.tsx
export function TodoInput() {
  const [text, setText] = useState('');
  const { addTodo } = useTodoActions();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (text.trim()) {
      addTodo(text);
      setText('');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="할 일 입력..."
      />
      <button type="submit">추가</button>
    </form>
  );
}

// components/TodoFilter.tsx
export function TodoFilter() {
  const filter = useFilter();
  const { setFilter } = useTodoActions();

  return (
    <div>
      <button
        onClick={() => setFilter('all')}
        disabled={filter === 'all'}
      >
        전체
      </button>
      <button
        onClick={() => setFilter('active')}
        disabled={filter === 'active'}
      >
        진행중
      </button>
      <button
        onClick={() => setFilter('completed')}
        disabled={filter === 'completed'}
      >
        완료
      </button>
    </div>
  );
}
```

### 3. Async Actions (비동기 처리)

```typescript
// stores/post.ts
interface Post {
  id: string;
  title: string;
  body: string;
}

interface PostState {
  // State
  posts: Post[];
  isLoading: boolean;
  error: string | null;

  // Actions
  actions: {
    fetchPosts: () => Promise<void>;
    createPost: (post: Omit<Post, 'id'>) => Promise<void>;
  };
}

const usePostStore = create<PostState>((set, get) => ({
  posts: [],
  isLoading: false,
  error: null,

  actions: {
    fetchPosts: async () => {
      set({ isLoading: true, error: null });

      try {
        const response = await fetch('/api/posts');
        if (!response.ok) throw new Error('Failed to fetch');

        const posts = await response.json();
        set({ posts, isLoading: false });
      } catch (error) {
        set({
          error: error instanceof Error ? error.message : 'Unknown error',
          isLoading: false,
        });
      }
    },

    createPost: async (newPost) => {
      set({ isLoading: true, error: null });

      try {
        const response = await fetch('/api/posts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(newPost),
        });

        if (!response.ok) throw new Error('Failed to create');

        const post = await response.json();
        set((state) => ({
          posts: [...state.posts, post],
          isLoading: false,
        }));
      } catch (error) {
        set({
          error: error instanceof Error ? error.message : 'Unknown error',
          isLoading: false,
        });
      }
    },
  },
}));

// Custom hooks
export const usePosts = () => usePostStore((state) => state.posts);
export const usePostsLoading = () => usePostStore((state) => state.isLoading);
export const usePostsError = () => usePostStore((state) => state.error);
export const usePostActions = () => usePostStore((state) => state.actions);

// Component
export function PostList() {
  const posts = usePosts();
  const isLoading = usePostsLoading();
  const error = usePostsError();
  const { fetchPosts } = usePostActions();

  useEffect(() => {
    fetchPosts();
  }, [fetchPosts]);

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error} />;

  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}
```

---

## 고급 패턴

### 1. Immer Middleware (불변성 관리)

```typescript
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface DeepState {
  user: {
    profile: {
      name: string;
      age: number;
    };
    settings: {
      theme: string;
      notifications: boolean;
    };
  };
  actions: {
    updateName: (name: string) => void;
    toggleNotifications: () => void;
  };
}

// ✅ Immer로 가변 문법 사용 가능
const useStore = create<DeepState>()(
  immer((set) => ({
    user: {
      profile: { name: '', age: 0 },
      settings: { theme: 'light', notifications: true },
    },
    actions: {
      // Immer 없이는 복잡한 코드
      // set((state) => ({
      //   user: {
      //     ...state.user,
      //     profile: {
      //       ...state.user.profile,
      //       name,
      //     },
      //   },
      // }))

      // ✅ Immer로 간결하게
      updateName: (name) => set((state) => {
        state.user.profile.name = name; // 가변 문법 사용 가능
      }),

      toggleNotifications: () => set((state) => {
        state.user.settings.notifications = !state.user.settings.notifications;
      }),
    },
  }))
);
```

### 2. Persist Middleware (로컬 스토리지 저장)

```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  user: User | null;
  actions: {
    login: (token: string, user: User) => void;
    logout: () => void;
  };
}

const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      actions: {
        login: (token, user) => set({ token, user }),
        logout: () => set({ token: null, user: null }),
      },
    }),
    {
      name: 'auth-storage', // localStorage key
      storage: createJSONStorage(() => localStorage), // default

      // 특정 필드만 저장
      partialize: (state) => ({
        token: state.token,
        user: state.user,
        // actions는 저장 안함
      }),
    }
  )
);
```

### 3. Devtools Middleware (디버깅)

```typescript
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

interface CounterState {
  count: number;
  actions: {
    increment: () => void;
    decrement: () => void;
  };
}

const useCounterStore = create<CounterState>()(
  devtools(
    (set) => ({
      count: 0,
      actions: {
        increment: () => set(
          (state) => ({ count: state.count + 1 }),
          false, // replace 여부
          'counter/increment' // Action name (Redux DevTools에 표시)
        ),
        decrement: () => set(
          (state) => ({ count: state.count - 1 }),
          false,
          'counter/decrement'
        ),
      },
    }),
    { name: 'CounterStore' } // DevTools에 표시될 이름
  )
);
```

### 4. Combining Middleware

```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface TodoState {
  todos: Todo[];
  actions: {
    addTodo: (text: string) => void;
  };
}

// ✅ 올바른 순서: devtools → persist → immer
const useTodoStore = create<TodoState>()(
  devtools(
    persist(
      immer((set) => ({
        todos: [],
        actions: {
          addTodo: (text) => set((state) => {
            state.todos.push({
              id: crypto.randomUUID(),
              text,
              completed: false,
            });
          }),
        },
      })),
      { name: 'todo-storage' }
    ),
    { name: 'TodoStore' }
  )
);

// ❌ 잘못된 순서: devtools는 가장 바깥에
// create()(immer(persist(devtools(...))))  // 동작 안함
```

### 5. Subscriptions (구독)

```typescript
// 스토어 외부에서 상태 변화 감지
const unsubscribe = useCartStore.subscribe(
  (state) => state.items,  // selector
  (items, prevItems) => {
    console.log('Cart items changed:', items);
    // 로깅, 분석 이벤트 전송 등
  }
);

// 구독 해제
unsubscribe();

// 전체 상태 구독
const unsubscribeAll = useCartStore.subscribe((state) => {
  console.log('Store updated:', state);
});
```

### 6. Transient Updates (임시 업데이트)

```typescript
// React 외부에서 스토어 업데이트 (리렌더링 없음)
const useStore = create<State>((set) => ({
  count: 0,
  actions: {
    increment: () => set((state) => ({ count: state.count + 1 })),
  },
}));

// React 외부에서 직접 호출 가능
useStore.getState().actions.increment();

// 현재 상태 읽기
const currentCount = useStore.getState().count;
```

---

## TypeScript 통합

### 1. 기본 타입 정의

```typescript
import { create } from 'zustand';

// ✅ Interface 사용 (권장)
interface BearState {
  bears: number;
  actions: {
    addBear: () => void;
  };
}

const useBearStore = create<BearState>((set) => ({
  bears: 0,
  actions: {
    addBear: () => set((state) => ({ bears: state.bears + 1 })),
  },
}));

// ✅ Type alias도 가능
type BearState = {
  bears: number;
  actions: {
    addBear: () => void;
  };
};
```

### 2. Middleware와 TypeScript

```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface TodoState {
  todos: Todo[];
  actions: {
    addTodo: (text: string) => void;
  };
}

// ✅ Middleware 타입 추론을 위한 올바른 패턴
const useTodoStore = create<TodoState>()(
  devtools(
    persist(
      immer((set) => ({
        todos: [],
        actions: {
          addTodo: (text) => set((state) => {
            state.todos.push({
              id: crypto.randomUUID(),
              text,
              completed: false,
            });
          }),
        },
      })),
      { name: 'todo-storage' }
    ),
    { name: 'TodoStore' }
  )
);

// ❌ 잘못된 패턴 (타입 추론 깨짐)
// const useTodoStore = create<TodoState>(devtools(...))
```

### 3. Slices 타입 정의

```typescript
import { StateCreator } from 'zustand';

// ✅ StateCreator로 slice 타입 정의
export interface BearSlice {
  bears: number;
  addBear: () => void;
}

export interface FishSlice {
  fish: number;
  addFish: () => void;
}

type SharedState = BearSlice & FishSlice;

export const createBearSlice: StateCreator<
  SharedState,  // 전체 상태 타입
  [],
  [],
  BearSlice     // 이 slice의 타입
> = (set) => ({
  bears: 0,
  addBear: () => set((state) => ({ bears: state.bears + 1 })),
});

export const createFishSlice: StateCreator<
  SharedState,
  [],
  [],
  FishSlice
> = (set) => ({
  fish: 0,
  addFish: () => set((state) => ({ fish: state.fish + 1 })),
});

// 통합
const useStore = create<SharedState>()((...a) => ({
  ...createBearSlice(...a),
  ...createFishSlice(...a),
}));
```

### 4. Middleware Slices 타입

```typescript
import { StateCreator } from 'zustand';

export interface UserSlice {
  user: User | null;
  setUser: (user: User) => void;
}

// ✅ Middleware를 사용하는 slice 타입
export const createUserSlice: StateCreator<
  UserSlice,
  [['zustand/immer', never], ['zustand/devtools', never]], // Middleware 타입
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set((state) => {
    state.user = user; // Immer 사용
  }),
});
```

---

## 성능 최적화

### 1. Selective Subscriptions

```typescript
// ❌ 전체 스토어 구독 → 모든 변경에 리렌더링
const store = useBearStore();

// ✅ 필요한 값만 구독
const bears = useBearStore((state) => state.bears);
const fish = useBearStore((state) => state.fish);
```

### 2. Shallow Comparison

```typescript
import { shallow } from 'zustand/shallow';

// ❌ 매번 새 객체 생성 → 항상 리렌더링
const { bears, fish } = useBearStore((state) => ({
  bears: state.bears,
  fish: state.fish,
}));

// ✅ Shallow comparison으로 실제 값 변경 시만 리렌더링
const { bears, fish } = useBearStore(
  (state) => ({ bears: state.bears, fish: state.fish }),
  shallow
);
```

### 3. Memoized Selectors

```typescript
import { useMemo } from 'react';

// ❌ 매 렌더링마다 새 배열 생성
const activeUsers = useUserStore((state) =>
  state.users.filter((user) => user.isActive)
);

// ✅ Custom hook으로 memoization
export const useActiveUsers = () => {
  const users = useUserStore((state) => state.users);

  return useMemo(
    () => users.filter((user) => user.isActive),
    [users]
  );
};

// 또는 zustand의 createSelector 사용
import { createSelector } from 'zustand';

const selectActiveUsers = createSelector(
  [(state: UserState) => state.users],
  (users) => users.filter((user) => user.isActive)
);

export const useActiveUsers = () => useUserStore(selectActiveUsers);
```

### 4. Actions 분리로 리렌더링 방지

```typescript
interface BearState {
  bears: number;
  actions: {
    addBear: () => void;
  };
}

// ✅ Actions는 절대 바뀌지 않으므로 리렌더링 없음
const { addBear } = useBearActions();

// Component는 addBear가 바뀌지 않으므로 useCallback 불필요
const handleClick = addBear; // 안전함
```

### 5. Computed Values 최적화

```typescript
// ❌ 컴포넌트에서 계산 → 매번 재계산
function TodoList() {
  const todos = useTodos();
  const activeTodos = todos.filter((todo) => !todo.completed); // 매번 계산
  const completedTodos = todos.filter((todo) => todo.completed);

  return <div>...</div>;
}

// ✅ Custom hook으로 분리 + memoization
export const useActiveTodos = () => {
  const todos = useTodos();
  return useMemo(
    () => todos.filter((todo) => !todo.completed),
    [todos]
  );
};

export const useCompletedTodos = () => {
  const todos = useTodos();
  return useMemo(
    () => todos.filter((todo) => todo.completed),
    [todos]
  );
};

function TodoList() {
  const activeTodos = useActiveTodos();
  const completedTodos = useCompletedTodos();

  return <div>...</div>;
}
```

---

## Anti-Patterns (피해야 할 것들)

### 1. ❌ 직접 Mutation

```typescript
// ❌ 절대 금지: 상태 직접 변경
const { todos, actions } = useTodoStore();
todos.push(newTodo); // 리렌더링 안됨, 버그 발생

// ✅ 항상 set 사용
const { addTodo } = useTodoActions();
addTodo(newTodo);
```

### 2. ❌ 컴포넌트 내 스토어 생성

```typescript
// ❌ 절대 금지: 컴포넌트 내부에서 스토어 생성
function MyComponent() {
  const useStore = create(() => ({ count: 0 })); // 매 렌더링마다 새 스토어
  return <div>...</div>;
}

// ✅ 컴포넌트 외부에서 생성
const useStore = create(() => ({ count: 0 }));

function MyComponent() {
  const count = useStore((state) => state.count);
  return <div>{count}</div>;
}
```

### 3. ❌ 전체 스토어 구독

```typescript
// ❌ 비효율: 전체 스토어 구독
const store = useBearStore();
return <div>{store.bears}</div>; // fish가 바뀌어도 리렌더링

// ✅ 선택적 구독
const bears = useBearStore((state) => state.bears);
return <div>{bears}</div>; // bears만 바뀌면 리렌더링
```

### 4. ❌ 복잡한 Selector 무분별 사용

```typescript
// ❌ 매번 새 배열/객체 생성
const data = useStore((state) => ({
  users: state.users.filter((u) => u.isActive),
  posts: state.posts.sort((a, b) => b.createdAt - a.createdAt),
}));
// 매 렌더링마다 새 객체 → 항상 리렌더링

// ✅ Custom hook + memoization
export const useActiveUsersAndPosts = () => {
  const users = useStore((state) => state.users);
  const posts = useStore((state) => state.posts);

  const activeUsers = useMemo(
    () => users.filter((u) => u.isActive),
    [users]
  );

  const sortedPosts = useMemo(
    () => posts.sort((a, b) => b.createdAt - a.createdAt),
    [posts]
  );

  return { activeUsers, sortedPosts };
};
```

### 5. ❌ Middleware 순서 오류

```typescript
// ❌ devtools가 중간에 있으면 동작 안함
const useStore = create(
  immer(
    devtools(  // 잘못된 위치
      persist(
        (set) => ({ ... }),
        { name: 'storage' }
      ),
      { name: 'Store' }
    )
  )
);

// ✅ 올바른 순서: devtools → persist → immer
const useStore = create(
  devtools(
    persist(
      immer((set) => ({ ... })),
      { name: 'storage' }
    ),
    { name: 'Store' }
  )
);
```

### 6. ❌ Actions에서 get() 남용

```typescript
// ❌ get() 남용
const useStore = create((set, get) => ({
  count: 0,
  increment: () => {
    const currentCount = get().count; // 불필요한 get
    set({ count: currentCount + 1 });
  },
}));

// ✅ set의 함수형 업데이트 사용
const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}));
```

---

## 마이그레이션 가이드

### Context API에서 마이그레이션

```typescript
// ❌ Before: Context API
const CounterContext = createContext<{
  count: number;
  increment: () => void;
} | null>(null);

function CounterProvider({ children }) {
  const [count, setCount] = useState(0);
  const increment = useCallback(() => setCount((c) => c + 1), []);

  return (
    <CounterContext.Provider value={{ count, increment }}>
      {children}
    </CounterContext.Provider>
  );
}

function useCounter() {
  const context = useContext(CounterContext);
  if (!context) throw new Error('...');
  return context;
}

// ✅ After: Zustand
const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  actions: {
    increment: () => set((state) => ({ count: state.count + 1 })),
  },
}));

export const useCount = () => useCounterStore((state) => state.count);
export const useCounterActions = () => useCounterStore((state) => state.actions);

// Provider 불필요!
```

### Redux에서 마이그레이션

```typescript
// ❌ Before: Redux
// actions.ts
const INCREMENT = 'counter/increment';
export const increment = () => ({ type: INCREMENT });

// reducer.ts
const initialState = { count: 0 };
export const counterReducer = (state = initialState, action) => {
  switch (action.type) {
    case INCREMENT:
      return { ...state, count: state.count + 1 };
    default:
      return state;
  }
};

// store.ts
const store = configureStore({
  reducer: { counter: counterReducer },
});

// Component
const count = useSelector((state) => state.counter.count);
const dispatch = useDispatch();
const handleClick = () => dispatch(increment());

// ✅ After: Zustand (훨씬 간결)
const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  actions: {
    increment: () => set((state) => ({ count: state.count + 1 })),
  },
}));

export const useCount = () => useCounterStore((state) => state.count);
export const useCounterActions = () => useCounterStore((state) => state.actions);

// Component
const count = useCount();
const { increment } = useCounterActions();
const handleClick = () => increment();
```

---

## 레퍼런스

### 공식 문서
- **[Zustand GitHub](https://github.com/pmndrs/zustand)**
  공식 저장소, 최신 기능 및 API 문서

- **[Zustand 공식 문서](https://docs.pmnd.rs/zustand/getting-started/introduction)**
  전체 가이드 및 API 레퍼런스

### Best Practices
- **[Working with Zustand - TkDodo's blog](https://tkdodo.eu/blog/working-with-zustand)**
  React Query 메인테이너의 Zustand best practice

- **[Zustand in React: DOs and DON'Ts](https://medium.com/@nfailla93/zustand-in-react-dos-and-donts-5a608c26c68)**
  실전 패턴과 안티패턴

- **[Zustand Best Practices - Project Rules](https://www.projectrules.ai/rules/zustand)**
  코드 조직화 및 성능 최적화 가이드

### 커뮤니티
- **[State Management in 2025: When to Use Context, Redux, Zustand, or Jotai](https://dev.to/hijazi313/state-management-in-2025-when-to-use-context-redux-zustand-or-jotai-2d2k)**
  상태 관리 라이브러리 비교 및 선택 가이드

---

## 요약

### 핵심 장점

| 항목 | Redux | Context API | Zustand | 효과 |
|------|-------|------------|---------|------|
| **보일러플레이트** | ❌ 많음 | ✅ 적음 | ✅ 최소 | 개발 속도 ↑ |
| **타입 안전성** | ✅ 우수 | ⚠️ 보통 | ✅ 우수 | 버그 감소 |
| **선택적 구독** | ✅ 지원 | ❌ 없음 | ✅ 지원 | 성능 최적화 |
| **Provider 필요** | ✅ 필요 | ✅ 필요 | ❌ 불필요 | 코드 간결 |
| **DevTools** | ✅ 지원 | ❌ 없음 | ✅ Middleware | 디버깅 편의 |
| **학습 곡선** | ⚠️ 가파름 | ✅ 낮음 | ✅ 낮음 | 빠른 적용 |
| **번들 크기** | ⚠️ 큼 | ✅ 작음 | ✅ 작음 (1.2KB) | 성능 ↑ |

### 언제 Zustand를 사용하는가?

✅ **추천하는 경우**
- 중소형~대형 React 애플리케이션
- Redux의 복잡성 없이 전역 상태 관리가 필요한 경우
- Context API의 성능 문제를 해결하고 싶은 경우
- TypeScript 프로젝트 (타입 안전성)
- 빠른 프로토타이핑이 필요한 경우

⚠️ **고려가 필요한 경우**
- 매우 작은 프로젝트 (useState만으로 충분)
- 서버 상태 관리 (→ TanStack Query 사용)
- 시간 여행 디버깅이 필수인 경우 (→ Redux DevTools가 더 강력)

### Best Practices 체크리스트

- [ ] Custom hooks만 export (스토어 직접 노출 X)
- [ ] Atomic selectors 사용 (개별 값 반환)
- [ ] Actions를 별도 namespace로 분리
- [ ] Event-driven actions (setter 스타일 지양)
- [ ] 도메인별 작은 스토어 (모놀리식 지양)
- [ ] 직접 mutation 금지 (항상 set 사용)
- [ ] 컴포넌트 외부에서 스토어 생성
- [ ] TypeScript 적극 활용
- [ ] Middleware 조합 시 올바른 순서 (devtools → persist → immer)
- [ ] Shallow comparison 활용 (여러 값 구독 시)
- [ ] Memoized selectors (복잡한 계산 시)

### 다음 단계

1. 프로젝트 규모에 따라 **Simple / Actions Namespace / Slices** 패턴 선택
2. Custom hooks로 스토어 감싸기
3. 비동기 로직은 actions에 집중
4. Middleware (persist, devtools, immer) 필요시 적용
5. 성능 최적화 (selective subscriptions, shallow, memoization)
