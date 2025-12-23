# Three.js MarchingCubes 가이드 (React Three Fiber / Drei)

## 개요

MarchingCubes는 Metaball 효과를 구현하는 Three.js 컴포넌트로, `@react-three/drei` 라이브러리에서 제공합니다.
여러 구체가 서로 가까워지면 물방울처럼 합쳐지는 유기적인 형태를 표현할 수 있습니다.

## 핵심 개념: 바운딩 박스 좌표계

**MarchingCubes는 -1 ~ 1 범위의 정규화된 좌표계를 사용합니다.**

```
         y = 1
           ↑
           │
  x = -1 ──┼── x = 1
           │
           ↓
         y = -1
```

- 이 범위를 벗어난 MarchingCube는 **렌더링되지 않음**
- `scale` prop은 최종 메쉬 크기만 키우며, 내부 좌표계는 변하지 않음

---

## MarchingCubes Props

| Prop | 타입 | 설명 |
|------|------|------|
| `resolution` | number | 3D 그리드 해상도. 높을수록 부드럽지만 성능 저하. 권장: 50~80 |
| `maxPolyCount` | number | 최대 폴리곤 수. resolution과 함께 조정 필요 |
| `enableColors` | boolean | MarchingCube별 색상 활성화 |
| `enableUvs` | boolean | UV 매핑 활성화 (텍스처 사용 시) |
| `scale` | number | 최종 렌더링 메쉬 크기 배율 |
| `position` | [x, y, z] | 월드 좌표계에서의 위치 |

### scale과 position의 관계

```tsx
// scale은 렌더링 크기만 확장
// 내부 좌표계는 여전히 -1 ~ 1
<MarchingCubes scale={6} position={[0, 0, 0]}>
  {/* MarchingCube position은 -1 ~ 1 범위 내에서 설정 */}
  <MarchingCube position={[0.3, 0.1, 0]} />
</MarchingCubes>
```

---

## MarchingCube Props

| Prop | 타입 | 설명 |
|------|------|------|
| `strength` | number | Metaball의 영향력 반경. 클수록 큰 구체 |
| `subtract` | number | 다른 metaball과의 상호작용 강도 |
| `color` | Color | 구체 색상 (enableColors 필요) |
| `position` | [x, y, z] | 바운딩 박스 내 위치 (-1 ~ 1 범위) |

### strength 값 가이드

```
strength 0.3~0.5: 작은 구체
strength 0.5~0.8: 중간 구체
strength 0.8~1.2: 큰 구체
```

---

## ⚠️ 바운딩 박스 표시 규칙 (중요!)

### 핵심 공식

```
|position| + strength < 1
```

이 조건을 만족해야 metaball이 **잘리지 않고 완전히 렌더링**됩니다.

### 예시

```tsx
// ✅ 올바른 설정
position: [0, 0.1, 0]    // |y| = 0.1
strength: 0.8            // 0.1 + 0.8 = 0.9 < 1 ✓

// ❌ 잘못된 설정 (위쪽이 잘림)
position: [0, 0.5, 0]    // |y| = 0.5
strength: 1.0            // 0.5 + 1.0 = 1.5 > 1 ✗
```

### 시각적 설명

```
바운딩 박스 y축 기준:

  y = 1  ┬─────────────┬  ← 경계
         │   잘리는    │
         │    영역     │
  y = 0.5├─────●───────┤  ← metaball 중심 (position.y = 0.5)
         │  strength   │
         │    = 1.0    │
  y = 0  ├─────────────┤
         │   정상      │
         │   렌더링    │
  y = -0.5├─────────────┤  ← metaball 하단 경계
         │             │
  y = -1 └─────────────┘  ← 경계
```

position.y = 0.5, strength = 1.0인 경우:
- 영향 범위: y = -0.5 ~ 1.5
- y = 1 이상은 바운딩 박스 밖 → **위쪽이 잘림**

---

## 권장 설정 패턴

### 화면 전체에 분산된 metaball

```tsx
const SPHERE_CONFIGS = [
  // position은 중앙 근처 (-0.3 ~ 0.3)
  // strength는 radius * 0.35 정도로 설정
  {
    position: [-0.3, 0.1, 0.1],
    radius: 2.0,  // strength = 0.7
    speed: 0.4,
    offset: 0,
  },
  {
    position: [0.3, -0.1, 0.15],
    radius: 1.8,  // strength = 0.63
    speed: 0.5,
    offset: 1,
  },
  // ...
]

// MetaballDroplets 내부
const strength = radius * 0.35  // 바운딩 박스 안전 범위
```

### MarchingCubes 기본 설정

```tsx
<MarchingCubes
  resolution={64}       // 적당한 품질
  maxPolyCount={30000}  // resolution에 맞춤
  enableColors          // 색상 활성화
  enableUvs={false}     // UV 불필요시 비활성화
  scale={6}             // 원하는 크기로 확장
>
```

---

## 트러블슈팅

### 문제 1: 구체가 하나만 보임

**원인**: position 값이 바운딩 박스(-1 ~ 1) 범위를 벗어남

**해결**:
```tsx
// ❌ 잘못된 설정
position: [-2, 1, 1]  // x, y가 범위 밖

// ✅ 올바른 설정
position: [-0.3, 0.1, 0.1]  // 모든 값이 -1 ~ 1 범위 내
```

### 문제 2: 구체가 화면 하단에만 표시됨

**원인**: position + strength가 바운딩 박스 상단(y=1)을 초과하여 위쪽이 잘림

**해결**:
```tsx
// 공식: |position.y| + strength < 1

// ❌ 잘못된 설정
position.y = 0.5, strength = 1.0  // 0.5 + 1.0 = 1.5 > 1

// ✅ 올바른 설정
position.y = 0.1, strength = 0.7  // 0.1 + 0.7 = 0.8 < 1
```

### 문제 3: 구체가 모두 사라짐

**원인**: scale 적용 후 position 값을 잘못 조정

**해결**:
- `scale`은 렌더링 크기만 변경
- 내부 좌표계는 항상 -1 ~ 1
- position은 scale과 무관하게 -1 ~ 1 범위 유지

```tsx
// scale과 position은 독립적
<MarchingCubes scale={6}>
  {/* position은 여전히 -1 ~ 1 범위 */}
  <MarchingCube position={[0.3, 0.1, 0]} strength={0.7} />
</MarchingCubes>
```

---

## 성능 최적화 팁

1. **resolution 조정**: 50~64가 품질/성능 균형점
2. **maxPolyCount**: resolution² × 10 정도로 설정
3. **enableUvs**: 텍스처 미사용시 false
4. **strength 최소화**: 필요한 크기만큼만 설정

---

## 참고 자료

- [React Three Drei - MarchingCubes](https://github.com/pmndrs/drei#marchingcubes)
- [Three.js MarchingCubes](https://threejs.org/examples/#webgl_marchingcubes)
