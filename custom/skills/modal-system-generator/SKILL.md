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

### 코어
- **OverlayProvider**: 모달 상태를 전역으로 관리하는 Context Provider
- **useOverlay**: 모달을 열고 닫는 훅
- **Backdrop**: 어두운 배경 + 클릭 시 닫기 옵션

### 기본 컴포넌트
- **Modal**: 중앙에 표시되는 다이얼로그 (Backdrop 포함)
- **Sheet**: 하단에서 올라오는 시트 (Backdrop 포함, alignBottom)

### 확장 컴포넌트
- **ConfirmModal**: Modal을 확장한 확인/취소 다이얼로그
- **ActionSheet**: Sheet를 확장한 옵션 선택 시트

## 폴더 구조

```
overlay/
├── OverlayProvider.tsx   # Provider + Context + useOverlay
├── Backdrop.tsx          # 배경 레이어
├── Modal.tsx             # 기본 모달
├── Sheet.tsx             # 기본 시트
├── index.ts              # 모든 export
├── modals/               # Modal 확장 컴포넌트들
│   └── ConfirmModal.tsx
└── sheets/               # Sheet 확장 컴포넌트들
    └── ActionSheet.tsx
```

## 컴포넌트 계층 구조

```
OverlayProvider (Context)
│
├── Backdrop (기본 레이어)
│   ├── Modal (기본 컴포넌트) ─── modals/ConfirmModal (확장)
│   └── Sheet (기본 컴포넌트) ─── sheets/ActionSheet (확장)
```

## 워크플로우

### 1단계: 프로젝트 구조 분석

다음을 확인하세요:

1. **디렉토리 구조 파악**
   ```
   src/
   ├── components/   # 컴포넌트 위치
   ├── hooks/        # 훅 위치
   ├── providers/    # Provider 위치 (있다면)
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

질문 2: 생성할 컴포넌트
- 기본만 (Modal, Sheet)
- 확장 포함 (Modal, Sheet, ConfirmModal, ActionSheet) - 기본값
- 커스텀 선택

질문 3: 백드롭 클릭 시 닫기 기본값
- true (기본) - 배경 클릭 시 닫힘
- false - 배경 클릭해도 안 닫힘 (각 컴포넌트에서 오버라이드 가능)
```

### 3단계: 코드 생성

templates/ 폴더의 템플릿을 참고하여 코드를 생성하세요.

**생성할 파일 목록:**
1. `OverlayProvider.tsx` - Provider + Context + useOverlay 훅
2. `Backdrop.tsx` - 백드롭 컴포넌트
3. `Modal.tsx` - 기본 모달 컴포넌트
4. `Sheet.tsx` - 기본 시트 컴포넌트
5. `modals/ConfirmModal.tsx` - 확인 모달 (선택)
6. `sheets/ActionSheet.tsx` - 액션 시트 (선택)
7. `index.ts` - export 파일

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
import { useOverlay, ConfirmModal } from '@/providers/overlay';

function MyComponent() {
  const { open } = useOverlay();

  async function handleDelete() {
    const confirmed = await open(({ close }) => (
      <ConfirmModal
        close={close}
        title="삭제 확인"
        message="정말 삭제하시겠습니까?"
      />
    ));

    if (confirmed) {
      await deleteItem();
    }
  }

  return <button onClick={handleDelete}>삭제</button>;
}
```

**3. 시트 사용 예시:**
```tsx
import { useOverlay, ActionSheet } from '@/providers/overlay';

function MyComponent() {
  const { open } = useOverlay();

  async function handleOptions() {
    const action = await open(({ close }) => (
      <ActionSheet
        close={close}
        title="옵션 선택"
        options={[
          { label: '수정', value: 'edit' },
          { label: '삭제', value: 'delete', destructive: true },
          { label: '취소', value: null },
        ]}
      />
    ));

    if (action === 'edit') { /* ... */ }
    if (action === 'delete') { /* ... */ }
  }

  return <button onClick={handleOptions}>옵션</button>;
}
```

## 템플릿 파일 참조

코드 생성 시 다음 템플릿을 참고하세요:

- `templates/overlay-provider.tsx.md` - Provider + useOverlay 코드
- `templates/overlay-animations.tsx.md` - 애니메이션 스타일
- `templates/backdrop.tsx.md` - 백드롭 컴포넌트
- `templates/modal.tsx.md` - 기본 Modal 컴포넌트
- `templates/sheet.tsx.md` - 기본 Sheet 컴포넌트
- `templates/confirm-modal.tsx.md` - ConfirmModal 확장 컴포넌트
- `templates/action-sheet.tsx.md` - ActionSheet 확장 컴포넌트

## 주의사항

1. **React 버전 확인**: React 18+ 권장 (createPortal 사용)
2. **ESLint 실행**: 생성 후 프로젝트의 ESLint 설정에 맞게 포맷팅
3. **경로 alias**: 프로젝트의 경로 alias 설정 확인 (`@/`, `~/` 등)
4. **네이밍 컨벤션**: 컴포넌트 파일은 반드시 파스칼 케이스로 작성

## ⚠️ Stale Closure 버그 방지 (필수)

### 문제 상황
모달이 열려 있는 동안 부모 컴포넌트가 **빈번하게 리렌더링**되면 모달 버튼이 **클릭해도 반응하지 않는** 버그가 발생할 수 있습니다.

**재현 조건 예시:**
- 타이머로 매초 상태 업데이트
- 실시간 데이터 스트림 (WebSocket, Audio 등)
- 빈번한 Zustand/Redux 상태 변경

### 원인 분석
```
시간 T0: 모달 열림
├── setResolvers로 새 Map 생성 { "abc123" => resolve }
├── close 함수 A 생성 (이전 resolvers 참조)
├── handleClose가 close 함수 A 클로저로 캡처
└── overlays에 element 저장 (handleClose 포함)

시간 T1~Tn: 리렌더링 발생
├── setResolvers로 새 Map 생성 (참조 변경)
└── close 함수 B, C, D... 재생성 (새 resolvers 참조)

시간 Tx: 버튼 클릭
├── overlays[0].element 내부의 handleClose 호출
├── handleClose는 T0 시점의 close 함수 A 사용
├── close 함수 A는 T0 시점의 resolvers 참조
├── resolvers.get("abc123") → undefined (새 Map에만 존재)
└── 아무 동작 없이 종료 ← 버그!
```

### 해결책: resolvers를 useRef로 관리

**잘못된 코드 (useState 사용):**
```tsx
// ❌ 버그 발생 가능
const [resolvers, setResolvers] = useState<Map<...>>(new Map())

const close = useCallback((id, result) => {
  const resolver = resolvers.get(id)  // 캡처된 시점의 resolvers
  // ...
}, [resolvers])  // resolvers 변경 시 함수 재생성
```

**올바른 코드 (useRef 사용):**
```tsx
// ✅ 항상 안전
const resolversRef = useRef<Map<...>>(new Map())

const close = useCallback((id, result) => {
  const resolver = resolversRef.current.get(id)  // 항상 최신 참조
  // ...
}, [])  // 의존성 없음 - 함수가 재생성되지 않음
```

### 핵심 원리
- `useState`: 값 변경 시 새 객체 생성 → 리렌더링 → 클로저가 새 참조를 캡처해야 함
- `useRef`: `.current` 속성만 변경 → 참조 자체는 불변 → 어느 시점에 캡처해도 동일한 Map 접근

**반드시 templates/overlay-provider.tsx.md의 수정된 템플릿을 사용하세요.**
