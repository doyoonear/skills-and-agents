---
name: tdd-workflow
description: |
  테스트 주도 개발(TDD) 방식으로 코드를 작성합니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "/tdd", "TDD로 구현해줘"
  - "테스트 먼저 작성해줘"
  - "테스트 주도 개발로 해줘"
  - "RED-GREEN-REFACTOR로 해줘"
---

# TDD Workflow Skill

테스트 주도 개발(Test-Driven Development) 방식으로 코드를 작성하는 skill입니다.

## TDD 사이클

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   RED ──────► GREEN ──────► REFACTOR ──┐       │
│    │                                    │       │
│    └────────────────────────────────────┘       │
│                                                 │
│   RED: 실패하는 테스트 작성                       │
│   GREEN: 테스트 통과하는 최소 코드 구현            │
│   REFACTOR: 테스트 유지하며 코드 개선             │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 워크플로우

### Phase 1: 인터페이스 정의

구현 전에 입출력 타입과 함수 시그니처를 먼저 정의합니다.

```typescript
// 1. 타입 정의
interface CartItem {
  id: string;
  price: number;
  quantity: number;
}

// 2. 함수 시그니처 정의
function calculateTotal(items: CartItem[]): number;
```

### Phase 2: RED - 실패하는 테스트 작성

**구현 전에** 테스트를 먼저 작성합니다.

```typescript
describe('calculateTotal', () => {
  test('빈 배열이면 0을 반환한다', () => {
    expect(calculateTotal([])).toBe(0);
  });

  test('단일 아이템의 총액을 계산한다', () => {
    const items = [{ id: '1', price: 1000, quantity: 2 }];
    expect(calculateTotal(items)).toBe(2000);
  });

  test('여러 아이템의 총액을 계산한다', () => {
    const items = [
      { id: '1', price: 1000, quantity: 2 },
      { id: '2', price: 500, quantity: 3 },
    ];
    expect(calculateTotal(items)).toBe(3500);
  });
});
```

테스트 실행:
```bash
pnpm test -- --watch
```

### Phase 3: GREEN - 최소 구현

테스트를 통과하는 **최소한의 코드**만 작성합니다.

```typescript
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}
```

⚠️ **주의**: 이 단계에서는 최적화나 리팩토링을 하지 않습니다.

### Phase 4: REFACTOR - 개선

테스트가 통과하는 상태를 유지하며 코드를 개선합니다.

```typescript
// 개선 예시: 가독성 향상
function calculateTotal(items: CartItem[]): number {
  const calculateItemTotal = (item: CartItem) => item.price * item.quantity;
  return items.reduce((sum, item) => sum + calculateItemTotal(item), 0);
}
```

### Phase 5: 커버리지 검증

```bash
pnpm test --coverage
```

---

## 필수 원칙

### ✅ 해야 할 것

1. **테스트 먼저**: 구현 전에 반드시 테스트 작성
2. **각 단계 확인**: 단계마다 테스트 실행
3. **최소 구현**: 테스트 통과에 필요한 최소 코드만
4. **80% 커버리지**: 최소 80% 테스트 커버리지 유지

### ❌ 하지 말 것

1. **구현 먼저**: 테스트 전에 구현 코드 작성 금지
2. **테스트 스킵**: 테스트 실행 건너뛰기 금지
3. **과도한 구현**: 한 번에 너무 많은 코드 작성 금지
4. **구현 테스트**: 동작이 아닌 구현 세부사항 테스트 금지

---

## 커버리지 요구사항

| 코드 영역 | 최소 커버리지 |
|----------|-------------|
| 일반 코드 | 80% |
| 금융 계산 | 100% |
| 인증/보안 | 100% |
| 핵심 비즈니스 로직 | 100% |

---

## 테스트 작성 팁

### 좋은 테스트의 특징

```typescript
// ✅ 좋은 테스트: 동작을 테스트
test('장바구니가 비어있으면 결제 버튼이 비활성화된다', () => {
  render(<Cart items={[]} />);
  expect(screen.getByRole('button', { name: '결제' })).toBeDisabled();
});

// ❌ 나쁜 테스트: 구현 세부사항 테스트
test('isDisabled 상태가 true이다', () => {
  const { result } = renderHook(() => useCart([]));
  expect(result.current.isDisabled).toBe(true);
});
```

### 테스트 구조 (AAA 패턴)

```typescript
test('설명', () => {
  // Arrange (준비)
  const items = [{ id: '1', price: 1000, quantity: 1 }];

  // Act (실행)
  const total = calculateTotal(items);

  // Assert (검증)
  expect(total).toBe(1000);
});
```

---

## 커밋 전략

TDD 사이클에 맞춰 커밋합니다:

```
test(cart): add failing tests for calculateTotal

feat(cart): implement calculateTotal function

refactor(cart): extract calculateItemTotal helper
```
