---
name: testing-principles
description: |
  테스트 코드 작성 원칙: 단위 테스트와 통합 테스트 구분, 작성 기준, Python/pytest 패턴.
  트리거: "테스트 작성", "테스트 코드", "단위 테스트", "통합 테스트", "pytest", "테스트 리뷰", "테스트 검토", "테스트 개선" 관련 요청 시 사용
---

# Testing Principles: 단위 테스트 vs 통합 테스트

## Overview

이 스킬은 테스트 코드 작성 시 단위 테스트와 통합 테스트를 올바르게 구분하고 작성하는 방법을 제공합니다.
특히 통합 테스트에서 내부 메서드를 호출하는 등의 안티패턴을 방지하고, PRD Pass 조건을 명확히 검증하는 테스트를 작성하도록 안내합니다.

## 핵심 원칙

### 테스트 분류 기준표

| 구분    | 단위 테스트              | 통합 테스트              |
|-------|---------------------|---------------------|
| 검증 대상 | 내부 로직               | 실제 동작               |
| 의존성   | Mock/제거             | 실제 사용               |
| 속도    | 빠름 (ms)             | 느림 (초)              |
| 호출 방식 | 내부 메서드 OK           | 공개 API만             |
| 예시    | _emit_event() 직접 호출 | mouse.click() 실제 클릭 |

### 🔬 단위 테스트 (Unit Test)

**목적**: 하나의 컴포넌트를 격리해서 내부 로직만 검증

**특징**:
- 외부 의존성을 제거하거나 모킹(Mock)
- 내부 메서드(_로 시작하는 private 메서드)를 직접 호출해도 됨
- 빠르게 실행됨 (ms 단위)
- 로직 자체가 맞는지만 확인

**언제 사용**:
- ✅ 알고리즘 로직 검증
- ✅ 에러 핸들링 검증
- ✅ 내부 상태 관리 검증
- ✅ 콜백 메커니즘 검증

**간단한 예시**:
```python
from unittest.mock import Mock

def test_callback_called_on_event():
    """콜백 메커니즘이 제대로 작동하는지 검증"""
    collector = InputEventCollector()
    callback = Mock()  # ✅ Mock 사용

    collector.add_callback(callback)

    # ✅ 내부 메서드 직접 호출 (단위 테스트에서는 OK)
    test_event = InputEvent(...)
    collector._emit_event(test_event)

    # 콜백이 호출되었는지만 확인
    callback.assert_called_once()
```

### 🔗 통합 테스트 (Integration Test)

**목적**: 여러 컴포넌트를 실제로 연결해서 함께 동작하는지 검증

**특징**:
- 실제 시스템 리소스 사용 (마우스, 화면, DB, 파일 등)
- Mock 사용 안 함
- 느리게 실행됨 (초 단위)
- 사용자가 실제로 사용하는 방식대로 테스트
- **공개 API만 사용** (내부 메서드 호출 금지)

**언제 사용**:
- ✅ End-to-End 워크플로우 검증
- ✅ 시스템 리소스 상호작용 검증
- ✅ PRD Pass 조건 검증
- ✅ 실제 사용 시나리오 검증

**간단한 예시**:
```python
from pynput.mouse import Button, Controller

def test_recorder_records_events():
    """실제 마우스 클릭 이벤트가 수집되는지 검증"""
    recorder = Recorder(fps=10)
    mouse = Controller()  # ✅ pynput의 실제 Controller

    recorder.start()  # ✅ 실제 리스너 시작
    time.sleep(0.1)

    # ✅ 실제 마우스 클릭 시뮬레이션 (시스템 이벤트 발생)
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    session = recorder.stop()

    # ✅ 실제로 수집된 이벤트 검증
    assert len(session.events) >= 1
```

## 일반적인 안티패턴

### ❌ 통합 테스트에서 내부 메서드 호출

이것이 가장 흔한 실수입니다. 통합 테스트에서 실제 시스템을 시작하고도 내부 메서드를 직접 호출하는 경우:

```python
# ❌ 잘못된 통합 테스트
def test_input_collector_with_window():
    collector = InputEventCollector()

    with collector:  # ✅ 리스너 시작 (통합 테스트)
        test_event = InputEvent(...)
        collector._emit_event(test_event)  # ❌ 내부 메서드 호출 (단위 테스트 방식)
```

**문제점**:
- 리스너는 시작했는데, 실제 시스템 이벤트를 기다리지 않음
- pynput 리스너를 우회해서 내부 메서드를 직접 호출
- "실제 환경에서 마우스 클릭 → pynput 감지 → WindowInfo 수집" 흐름을 검증 못함

**올바른 수정**:
```python
# ✅ 올바른 통합 테스트
def test_input_collector_with_window():
    from pynput.mouse import Button, Controller

    collector = InputEventCollector()
    mouse = Controller()  # ✅ pynput Controller

    collector.start()
    time.sleep(0.1)

    # ✅ 실제 마우스 클릭 시뮬레이션
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    collector.stop()

    events = collector.get_events()

    # ✅ 실제로 수집된 이벤트의 window_info 검증
    assert len(events) >= 1
    assert events[0].window_info is not None
```

