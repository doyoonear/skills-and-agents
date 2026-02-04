# Migration 에러

## 1. Migration 적용 실패

### 문제

```
ERROR: relation "TableName" does not exist
```

### 원인

- 참조하는 테이블이 아직 생성되지 않음
- Migration 파일 순서 문제
- 이전 Migration이 실패하여 테이블이 누락됨

### 해결

#### 방법 1: 원격 스키마를 먼저 가져오기

```bash
supabase db pull
supabase migration new add_new_table
```

#### 방법 2: Migration 순서 확인

```bash
ls -la supabase/migrations/
```

의존성 있는 테이블은 순서 주의:
- User 테이블 → Product 테이블 (userId Foreign Key)
- Product 테이블 → Comment 테이블 (productId Foreign Key)

#### 방법 3: 로컬 DB 초기화 후 재실행

```bash
supabase db reset
```

## 2. 로컬-원격 히스토리 불일치

### 문제

```
The remote database's migration history does not match local files
```

### 원인

- 로컬과 원격의 Migration 히스토리가 다름
- 팀원이 원격에 Migration을 push했는데 로컬에서 pull 안 함
- Migration 파일을 직접 삭제하거나 수정함

### 해결

#### 방법 1: 원격 스키마 동기화

```bash
git pull
supabase db pull
```

#### 방법 2: Migration 히스토리 복구

```bash
supabase migration repair --status applied <migration_id>
```

#### 방법 3: 로컬 환경 재설정

```bash
supabase stop
supabase db reset --linked
supabase start
supabase db reset
```

## 3. 인코딩 에러

### 문제

```
ERROR: invalid byte sequence for encoding "UTF8": 0xed 0x95 0x9c
```

### 원인

- SQL 파일에 한글 주석이 포함됨
- 파일 인코딩이 UTF-8이 아님

### 해결

#### 방법 1: 주석을 영어로 작성 (권장)

```sql
-- ❌ 나쁜 예
-- 사용자 테이블 생성
CREATE TABLE "User" ( ... );

-- ✅ 좋은 예
-- Create User table
CREATE TABLE "User" ( ... );
```

#### 방법 2: 파일 인코딩 확인 및 변경

```bash
file -I supabase/migrations/xxx.sql
iconv -f ISO-8859-1 -t UTF-8 input.sql > output.sql
```

## 4. 함수/트리거 관련 에러

### 문제

```
ERROR: function update_updated_at_column() does not exist
```

### 원인

- 함수 정의보다 먼저 사용하려 함
- Drop migration에서 함수를 삭제했는데 테이블은 남아있음

### 해결

#### 방법 1: 함수 정의 순서 확인

```sql
-- 함수 먼저 정의
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 그 다음 트리거 생성
CREATE TRIGGER update_table_updated_at
  BEFORE UPDATE ON "Table"
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

#### 방법 2: Drop Migration 수정

```sql
-- ❌ 나쁜 예: 함수 먼저 삭제
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP TABLE IF EXISTS "Table";

-- ✅ 좋은 예: 테이블 먼저 삭제
DROP TABLE IF EXISTS "Table";
DROP FUNCTION IF EXISTS update_updated_at_column();
```

## 5. Docker 문제

### 문제

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

### 원인

- Docker Desktop이 실행되지 않음
- Docker 서비스가 중지됨

### 해결

```bash
# macOS
open -a Docker

# Docker 상태 확인
docker ps
docker --version
```

## 디버깅 체크리스트

### Migration 실패 시:

- [ ] Docker Desktop이 실행 중인가?
- [ ] `supabase start`가 성공적으로 실행되었는가?
- [ ] SQL 파일에 한글 주석이 없는가?
- [ ] 테이블/함수 생성 순서가 올바른가?
- [ ] Foreign Key가 참조하는 테이블이 먼저 생성되는가?
- [ ] 최신 Migration 파일을 `git pull`로 받았는가?

### 로컬-원격 불일치 시:

- [ ] `git pull`로 최신 Migration 파일 받았는가?
- [ ] `supabase db pull`로 원격 스키마 가져왔는가?
- [ ] Migration 파일을 직접 수정하지 않았는가?
- [ ] Migration 파일을 삭제하지 않았는가?

## 빠른 참조

### Migration 실패 시 순서대로 시도

```bash
# 1. Docker 확인
docker ps

# 2. Supabase 재시작
supabase stop
supabase start

# 3. Git 동기화
git pull

# 4. 원격 스키마 동기화
supabase db pull

# 5. 로컬 DB 초기화
supabase db reset

# 6. 에러 로그 확인
supabase logs
```
