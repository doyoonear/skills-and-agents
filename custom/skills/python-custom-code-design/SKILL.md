---
name: python-custom-code-design
description: >-
  Python 코드에서 변수 출처·데이터 흐름을 추적하거나, 상속·super()·부모/자식 초기화 책임을 판단할 때만 사용한다.
  일반적인 Python 코드 작성, 리팩토링, 가독성 개선, 구조 설계는 python-design-patterns와 python-code-style을 우선 사용한다.
  완료 전 안티패턴 점검은 python-anti-patterns를 사용한다.
---

# Python Custom Code Design

이 스킬은 개인 프로젝트에서 자주 헷갈렸던 Python 코드 설계 지점을 좁게 다룬다.

범위는 두 가지다.

1. **Data Flow & Traceability**: 변수 출처, import 경로, 타입 힌트, pandas DataFrame 변환 단계 추적
2. **Inheritance & Initialization**: 상속, `super()`, 부모/자식 `__init__()`, 공통 초기화 책임 판단

일반적인 Python 가독성·구조 설계는 이 스킬이 아니라 다음 스킬을 우선한다.

- `python-design-patterns`: KISS, 단일 책임, 관심사 분리, 추상화 판단, composition over inheritance
- `python-code-style`: 네이밍, import, docstring, type hint, ruff/mypy/pyright 설정
- `python-anti-patterns`: 완료 전 bare except, mixed I/O/business logic, hard-coded config 등 점검

## 사용 범위

이 스킬을 사용하는 경우:

- “이 변수 어디서 왔어?”
- “이 DataFrame이 어떤 단계로 바뀌었어?”
- “이 import된 이름의 출처가 뭐야?”
- “타입 힌트가 데이터 흐름 이해에 충분한가?”
- “부모 클래스 `__init__()`이 있는데 왜 `super()`를 안 부르지?”
- “이 상속 구조가 있는 게 나은가, 없는 게 나은가?”
- “공통 초기화 책임을 부모에 둬야 하나, 자식에 둬야 하나?”

사용하지 않는 경우:

- 일반 Python 코드를 새로 작성할 때
- 리팩토링 방향이나 구조 설계 전반을 결정할 때
- 코드 스타일, 포맷팅, docstring 규칙을 정할 때
- 완료 전 안티패턴 리뷰를 할 때

---

## 1. Data Flow & Traceability

Python 코드를 읽을 때 핵심은 **값이 어디서 만들어졌고 어떤 단계를 거쳐 현재 이름이 되었는지**를 추적하는 것이다.

Python은 변수가 할당 시점에 생성되고, 타입이 런타임에 강제되지 않기 때문에 큰 코드에서는 “이 값이 어디서 왔는가”를 명확히 만드는 컨벤션이 중요하다.

### 1-1. 변수 출처 추적 순서

#### 현재 스코프의 할당문

```python
name = value
name: Type = value
a, b = value
for item in items:
with open(path) as file:
```

변수는 보통 가장 가까운 함수 스코프 안에서 만들어진다. 먼저 같은 함수 안에서 최초 할당 위치를 찾는다.

#### 함수 매개변수

```python
def save_plots(analysis: pd.DataFrame, category_summary: pd.DataFrame) -> None:
    ...
```

이 경우 `analysis`와 `category_summary`는 함수 내부에서 만든 값이 아니라 호출자가 넘겨준 값이다. 다음 단계로 호출 위치를 찾아야 한다.

#### 호출 흐름

실행 진입점이 있으면 먼저 본다.

```python
def main() -> None:
    raw_reviews = load_reviews(INPUT_PATH)
    validate_reviews(raw_reviews)
    analysis_reviews = prepare_analysis_data(raw_reviews)
    category_summary = build_category_summary(analysis_reviews)
    save_category_summary(category_summary, OUTPUT_DIR)
```

좋은 `main()`은 코드 전체의 데이터 흐름 지도 역할을 한다.

#### import 출처

```python
import pandas as pd
from pathlib import Path
from analysis import prepare_analysis_data
```

`from module import *`는 출처 추적을 어렵게 하므로 피한다. 읽을 때도 wildcard import가 있으면 이름의 출처를 먼저 확인한다.

### 1-2. 추적 가능한 코드 작성 규칙

#### 입력과 출력을 타입 힌트로 드러낸다

```python
def prepare_analysis_data(df: pd.DataFrame) -> pd.DataFrame:
    analysis_reviews = df[df["is_valid_rating"] == 1].copy()
    return analysis_reviews
```

타입 힌트는 런타임 강제가 아니라 읽는 사람과 IDE를 위한 문서다. 공개 함수와 주요 데이터 변환 함수에는 타입 힌트를 둔다.

#### 전역 상태를 몰래 바꾸지 않는다

피하기:

```python
analysis = None


def prepare_analysis_data() -> None:
    global analysis
    analysis = ...
```

