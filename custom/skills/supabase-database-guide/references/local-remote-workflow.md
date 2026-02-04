# Supabase 로컬/원격 환경 가이드

## 개요

| 환경 | 위치 | 용도 | 데이터 |
|------|------|------|--------|
| **로컬** | Docker | Migration 테스트, 개발 | 더미 데이터 |
| **원격** | Supabase Cloud | 프로덕션 | 실제 사용자 데이터 |

## 로컬 환경을 사용하는 이유

### 1. 안전한 Migration 테스트
- 프로덕션 DB에 직접 적용 시 서비스 중단, 데이터 손실 위험
- 로컬에서 먼저 테스트하여 SQL 오류 사전 검증

### 2. 빠른 개발 사이클
- `supabase db reset` 명령으로 몇 초 만에 DB 초기화
- 에러 발생 시 부담 없이 수정하고 재시도
- 다른 개발자나 사용자에게 영향 없음

### 3. 완전한 기능 테스트
- Database, Storage, Auth 등 모든 Supabase 기능 제공
- 웹 기반 Studio UI로 데이터 확인 가능

## 환경 구성

### 로컬 환경 (Docker)

```
API URL:         http://127.0.0.1:54321
Database URL:    postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL:      http://127.0.0.1:54323
```

### 원격 환경 (Supabase Cloud)

```
API URL:         https://<project-id>.supabase.co
```

## 환경 전환 방법

### 로컬로 전환

```bash
# 1. Docker Desktop 실행 필요
supabase start

# 2. 환경 변수 변경 (.env.local)
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<로컬 anon key>  # supabase status로 확인

# 3. 개발 서버 재시작
pnpm run dev
```

### 원격으로 전환

```bash
# 1. 환경 변수 변경 (.env.local)
NEXT_PUBLIC_SUPABASE_URL=https://<project-id>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<원격 anon key>

# 2. 개발 서버 재시작
pnpm run dev

# 3. 확인
# 브라우저 개발자 도구 → Network 탭 → Request URL 확인
```

## 개발 워크플로우

```
1. 기능 브랜치 생성
   $ git checkout -b feat/new-feature

2. 로컬 환경으로 전환
   .env.local → NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321

3. Migration 작성 및 테스트
   $ supabase migration new add_new_table
   $ supabase db reset

4. 앱에서 기능 테스트
   $ pnpm run dev

5. 원격 환경으로 전환 및 배포
   .env.local → NEXT_PUBLIC_SUPABASE_URL=https://<project-id>.supabase.co
   $ supabase db push

6. Git 커밋 및 PR
   $ git add . && git commit -m "feat: add new feature"
```

## 자주 사용하는 명령어

### 로컬 Supabase 관리

```bash
supabase start                  # 로컬 Supabase 시작
supabase status                 # 상태 및 URL 확인
supabase stop                   # 로컬 Supabase 중지
supabase db reset               # 모든 Migration 재실행
```

### 디버깅

```bash
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres  # 로컬 DB 접속
supabase logs                   # 로그 확인
open http://127.0.0.1:54323     # Studio UI
```

## 주의사항

### 로컬 환경
- ✅ 테스트용 더미 데이터 사용
- ✅ Migration 테스트 후 원격 배포
- ✅ 환경 전환 시 개발 서버 재시작
- ❌ 중요 데이터 저장 금지 (언제든 삭제 가능)

### 원격 환경
- ✅ 모든 스키마 변경은 Migration으로 관리
- ✅ 로컬에서 충분히 테스트 후 배포
- ✅ RLS 정책 필수 적용
- ❌ SQL Editor에서 직접 스키마 수정 금지
