# Postgres Best Practices

**Version 1.0.0**
Supabase
January 2026

> 이 문서는 AI 에이전트와 LLM에 최적화되어 있습니다. 규칙은 성능 영향도 순으로 우선순위가 정해져 있습니다.

---

## 개요

Supabase와 Postgres를 사용하는 개발자를 위한 종합적인 Postgres 성능 최적화 가이드입니다. 8개 카테고리에 걸쳐 성능 규칙을 포함하며, Critical(쿼리 성능, 커넥션 관리)부터 점진적(고급 기능)까지 영향도별로 우선순위가 정해져 있습니다.

---

## 목차

1. [Query Performance](#1-query-performance) - **CRITICAL**
2. [Connection Management](#2-connection-management) - **CRITICAL**
3. [Security & RLS](#3-security--rls) - **CRITICAL**
4. [Schema Design](#4-schema-design) - **HIGH**
5. [Concurrency & Locking](#5-concurrency--locking) - **MEDIUM-HIGH**
6. [Data Access Patterns](#6-data-access-patterns) - **MEDIUM**
7. [Monitoring & Diagnostics](#7-monitoring--diagnostics) - **LOW-MEDIUM**
8. [Advanced Features](#8-advanced-features) - **LOW**

---

## 1. Query Performance

**Impact: CRITICAL**

느린 쿼리, 누락된 인덱스, 비효율적인 쿼리 플랜. Postgres 성능 문제의 가장 흔한 원인입니다.

### 1.1 WHERE와 JOIN 컬럼에 인덱스 추가

**Impact: CRITICAL (대용량 테이블에서 100-1000배 빠른 쿼리)**

인덱스가 없는 컬럼에서 필터링이나 조인을 하면 풀 테이블 스캔이 발생하며, 테이블이 커질수록 기하급수적으로 느려집니다.

```sql
-- ❌ 잘못된 예 (Sequential Scan)
select * from orders where customer_id = 123;
-- EXPLAIN: Seq Scan on orders (cost=0.00..25000.00 rows=100 width=85)

-- ✅ 올바른 예 (Index Scan)
create index orders_customer_id_idx on orders (customer_id);
select * from orders where customer_id = 123;
-- EXPLAIN: Index Scan using orders_customer_id_idx (cost=0.42..8.44 rows=100 width=85)
```

JOIN 컬럼의 경우, 항상 외래 키 측에 인덱스를 생성하세요.

### 1.2 데이터에 맞는 인덱스 타입 선택

**Impact: HIGH (올바른 인덱스 타입으로 10-100배 개선)**

다른 인덱스 타입은 다른 쿼리 패턴에 최적화되어 있습니다. 기본 B-tree가 항상 최적인 것은 아닙니다.

```sql
-- ❌ 잘못된 예 (JSONB 포함 연산에 B-tree)
create index products_attrs_idx on products (attributes);
select * from products where attributes @> '{"color": "red"}';
-- 풀 테이블 스캔 - B-tree는 @> 연산자를 지원하지 않음

-- ✅ 올바른 예 (JSONB에 GIN)
create index products_attrs_idx on products using gin (attributes);

-- 인덱스 타입 가이드:
-- B-tree (기본): =, <, >, BETWEEN, IN, IS NULL
-- GIN: 배열, JSONB, 전문 검색
-- BRIN: 대용량 시계열 테이블 (10-100배 작은 크기)
-- Hash: 등호 비교만 (B-tree보다 약간 빠름)
```

### 1.3 다중 컬럼 쿼리를 위한 복합 인덱스 생성

**Impact: HIGH (5-10배 빠른 다중 컬럼 쿼리)**

```sql
-- ❌ 잘못된 예 (별도 인덱스는 Bitmap Scan 필요)
create index orders_status_idx on orders (status);
create index orders_created_idx on orders (created_at);

-- ✅ 올바른 예 (복합 인덱스)
-- 등호 조건 컬럼을 먼저, 범위 조건 컬럼을 나중에
create index orders_status_created_idx on orders (status, created_at);

-- 작동: WHERE status = 'pending'
-- 작동: WHERE status = 'pending' AND created_at > '2024-01-01'
-- 작동 안함: WHERE created_at > '2024-01-01' (leftmost prefix 규칙)
```

### 1.4 테이블 조회 없이 Covering Index 사용

**Impact: MEDIUM-HIGH (힙 페치 제거로 2-5배 빠른 쿼리)**

```sql
-- ❌ 잘못된 예 (Index Scan + Heap Fetch)
create index users_email_idx on users (email);
select email, name, created_at from users where email = 'user@example.com';

-- ✅ 올바른 예 (Index-only Scan with INCLUDE)
create index users_email_idx on users (email) include (name, created_at);
-- 모든 컬럼이 인덱스에서 제공되어 테이블 접근 불필요
```

### 1.5 필터링된 쿼리를 위한 Partial Index 사용

**Impact: HIGH (5-20배 작은 인덱스, 더 빠른 쓰기와 쿼리)**

```sql
-- ❌ 잘못된 예 (모든 행 포함하는 전체 인덱스)
create index users_email_idx on users (email);

-- ✅ 올바른 예 (쿼리 필터에 맞는 부분 인덱스)
create index users_active_email_idx on users (email)
where deleted_at is null;

-- 일반적인 사용 사례:
-- pending 상태 주문만 (상태는 완료 후 거의 변경되지 않음)
create index orders_pending_idx on orders (created_at)
where status = 'pending';
```

---

## 2. Connection Management

**Impact: CRITICAL**

커넥션 풀링, 제한, 서버리스 전략. 높은 동시성이나 서버리스 배포 애플리케이션에 필수적입니다.

### 2.1 유휴 커넥션 타임아웃 설정

**Impact: HIGH (유휴 클라이언트에서 30-50% 커넥션 슬롯 회수)**

```sql
-- ❌ 잘못된 예 (커넥션이 무기한 유지)
show idle_in_transaction_session_timeout;  -- 0 (비활성화)

-- ✅ 올바른 예 (유휴 커넥션 자동 정리)
alter system set idle_in_transaction_session_timeout = '30s';
alter system set idle_session_timeout = '10min';
select pg_reload_conf();
```

### 2.2 적절한 커넥션 제한 설정

**Impact: CRITICAL (데이터베이스 크래시와 메모리 고갈 방지)**

```sql
-- ❌ 잘못된 예 (무제한 또는 과도한 커넥션)
show max_connections;  -- 500 (4GB RAM에 너무 높음)
-- 각 커넥션은 1-3MB RAM 사용
-- 500 커넥션 * 2MB = 커넥션만으로 1GB!

-- ✅ 올바른 예 (리소스 기반 계산)
-- 공식: max_connections = (RAM MB / 5MB) - reserved
-- 4GB RAM: (4096 / 5) - 10 = ~800 이론상 최대
-- 실제로는 100-200이 쿼리 성능에 더 좋음
alter system set max_connections = 100;
alter system set work_mem = '8MB';  -- 8MB * 100 = 800MB 최대
```

### 2.3 모든 애플리케이션에 커넥션 풀링 사용

**Impact: CRITICAL (10-100배 더 많은 동시 사용자 처리)**

```sql
-- ❌ 잘못된 예 (요청당 새 커넥션)
-- 500 동시 사용자 = 500 커넥션 = 데이터베이스 크래시

-- ✅ 올바른 예 (커넥션 풀링)
-- PgBouncer 같은 풀러 사용
-- pool_size = (CPU 코어 * 2) + spindle_count
-- 4코어: pool_size = 10
-- 결과: 500 동시 사용자가 10개의 실제 커넥션 공유
```

풀 모드:
- **Transaction mode**: 각 트랜잭션 후 커넥션 반환 (대부분의 앱에 최적)
- **Session mode**: 전체 세션 동안 커넥션 유지 (prepared statements, temp tables 필요 시)

### 2.4 풀링과 함께 Prepared Statements 올바르게 사용

**Impact: HIGH (풀링 환경에서 prepared statement 충돌 방지)**

```sql
-- ❌ 잘못된 예 (트랜잭션 풀링에서 named prepared statements)
prepare get_user as select * from users where id = $1;
execute get_user(123);
-- ERROR: prepared statement "get_user" does not exist

-- ✅ 올바른 예 (unnamed statements 또는 session mode)
-- 옵션 1: unnamed prepared statements 사용 (대부분의 ORM이 자동으로 함)
-- 옵션 2: 트랜잭션 모드에서 사용 후 deallocate
prepare get_user as select * from users where id = $1;
execute get_user(123);
deallocate get_user;
-- 옵션 3: session mode 풀링 사용 (포트 5432 vs 6543)
```

---

## 3. Security & RLS

**Impact: CRITICAL**

Row-Level Security 정책, 권한 관리, 인증 패턴.

### 3.1 최소 권한 원칙 적용

**Impact: MEDIUM (공격 표면 감소, 더 나은 감사 추적)**

```sql
-- ❌ 잘못된 예 (과도하게 넓은 권한)
grant all privileges on all tables in schema public to app_user;
-- SQL 인젝션이 치명적 결과로 이어짐

-- ✅ 올바른 예 (최소한의 특정 권한)
create role app_readonly nologin;
grant usage on schema public to app_readonly;
grant select on public.products, public.categories to app_readonly;

create role app_writer nologin;
grant usage on schema public to app_writer;
grant select, insert, update on public.orders to app_writer;
-- DELETE 권한 없음

-- public 기본값 제거
revoke all on schema public from public;
```

### 3.2 멀티테넌트 데이터에 Row Level Security 활성화

**Impact: CRITICAL (데이터베이스 수준 테넌트 격리, 데이터 유출 방지)**

```sql
-- ❌ 잘못된 예 (애플리케이션 레벨 필터링만 의존)
select * from orders where user_id = $current_user_id;
-- 버그나 우회 시 모든 데이터 노출!

-- ✅ 올바른 예 (데이터베이스 수준 RLS)
alter table orders enable row level security;

create policy orders_user_policy on orders
  for all
  using (user_id = current_setting('app.current_user_id')::bigint);

-- 테이블 소유자에게도 RLS 강제
alter table orders force row level security;

-- Supabase Auth와 연동:
create policy orders_user_policy on orders
  for all
  to authenticated
  using (user_id = auth.uid());
```

### 3.3 RLS 정책 성능 최적화

**Impact: HIGH (적절한 패턴으로 5-10배 빠른 RLS 쿼리)**

```sql
-- ❌ 잘못된 예 (모든 행마다 함수 호출)
create policy orders_policy on orders
  using (auth.uid() = user_id);  -- 행마다 auth.uid() 호출!

-- ✅ 올바른 예 (SELECT로 함수 래핑)
create policy orders_policy on orders
  using ((select auth.uid()) = user_id);  -- 한 번만 호출, 캐시됨
-- 대용량 테이블에서 100배 이상 빠름

-- 복잡한 체크를 위한 security definer 함수:
create or replace function is_team_member(team_id bigint)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.team_members
    where team_id = $1 and user_id = (select auth.uid())
  );
$$;

-- RLS 정책에 사용되는 컬럼에 항상 인덱스 추가:
create index orders_user_id_idx on orders (user_id);
```

---

## 4. Schema Design

**Impact: HIGH**

테이블 설계, 인덱스 전략, 파티셔닝, 데이터 타입 선택. 장기 성능의 기반입니다.

### 4.1 적절한 데이터 타입 선택

**Impact: HIGH (50% 저장 공간 감소, 더 빠른 비교)**

```sql
-- ❌ 잘못된 예 (잘못된 데이터 타입)
create table users (
  id int,                    -- 21억에서 오버플로우
  email varchar(255),        -- 불필요한 길이 제한
  created_at timestamp,      -- 타임존 정보 누락
  is_active varchar(5),      -- boolean에 문자열
  price varchar(20)          -- 숫자에 문자열
);

-- ✅ 올바른 예 (적절한 데이터 타입)
create table users (
  id bigint generated always as identity primary key,  -- 9경 최대
  email text,                     -- 인위적 제한 없음, varchar와 동일 성능
  created_at timestamptz,         -- 항상 타임존 포함 타임스탬프 저장
  is_active boolean default true, -- 1바이트 vs 가변 문자열 길이
  price numeric(10,2)             -- 정확한 십진 연산
);
```

핵심 가이드라인:
- ID: bigint 사용, int 아님 (미래 대비)
- 문자열: text 사용, 제약이 필요한 경우가 아니면 varchar(n) 아님
- 시간: timestamptz 사용, timestamp 아님
- 금액: numeric 사용, float 아님 (정밀도 중요)

### 4.2 외래 키 컬럼에 인덱스 추가

**Impact: HIGH (10-100배 빠른 JOIN과 CASCADE 작업)**

```sql
-- ❌ 잘못된 예 (인덱스 없는 외래 키)
create table orders (
  id bigint generated always as identity primary key,
  customer_id bigint references customers(id) on delete cascade,
  total numeric(10,2)
);
-- customer_id에 인덱스 없음!
-- JOIN과 ON DELETE CASCADE 모두 풀 테이블 스캔 필요

-- ✅ 올바른 예 (인덱스된 외래 키)
create index orders_customer_id_idx on orders (customer_id);

-- 누락된 FK 인덱스 찾기:
select
  conrelid::regclass as table_name,
  a.attname as fk_column
from pg_constraint c
join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any(c.conkey)
where c.contype = 'f'
  and not exists (
    select 1 from pg_index i
    where i.indrelid = c.conrelid and a.attnum = any(i.indkey)
  );
```

### 4.3 대용량 테이블 파티셔닝

**Impact: MEDIUM-HIGH (대용량 테이블에서 5-20배 빠른 쿼리와 유지보수)**

```sql
-- ❌ 잘못된 예 (단일 대용량 테이블)
create table events (
  id bigint generated always as identity,
  created_at timestamptz,
  data jsonb
);
-- 5억 행, 모든 쿼리가 전체 스캔

-- ✅ 올바른 예 (시간 범위별 파티셔닝)
create table events (
  id bigint generated always as identity,
  created_at timestamptz not null,
  data jsonb
) partition by range (created_at);

create table events_2024_01 partition of events
  for values from ('2024-01-01') to ('2024-02-01');

-- 관련 파티션만 스캔
-- 오래된 데이터 즉시 삭제
drop table events_2023_01;  -- DELETE로 시간 소요 vs 즉시
```

파티셔닝 시점:
- 테이블 > 1억 행
- 날짜 기반 쿼리가 있는 시계열 데이터
- 오래된 데이터를 효율적으로 삭제해야 할 때

### 4.4 최적의 Primary Key 전략 선택

**Impact: HIGH (더 나은 인덱스 지역성, 단편화 감소)**

```sql
-- ❌ 잘못된 예 (문제 있는 PK 선택)
create table users (
  id serial primary key  -- 작동하지만 IDENTITY 권장
);

create table orders (
  id uuid default gen_random_uuid() primary key  -- UUIDv4 = 랜덤 = 분산된 삽입
);

-- ✅ 올바른 예 (최적의 PK 전략)
-- 순차 ID에 IDENTITY 사용 (SQL 표준, 대부분의 경우에 최적)
create table users (
  id bigint generated always as identity primary key
);

-- 분산 시스템에서 UUID 필요 시 UUIDv7 사용 (시간 순서)
-- pg_uuidv7 확장 필요: create extension pg_uuidv7;
create table orders (
  id uuid default uuid_generate_v7() primary key  -- 시간 순서, 단편화 없음
);
```

가이드라인:
- 단일 데이터베이스: `bigint identity` (순차, 8바이트, SQL 표준)
- 분산/노출 ID: UUIDv7 또는 ULID (시간 순서, 단편화 없음)
- 대용량 테이블에서 랜덤 UUID (v4)를 PK로 사용하지 마세요 (인덱스 단편화)

### 4.5 호환성을 위해 소문자 식별자 사용

**Impact: MEDIUM (도구, ORM, AI 어시스턴트와의 대소문자 민감성 버그 방지)**

```sql
-- ❌ 잘못된 예 (대소문자 혼합 식별자)
CREATE TABLE "Users" (
  "userId" bigint PRIMARY KEY,
  "firstName" text
);
-- 항상 따옴표 필요, 없으면 실패

-- ✅ 올바른 예 (소문자 snake_case)
CREATE TABLE users (
  user_id bigint PRIMARY KEY,
  first_name text
);
-- 따옴표 없이 작동, 모든 도구에서 인식
```

---

## 5. Concurrency & Locking

**Impact: MEDIUM-HIGH**

트랜잭션 관리, 격리 수준, 데드락 방지, 잠금 경합 패턴.

### 5.1 잠금 경합 감소를 위해 트랜잭션 짧게 유지

**Impact: MEDIUM-HIGH (3-5배 처리량 개선, 더 적은 데드락)**

```sql
-- ❌ 잘못된 예 (외부 호출이 있는 긴 트랜잭션)
begin;
select * from orders where id = 1 for update;  -- 잠금 획득
-- 애플리케이션이 결제 API 호출 (2-5초)
-- 이 행에 대한 다른 쿼리가 차단됨!
update orders set status = 'paid' where id = 1;
commit;

-- ✅ 올바른 예 (최소 트랜잭션 범위)
-- 트랜잭션 외부에서 데이터 검증과 API 호출
-- 실제 업데이트에만 잠금 유지
begin;
update orders
set status = 'paid', payment_id = $1
where id = $2 and status = 'pending'
returning *;
commit;  -- 밀리초 동안만 잠금 유지

-- statement_timeout으로 폭주 트랜잭션 방지:
set statement_timeout = '30s';
```

### 5.2 일관된 잠금 순서로 데드락 방지

**Impact: MEDIUM-HIGH (데드락 오류 제거, 신뢰성 향상)**

```sql
-- ❌ 잘못된 예 (일관성 없는 잠금 순서)
-- 트랜잭션 A: id=1 잠금 후 id=2 대기
-- 트랜잭션 B: id=2 잠금 후 id=1 대기
-- 데드락! 서로 대기

-- ✅ 올바른 예 (ID 순서로 먼저 잠금 획득)
begin;
select * from accounts where id in (1, 2) order by id for update;
-- 이제 어떤 순서로든 업데이트 - 잠금 이미 보유
update accounts set balance = balance - 100 where id = 1;
update accounts set balance = balance + 100 where id = 2;
commit;

-- 대안: 단일 문장으로 원자적 업데이트
update accounts
set balance = balance + case id
  when 1 then -100
  when 2 then 100
end
where id in (1, 2);
```

### 5.3 애플리케이션 레벨 잠금을 위한 Advisory Lock 사용

**Impact: MEDIUM (행 수준 잠금 오버헤드 없이 효율적인 조정)**

```sql
-- ❌ 잘못된 예 (잠금을 위해 행 생성)
create table resource_locks (resource_name text primary key);
insert into resource_locks values ('report_generator');
select * from resource_locks where resource_name = 'report_generator' for update;

-- ✅ 올바른 예 (advisory locks)
-- 세션 레벨 advisory lock
select pg_advisory_lock(hashtext('report_generator'));
-- ... 독점 작업 수행 ...
select pg_advisory_unlock(hashtext('report_generator'));

-- 트랜잭션 레벨 lock (커밋/롤백 시 해제)
begin;
select pg_advisory_xact_lock(hashtext('daily_report'));
-- ... 작업 수행 ...
commit;  -- 잠금 자동 해제

-- 비차단 작업을 위한 try-lock
select pg_try_advisory_lock(hashtext('resource_name'));
-- true/false 즉시 반환
```

### 5.4 비차단 큐 처리를 위한 SKIP LOCKED 사용

**Impact: MEDIUM-HIGH (워커 큐에서 10배 처리량)**

```sql
-- ❌ 잘못된 예 (워커들이 서로 차단)
begin;
select * from jobs where status = 'pending' order by created_at limit 1 for update;
-- Worker 2가 Worker 1의 잠금 해제를 기다림!

-- ✅ 올바른 예 (병렬 처리를 위한 SKIP LOCKED)
begin;
select * from jobs
where status = 'pending'
order by created_at
limit 1
for update skip locked;
-- Worker 1은 job 1, Worker 2는 job 2 (대기 없음)
update jobs set status = 'processing' where id = $1;
commit;

-- 원자적 claim-and-update 패턴:
update jobs
set status = 'processing', worker_id = $1, started_at = now()
where id = (
  select id from jobs
  where status = 'pending'
  order by created_at
  limit 1
  for update skip locked
)
returning *;
```

---

## 6. Data Access Patterns

**Impact: MEDIUM**

N+1 쿼리 제거, 배치 작업, 커서 기반 페이지네이션, 효율적인 데이터 조회.

### 6.1 대량 데이터를 위한 배치 INSERT

**Impact: MEDIUM (10-50배 빠른 벌크 삽입)**

```sql
-- ❌ 잘못된 예 (개별 삽입)
insert into events (user_id, action) values (1, 'click');
insert into events (user_id, action) values (1, 'view');
-- 1000개 삽입 = 1000번 왕복 = 느림

-- ✅ 올바른 예 (배치 삽입)
insert into events (user_id, action) values
  (1, 'click'),
  (1, 'view'),
  (2, 'click'),
  -- 배치당 최대 ~1000행
  (999, 'view');
-- 1000행에 1번 왕복

-- 대량 로드에는 COPY가 가장 빠름
copy events (user_id, action, created_at)
from '/path/to/data.csv'
with (format csv, header true);
```

### 6.2 배치 로딩으로 N+1 쿼리 제거

**Impact: MEDIUM-HIGH (10-100배 적은 데이터베이스 왕복)**

```sql
-- ❌ 잘못된 예 (N+1 쿼리)
select id from users where active = true;  -- 100개 ID 반환
-- 그 다음 사용자당 N개 쿼리
select * from orders where user_id = 1;
select * from orders where user_id = 2;
-- ... 97개 더 쿼리!
-- 총: 데이터베이스에 101번 왕복

-- ✅ 올바른 예 (단일 배치 쿼리)
select * from orders where user_id = any(array[1, 2, 3, ...]);

-- 또는 루프 대신 JOIN 사용
select u.id, u.name, o.*
from users u
left join orders o on o.user_id = u.id
where u.active = true;
-- 총: 1번 왕복
```

### 6.3 OFFSET 대신 커서 기반 페이지네이션 사용

**Impact: MEDIUM-HIGH (페이지 깊이에 관계없이 일관된 O(1) 성능)**

```sql
-- ❌ 잘못된 예 (OFFSET 페이지네이션)
select * from products order by id limit 20 offset 0;      -- 20행 스캔
select * from products order by id limit 20 offset 1980;   -- 2000행 스캔
select * from products order by id limit 20 offset 199980; -- 20만 행 스캔!

-- ✅ 올바른 예 (커서/keyset 페이지네이션)
-- 페이지 1: 처음 20개
select * from products order by id limit 20;
-- 애플리케이션이 last_id = 20 저장

-- 페이지 2: 마지막 ID 이후부터 시작
select * from products where id > 20 order by id limit 20;
-- 인덱스 사용, 페이지 깊이와 관계없이 항상 빠름

-- 다중 컬럼 정렬:
select * from products
where (created_at, id) > ('2024-01-15 10:00:00', 12345)
order by created_at, id
limit 20;
```

### 6.4 Insert-or-Update 작업에 UPSERT 사용

**Impact: MEDIUM (원자적 작업, 경쟁 조건 제거)**

```sql
-- ❌ 잘못된 예 (check-then-insert 경쟁 조건)
select * from settings where user_id = 123 and key = 'theme';
-- 둘 다 아무것도 찾지 못함
-- 둘 다 삽입 시도
-- 하나 성공, 하나 중복 키 오류!

-- ✅ 올바른 예 (원자적 UPSERT)
insert into settings (user_id, key, value)
values (123, 'theme', 'dark')
on conflict (user_id, key)
do update set value = excluded.value, updated_at = now();

-- 존재하지 않으면 삽입만 (업데이트 없음)
insert into page_views (page_id, user_id)
values (1, 123)
on conflict (page_id, user_id) do nothing;
```

---

## 7. Monitoring & Diagnostics

**Impact: LOW-MEDIUM**

pg_stat_statements 사용, EXPLAIN ANALYZE, 메트릭 수집, 성능 진단.

### 7.1 쿼리 분석을 위한 pg_stat_statements 활성화

**Impact: LOW-MEDIUM (최다 리소스 소비 쿼리 식별)**

```sql
create extension if not exists pg_stat_statements;

-- 총 시간 기준 가장 느린 쿼리 찾기
select
  calls,
  round(total_exec_time::numeric, 2) as total_time_ms,
  round(mean_exec_time::numeric, 2) as mean_time_ms,
  query
from pg_stat_statements
order by total_exec_time desc
limit 10;

-- 가장 빈번한 쿼리 찾기
select calls, query
from pg_stat_statements
order by calls desc
limit 10;

-- 높은 평균 시간 쿼리 (최적화 후보)
select query, mean_exec_time, calls
from pg_stat_statements
where mean_exec_time > 100  -- 평균 > 100ms
order by mean_exec_time desc;
```

### 7.2 VACUUM과 ANALYZE로 테이블 통계 유지

**Impact: MEDIUM (정확한 통계로 2-10배 더 나은 쿼리 플랜)**

```sql
-- 대량 데이터 변경 후 수동 분석
analyze orders;

-- WHERE 절에 사용되는 특정 컬럼 분석
analyze orders (status, created_at);

-- 테이블이 마지막으로 분석된 시점 확인
select
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
from pg_stat_user_tables
order by last_analyze nulls first;

-- 고변동 테이블을 위한 autovacuum 튜닝
alter table orders set (
  autovacuum_vacuum_scale_factor = 0.05,     -- 5% 죽은 튜플에서 Vacuum (기본 20%)
  autovacuum_analyze_scale_factor = 0.02     -- 2% 변경에서 Analyze (기본 10%)
);
```

### 7.3 느린 쿼리 진단을 위한 EXPLAIN ANALYZE 사용

**Impact: LOW-MEDIUM (쿼리 실행의 정확한 병목 식별)**

```sql
explain (analyze, buffers, format text)
select * from orders where customer_id = 123 and status = 'pending';

-- 출력이 문제를 드러냄:
-- Seq Scan on orders (actual time=0.015..450.123 rows=50 loops=1)
--   Filter: ((customer_id = 123) AND (status = 'pending'::text))
--   Rows Removed by Filter: 999950
--   Buffers: shared hit=5000 read=15000
-- Execution Time: 450.500 ms

-- 주의 사항:
-- 대용량 테이블의 Seq Scan = 누락된 인덱스
-- Rows Removed by Filter = 낮은 선택성 또는 누락된 인덱스
-- Buffers: read >> hit = 캐시되지 않은 데이터, 메모리 더 필요
-- 높은 loops의 Nested Loop = 다른 조인 전략 고려
-- Sort Method: external merge = work_mem 너무 낮음
```

---

## 8. Advanced Features

**Impact: LOW**

전문 검색, JSONB 최적화, PostGIS, 확장, 고급 Postgres 기능.

### 8.1 효율적인 쿼리를 위한 JSONB 컬럼 인덱싱

**Impact: MEDIUM (적절한 인덱싱으로 10-100배 빠른 JSONB 쿼리)**

```sql
-- ❌ 잘못된 예 (JSONB에 인덱스 없음)
select * from products where attributes @> '{"color": "red"}';
-- 모든 쿼리에 풀 테이블 스캔

-- ✅ 올바른 예 (JSONB에 GIN 인덱스)
-- 포함 연산자용 GIN 인덱스 (@>, ?, ?&, ?|)
create index products_attrs_gin on products using gin (attributes);

-- 특정 키 조회용 표현식 인덱스
create index products_brand_idx on products ((attributes->>'brand'));
select * from products where attributes->>'brand' = 'Nike';

-- 올바른 연산자 클래스 선택:
-- jsonb_ops (기본): 모든 연산자 지원, 더 큰 인덱스
create index idx1 on products using gin (attributes);
-- jsonb_path_ops: @> 연산자만, 2-3배 작은 인덱스
create index idx2 on products using gin (attributes jsonb_path_ops);
```

### 8.2 전문 검색을 위한 tsvector 사용

**Impact: MEDIUM (LIKE보다 100배 빠름, 랭킹 지원)**

```sql
-- ❌ 잘못된 예 (LIKE 패턴 매칭)
select * from articles where content like '%postgresql%';
-- 인덱스 사용 불가, 모든 행 스캔

-- ✅ 올바른 예 (tsvector 전문 검색)
alter table articles add column search_vector tsvector
  generated always as (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,''))) stored;

create index articles_search_idx on articles using gin (search_vector);

-- 빠른 전문 검색
select * from articles
where search_vector @@ to_tsquery('english', 'postgresql & performance');

-- 랭킹 포함
select *, ts_rank(search_vector, query) as rank
from articles, to_tsquery('english', 'postgresql') query
where search_vector @@ query
order by rank desc;

-- 검색 연산자:
-- AND: 두 용어 모두 필요
to_tsquery('postgresql & performance')
-- OR: 둘 중 하나
to_tsquery('postgresql | mysql')
-- 접두사 매칭
to_tsquery('post:*')
```

---

## 참고 자료

- https://www.postgresql.org/docs/current/
- https://supabase.com/docs
- https://wiki.postgresql.org/wiki/Performance_Optimization
- https://supabase.com/docs/guides/database/overview
- https://supabase.com/docs/guides/auth/row-level-security
