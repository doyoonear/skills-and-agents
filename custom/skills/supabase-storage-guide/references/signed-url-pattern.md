# Signed URL 패턴 가이드

## Signed URL이란?

Signed URL은 **디지털 서명이 포함된 URL**로, 시간 제한이 있는 임시 접근 권한을 제공하는 보안 패턴.

### Public vs Private 비교

| 항목 | Public URL | Signed URL |
|------|------------|-----------|
| 접근성 | 누구나 접근 가능 | 인증된 사용자만 |
| 시간 제한 | 없음 | 만료 시간 있음 |
| URL 변조 | 가능 | 불가능 (서명 검증) |
| 민감 데이터 | 부적합 | 적합 |

### Signed URL 형식

```
https://storage.com/file.jpg?
  token=abc123&
  expires=1234567890&
  signature=xyz789
```

## 서명 생성 과정

```typescript
// 1. 서명할 데이터 준비
const dataToSign = `${filePath}:${expirationTime}`;

// 2. HMAC-SHA256으로 서명 생성
const signature = HMAC_SHA256(dataToSign, SECRET_KEY);

// 3. URL에 서명 첨부
const signedUrl = `${baseUrl}?expires=${expirationTime}&signature=${signature}`;
```

### 핵심 특징

1. **무결성 (Integrity)**: URL의 어떤 부분이라도 변조하면 서명이 무효화
2. **인증 (Authentication)**: SECRET_KEY는 서버만 보유
3. **시간 제한 (Temporal)**: 만료 후 자동으로 접근 불가

## 인증 토큰 vs Signed URL

| 항목 | JWT 토큰 | Signed URL |
|------|----------|-----------|
| **목적** | 사용자 신원 증명 | 리소스 접근 권한 |
| **범위** | 여러 API 엔드포인트 | 특정 파일 하나 |
| **위치** | HTTP 헤더 | URL 쿼리 파라미터 |
| **유효기간** | 길다 (일~주) | 짧다 (분~시간) |
| **재사용** | 가능 | 불가능 (만료 후) |

## 캐싱 전략

### 전략 1: React Query 캐싱

```typescript
const useSignedUrl = (imagePath: string | null) => {
  return useQuery({
    queryKey: ['signedUrl', imagePath],
    queryFn: async () => {
      const response = await fetch(
        `/api/signed-url?path=${encodeURIComponent(imagePath!)}`
      );
      const { signedUrl } = await response.json();
      return signedUrl;
    },
    enabled: !!imagePath,
    staleTime: 30 * 60 * 1000, // 30분
    cacheTime: 45 * 60 * 1000, // 45분
    refetchOnWindowFocus: false,
  });
};
```

### 전략 2: Batch 발급

```typescript
// API: POST /api/signed-urls
const urls = await Promise.all(
  paths.map(async (path: string) => {
    const signedUrl = await getSignedUrl(path);
    return { path, signedUrl };
  })
);
```

### 전략 비교

| 전략 | 구현 복잡도 | 성능 | 적합한 상황 |
|------|-----------|------|------------|
| React Query | 낮음 | 중간 | 개발 중, 간단한 앱 |
| Batch 발급 | 중간 | 높음 | 갤러리, 리스트 |

## 보안 고려사항

### 1. SECRET_KEY 관리

```typescript
// ✅ 환경 변수로 관리
const SECRET_KEY = process.env.STORAGE_SECRET_KEY!;

// ❌ 코드에 하드코딩
const SECRET_KEY = 'my-secret-123';

// ❌ 클라이언트에 노출
const response = { signedUrl, secretKey: SECRET_KEY };
```

### 2. 만료 시간 설정

```typescript
// 일회성 다운로드
const DOWNLOAD_EXPIRES = 5 * 60; // 5분

// 이미지 미리보기
const PREVIEW_EXPIRES = 60 * 60; // 1시간

// 갤러리/대시보드
const GALLERY_EXPIRES = 24 * 60 * 60; // 24시간
```

### 3. HTTPS 필수

Signed URL 자체가 접근 권한이므로 HTTP로 전송 시 URL 탈취 가능.

## Supabase에서 사용

### Signed URL 생성 API

```typescript
// app/api/signed-url/route.ts
export async function GET(request: NextRequest) {
  const path = request.nextUrl.searchParams.get('path');

  if (!path) {
    return NextResponse.json({ error: 'Path required' }, { status: 400 });
  }

  // TODO: 사용자 인증 및 권한 확인

  const { data, error } = await supabase.storage
    .from('private-bucket')
    .createSignedUrl(path, 3600);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ signedUrl: data.signedUrl });
}
```

### 컴포넌트에서 사용

```typescript
function PrivateImage({ imagePath }: { imagePath: string }) {
  const { data: signedUrl, isLoading } = useSignedUrl(imagePath);

  if (isLoading) return <Skeleton />;
  if (!signedUrl) return <ImageError />;

  return <img src={signedUrl} alt="Private Image" />;
}
```
