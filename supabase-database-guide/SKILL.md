---
name: supabase-database-guide
description: |
  Supabase 데이터베이스 개발 가이드. Migration 작성, 로컬/원격 환경 관리, RLS 정책 설정.
  다음 요청 시 사용: "supabase migration", "DB 스키마 변경", "테이블 추가", "RLS 정책", "로컬 DB 설정"
  한글 트리거: "수파베이스 마이그레이션", "DB 마이그레이션", "테이블 생성", "로컬 환경 설정"
---

# Supabase Database Development Guide

Supabase 데이터베이스 스키마 변경, Migration 작업, 로컬/원격 환경 관리를 위한 가이드.

## 핵심 원칙

1. **항상 로컬에서 먼저 테스트** → 원격 배포
2. **모든 스키마 변경은 Migration 파일로 관리** (Dashboard 직접 수정 금지)
3. **RLS 정책 필수 설정** (보안)
4. **NOT NULL 컬럼에는 DEFAULT 값 설정** 또는 코드에서 반드시 제공
5. **Migration은 자주, 작게** (큰 변경사항을 한 번에 하지 않기)

## 개발 워크플로우

```
1. 로컬 환경으로 전환
   $ supabase start
   .env.local → NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321

2. Migration 파일 생성
   $ supabase migration new <migration_name>

3. SQL 작성
   supabase/migrations/xxx_<migration_name>.sql 편집

4. 로컬 DB에서 테스트
   $ supabase db reset
   ✅ 성공 → 다음 단계
   ❌ 실패 → SQL 수정 후 다시 reset

5. 앱에서 기능 테스트
   $ pnpm run dev (또는 npm run dev)

6. 원격 환경으로 전환 및 배포
   .env.local → NEXT_PUBLIC_SUPABASE_URL=https://<project-id>.supabase.co
   $ supabase db push

7. Git 커밋
   $ git add supabase/migrations/
   $ git commit -m "feat: add xxx migration"
```

## 빠른 참조

### 로컬 Supabase 관리

```bash
supabase start                  # 로컬 Supabase 시작
supabase status                 # 상태 및 URL 확인
supabase stop                   # 로컬 Supabase 중지
supabase db reset               # 모든 Migration 재실행 (테스트용)
```

### Migration 관리

```bash
supabase migration new <name>   # 새 Migration 파일 생성
supabase migration list         # Migration 히스토리 확인
supabase db push                # 원격 DB에 배포
supabase db pull                # 원격 스키마 가져오기
supabase db diff                # 로컬-원격 차이 확인
```

### 로컬 환경 URL

```
API:      http://127.0.0.1:54321
Studio:   http://127.0.0.1:54323
Database: postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

## 상세 문서

- [Migration 가이드](./references/migration-guide.md): Migration 파일 작성, 로컬/원격 동기화, Best Practices
- [로컬/원격 환경 워크플로우](./references/local-remote-workflow.md): 환경 전환 방법, Docker 기반 로컬 관리

## 환경 전환 체크리스트

### 로컬 환경 사용 시:

- [ ] Docker Desktop 실행
- [ ] `supabase start` 실행
- [ ] `.env.local` URL을 `http://127.0.0.1:54321`로 변경
- [ ] `.env.local` ANON_KEY를 로컬 키로 변경 (`supabase status`로 확인)
- [ ] 개발 서버 재시작

### 원격 환경 사용 시:

- [ ] `.env.local` URL을 `https://<project-id>.supabase.co`로 변경
- [ ] `.env.local` ANON_KEY를 원격 키로 변경
- [ ] 개발 서버 재시작
- [ ] Network 탭에서 원격 URL 확인
