# Lottie 애니메이션 웹 페이지 통합 가이드

## 개요
웹 페이지에서 Lottie 애니메이션을 표시하는 방법과 일반적인 문제 해결 방법을 다룹니다.

## 주요 라이브러리

### 1. dotlottie-player (웹 컴포넌트)
- **CDN**: `https://unpkg.com/@dotlottie/player-component@latest/dist/dotlottie-player.mjs`
- **타입**: ES Module
- **사용법**: `<dotlottie-player>` 커스텀 엘리먼트

### 2. lottie-web (공식 라이브러리)
- **CDN**: `https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js`
- **사용법**: JavaScript API 직접 호출

## dotlottie-player 사용법

### 기본 HTML 마크업
```html
<script src="https://unpkg.com/@dotlottie/player-component@latest/dist/dotlottie-player.mjs" type="module"></script>

<dotlottie-player
  src="애니메이션URL"
  background="transparent"
  speed="1"
  loop
  autoplay>
</dotlottie-player>
```

### JavaScript로 동적 생성
```javascript
const player = document.createElement('dotlottie-player');
player.setAttribute('background', 'transparent');
player.setAttribute('speed', '1');
player.setAttribute('loop', '');
player.setAttribute('autoplay', '');
player.setAttribute('src', '애니메이션URL');
container.appendChild(player);
```

## JSON 데이터 직접 사용하기

### ❌ 잘못된 방법
```javascript
// .load() 메서드는 지원하지 않음
const lottiePlayer = document.createElement('dotlottie-player');
lottiePlayer.load(animationData); // 작동하지 않음!
```

### ✅ 올바른 방법: Data URI 사용
```javascript
const lottiePlayer = document.createElement('dotlottie-player');
lottiePlayer.setAttribute('background', 'transparent');
lottiePlayer.setAttribute('speed', '1');
lottiePlayer.setAttribute('loop', '');
lottiePlayer.setAttribute('autoplay', '');

// JSON 데이터를 Data URI로 변환
const jsonString = JSON.stringify(animationData);
const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(jsonString);
lottiePlayer.setAttribute('src', dataUri);
```

## 일반적인 문제와 해결 방법

### 문제 1: 애니메이션이 표시되지 않음 (빈 공간만 보임)

**원인:**
- JSON 데이터가 제대로 로드되지 않음
- `.load()` 메서드 사용 (지원되지 않음)
- `src` 속성이 올바르게 설정되지 않음

**해결:**
1. JSON 데이터를 Data URI로 변환하여 `src` 속성에 할당
2. 또는 외부 파일로 저장 후 URL 경로 사용

### 문제 2: 스크립트 로드 순서 문제

**원인:**
- DOM이 완전히 로드되기 전에 스크립트 실행

**해결:**
```javascript
document.addEventListener("DOMContentLoaded", function () {
  // Lottie 애니메이션 생성 코드
});
```

### 문제 3: 애니메이션 크기 문제

**해결 - CSS 설정:**
```css
#lottie-container {
  width: 100%;
  max-width: 800px;
  margin: 24px auto;
}

#lottie-container dotlottie-player {
  width: 100%;
  height: auto;
}
```

## lottie-web 라이브러리 사용 (대안)

JSON 데이터를 직접 사용하는 더 유연한 방법:

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>

<div id="lottie-container"></div>

<script>
const animationData = { /* Lottie JSON 데이터 */ };

lottie.loadAnimation({
  container: document.getElementById('lottie-container'),
  renderer: 'svg',
  loop: true,
  autoplay: true,
  animationData: animationData
});
</script>
```

## 실제 사용 예제 (아임웹 환경)

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <script src="https://unpkg.com/@dotlottie/player-component@latest/dist/dotlottie-player.mjs" type="module"></script>
  <style>
    #lottie-animation-container {
      width: 100%;
      max-width: 800px;
      margin: 24px auto;
      padding: 0 16px;
    }

    #lottie-animation-container dotlottie-player {
      width: 100%;
      height: auto;
    }
  </style>
</head>
<body>
  <!-- JSON 데이터를 script 태그에 저장 -->
  <script id="lottie-json-data" type="application/json">
  {
    "nm": "Animation",
    "v": "4.8.0",
    "fr": 30,
    "layers": [...]
  }
  </script>

  <script>
    document.addEventListener("DOMContentLoaded", function () {
      // JSON 데이터 파싱
      const dataElement = document.getElementById('lottie-json-data');
      let animationData = null;

      if (dataElement) {
        try {
          animationData = JSON.parse(dataElement.textContent || '{}');
        } catch (error) {
          console.error('JSON 파싱 실패:', error);
        }
      }

      // 컨테이너 생성
      const container = document.createElement('div');
      container.id = 'lottie-animation-container';

      // 플레이어 생성
      const player = document.createElement('dotlottie-player');
      player.setAttribute('background', 'transparent');
      player.setAttribute('speed', '1');
      player.setAttribute('loop', '');
      player.setAttribute('autoplay', '');

      if (animationData) {
        // JSON을 Data URI로 변환
        const jsonString = JSON.stringify(animationData);
        const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(jsonString);
        player.setAttribute('src', dataUri);
      }

      container.appendChild(player);
      document.body.appendChild(container);
    });
  </script>
</body>
</html>
```

## 트러블슈팅 체크리스트

애니메이션이 작동하지 않을 때 확인할 사항:

1. ✅ 스크립트가 올바르게 로드되었는가?
2. ✅ DOM이 완전히 로드된 후 실행되는가?
3. ✅ JSON 데이터가 올바르게 파싱되었는가? (콘솔 확인)
4. ✅ `src` 속성이 Data URI 또는 유효한 URL인가?
5. ✅ CSS에서 컨테이너 크기가 설정되었는가?
6. ✅ 브라우저 콘솔에 에러가 있는가?

## 참고 자료

- [Lottie Files 공식 문서](https://lottiefiles.com/blog/working-with-lottie-animations/how-to-add-lottie-animation-in-web-page-html)
- [dotlottie-player GitHub](https://github.com/dotlottie/player-component)
- [lottie-web GitHub](https://github.com/airbnb/lottie-web)