권장:

```python
def prepare_analysis_data(df: pd.DataFrame) -> pd.DataFrame:
    return df[df["is_valid_rating"] == 1].copy()
```

함수는 가능한 한 입력을 받고 결과를 반환해야 한다. 전역 변경은 변수 출처와 변경 시점을 흐리게 만든다.

#### 변수명에 데이터 상태를 담는다

피하기:

```python
data = load_data()
result = process(data)
temp = result.copy()
```

권장:

```python
raw_reviews = load_reviews(input_path)
validated_reviews = validate_reviews(raw_reviews)
analysis_reviews = prepare_analysis_data(validated_reviews)
category_summary = build_category_summary(analysis_reviews)
```

데이터가 의미 있게 바뀌면 같은 이름을 재사용하지 말고 상태가 드러나는 이름을 사용한다.

자주 쓰는 상태 접두어:

- `raw_*`: 외부에서 읽은 원본
- `validated_*`: 필수 컬럼, 범위, 결측치 등을 검증한 값
- `cleaned_*`: 결측치/형식 등을 정리한 값
- `prepared_*`: 분석이나 모델 입력에 맞게 전처리한 값
- `analysis_*`: 분석 대상만 남긴 값
- `*_summary`: 집계나 요약 결과

#### 변환 단계는 함수명으로 설명한다

```python
def load_reviews(path: Path) -> pd.DataFrame:
    ...


def validate_reviews(reviews: pd.DataFrame) -> None:
    ...


def prepare_analysis_data(reviews: pd.DataFrame) -> pd.DataFrame:
    ...


def build_category_summary(analysis_reviews: pd.DataFrame) -> pd.DataFrame:
    ...
```

함수명은 “데이터가 어떤 단계로 이동하는지”를 설명해야 한다.

### 1-3. pandas 분석 코드 흐름

pandas 코드는 데이터 상태가 계속 바뀌므로 단계 이름이 특히 중요하다.

권장 흐름:

```python
def main() -> None:
    raw_reviews = load_reviews(INPUT_PATH)
    validate_reviews(raw_reviews)
    analysis_reviews = prepare_analysis_data(raw_reviews)
    category_summary = build_category_summary(analysis_reviews)
    save_category_summary(category_summary, OUTPUT_DIR)
```

| 단계 | 역할 |
|---|---|
| `load_*` | 파일이나 외부 소스에서 읽기 |
| `validate_*` | 필수 컬럼, 중복, 결측치, 범위 확인 |
| `prepare_*` | 타입 변환, 필터링, 파생 컬럼 생성 |
| `build_*` | 분석 결과 DataFrame 생성 |
| `save_*` | CSV, 이미지, 리포트 저장 |

### 1-4. 추적성 체크리스트

- [ ] 실행 흐름을 보여주는 `main()` 또는 진입점이 있는가?
- [ ] 주요 함수에 입력/출력 타입 힌트가 있는가?
- [ ] 함수가 입력을 받고 결과를 반환하는가?
- [ ] 전역 변수를 수정하지 않는가?
- [ ] 변수명이 데이터의 상태와 역할을 드러내는가?
- [ ] `from module import *`를 피했는가?
- [ ] pandas DataFrame의 원본/검증/분석/요약 단계가 이름으로 구분되는가?
- [ ] 복잡한 변환이 단계별 함수로 나뉘어 있는가?

### 1-5. 데이터 흐름 설명 방식

사용자가 Python 코드 흐름을 물으면 다음 순서로 설명한다.

1. 이 변수는 어디서 처음 만들어졌는지
2. 함수 인자인지, 로컬 할당인지, import된 이름인지
3. 어떤 함수 호출을 거쳐 값이 변했는지
4. 현재 이름이 데이터 상태를 충분히 설명하는지
5. 필요하면 더 추적 가능한 이름이나 함수 분리를 제안

예시:

```text
`analysis_reviews`는 `prepare_analysis_data()`가 반환한 값입니다.
이 함수는 `validated_reviews`를 입력받아 유효 평점 리뷰만 남긴 새 DataFrame을 반환합니다.
따라서 이 변수는 원본이 아니라 분석 대상만 남긴 중간 데이터입니다.
```

---

## 2. Inheritance & Initialization

이 항목은 Python 유지보수성 전반을 다루지 않는다. 일반적인 설계·가독성 판단은 `python-design-patterns`에 위임하고, 여기서는 **상속 구조와 초기화 책임**만 좁게 다룬다.

### 2-1. 핵심 판단 기준

#### 존재하는 코드는 실제로 사용되어야 한다

클래스, 함수, 메서드, 변수는 “미래에 쓸 수도 있음”만으로 남기지 않는다. 특히 부모 클래스에 `__init__()`이 있으면 독자는 자식 클래스가 그 초기화 로직을 사용할 것이라고 기대한다.

