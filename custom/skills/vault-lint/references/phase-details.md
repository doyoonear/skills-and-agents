# Phase 3.5 상세: 이미지 참조 통일 + 미참조 검출

vault-lint Phase 3.5의 정규식 패턴, 변환 규칙, 엣지 케이스 상세 레퍼런스.

---

## Obsidian 설정 기준

- `attachmentFolderPath`: `_assets` (vault 루트 기준)
- 기본 링크 형식: wikilink
- 목표 통일 형식: `![[filename]]` (경로 없이 파일명만)

---

## Stage A: 형식 통일 - 정규식 패턴

### Pattern 1: Markdown 이미지 `![alt](path)`

```regex
!\[([^\]]*)\]\(([^)]+)\)
```

**캡처 그룹:**
- Group 1: alt text (빈 문자열 가능)
- Group 2: 이미지 경로

**주의:** 일반 링크 `[text](url)`와 구분하기 위해 반드시 `!` 접두사를 확인한다.

**변환 규칙:**

| 원본 패턴 | 변환 결과 | 비고 |
|-----------|----------|------|
| `![alt](_assets/image.png)` | `![[image.png\|alt]]` | _assets/ 접두사 제거 |
| `![alt](image.png)` | `![[image.png\|alt]]` | 그대로 파일명 사용 |
| `![alt](../path/image.png)` | `![[image.png\|alt]]` | 상대 경로에서 파일명만 추출 |
| `![](image.png)` | `![[image.png]]` | alt 비어있으면 alias 생략 |
| `![alt](https://example.com/img.png)` | 변환하지 않음 | 외부 URL은 skip |

**경로에서 파일명 추출 로직:**

```
path → 마지막 `/` 이후 문자열 → percent-decode → 결과가 파일명
```

### Pattern 2: HTML 이미지 `<img>`

```regex
<img\s+[^>]*src=["']([^"']+)["'][^>]*>
```

**캡처 그룹:**
- Group 1: src 속성 값 (이미지 경로)

**추가 추출 (선택):**

alt 속성 추출용:
```regex
alt=["']([^"']*)["']
```

width/height 추출용 (보존 필요 시):
```regex
width=["']?(\d+)["']?
```

**변환 규칙:**

| 원본 패턴 | 변환 결과 | 비고 |
|-----------|----------|------|
| `<img src="_assets/image.png">` | `![[image.png]]` | 기본 변환 |
| `<img src="_assets/image.png" alt="설명">` | `![[image.png\|설명]]` | alt → alias |
| `<img src="image.png" width="300">` | `![[image.png\|300]]` | width → Obsidian 크기 지정 |
| `<img src="_assets/image.png" alt="설명" width="300">` | `![[image.png\|설명]]` | alt 우선, width는 유실됨 (경고 출력) |
| `<img src="https://example.com/img.png">` | 변환하지 않음 | 외부 URL은 skip |

**width + alt 동시 존재 시 정책:**
- Obsidian wikilink는 `|` 뒤에 하나의 값만 받는다 (alias 또는 크기).
- alt text를 우선하고, width 유실에 대한 경고를 출력한다.
- 사용자가 width 보존을 원하면 수동 처리하도록 보고한다.

### Pattern 3: Wikilink 이미지 (이미 통일 형식)

```regex
!\[\[([^\]|]+)(?:\|([^\]]*))?\]\]
```

이 패턴은 변환 대상이 아니라 Stage B 검증에서 사용한다.

**캡처 그룹:**
- Group 1: 파일명 (또는 경로)
- Group 2: alias/크기 (선택)

---

## 엣지 케이스

### 1. 파일명에 공백 포함

Obsidian의 기본 스크린샷/붙여넣기 파일명 패턴:

```
Pasted image 20250415123045.png
Screenshot 2025-04-15 at 12.30.45.png
```

**markdown 참조에서의 형태:**
```markdown
![alt](_assets/Pasted%20image%2020250415123045.png)
![alt](_assets/Pasted image 20250415123045.png)
```

**처리:**
- percent-encoded 경로(`%20` 등)를 디코딩한 뒤 파일명을 추출한다.
- 공백이 포함된 파일명도 wikilink에서 정상 동작한다: `![[Pasted image 20250415123045.png]]`

**percent-decode 대상 문자:**

| 인코딩 | 원본 |
|--------|------|
| `%20` | 공백 |
| `%28` | `(` |
| `%29` | `)` |
| `%5B` | `[` |
| `%5D` | `]` |
| `%23` | `#` |

### 2. 경로에 _assets/ 접두사가 있거나 없는 경우

Obsidian 설정에 따라 이미지 참조가 다양한 형태로 존재할 수 있다:

