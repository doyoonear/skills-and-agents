# Storage RLS 정책 에러

## 문제 상황

```
Error: new row violates row-level security policy
```

Storage 버킷에 설정된 RLS 정책과 실제 코드에서 업로드하는 파일의 경로/형식이 일치하지 않아 발생.

## 원인 분석

**정상 작동하는 버킷:**
```
Policy: Public Access (ALL operations, definition: true)
```

**에러 발생하는 버킷:**
```
1. "Give anon users access to JPG images in folder xxx" - SELECT
2. "Give anon users access to JPG images in folder xxx" - INSERT
```

**문제점:**
- ❌ 정책이 특정 폴더에만 적용됨
- ❌ JPG만 허용, 실제는 PNG, JPEG 등 다양한 형식 업로드
- ❌ 코드는 루트 디렉토리에 업로드, 정책은 특정 폴더 요구

## 해결 방법

### 옵션 1: 정책 수정 (권장)

**Supabase Dashboard → Storage → 버킷 → Policies**

```sql
CREATE POLICY "Public Access"
ON storage.objects FOR ALL
USING (bucket_id = 'your-bucket-name')
WITH CHECK (bucket_id = 'your-bucket-name');
```

간단한 정책 하나로 모든 파일 형식, 모든 경로에서 업로드 가능.

### 옵션 2: 코드 수정

정책에 맞춰 특정 폴더에 업로드:

```typescript
const { data, error } = await supabase.storage
  .from('bucket-name')
  .upload(`specific-folder/${timestamp}.jpg`, file);
```

## Public vs Private 버킷 설정

### Public 버킷

```sql
CREATE POLICY "Public Access"
ON storage.objects FOR ALL
USING (bucket_id = 'your-bucket-name')
WITH CHECK (bucket_id = 'your-bucket-name');
```

```typescript
// 업로드
const { data } = await supabase.storage
  .from('bucket-name')
  .upload(`${timestamp}_${filename}`, file);

// 접근 (Public URL)
const publicUrl = supabase.storage
  .from('bucket-name')
  .getPublicUrl(data.path);
```

### Private 버킷

```sql
CREATE POLICY "User Access"
ON storage.objects FOR ALL
USING (
  bucket_id = 'private-bucket'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

```typescript
// 업로드 (사용자 ID를 폴더명으로)
const userId = (await supabase.auth.getUser()).data.user?.id;
const { data } = await supabase.storage
  .from('private-bucket')
  .upload(`${userId}/${timestamp}_${filename}`, file);

// 접근 (Signed URL)
const { data: signedData } = await supabase.storage
  .from('private-bucket')
  .createSignedUrl(data.path, 3600);
```

## 일반적인 RLS 정책 패턴

### 1. 완전 Public

```sql
CREATE POLICY "Public Access"
ON storage.objects FOR ALL
USING (bucket_id = 'bucket-name');
```

### 2. 읽기만 Public, 쓰기는 인증 필요

```sql
CREATE POLICY "Public Read"
ON storage.objects FOR SELECT
USING (bucket_id = 'bucket-name');

CREATE POLICY "Authenticated Write"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'bucket-name'
  AND auth.role() = 'authenticated'
);
```

### 3. 본인 파일만 접근

```sql
CREATE POLICY "Own Files Only"
ON storage.objects FOR ALL
USING (
  bucket_id = 'bucket-name'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

## 디버깅 체크리스트

- [ ] 버킷 존재 확인
- [ ] RLS 정책 확인 (Dashboard → Storage → Policies)
- [ ] 파일 경로 확인 (코드의 업로드 경로와 정책 매칭)
- [ ] 파일 형식 확인 (allowed_mime_types)
- [ ] 에러 상세 확인

```typescript
const { data, error } = await supabase.storage.from('bucket').upload(path, file);
if (error) {
  console.error('Upload error:', error);
  console.error('Error details:', error.message);
}
```

## 권장사항

### ✅ 권장
1. **간단한 정책 우선**: 복잡한 정책보다 `true` 정책 하나가 더 안전
2. **정책과 코드 일치**: 정책 변경 시 코드도 함께 검토
3. **Public vs Private 명확히**: Public 데이터는 Public 버킷, Private 데이터는 Private 버킷 + Signed URL

### ❌ 피해야 할 것
1. Dashboard에서 직접 정책 수정 금지 (Migration 파일로 관리)
2. Public 버킷에 민감한 데이터 저장 금지
