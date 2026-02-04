# Tailwind CSS v4 가이드

Tailwind CSS v4의 새로운 문법과 주요 변경사항에 대한 가이드입니다.

## 주요 변경사항

### 설치 및 설정 간소화

**v3 방식:**
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init
```

**v4 방식:**
```bash
npm install tailwindcss @tailwindcss/postcss
```

- **설정 파일 불필요**: `tailwind.config.js` 파일이 더 이상 필요 없음
- **적은 의존성**: 패키지 수가 대폭 감소
- **자동 콘텐츠 감지**: 템플릿 파일을 자동으로 찾아 처리

### CSS 파일 설정

**v3 방식:**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**v4 방식:**
```css
@import "tailwindcss";
```

단 한 줄로 Tailwind CSS를 임포트합니다.

## 핵심 문법

### 1. @layer 디렉티브

CSS를 cascade layer로 조직화하는 데 사용됩니다. v4에서는 CSS 우선순위 제어가 더욱 강력해졌습니다.

**기본 레이어:**
- `base`: 기본 스타일 및 reset
- `components`: 재사용 가능한 컴포넌트 스타일
- `utilities`: 유틸리티 클래스

**사용 예시:**

```css
@import "tailwindcss";

@layer base {
  * {
    box-sizing: border-box;
    padding: 0;
    margin: 0;
  }

  body {
    font-family: Arial, sans-serif;
  }
}

@layer components {
  .btn-primary {
    @apply rounded-lg bg-blue-500 px-4 py-2 text-white;
  }
}

@layer utilities {
  .mx-6 {
    margin-inline: calc(var(--spacing) * 6);
  }
}
```

**레이어 우선순위:**
1. `@layer base` - 가장 낮은 우선순위
2. `@layer components` - 중간 우선순위
3. `@layer utilities` - 가장 높은 우선순위

### 2. @theme 디렉티브

디자인 토큰을 CSS 변수로 정의하고 유틸리티 클래스를 자동 생성합니다.

**사용 예시:**

```css
@import "tailwindcss";

@theme {
  /* 색상 정의 */
  --color-primary-100: oklch(0.99 0 0);
  --color-primary-200: oklch(0.98 0.04 113.22);
  --color-brand: #b4d455;

  /* 간격 정의 */
  --spacing: 0.25rem;
  --spacing-tight: 0.125rem;

  /* 폰트 정의 */
  --font-display: "Roboto", "sans-serif";
  --font-body: "Inter", "sans-serif";

  /* 브레이크포인트 정의 */
  --breakpoint-3xl: 1920px;
}
```

**@theme vs :root:**
- `@theme`: 유틸리티 클래스를 자동 생성하고 싶을 때
- `:root`: 일반 CSS 변수만 필요할 때

```css
/* 이렇게 정의하면 */
@theme {
  --color-brand: #b4d455;
}

/* 이런 클래스가 자동 생성됨 */
.text-brand { color: var(--color-brand); }
.bg-brand { background-color: var(--color-brand); }
```

### 3. PostCSS 설정

**postcss.config.mjs:**
```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

또는 Vite를 사용하는 경우:

**vite.config.ts:**
```javascript
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss()],
});
```

## 성능 개선

### 빌드 속도
- **전체 빌드**: 최대 5배 빠름
- **증분 빌드**: 100배 이상 빠름

### 최적화 기능
- 자동 콘텐츠 감지
- `.gitignore` 파일 자동 인식
- 불필요한 CSS 자동 제거

## 마이그레이션 가이드

### v3 → v4 주요 변경사항

1. **설정 파일 제거**
   ```bash
   rm tailwind.config.js
   ```

2. **globals.css 수정**
   ```css
   /* Before (v3) */
   @tailwind base;
   @tailwind components;
   @tailwind utilities;

   /* After (v4) */
   @import "tailwindcss";
   ```

3. **커스텀 스타일 @layer로 감싸기**
   ```css
   /* Before (v3) */
   * {
     margin: 0;
     padding: 0;
   }

   /* After (v4) */
   @layer base {
     * {
       margin: 0;
       padding: 0;
     }
   }
   ```

4. **패키지 업데이트**
   ```bash
   npm uninstall tailwindcss postcss autoprefixer
   npm install tailwindcss @tailwindcss/postcss
   ```

## 모던 CSS 기능 활용

### Cascade Layers
v4는 네이티브 CSS cascade layers를 활용하여 스타일 우선순위를 더 정밀하게 제어합니다.

### @property
커스텀 속성을 등록하여 타입 안정성과 애니메이션 지원을 개선합니다.

### color-mix()
색상 혼합을 위한 모던 CSS 함수를 지원합니다.

## 참고 자료

- [Tailwind CSS v4 공식 문서](https://tailwindcss.com/docs)
- [Tailwind CSS v4 릴리즈 노트](https://tailwindcss.com/blog/tailwindcss-v4)
- [Theme Variables](https://tailwindcss.com/docs/theme)
- [Functions and Directives](https://tailwindcss.com/docs/functions-and-directives)