```markdown
![alt](_assets/image.png)       <!-- 상대 경로 포함 -->
![alt](image.png)               <!-- 파일명만 -->
![alt](../_assets/image.png)    <!-- 상위 디렉토리 참조 -->
![alt](./_assets/image.png)     <!-- 현재 디렉토리 명시 -->
```

**처리:** 모든 경우에서 최종 파일명(`image.png`)만 추출하여 `![[image.png]]`로 통일한다.

### 3. 동일 파일명, 다른 경로

vault 내 다른 디렉토리에 동일 파일명이 존재할 수 있다:

```
_assets/screenshot.png
Projects/my-app/_assets/screenshot.png
```

**처리:**
- 변환 전 vault 전체에서 동일 파일명 검색을 수행한다.
- 동일 파일명이 2개 이상이면 해당 변환을 skip하고 경고를 출력한다.
- 사용자가 수동으로 경로를 명시하도록 안내한다.

### 4. 이미 wikilink지만 경로가 포함된 경우

```markdown
![[_assets/image.png]]
![[_assets/Pasted image 20250415.png|설명]]
```

**처리:**
- `![[_assets/image.png]]` → `![[image.png]]`로 경로를 정리한다.
- Obsidian은 파일명만으로 해석하므로 경로 접두사는 불필요하다.

### 5. 외부 URL

```markdown
![alt](https://example.com/image.png)
<img src="https://cdn.example.com/photo.jpg">
```

**처리:** `http://` 또는 `https://`로 시작하는 경로는 모두 skip한다.

외부 URL 판별 정규식:
```regex
^https?://
```

### 6. 특수 이미지 형식

지원하는 이미지 확장자:
```
.png, .jpg, .jpeg, .gif, .bmp, .svg, .webp, .avif, .ico, .tiff, .tif
```

PDF 임베드(`![[document.pdf]]`)는 이미지가 아니므로 Phase 3.5에서 처리하지 않는다.

### 7. 줄 단위 vs 인라인 처리

한 줄에 여러 이미지 참조가 있을 수 있다:

```markdown
비교: ![A](_assets/before.png) → ![B](_assets/after.png)
```

**처리:** 정규식을 non-greedy로 적용하고, 한 줄 내 모든 매칭을 개별 처리한다. `re.findall()` 또는 `re.sub()` 사용 시 기본적으로 모든 매칭을 처리한다.

---

## Stage B: 미참조 이미지 검출 - 상세 로직

### 수집

```bash
# _assets/ 내 모든 파일 (서브디렉토리 포함, _orphaned/ 제외)
find _assets/ -type f -not -path "_assets/_orphaned/*"
```

### 참조 검색

통일 완료 후에는 단일 패턴만 검색하면 된다:

```regex
!\[\[{filename}(?:\|[^\]]*)?]\]
```

`{filename}`에는 정규식 특수문자를 escape 처리한다 (특히 공백, 괄호, 점).

### 미참조 판정 기준

`_assets/` 내 파일 중 vault 전체 `.md` 파일 어디에서도 `![[filename]]` (또는 `![[filename|...]]`) 패턴으로 참조되지 않은 파일.

### 출력 형식

```
## 미참조 이미지 (orphan assets)

총 {n}개 파일, {size} MB

| # | 파일명 | 크기 | 비고 |
|---|--------|------|------|
| 1 | large-screenshot.png | 4.2 MB | |
| 2 | Pasted image 20250101.png | 1.8 MB | |
| 3 | old-diagram.svg | 0.3 MB | |
...
```

### 검출 한계

다음 경우는 정적 분석으로 감지할 수 없다:

1. **Dataview 플러그인 동적 쿼리**: `dv.paragraph("![[" + name + "]]")` 형태의 동적 참조.
2. **Templater 변수**: `<% tp.file.include("[[image.png]]") %>` 형태.
3. **CSS snippet에서의 참조**: `background-image: url(...)` 형태.
4. **Obsidian Canvas (.canvas 파일)**: JSON 구조 내 이미지 참조.

이 한계를 사용자에게 경고하고, `--delete-orphans`를 사용하더라도 `_assets/_orphaned/`로 이동(soft delete)하여 복구 가능하게 한다.

---

## 통일 완료 판별 기준

후속 lint 실행 시 Stage A를 건너뛸지 판별하는 기준:

1. vault 전체에서 markdown 이미지 패턴 (`![alt](path)`) 건수를 센다.
2. vault 전체에서 HTML 이미지 패턴 (`<img src>`) 건수를 센다.
3. 두 합계가 5건 미만이면 "통일 완료"로 간주하고 Stage A를 skip한다.
4. 5건 이상이면 Stage A를 실행한다.

임계값 5는 외부 URL 이미지(skip 대상)가 소수 잔존할 수 있음을 감안한 여유 값이다.
