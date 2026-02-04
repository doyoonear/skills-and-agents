# Vapor UI 컴포넌트 가이드 (v1.0.0-beta.6)

이 문서는 와들와들 히어로즈 프로젝트에서 사용하는 Vapor UI 컴포넌트의 사용법을 정리한 것입니다.

## 목차

1. [Field 컴포넌트](#field-컴포넌트)
2. [TextInput 컴포넌트](#textinput-컴포넌트)
3. [Radio / RadioGroup 컴포넌트](#radio--radiogroup-컴포넌트)
4. [Sheet 컴포넌트](#sheet-컴포넌트)
5. [레이아웃 컴포넌트](#레이아웃-컴포넌트)
6. [기타 컴포넌트](#기타-컴포넌트)

---

## Field 컴포넌트

**라이브러리**: `@vapor-ui/core`

Field는 폼 요소들을 감싸는 컨테이너 컴포넌트로, 라벨, 설명, 에러 메시지, 성공 메시지 등을 제공합니다.

### 기본 사용법

```tsx
import { Field } from '@vapor-ui/core';

<Field.Root name="username">
  <Field.Label>사용자명</Field.Label>
  <Field.Description>4-20자의 영문, 숫자 조합</Field.Description>
  <Field.Error match="valueMissing">사용자명을 입력해주세요</Field.Error>
</Field.Root>
```

### 주요 Props

**Field.Root**
- `name`: 폼 제출 시 필드 식별 이름
- `disabled`: 사용자 상호작용 무시 여부 (기본값: `false`)
- `invalid`: 강제로 유효하지 않은 상태로 표시
- `validate`: 커스텀 유효성 검사 함수
- `validationMode`: `onBlur` | `onChange` (기본값: `onBlur`)
- `validationDebounceTime`: onChange 검사 시 대기 시간 (기본값: `0`)

**Field.Error**
- `match`: 특정 유효성 검사 상태에 대한 오류 메시지 표시
  - `false`: 모든 오류 표시
  - `true`: 모든 오류 숨김
  - 특정 타입: `valueMissing`, `typeMismatch`, `patternMismatch`, `tooLong`, `tooShort` 등

**Field.Success**
- `match`: `false` | `true` | `valid`

### 사용 예시

**필수 필드**
```tsx
<Field.Root name="email" required>
  <Field.Label>이메일 *</Field.Label>
  <Field.Error match="valueMissing">필수 항목입니다</Field.Error>
</Field.Root>
```

**RadioGroup과 함께 사용**
```tsx
<Field.Root name="gender">
  <Field.Label>성별</Field.Label>
  <RadioGroup.Root>
    <Radio.Root value="male"><Radio.Indicator /></Radio.Root>
    <Radio.Root value="female"><Radio.Indicator /></Radio.Root>
  </RadioGroup.Root>
  <Field.Description>개인정보 보호를 위해 선택사항입니다.</Field.Description>
</Field.Root>
```

---

## TextInput 컴포넌트

**라이브러리**: `@vapor-ui/core`

사용자가 데이터를 입력할 수 있도록 텍스트, 숫자 등 다양한 형식의 입력 필드를 제공합니다.

### 기본 사용법

```tsx
import { TextInput } from '@vapor-ui/core';

<TextInput
  type="text"
  size="md"
  placeholder="입력하세요"
/>
```

### 주요 Props

- `size`: `sm` | `md` | `lg` | `xl` (기본값: `md`)
- `type`: `text` | `email` | `password` | `url` | `tel` | `search` (기본값: `text`)
- `defaultValue`: 비제어 컴포넌트 초기값
- `value`: 제어 컴포넌트 값
- `onValueChange`: 값 변경 시 콜백
- `invalid`: 유효하지 않은 상태 (기본값: `false`)
- `disabled`: 비활성화 상태
- `readOnly`: 읽기 전용 상태

### 사용 예시

**크기별 TextInput**
```tsx
<TextInput size="sm" placeholder="Small" />
<TextInput size="md" placeholder="Medium" />
<TextInput size="lg" placeholder="Large" />
<TextInput size="xl" placeholder="Extra Large" />
```

**타입별 TextInput**
```tsx
<TextInput type="email" placeholder="example@email.com" />
<TextInput type="password" placeholder="비밀번호" />
<TextInput type="tel" placeholder="010-0000-0000" />
```

**상태별 TextInput**
```tsx
<TextInput disabled placeholder="비활성화" />
<TextInput readOnly value="읽기 전용" />
<TextInput invalid placeholder="유효하지 않음" />
```

---

## Radio / RadioGroup 컴포넌트

**라이브러리**: `@vapor-ui/core`

여러 옵션 중 하나만 선택할 수 있는 입력 컴포넌트입니다.

### 기본 사용법

```tsx
import { Radio, RadioGroup } from '@vapor-ui/core';

<RadioGroup.Root defaultValue="option1">
  <Radio.Root value="option1">
    <Radio.Indicator />
  </Radio.Root>
  <Radio.Root value="option2">
    <Radio.Indicator />
  </Radio.Root>
</RadioGroup.Root>
```

### 주요 Props

**RadioGroup.Root**
- `size`: `md` | `lg`
- `name`: 폼 제출 시 필드 식별 이름
- `defaultValue`: 초기 선택값 (비제어 컴포넌트)
- `value`: 현재 선택값 (제어 컴포넌트)
- `onValueChange`: 값 변경 시 콜백
- `disabled`: 비활성화 여부 (기본값: `false`)
- `readOnly`: 읽기 전용 여부 (기본값: `false`)
- `required`: 필수 여부 (기본값: `false`)
- `invalid`: 유효하지 않은 상태

**Radio.Root**
- `size`: `md` | `lg`
- `value`: **필수** - 라디오 그룹 내 고유 식별값
- `disabled`: 비활성화 여부
- `readOnly`: 읽기 전용 여부
- `required`: 필수 여부
- `invalid`: 유효하지 않은 상태
- `inputRef`: 숨겨진 input 요소 ref
- `nativeButton`: 네이티브 버튼 렌더링 여부 (기본값: `true`)

### 사용 예시

**라벨과 함께 사용**
```tsx
<RadioGroup.Root>
  <div className="v-flex v-items-center v-gap-2">
    <Radio.Root value="male">
      <Radio.Indicator />
    </Radio.Root>
    <Field.Label>남성</Field.Label>
  </div>
  <div className="v-flex v-items-center v-gap-2">
    <Radio.Root value="female">
      <Radio.Indicator />
    </Radio.Root>
    <Field.Label>여성</Field.Label>
  </div>
</RadioGroup.Root>
```

**크기별 RadioGroup**
```tsx
<RadioGroup.Root size="md">
  <Radio.Root value="option1"><Radio.Indicator /></Radio.Root>
</RadioGroup.Root>

<RadioGroup.Root size="lg">
  <Radio.Root value="option1"><Radio.Indicator /></Radio.Root>
</RadioGroup.Root>
```

**방향 조절 (VStack/HStack 활용)**
```tsx
// 세로 방향
<VStack>
  <RadioGroup.Root>
    <Radio.Root value="1"><Radio.Indicator /></Radio.Root>
    <Radio.Root value="2"><Radio.Indicator /></Radio.Root>
  </RadioGroup.Root>
</VStack>

// 가로 방향
<HStack>
  <RadioGroup.Root>
    <Radio.Root value="1"><Radio.Indicator /></Radio.Root>
    <Radio.Root value="2"><Radio.Indicator /></Radio.Root>
  </RadioGroup.Root>
</HStack>
```

---

## Sheet 컴포넌트

**라이브러리**: `@vapor-ui/core`

Sheet는 화면의 가장자리에서 슬라이드되어 나타나는 오버레이 컴포넌트입니다. 사이드바, 메뉴, 폼, 상세 정보 등을 표시할 때 사용합니다.

### 기본 사용법

```tsx
import { Sheet, Button } from '@vapor-ui/core';

<Sheet.Root>
  <Sheet.Trigger render={<Button />}>Open Sheet</Sheet.Trigger>
  <Sheet.Popup>
    <Sheet.Header>
      <Sheet.Title>제목</Sheet.Title>
      <Sheet.Description>설명</Sheet.Description>
    </Sheet.Header>
    <Sheet.Body>
      <p>본문 내용</p>
    </Sheet.Body>
    <Sheet.Footer>
      <Sheet.Close render={<Button />}>닫기</Sheet.Close>
    </Sheet.Footer>
  </Sheet.Popup>
</Sheet.Root>
```

### 주요 Props

**Sheet.Root**
- `open`: 다이얼로그가 현재 열려 있는지 여부 (제어 모드)
- `defaultOpen`: 초기 열림 상태 (비제어 모드, 기본값: `false`)
- `modal`: 모달 상태 여부 (`true` | `false` | `'trap-focus'`, 기본값: `true`)
  - `true`: 포커스 트랩, 스크롤 잠금, 외부 클릭 차단
  - `false`: 문서 상호작용 허용
  - `'trap-focus'`: 포커스 트랩만 적용
- `onOpenChange`: 열림/닫힘 시 콜백 `(open: boolean, eventDetails: ChangeEventDetails) => void`
- `onOpenChangeComplete`: 애니메이션 완료 후 콜백
- `closeOnClickOverlay`: 오버레이 클릭 시 닫기 여부
- `actionsRef`: 명령형 액션을 위한 ref

**Sheet.Trigger**
- `nativeButton`: 네이티브 `<button>` 렌더링 여부 (기본값: `true`)

**Sheet.Popup**
- `initialFocus`: 열릴 때 포커스할 요소
- `finalFocus`: 닫힐 때 포커스할 요소
- `portalElement`: 커스텀 Portal 요소
- `overlayElement`: 커스텀 Overlay 요소
- `positionerElement`: 커스텀 Positioner 요소

**Sheet.PositionerPrimitive**
- `side`: Sheet가 나타날 화면 방향 (`top` | `bottom` | `left` | `right`, 기본값: `right`)

**Sheet.PortalPrimitive**
- `keepMounted`: 닫혀도 DOM에 유지 여부 (기본값: `false`)
- `container`: 포털 컨테이너 요소

**Sheet.OverlayPrimitive**
- `forceRender`: 중첩된 경우에도 백드롭 강제 렌더링 여부 (기본값: `false`)

### 사용 예시

**위치별 Sheet (Side Property)**
```tsx
// 오른쪽 (기본값)
<Sheet.Root>
  <Sheet.Trigger render={<Button />}>Right Sheet</Sheet.Trigger>
  <Sheet.Popup
    positionerElement={<Sheet.PositionerPrimitive side="right" />}
  >
    <Sheet.Header>
      <Sheet.Title>오른쪽 Sheet</Sheet.Title>
    </Sheet.Header>
    <Sheet.Body>내용</Sheet.Body>
  </Sheet.Popup>
</Sheet.Root>

// 왼쪽
<Sheet.Root>
  <Sheet.Popup
    positionerElement={<Sheet.PositionerPrimitive side="left" />}
  >
    {/* ... */}
  </Sheet.Popup>
</Sheet.Root>

// 상단
<Sheet.Root>
  <Sheet.Popup
    positionerElement={<Sheet.PositionerPrimitive side="top" />}
  >
    {/* ... */}
  </Sheet.Popup>
</Sheet.Root>

// 하단
<Sheet.Root>
  <Sheet.Popup
    positionerElement={<Sheet.PositionerPrimitive side="bottom" />}
  >
    {/* ... */}
  </Sheet.Popup>
</Sheet.Root>
```

**제어 컴포넌트 (Controlled State)**
```tsx
const [isOpen, setIsOpen] = useState(false);

<Sheet.Root open={isOpen} onOpenChange={(open) => setIsOpen(open)}>
  <Sheet.Trigger render={<Button />}>Open Sheet</Sheet.Trigger>
  <Sheet.Popup>
    <Sheet.Header>
      <Sheet.Title>제어되는 Sheet</Sheet.Title>
    </Sheet.Header>
    <Sheet.Body>
      <p>외부에서 상태를 제어합니다.</p>
      <Button onClick={() => setIsOpen(false)}>닫기</Button>
    </Sheet.Body>
  </Sheet.Popup>
</Sheet.Root>
```

**Keep Mounted (DOM 유지)**
```tsx
<Sheet.Root>
  <Sheet.Trigger render={<Button />}>Open Sheet</Sheet.Trigger>
  <Sheet.Popup
    portalElement={<Sheet.PortalPrimitive keepMounted />}
  >
    <Sheet.Header>
      <Sheet.Title>입력 폼</Sheet.Title>
    </Sheet.Header>
    <Sheet.Body>
      <TextInput placeholder="닫혀도 입력 내용이 유지됩니다" />
    </Sheet.Body>
  </Sheet.Popup>
</Sheet.Root>
```

**유연한 커스텀 사용**
```tsx
<Sheet.Root closeOnClickOverlay={false}>
  <Sheet.Trigger render={<Button variant="outline" />}>
    커스텀 Sheet
  </Sheet.Trigger>
  <Sheet.Popup
    initialFocus={false}
    positionerElement={<Sheet.PositionerPrimitive side="left" />}
  >
    <Sheet.Header>
      <Sheet.Title>사이드바 메뉴</Sheet.Title>
      <Sheet.Close render={<Button size="sm" variant="ghost" />}>
        ✕
      </Sheet.Close>
    </Sheet.Header>
    <Sheet.Body>
      <VStack spacing="$200">
        <Button variant="ghost" stretch>메뉴 1</Button>
        <Button variant="ghost" stretch>메뉴 2</Button>
        <Button variant="ghost" stretch>메뉴 3</Button>
      </VStack>
    </Sheet.Body>
    <Sheet.Footer>
      <Button variant="outline" stretch>로그아웃</Button>
    </Sheet.Footer>
  </Sheet.Popup>
</Sheet.Root>
```

### 컴포넌트 구조

Sheet는 다음과 같은 하위 컴포넌트로 구성됩니다:

**Root 컴포넌트**
- `Sheet.Root`: 전체 상태 관리
- `Sheet.Trigger`: Sheet 열기 버튼
- `Sheet.Popup`: Sheet 팝업 컨테이너

**내부 Primitive 컴포넌트**
- `Sheet.PortalPrimitive`: 포털 처리 (Portal 렌더링)
- `Sheet.OverlayPrimitive`: 배경 오버레이
- `Sheet.PopupPrimitive`: 팝업 기본 요소
- `Sheet.PositionerPrimitive`: 위치 설정 (side prop)

**콘텐츠 구성 컴포넌트**
- `Sheet.Header`: 상단 영역
- `Sheet.Title`: 제목
- `Sheet.Description`: 설명
- `Sheet.Body`: 본문 콘텐츠
- `Sheet.Footer`: 하단 영역
- `Sheet.Close`: 닫기 버튼

---

## 레이아웃 컴포넌트

### HStack

수평으로 아이템들을 배치하는 레이아웃 컴포넌트입니다.

**주요 Props**
- `inline`: 인라인 플렉스 여부
- `reverse`: 역방향 배치 여부
- `render`: 커스텀 요소 렌더링

**사용 예시**
```tsx
<HStack spacing="$200" reverse>
  <Box>Item 1</Box>
  <Box>Item 2</Box>
  <Box>Item 3</Box>
</HStack>
```

### VStack

수직으로 아이템들을 배치하는 레이아웃 컴포넌트입니다.

**주요 Props**
- `inline`: 인라인 플렉스 여부
- `reverse`: 자식 요소의 쌓이는 순서를 반대로 할지 여부
- `spacing`: 아이템 간 간격
- `alignItems`: 수평 정렬
- `justifyContent`: 수직 분산

**사용 예시**
```tsx
<VStack spacing="$200" alignItems="center" justifyContent="space-between">
  <Box>Item 1</Box>
  <Box>Item 2</Box>
  <Box>Item 3</Box>
</VStack>
```

### Box

레이아웃과 스타일링을 위한 기본 컨테이너 컴포넌트입니다. 디자인 토큰을 활용한 간격, 색상, 크기 등의 속성을 제공합니다.

**주요 Props**
- `display`: 디스플레이 타입 (`flex`, `block`, `inline`, etc.)
- `backgroundColor`: 배경 색상 (시맨틱 색상 및 팔레트 색상)
- `padding`, `margin`: 내부/외부 여백
- `width`, `height`: 크기
- `borderRadius`: 테두리 둥글기
- `gap`: 플렉스박스 간격

**사용 예시**
```tsx
<Box
  display="flex"
  backgroundColor="$canvas-100"
  padding="$200"
  borderRadius="$400"
  gap="$100"
>
  <div>Content</div>
</Box>
```

### Flex

플렉스박스 레이아웃을 쉽게 구현할 수 있는 컨테이너 컴포넌트입니다. Box 컴포넌트를 확장하여 플렉스 관련 기능을 제공합니다.

**주요 Props**
- `flexDirection`: 주축 방향 (`row`, `column`, `row-reverse`, `column-reverse`)
- `alignItems`: 교차축 정렬
- `justifyContent`: 주축 정렬
- `gap`: 아이템 간 간격

**사용 예시**
```tsx
<Flex flexDirection="column" alignItems="center" gap="$200">
  <div>Item 1</div>
  <div>Item 2</div>
</Flex>
```

### Grid

유연하고 강력한 CSS Grid 기반의 레이아웃 컴포넌트입니다.

**Grid.Root Props**
- `inline`: 인라인 그리드 여부
- `flow`: 그리드 아이템 배치 방향 (`row`, `column`, `row-dense`, `column-dense`)
- `templateRows`: 그리드 행 템플릿
- `templateColumns`: 그리드 열 템플릿

**Grid.Item Props**
- `colSpan`: 열 범위 지정
- `rowSpan`: 행 범위 지정

**사용 예시**
```tsx
<Grid.Root templateColumns="repeat(3, 1fr)" gap="$200">
  <Grid.Item colSpan="2">Wide Item</Grid.Item>
  <Grid.Item>Regular Item</Grid.Item>
</Grid.Root>
```

---

## 기타 컴포넌트

### Badge

이미지, 컨텐츠 등의 상태 또는 분류를 시각적으로 표시합니다.

**주요 Props**
- `size`: `sm` | `md` | `lg` (기본값: `md`)
- `shape`: `square` | `pill` (기본값: `square`)
- `colorPalette`: `primary` | `success` | `warning` | `danger` | `hint` | `contrast` (기본값: `primary`)

**사용 예시**
```tsx
<Badge size="md" colorPalette="success" shape="pill">
  완료
</Badge>
```

### Button

사용자가 주요 작업을 수행하도록 돕는 핵심 상호작용 요소입니다.

**주요 Props**
- `size`: `sm` | `md` | `lg` | `xl` (기본값: `md`)
- `variant`: `fill` | `outline` | `ghost` (기본값: `fill`)
- `colorPalette`: `primary` | `secondary` | `success` | `warning` | `danger` | `contrast` (기본값: `primary`)
- `stretch`: 버튼 너비 확장 여부 (기본값: `false`)

**사용 예시**
```tsx
<Button size="lg" variant="fill" colorPalette="primary">
  확인
</Button>

<Button variant="outline" colorPalette="danger">
  <DeleteIcon />
  삭제
</Button>
```

### Card

이미지와 텍스트, 일부 기능 버튼을 포함한 컨테이너로 콘텐츠를 제공합니다.

**컴포넌트 구조**
- `Card.Root`: 카드 컨테이너
- `Card.Header`: 헤더 영역
- `Card.Body`: 본문 영역
- `Card.Footer`: 푸터 영역

**사용 예시**
```tsx
<Card.Root>
  <Card.Header>
    <h3>카드 제목</h3>
  </Card.Header>
  <Card.Body>
    <p>카드 내용</p>
  </Card.Body>
  <Card.Footer>
    <Button>액션</Button>
  </Card.Footer>
</Card.Root>
```

### Checkbox

여러 항목 중 복수 선택을 가능하게 하는 입력 컴포넌트입니다.

**주요 Props (Checkbox.Root)**
- `size`: `md` | `lg` (기본값: `md`)
- `defaultChecked`: 초기 선택 여부 (비제어)
- `checked`: 현재 선택 여부 (제어)
- `onCheckedChange`: 선택 변경 시 콜백
- `disabled`: 비활성화 여부
- `readOnly`: 읽기 전용 여부
- `invalid`: 유효하지 않은 상태
- `indeterminate`: 혼합 상태 여부

**사용 예시**
```tsx
<Checkbox.Root size="md" defaultChecked>
  <Checkbox.Indicator />
</Checkbox.Root>
```

---

## Vapor UI 사용 시 주의사항

1. **Compound Component 패턴**: Field, Radio, Card 등은 Root와 하위 컴포넌트를 조합하여 사용
2. **제어/비제어 컴포넌트**: `value` + `onValueChange` (제어) vs `defaultValue` (비제어)
3. **타입 안전성**: 모든 컴포넌트는 TypeScript 타입을 제공하므로 적극 활용
4. **상태 전파**: RadioGroup.Root의 `disabled`, `invalid` 등은 하위 Radio에 자동 전파
5. **Render Prop**: 모든 컴포넌트는 `render` prop으로 커스텀 요소 렌더링 가능

---

## 참고 자료

- 공식 문서: [Vapor UI Documentation](https://vapor-docs.goorm.io/)
- 버전: v1.0.0-beta.6
- 프로젝트: 와들와들 히어로즈 프론트엔드

---

**마지막 업데이트**: 2025-12-04
