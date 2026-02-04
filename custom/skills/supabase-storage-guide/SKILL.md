---
name: supabase-storage-guide
description: |
  Supabase Storage 이미지 업로드, Signed URL, RLS 정책 가이드.
  다음 요청 시 사용: "이미지 업로드", "Storage 버킷", "Signed URL", "파일 업로드", "Private 파일 접근"
  한글 트리거: "수파베이스 스토리지", "이미지 저장", "파일 저장", "버킷 설정", "서명된 URL"
---

# Supabase Storage Guide

이미지 업로드, Storage 버킷 관리, Signed URL 패턴을 위한 가이드.

## 핵심 원칙

1. **지연 업로드 패턴**: DB 저장 성공 후 이미지 업로드 (데이터 무결성 보장)
2. **메모리 기반 처리**: 업로드 전 Buffer로 처리하여 불필요한 Storage 사용 방지
3. **에러 격리**: 이미지 업로드 실패가 핵심 데이터 저장을 막지 않음
4. **버킷 분리**: 용도별 Storage 버킷 구분 (public/private)
5. **보안**: Private 파일은 Signed URL로 시간 제한 접근

## Storage 버킷 설계

| 버킷 유형 | 접근 권한 | 용도 | 접근 방법 |
|----------|----------|------|----------|
| **Public** | 공개 | 공개 이미지, 썸네일 | `getPublicUrl()` |
| **Private** | 비공개 | 개인 문서, 민감 파일 | `createSignedUrl()` |

### RLS 정책 설정

**Public 버킷:**

```sql
CREATE POLICY "Public Access"
ON storage.objects FOR ALL
USING (bucket_id = 'your-bucket-name')
WITH CHECK (bucket_id = 'your-bucket-name');
```

**Private 버킷 (본인만 접근):**

```sql
CREATE POLICY "User Access"
ON storage.objects FOR ALL
USING (
  bucket_id = 'private-bucket'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

## 이미지 업로드 패턴

### 기본 업로드

```typescript
const uploadImage = async (file: File, bucket: string): Promise<string> => {
  const timestamp = Date.now();
  const filename = `${timestamp}_${file.name}`;

  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(filename, file);

  if (error) throw error;
  return data.path;
};
```

### 지연 업로드 (권장)

```typescript
// 1. Placeholder로 DB 먼저 저장
const record = await db.insert({
  imageUrl: 'PLACEHOLDER'
});

// 2. DB 저장 성공 후 실제 업로드
const imagePath = await uploadImage(file, 'bucket-name');

// 3. Placeholder를 실제 URL로 업데이트
await db.update(record.id, { imageUrl: imagePath });
```

## Signed URL

### 생성

```typescript
const getSignedUrl = async (
  path: string,
  bucket: string,
  expiresIn: number = 3600
): Promise<string> => {
  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, expiresIn);

  if (error) throw error;
  return data.signedUrl;
};
```

### 캐싱 전략

```typescript
// React Query 캐싱
const useSignedUrl = (path: string) => {
  return useQuery({
    queryKey: ['signedUrl', path],
    queryFn: () => getSignedUrl(path, 'bucket', 3600),
    staleTime: 30 * 60 * 1000, // 30분
    enabled: !!path,
  });
};
```

## 상세 문서

- [Signed URL 패턴](./references/signed-url-pattern.md): 디지털 서명 메커니즘, 캐싱 전략, 보안 고려사항

## Storage 설정 체크리스트

### Public 버킷:

- [ ] 버킷 생성 (Dashboard 또는 Migration)
- [ ] Public 설정
- [ ] RLS 정책: `true` (모든 접근 허용)
- [ ] 파일 크기 제한 설정
- [ ] 허용 MIME 타입 설정

### Private 버킷:

- [ ] 버킷 생성
- [ ] Private 설정
- [ ] RLS 정책: 본인만 접근
- [ ] Signed URL 유효 시간 설정 (1시간 권장)