피하기:

```python
class Animal:
    def __init__(self, name: str) -> None:
        self.name = name


class Dog(Animal):
    def __init__(self) -> None:
        self.name = "강아지"
```

위 코드는 `Animal.__init__()`이 있지만 실제로 사용되지 않는다. 이 상태라면 다음 둘 중 하나를 선택해야 한다.

1. 부모 초기화 책임을 실제로 사용한다.
2. 부모 초기화가 필요 없다면 제거하거나 구조를 단순화한다.

#### 공통 초기화 책임이 있다면 `super()`로 연결한다

권장:

```python
class Animal:
    def __init__(self, name: str) -> None:
        self.name = name

    def speak(self) -> None:
        print(f"{self.name}가 소리를 냅니다")


class Dog(Animal):
    def __init__(self) -> None:
        super().__init__("강아지")


class Cat(Animal):
    def __init__(self) -> None:
        super().__init__("고양이")
```

이 구조에서는 `name` 초기화 책임이 `Animal`에 모이고, 자식 클래스는 차이점만 표현한다.

#### 자식 클래스는 차이점만 표현한다

반복되는 공통 속성은 부모나 composition 대상 객체에 모으고, 자식에는 고유 값이나 고유 동작만 둔다.

```python
class Animal:
    def __init__(self, name: str, sound: str) -> None:
        self.name = name
        self.sound = sound

    def speak(self) -> str:
        return self.sound


class Dog(Animal):
    def __init__(self) -> None:
        super().__init__(name="강아지", sound="멍멍")
```

### 2-2. 상속 유지/제거 결정 흐름

아래 질문을 순서대로 확인한다.

1. 하위 클래스들이 같은 개념적 계약을 공유하는가?
2. 부모의 코드가 현재 실행 경로에서 실제로 사용되는가?
3. 부모가 공통 책임을 한 곳으로 모으는가?
4. 자식이 부모 초기화를 우회해서 독자에게 잘못된 기대를 만들고 있지 않은가?
5. 변경이 생겼을 때 수정 위치가 줄어드는가?
6. composition으로 바꾸면 더 단순해지는가?

판단:

- 모두 예: 상속 유지 가능
- 2번이 아니오: 부모 코드 제거 또는 `super()` 연결 필요
- 3번이 아니오: 상속보다 composition 또는 단순 함수가 나을 수 있음
- 4번이 예: 구조를 고쳐 기대와 실제를 맞춘다

### 2-3. 상속보다 composition이 나은 경우

상속은 “is-a” 관계와 공통 계약이 명확할 때만 사용한다. 단순히 코드를 재사용하려고 상속을 만들면 구조가 빨리 굳는다.

상속보다 composition을 고려할 때:

- 자식 클래스가 부모 메서드 대부분을 쓰지 않는다.
- 부모 초기화를 우회해야 한다.
- 런타임에 동작 조합을 바꿔야 한다.
- 테스트에서 부모의 숨은 상태 때문에 setup이 복잡하다.

예시:

```python
class CsvExporter:
    def export(self, rows: list[dict[str, str]]) -> str:
        ...


class ReportService:
    def __init__(self, exporter: CsvExporter) -> None:
        self.exporter = exporter

    def build_report(self, rows: list[dict[str, str]]) -> str:
        return self.exporter.export(rows)
```

### 2-4. 상속 구조 답변 방식

상속/초기화 구조를 리뷰할 때는 다음 순서로 답한다.

1. 현재 구조 요약
2. 부모 초기화/메서드가 실제로 사용되는지
3. 독자가 기대할 구조와 실제 구현이 일치하는지
4. 유지, 제거, `super()` 연결, composition 전환 중 추천
5. 추천 코드 예시

예시:

```text
현재 `Animal.__init__()`은 존재하지만 `Dog`에서 호출되지 않습니다.
따라서 지금 형태로 둘 거라면 부모 초기화 메서드는 읽는 사람에게 잘못된 기대를 만듭니다.
공통 초기화 책임을 부모에 둘 의도라면 `super().__init__()`으로 연결하는 편이 좋고,
그 의도가 없다면 부모 초기화를 제거해 구조를 단순화하는 편이 낫습니다.
```

### 2-5. 상속/초기화 체크리스트

- [ ] 부모 클래스의 `__init__()`은 실제로 호출되는가?
- [ ] 자식 클래스가 부모 초기화를 의도 없이 우회하지 않는가?
- [ ] 공통 책임이 부모에 모여 있는가?
- [ ] 자식 클래스는 차이점만 표현하는가?
- [ ] 상속 관계가 개념적으로 자연스러운가?
- [ ] composition으로 바꾸면 더 단순해지지 않는가?
- [ ] 사용되지 않는 부모 메서드나 추상화가 남아 있지 않은가?
