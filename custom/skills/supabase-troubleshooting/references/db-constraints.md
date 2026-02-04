# Database 제약 조건 에러

## NOT NULL 제약 조건 위반

### 문제 상황

```
Error: null value in column "columnName" violates not-null constraint
```

Migration에서 `NOT NULL`로 정의했으나 코드에서 값을 제공하지 않아 발생.

### 예시

**Migration:**
```sql
CREATE TABLE "Product" (
  "id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "name" TEXT NOT NULL,
  "userId" TEXT NOT NULL,  -- NOT NULL이지만 코드에서 누락
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**문제 코드:**
```typescript
// userId를 제공하지 않음
const { data, error } = await supabase
  .from('Product')
  .insert({
    name: productName  // userId 누락!
  });
```

### 해결 방법

#### 방법 1: 코드에서 값 제공 (권장)

```typescript
const { data: { user } } = await supabase.auth.getUser();

const { data, error } = await supabase
  .from('Product')
  .insert({
    name: productName,
    userId: user?.id  // 값 제공
  });
```

#### 방법 2: NULL 허용으로 변경

```sql
"userId" TEXT,  -- NULL 허용
CONSTRAINT "Product_userId_fkey"
  FOREIGN KEY ("userId")
  REFERENCES "User"("id")
  ON DELETE SET NULL
```

#### 방법 3: DEFAULT 값 설정

```sql
"userId" TEXT NOT NULL DEFAULT 'anonymous'
```

## NOT NULL vs NULL 허용 결정 가이드

| 상황 | 설정 | 예시 |
|------|------|------|
| 시스템이 자동 생성 | `NOT NULL DEFAULT` | `id`, `createdAt` |
| 비즈니스상 필수 | `NOT NULL` | `name`, `email` |
| 비즈니스상 필수 + 기본값 존재 | `NOT NULL DEFAULT` | `status`, `isActive` |
| 선택 사항 | `NULL` 허용 | `phoneNumber`, `description` |
| Foreign Key (필수 관계) | `NOT NULL` | `userId` (게시글 작성자) |
| Foreign Key (선택 관계) | `NULL` 허용 | `parentCommentId` (답글) |

## Foreign Key 제약 조건 에러

### 문제

```
Error: insert or update on table "Product" violates foreign key constraint
```

### 원인

참조하는 레코드가 존재하지 않음:

```typescript
// userId='non-existent-id'가 User 테이블에 없음
const { error } = await supabase.from('Product').insert({
  name: 'Product Name',
  userId: 'non-existent-id'
});
```

### 해결

1. **참조 데이터 먼저 생성**
   ```typescript
   const { data: user } = await supabase.from('User').insert({ ... });
   await supabase.from('Product').insert({ userId: user.id });
   ```

2. **존재하는 ID 사용**
   ```typescript
   const { data: { user } } = await supabase.auth.getUser();
   // user.id는 이미 존재하는 ID
   ```

3. **Foreign Key를 NULL 허용으로 변경**
   ```sql
   "userId" TEXT,
   FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL
   ```

## DEFAULT 설정 전략

### 시스템 자동 생성

```sql
"id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
"createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
"updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### 비즈니스 기본값

```sql
"quantity" INTEGER NOT NULL DEFAULT 1,
"isActive" BOOLEAN NOT NULL DEFAULT false,
"status" TEXT NOT NULL DEFAULT 'pending'
```

### Foreign Key 관계

```sql
-- 필수 관계: CASCADE
FOREIGN KEY ("parentId") REFERENCES "Parent"("id") ON DELETE CASCADE

-- 선택 관계: SET NULL
FOREIGN KEY ("optionalId") REFERENCES "Optional"("id") ON DELETE SET NULL
```

## 디버깅 팁

### 에러 코드 확인

```typescript
const { data, error } = await supabase.from('Table').insert(newData);

if (error) {
  console.error('Error code:', error.code);
  console.error('Error details:', error.details);
  console.error('Error hint:', error.hint);

  // NOT NULL 제약 조건 에러
  if (error.code === '23502') {
    console.error('Missing required field');
  }

  // Foreign Key 제약 조건 에러
  if (error.code === '23503') {
    console.error('Referenced record does not exist');
  }
}
```

### 테이블 스키마 확인

```bash
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres
\d "TableName"
```

## 에러 방지 체크리스트

### 테이블 생성 시:

- [ ] 모든 `NOT NULL` 컬럼에 `DEFAULT` 값이 있거나 코드에서 반드시 제공
- [ ] `DEFAULT` 값이 비즈니스 로직과 일치
- [ ] Foreign Key의 `ON DELETE`, `ON UPDATE` 동작이 적절
- [ ] NULL 허용 컬럼이 NULL일 때 앱 로직이 정상 작동

### 코드 작성 시:

```typescript
// ❌ 나쁜 예
await supabase.from('Product').insert({ name: productName });

// ✅ 좋은 예
await supabase.from('Product').insert({
  name: productName,
  userId: currentUser.id
});
```
