---
name: supabase-troubleshooting
description: |
  Supabase 에러 해결 가이드. Storage RLS, DB 제약조건, Migration 에러 해결.
  다음 요청 시 사용: "supabase 에러", "RLS 에러", "migration 실패", "NOT NULL 에러", "Storage 업로드 실패"
  한글 트리거: "수파베이스 에러", "마이그레이션 오류", "업로드 오류", "DB 에러", "권한 에러"
---

# Supabase Troubleshooting Guide

Supabase 및 프로젝트 관련 에러 해결을 위한 가이드.

## 에러 진단 플로우

```
1. 에러 메시지에서 키워드 추출
   ↓
2. 아래 에러 유형에서 매칭되는 유형 찾기
   ↓
3. 해당 context 문서 참조하여 해결
   ↓
4. 해결 안 되면 로그 확인 및 디버깅
```

## 에러 유형 인덱스

### Storage 관련

**RLS 정책 위반** → [storage-rls.md](./references/storage-rls.md)

```
new row violates row-level security policy
RLS policy violation
Storage 업로드 시 403 Forbidden
```

**일반적인 원인:**
- Public 버킷에 RLS 정책이 제대로 설정되지 않음
- 정책의 파일 경로/형식이 코드와 불일치
- Private 버킷에 Signed URL 없이 접근

### Database 관련

**제약 조건 위반** → [db-constraints.md](./references/db-constraints.md)

```
NOT NULL constraint violation
violates not-null constraint
Foreign key constraint
null value in column ... violates not-null constraint
```

**일반적인 원인:**
- Migration에서 `NOT NULL`로 정의했으나 코드에서 값 미제공
- Foreign Key 참조 무결성 문제
- DEFAULT 값 미설정

### Migration 관련

**적용 실패** → [migration-errors.md](./references/migration-errors.md)

```
relation "TableName" does not exist
function ... does not exist
migration history mismatch
invalid byte sequence for encoding "UTF8"
Cannot connect to the Docker daemon
```

**일반적인 원인:**
- 테이블/함수 의존성 순서 문제
- 로컬-원격 히스토리 불일치
- SQL 파일 인코딩 문제 (한글 주석)
- Docker Desktop 미실행

## 빠른 진단 체크리스트

### Storage 업로드 실패 시:

- [ ] 버킷이 생성되어 있는가?
- [ ] Public 버킷에 RLS 정책이 `true`로 설정되어 있는가?
- [ ] Private 버킷에 Signed URL을 사용하고 있는가?
- [ ] 파일 크기가 제한을 초과하지 않는가?
- [ ] MIME 타입이 허용 목록에 포함되어 있는가?

### DB 저장 실패 시:

- [ ] 모든 `NOT NULL` 컬럼에 값을 제공하고 있는가?
- [ ] Foreign Key가 참조하는 레코드가 존재하는가?
- [ ] DEFAULT 값이 설정되어 있는가?
- [ ] 로컬/원격 환경이 올바른가? (`.env.local` 확인)

### Migration 실패 시:

- [ ] Docker Desktop이 실행 중인가?
- [ ] `supabase start`가 성공적으로 실행되었는가?
- [ ] SQL 파일에 한글 주석이 없는가?
- [ ] 테이블/함수 생성 순서가 올바른가?
- [ ] 로컬-원격 히스토리가 일치하는가?

## 일반적인 디버깅 방법

### 에러 메시지 상세 확인

```typescript
const { data, error } = await supabase.from('Table').insert(newData);
if (error) {
  console.error('Supabase error:', error);
  console.error('Error details:', error.details);
  console.error('Error hint:', error.hint);
  throw error;
}
```

### 로컬 환경에서 재현

```bash
supabase start
supabase db reset
supabase logs
```

## 상세 문서

- [Storage RLS 에러](./references/storage-rls.md): RLS 정책 위반 해결
- [DB 제약 조건 에러](./references/db-constraints.md): NOT NULL, Foreign Key 에러 해결
- [Migration 에러](./references/migration-errors.md): Migration 적용 실패 해결
