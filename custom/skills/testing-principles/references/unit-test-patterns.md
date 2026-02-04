# 단위 테스트 패턴 (Unit Test Patterns)

## 개요

단위 테스트는 하나의 컴포넌트를 격리해서 내부 로직만 검증합니다.
외부 의존성을 제거하거나 모킹(Mock)하여 빠르고 독립적으로 실행됩니다.

## 핵심 특징

- **격리성**: 외부 시스템과 독립적으로 실행
- **속도**: ms 단위로 빠른 실행
- **내부 메서드 접근**: private 메서드(_로 시작)를 직접 호출 가능
- **Mock/Stub 사용**: 의존성을 가짜 객체로 대체

## 패턴 1: Mock을 사용한 의존성 제거

### 콜백 메커니즘 테스트

```python
from unittest.mock import Mock

def test_callback_called_on_event():
    """콜백 메커니즘이 제대로 작동하는지 검증"""
    collector = InputEventCollector()
    callback = Mock()  # ✅ Mock 객체 생성

    collector.add_callback(callback)

    # ✅ 내부 메서드 직접 호출 (단위 테스트에서는 OK)
    test_event = InputEvent(
        timestamp=time.time(),
        event_type=InputEventType.MOUSE_CLICK,
        x=100,
        y=100,
    )
    collector._emit_event(test_event)

    # Mock 호출 검증
    callback.assert_called_once()
    called_event = callback.call_args[0][0]
    assert called_event.event_type == InputEventType.MOUSE_CLICK
    assert called_event.x == 100
```

**핵심 포인트**:
- Mock을 사용하여 실제 콜백 없이 호출 여부 검증
- `_emit_event()` 같은 내부 메서드를 직접 호출하여 로직만 검증
- 실제 시스템 이벤트 없이 빠르게 실행

### 여러 콜백 동시 호출 검증

```python
def test_multiple_callbacks():
    """여러 콜백이 모두 호출되는지 검증"""
    collector = InputEventCollector()
    callback1 = Mock()
    callback2 = Mock()

    collector.add_callback(callback1)
    collector.add_callback(callback2)

    test_event = InputEvent(
        timestamp=time.time(),
        event_type=InputEventType.MOUSE_CLICK,
        x=200,
        y=300,
    )

    collector._emit_event(test_event)

    # 두 콜백 모두 호출됨
    callback1.assert_called_once()
    callback2.assert_called_once()
```

## 패턴 2: 에러 핸들링 검증

### 콜백 에러가 수집을 멈추지 않는지 검증

```python
def test_callback_error_does_not_stop_collection():
    """콜백 에러가 발생해도 이벤트 수집은 계속됨"""
    collector = InputEventCollector()

    # 에러를 발생시키는 콜백
    def error_callback(event):
        raise RuntimeError("Test error")

    collector.add_callback(error_callback)

    test_event = InputEvent(
        timestamp=time.time(),
        event_type=InputEventType.MOUSE_CLICK,
        x=100,
        y=100,
    )

    # 에러가 발생해도 정상 동작
    collector._emit_event(test_event)

    # 이벤트는 버퍼에 저장됨
    events = collector.get_events()
    assert len(events) == 1
```

**핵심 포인트**:
- 에러 상황에서의 동작을 검증
- 시스템의 견고성(robustness) 확인

## 패턴 3: 내부 상태 검증

### 초기화 상태 검증

```python
def test_collector_initialization():
    """초기 상태가 올바른지 검증"""
    collector = InputEventCollector()

    assert collector is not None
    assert not collector._running
    assert collector._events.empty()
```

### 버퍼 관리 로직 검증

```python
def test_buffer_overflow_removes_old_events():
    """버퍼 크기 초과 시 오래된 이벤트 제거"""
    collector = InputEventCollector(buffer_size=3)

    # 4개 이벤트 추가 (버퍼 크기는 3)
    for i in range(4):
        test_event = InputEvent(
            timestamp=time.time() + i,
            event_type=InputEventType.MOUSE_CLICK,
            x=i * 100,
            y=i * 100,
        )
        collector._emit_event(test_event)

    # 버퍼 크기는 3이므로 최신 3개만 남음
    events = collector.get_events()
    assert len(events) == 3

    # 가장 오래된 이벤트(x=0)는 제거됨
    x_values = [e.x for e in events]
    assert 0 not in x_values
```

**핵심 포인트**:
- 내부 상태와 로직을 직접 검증
- 버퍼 관리 같은 내부 구현 세부사항 테스트

