# Supabase Migration 가이드

## 초기 설정

### Supabase CLI 설치

```bash
brew install supabase/tap/supabase
```

### 프로젝트 초기화

```bash
supabase init
```

### 원격 프로젝트 연결

```bash
supabase link --project-ref <project-id>
```

## Migration 워크플로우

```
1. Migration 파일 생성 (로컬)
   ↓
2. SQL 작성 (로컬 파일)
   ↓
3. 로컬 DB에서 테스트
   ↓
4. 원격 DB에 적용
   ↓
5. Git 커밋 (팀원과 공유)
```

### Migration 파일 생성

```bash
supabase migration new <migration_name>
# → supabase/migrations/20251029115659_<migration_name>.sql 생성
```

**파일 네이밍 규칙:**
- 형식: `<timestamp>_<description>.sql`
- description은 영어로 작성 (공백 대신 언더스코어)

### SQL 작성 예시

```sql
-- Create User table
CREATE TABLE "User" (
  "id" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "email" TEXT NOT NULL UNIQUE,
  "name" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX "User_email_idx" ON "User"("email");

-- Enable RLS
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own data"
  ON "User" FOR SELECT
  USING (auth.uid()::text = "id");
```

**주의사항:**
- SQL 주석은 영어로 작성 (인코딩 문제 방지)
- RLS(Row Level Security) 정책은 필수
- 인덱스는 성능을 위해 추가

### 로컬 DB에서 테스트

```bash
supabase db reset
```

- ✅ 성공: `Finished supabase db reset`
- ❌ 실패: SQL 수정 후 다시 실행

### 원격 DB에 적용

```bash
supabase db push
```

**중요:** 이 시점에 실제 프로덕션 DB가 변경됨

## 로컬-원격 DB 동기화

### 원격 → 로컬

```bash
supabase db pull
```

### 로컬 → 원격

```bash
supabase db push
```

### 상태 확인

```bash
supabase migration list
supabase db diff
```

## Best Practices

### ✅ 권장사항

1. **항상 로컬에서 먼저 테스트**
2. **Migration 파일은 수정하지 말고 새로 생성**
3. **의미 있는 Migration 이름 사용**
   ```bash
   # ✅ Good
   supabase migration new create_user_table
   supabase migration new add_user_profile_columns

   # ❌ Bad
   supabase migration new update
   supabase migration new fix
   ```
4. **RLS 정책 필수 포함**
5. **인덱스 추가**
6. **Migration은 자주, 작게**

### ❌ 피해야 할 것

1. **원격 DB에서 직접 수정** (Dashboard SQL Editor 사용 금지)
2. **Migration 파일 삭제** (히스토리가 깨짐)
3. **로컬 테스트 없이 push**

## 문제 해결

### Migration 적용 실패

```bash
# 원격 스키마를 먼저 가져오기
supabase db pull
# 그 다음 새 migration 생성
supabase migration new <name>
```

### 로컬-원격 히스토리 불일치

```bash
supabase migration repair --status applied <migration_id>
```

### 인코딩 에러

- SQL 파일의 주석을 영어로 작성
- 파일 인코딩을 UTF-8로 저장

### Docker 문제

```bash
# Docker Desktop 실행
open -a Docker
```
