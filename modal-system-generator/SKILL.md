---
name: modal-system-generator
description: |
  프로젝트에 Promise 기반 모달/오버레이 시스템을 생성합니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "모달 시스템 만들어줘"
  - "overlay 시스템 추가해줘"
  - "Promise 기반 모달 구현해줘"
  - "팝업/다이얼로그 시스템 세팅해줘"
  - "바텀시트 시스템 만들어줘"
---

# Modal System Generator

프로젝트에 Promise 기반의 모달/오버레이 시스템을 생성하는 skill입니다.

## 이 Skill이 생성하는 것

- **OverlayProvider**: 모달 상태를 전역으로 관리하는 Context Provider
- **overlay 객체**: `overlay.open()` Promise 기반 API
- **애니메이션**: fade/slide 애니메이션 스타일
- **Backdrop**: 어두운 배경 + 클릭 시 닫기 옵션
- **예시 컴포넌트**: 모달, 바텀시트 예시

## 지원 컴포넌트 타입

| 타입 | 설명 | 애니메이션 |
|------|------|-----------|
| 모달 | 중앙에 표시되는 다이얼로그 | fade + scale |
| 바텀시트 | 하단에서 올라오는 시트 | slide (bottom → top) |

## 워크플로우

### 1단계: 프로젝트 구조 분석

다음을 확인하세요:

1. **디렉토리 구조 파악**
   ```
   src/
   ├── components/   # 컴포넌트 위치
   ├── hooks/        # 훅 위치
   ├── providers/    # Provider 위치 (있다면)
   ├── styles/       # 스타일 위치 (있다면)
   └── App.tsx       # 메인 앱 파일
   ```

2. **스타일링 방식 감지**
   - `package.json`에서 확인: `@emotion/react`, `styled-components`, `tailwindcss` 등
   - 기존 컴포넌트에서 사용 패턴 확인

3. **TypeScript 사용 여부**
   - `tsconfig.json` 존재 여부
   - `.tsx` vs `.jsx` 확장자

4. **기존 모달 라이브러리 확인**
   - `overlay-kit`, `@ebay/nice-modal-react` 등이 설치되어 있다면 사용자에게 알림

### 2단계: 사용자에게 옵션 확인

AskUserQuestion 도구를 사용하여 다음을 확인하세요:

```
질문 1: 파일 생성 위치
- 제안: 프로젝트 분석 결과에 따라 적절한 위치 제안
  - providers/ 폴더가 있으면: src/providers/overlay/
  - 없으면: src/overlay/ 또는 src/lib/overlay/
- 사용자가 다른 위치를 원하는지 확인

질문 2: 생성할 예시 컴포넌트
- 모달만
- 바텀시트만
- 둘 다 (기본)

질문 3: 백드롭 클릭 시 닫기 기본값
- true (기본) - 배경 클릭 시 닫힘
- false - 배경 클릭해도 안 닫힘 (각 컴포넌트에서 오버라이드 가능)
```

### 3단계: 코드 생성

templates/ 폴더의 템플릿을 참고하여 코드를 생성하세요.

**생성할 파일 목록:**
1. `overlay.tsx` - Provider + Context + overlay 객체
2. `animations.ts` - 애니메이션 keyframes (스타일링 방식에 맞게)
3. `Backdrop.tsx` - 백드롭 컴포넌트
4. `index.ts` - export 파일
5. `examples/Modal.tsx` - 모달 예시 (선택)
6. `examples/BottomSheet.tsx` - 바텀시트 예시 (선택)

**스타일링 방식별 조정:**

- **Emotion**: `css` prop 또는 `@emotion/react`의 `keyframes` 사용
- **styled-components**: `styled` + `keyframes` 사용
- **Tailwind**: className 문자열 + CSS keyframes 별도 정의
- **CSS Modules**: `.module.css` 파일 생성

### 4단계: 통합 안내

생성 완료 후 사용자에게 다음을 안내하세요:

**1. App.tsx에 Provider 추가:**
```tsx
import { OverlayProvider } from './providers/overlay';
// 또는 import { OverlayProvider } from './overlay';

function App() {
  return (
    <OverlayProvider>
      {/* 기존 앱 내용 */}
    </OverlayProvider>
  );
}
```

**2. 모달 사용 예시:**
```tsx
import { overlay } from '@/providers/overlay';
import { ConfirmModal } from '@/components/ConfirmModal';

async function handleDelete() {
  const confirmed = await overlay.open(({ close }) => (
    <ConfirmModal
      title="삭제 확인"
      message="정말 삭제하시겠습니까?"
      onConfirm={() => close(true)}
      onCancel={() => close(false)}
    />
  ));

  if (confirmed) {
    await deleteItem();
  }
}
```

**3. 바텀시트 사용 예시:**
```tsx
import { overlay } from '@/providers/overlay';
import { ActionSheet } from '@/components/ActionSheet';

async function handleOptions() {
  const action = await overlay.open(({ close }) => (
    <ActionSheet
      options={[
        { label: '수정', value: 'edit' },
        { label: '삭제', value: 'delete' },
        { label: '취소', value: null },
      ]}
      onSelect={(value) => close(value)}
    />
  ));

  if (action === 'edit') { /* ... */ }
  if (action === 'delete') { /* ... */ }
}
```

## 템플릿 파일 참조

코드 생성 시 다음 템플릿을 참고하세요:

- `templates/overlay-context.tsx.md` - 메인 Provider 코드
- `templates/overlay-animations.tsx.md` - 애니메이션 스타일
- `templates/backdrop.tsx.md` - 백드롭 컴포넌트
- `templates/example-modal.tsx.md` - 모달 예시
- `templates/example-bottomsheet.tsx.md` - 바텀시트 예시

## 주의사항

1. **React 버전 확인**: React 18+ 권장 (createPortal 사용)
2. **ESLint 실행**: 생성 후 프로젝트의 ESLint 설정에 맞게 포맷팅
3. **경로 alias**: 프로젝트의 경로 alias 설정 확인 (`@/`, `~/` 등)