### ❌ 통합 테스트에서 Mock 사용

```python
# ❌ 잘못됨
def test_recorder_with_mock():
    recorder = Recorder()

    # ❌ Mock 사용 (통합 테스트에서는 부적절)
    mock_capture = Mock()
    recorder._screen_capture = mock_capture

    recorder.start()
    recorder.stop()
```

**문제점**: Mock을 사용하면 실제 통합을 검증할 수 없음

## PRD Pass 조건 검증

PRD 문서의 Pass 조건을 명확히 검증하는 테스트를 작성합니다.

**예시**: F-03 Pass 조건 "app_name 필드 존재"

```python
def test_window_info_has_app_name():
    """PRD F-03 Pass 조건: app_name 필드 존재"""
    collector = InputEventCollector()
    mouse = Controller()

    collector.start()
    time.sleep(0.1)

    mouse.click(Button.left, 1)

    time.sleep(0.2)
    collector.stop()

    events = collector.get_events()
    click_events = [e for e in events if e.event_type == InputEventType.MOUSE_CLICK]

    assert len(click_events) >= 1
    event = click_events[0]

    # F-03 Pass 조건 검증
    assert hasattr(event, "window_info")
    if event.window_info:
        assert hasattr(event.window_info, "app_name")
        assert event.window_info.app_name is not None
```

## 테스트 분류 체크리스트

테스트를 작성하거나 리뷰할 때 다음 체크리스트를 사용하세요.

**단위 테스트인지 확인**:
- [ ] Mock을 사용하는가?
- [ ] 내부 메서드(_로 시작)를 호출하는가?
- [ ] 실제 시스템 리소스 없이 실행 가능한가?
- [ ] ms 단위로 빠르게 실행되는가?

**통합 테스트인지 확인**:
- [ ] 실제 시스템 리소스를 사용하는가?
- [ ] 여러 컴포넌트를 연결하는가?
- [ ] 공개 API만 사용하는가?
- [ ] 실제 사용 시나리오를 검증하는가?

**⚠️ 혼합 패턴 경고**:
- [ ] 통합 테스트인데 내부 메서드를 호출하는가? → ❌ 안티패턴
- [ ] 통합 테스트인데 Mock을 사용하는가? → ❌ 안티패턴

## 테스트 코드 작성 시 적용 방법

### 1. 새로운 테스트 코드 작성 시

1. **먼저 검증 목적 명확화**: 무엇을 검증하려는가?
   - 내부 로직만? → 단위 테스트
   - 실제 동작/통합? → 통합 테스트

2. **단위 테스트 작성 시**:
   - Mock/Stub 사용
   - 내부 메서드 직접 호출 가능
   - 빠르게 실행되도록 작성

3. **통합 테스트 작성 시**:
   - 실제 시스템 리소스 사용 (pynput Controller, mss, DB 등)
   - 공개 API만 사용
   - time.sleep()으로 실제 대기 시간 확보
   - PRD Pass 조건 명시

### 2. 기존 테스트 코드 리뷰 시

1. **파일명/테스트명으로 의도 파악**: 단위인가 통합인가?

2. **안티패턴 확인**:
   - 통합 테스트에서 내부 메서드 호출하는가?
   - 통합 테스트에서 Mock 사용하는가?
   - 실제 리스너/시스템을 시작하고도 우회하는가?

3. **수정 방향 제시**:
   - 내부 메서드 호출 → 실제 시스템 이벤트 사용
   - Mock 사용 → 실제 컴포넌트 사용
   - PRD Pass 조건 추가

## 상세 참조 문서

더 자세한 패턴과 예시는 다음 참조 문서를 확인하세요:

- **단위 테스트 패턴**: [unit-test-patterns.md](references/unit-test-patterns.md)
  - Mock 사용 패턴
  - 내부 메서드 테스트 패턴
  - 에러 핸들링 테스트
  - 버퍼 관리 테스트

- **통합 테스트 패턴**: [integration-test-patterns.md](references/integration-test-patterns.md)
  - pynput Controller 사용법
  - 시스템 리소스 사용 패턴
  - PRD Pass 조건 검증
  - 타임스탬프 동기화

- **실제 프로젝트 예시**: [shadow-py-examples.md](references/shadow-py-examples.md)
  - shadow-py 프로젝트의 실제 테스트 코드
  - Before/After 비교
  - 각 파일의 분류 이유
  - 올바른 패턴과 안티패턴 예시

## 요약

**핵심 규칙 3가지**:

1. **단위 테스트**: Mock 사용 OK, 내부 메서드 호출 OK, 빠르게
2. **통합 테스트**: 실제 시스템 사용, 공개 API만, Mock 금지
3. **혼합 금지**: 통합 테스트에서 내부 메서드 호출하지 말 것

**테스트 작성 전 질문**:
- "무엇을 검증하는가?" → 로직? 실제 동작?
- "어떻게 검증하는가?" → Mock? 실제 시스템?
- "통합 테스트인데 내부 메서드를 호출하고 있지는 않은가?"

이 원칙들을 따르면 명확하고 유지보수하기 쉬운 테스트 코드를 작성할 수 있습니다.
