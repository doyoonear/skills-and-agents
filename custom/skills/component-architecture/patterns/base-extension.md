# 기본 + 확장 컴포넌트 패턴

기본 컴포넌트를 만들고, 이를 확장하여 특화된 변형 컴포넌트를 생성하는 패턴입니다.

## 핵심 원칙

### 1. 기본 컴포넌트 (Base Component)

```tsx
// ✅ 좋은 예: 최소한의 공통 기능만 포함
interface ModalProps<T = unknown> {
    close: (result?: T) => void
    title?: string
    children: React.ReactNode
}

export function Modal<T = unknown>({ close, title, children }: ModalProps<T>) {
    return (
        <Backdrop onClick={() => close()}>
            <div className="modal-container">
                {title && <h2>{title}</h2>}
                {children}
            </div>
        </Backdrop>
    )
}
```

**기본 컴포넌트의 특징:**
- 최소한의 공통 UI/로직만 포함
- `children`으로 내용 확장 가능
- 제네릭 타입(`<T>`)으로 타입 안전성 확보
- 필수가 아닌 props는 optional로 정의

### 2. 확장 컴포넌트 (Extension Component)

```tsx
// ✅ 좋은 예: 기본 컴포넌트를 래핑하여 확장
interface ConfirmModalProps {
    close: (result?: boolean) => void
    title: string
    message: string
    confirmText?: string
    cancelText?: string
}

export function ConfirmModal({
    close,
    title,
    message,
    confirmText = '확인',
    cancelText = '취소',
}: ConfirmModalProps) {
    return (
        <Modal close={close} title={title}>
            <p>{message}</p>
            <div className="button-group">
                <button onClick={() => close(false)}>{cancelText}</button>
                <button onClick={() => close(true)}>{confirmText}</button>
            </div>
        </Modal>
    )
}
```

**확장 컴포넌트의 특징:**
- 기본 컴포넌트를 import하여 내부적으로 사용
- 특화된 props 정의 (message, confirmText 등)
- 구체적인 반환 타입 지정 (boolean, string 등)
- 별도 폴더에 그룹화

---

## 폴더 구조

```
overlay/
├── Backdrop.tsx          # 공통 레이어 (가장 기본)
├── Modal.tsx             # 기본 모달
├── Sheet.tsx             # 기본 시트
├── index.ts              # 모든 export
├── modals/               # Modal 확장 컴포넌트들
│   ├── ConfirmModal.tsx
│   ├── AlertModal.tsx
│   └── FormModal.tsx
└── sheets/               # Sheet 확장 컴포넌트들
    ├── ActionSheet.tsx
    ├── FilterSheet.tsx
    └── ShareSheet.tsx
```

### index.ts 구성

```tsx
// 코어 레이어
export { Backdrop } from './Backdrop'

// 기본 컴포넌트
export { Modal } from './Modal'
export { Sheet } from './Sheet'

// 확장 컴포넌트 - 모달
export { ConfirmModal } from './modals/ConfirmModal'
export { AlertModal } from './modals/AlertModal'

// 확장 컴포넌트 - 시트
export { ActionSheet } from './sheets/ActionSheet'
export { FilterSheet } from './sheets/FilterSheet'
```

---

## 제네릭 타입 활용

### 기본 컴포넌트에서 제네릭 정의

```tsx
// Sheet.tsx
interface SheetProps<T = unknown> {
    close: (result?: T) => void
    title?: string
    children: React.ReactNode
}

export function Sheet<T = unknown>({
    close,
    title,
    children,
}: SheetProps<T>) {
    const handleClose = (result?: T) => {
        // 애니메이션 처리 후 close 호출
        close(result)
    }

    return (
        <Backdrop alignBottom>
            <div className="sheet-container">
                {title && <h2>{title}</h2>}
                {children}
            </div>
        </Backdrop>
    )
}
```

### 확장 컴포넌트에서 구체적 타입 사용

```tsx
// ActionSheet.tsx
interface ActionSheetOption<T> {
    label: string
    value: T
    destructive?: boolean
}

interface ActionSheetProps<T> {
    close: (result?: T | null) => void
    title?: string
    options: ActionSheetOption<T>[]
}

export function ActionSheet<T>({
    close,
    title,
    options,
}: ActionSheetProps<T>) {
    return (
        <Sheet close={close} title={title}>
            {options.map((option, index) => (
                <button
                    key={index}
                    onClick={() => close(option.value)}
                    className={option.destructive ? 'text-red-500' : ''}
                >
                    {option.label}
                </button>
            ))}
            <button onClick={() => close(null)}>취소</button>
        </Sheet>
    )
}
```

### 사용 예시

```tsx
// 타입 안전한 사용
const action = await open<string>(({ close }) => (
    <ActionSheet
        close={close}
        title="작업 선택"
        options={[
            { label: '수정', value: 'edit' },
            { label: '삭제', value: 'delete', destructive: true },
        ]}
    />
))

// action 타입: string | null | undefined
if (action === 'edit') { /* ... */ }
```

---

## 컴포넌트 계층 구조

```
Backdrop (최하위 레이어)
│
├── Modal (기본 컴포넌트)
│   ├── ConfirmModal (확장)
│   ├── AlertModal (확장)
│   └── FormModal (확장)
│
└── Sheet (기본 컴포넌트)
    ├── ActionSheet (확장)
    ├── FilterSheet (확장)
    └── ShareSheet (확장)
```

### 계층별 책임

| 계층 | 책임 |
|------|------|
| Backdrop | 어두운 배경, 클릭 이벤트 처리 |
| Modal/Sheet | 흰색 컨테이너, 애니메이션, 기본 레이아웃 |
| 확장 컴포넌트 | 특화된 UI, 비즈니스 로직 |

---

## 안티패턴

### ❌ 기본 컴포넌트에 너무 많은 기능

```tsx
// 잘못된 예: 기본 컴포넌트가 너무 많은 것을 알고 있음
interface ModalProps {
    type: 'confirm' | 'alert' | 'form'  // ❌ 타입에 따른 분기
    showCloseButton?: boolean
    showFooter?: boolean
    footerButtons?: Button[]
    // ... 수많은 옵션
}
```

### ❌ 확장 컴포넌트가 기본을 사용하지 않음

```tsx
// 잘못된 예: 기본 컴포넌트를 무시하고 직접 구현
export function ConfirmModal({ close }) {
    return (
        <Backdrop>  {/* ❌ Modal 대신 Backdrop 직접 사용 */}
            <div className="confirm-modal">
                {/* Modal과 중복된 스타일/로직 */}
            </div>
        </Backdrop>
    )
}
```

### ❌ 한 파일에 여러 컴포넌트

```tsx
// 잘못된 예: Modal.tsx에 ConfirmModal도 함께 정의
export function Modal() { /* ... */ }
export function ConfirmModal() { /* ... */ }  // ❌ 별도 파일로 분리해야 함
```

---

## 체크리스트

새 확장 컴포넌트 추가 시:

- [ ] 기본 컴포넌트의 기능으로 충분한지 먼저 검토
- [ ] 기본 컴포넌트를 래핑하여 구현
- [ ] 적절한 폴더에 배치 (`modals/`, `sheets/` 등)
- [ ] `index.ts`에 export 추가
- [ ] 제네릭 타입 필요시 적절히 정의