## 패턴 4: 순수 로직 검증

### 알고리즘 정확성 검증

```python
def test_extract_pairs_with_single_click():
    """단일 클릭 이벤트에서 Before/After 프레임 쌍 추출"""
    base_time = 1000.0
    frames = [
        Frame(timestamp=base_time + 0.0, image=np.zeros((100, 100, 3))),
        Frame(timestamp=base_time + 0.1, image=np.zeros((100, 100, 3))),
        Frame(timestamp=base_time + 0.2, image=np.zeros((100, 100, 3))),
    ]

    events = [
        InputEvent(
            timestamp=base_time + 0.15,
            event_type=InputEventType.MOUSE_CLICK,
            x=100,
            y=100,
        )
    ]

    session = RecordingSession(frames=frames, events=events)
    extractor = KeyframeExtractor()

    pairs = extractor.extract_pairs(session)

    assert len(pairs) == 1
    pair = pairs[0]

    # Before 프레임은 클릭과 가까운 시점
    time_diff = abs(pair.before_frame.timestamp - pair.trigger_event.timestamp)
    assert time_diff <= 0.1
```

**핵심 포인트**:
- 실제 시스템 리소스 없이 순수 로직만 검증
- numpy 배열로 가짜 데이터 생성
- 알고리즘의 정확성에 집중

## 패턴 5: 엣지 케이스 검증

### 빈 데이터 처리

```python
def test_get_events_returns_empty_when_no_events():
    """이벤트가 없을 때 빈 리스트 반환"""
    collector = InputEventCollector()

    events = collector.get_events()

    assert events == []
```

### 경계 조건 검증

```python
def test_extract_pairs_no_frames_returns_empty():
    """프레임이 없으면 빈 리스트 반환"""
    events = [
        InputEvent(
            timestamp=time.time(),
            event_type=InputEventType.MOUSE_CLICK,
            x=100,
            y=100,
        )
    ]

    session = RecordingSession(frames=[], events=events)
    extractor = KeyframeExtractor()

    pairs = extractor.extract_pairs(session)

    assert len(pairs) == 0
```

**핵심 포인트**:
- 예외 상황에서의 동작 검증
- None, 빈 리스트, 0 등의 경계값 테스트

## 언제 단위 테스트를 사용하는가

### 적합한 경우

- ✅ 알고리즘 로직 검증
- ✅ 에러 핸들링 검증
- ✅ 내부 상태 관리 검증
- ✅ 콜백/이벤트 메커니즘 검증
- ✅ 데이터 변환 로직 검증
- ✅ 엣지 케이스 검증

### 부적합한 경우

- ❌ 시스템 리소스 상호작용 (파일, DB, 네트워크)
- ❌ 여러 컴포넌트 간 상호작용
- ❌ End-to-End 워크플로우
- ❌ PRD Pass 조건 검증 (실제 동작 필요)

## 주요 원칙

1. **Fast**: ms 단위로 빠르게 실행
2. **Isolated**: 외부 의존성 제거
3. **Repeatable**: 항상 같은 결과
4. **Self-checking**: 자동으로 성공/실패 판단
5. **Timely**: 코드 작성과 동시에 작성

## Mock 사용 가이드

### Mock의 주요 메서드

```python
from unittest.mock import Mock

callback = Mock()

# 호출 검증
callback.assert_called()           # 최소 1번 호출
callback.assert_called_once()      # 정확히 1번 호출
callback.assert_not_called()       # 호출 안 됨

# 인자 검증
callback.assert_called_with(arg1, arg2)        # 마지막 호출의 인자
callback.assert_called_once_with(arg1, arg2)   # 1번 호출되었고 인자 확인

# 호출 기록 확인
callback.call_count                # 호출 횟수
callback.call_args                 # 마지막 호출의 인자
callback.call_args_list            # 모든 호출의 인자 리스트
```

### Mock vs MagicMock

```python
from unittest.mock import Mock, MagicMock

# Mock: 기본적인 호출만 추적
mock = Mock()
mock.method()  # ✅

# MagicMock: 매직 메서드(__len__, __str__ 등)도 지원
magic = MagicMock()
len(magic)     # ✅
str(magic)     # ✅
```

## 요약

단위 테스트는:
- 하나의 컴포넌트만 격리해서 테스트
- Mock을 사용하여 의존성 제거
- 내부 메서드를 직접 호출 가능
- 빠르고 독립적으로 실행
- 로직의 정확성에 집중
