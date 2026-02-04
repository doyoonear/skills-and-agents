# 통합 테스트 패턴 (Integration Test Patterns)

## 개요

통합 테스트는 여러 컴포넌트를 실제로 연결해서 함께 동작하는지 검증합니다.
실제 시스템 리소스를 사용하며, Mock 없이 사용자가 사용하는 방식대로 테스트합니다.

## 핵심 특징

- **실제 환경**: 시스템 리소스 사용 (마우스, 화면, DB, 파일 등)
- **속도**: 초 단위로 느린 실행
- **공개 API만**: 내부 메서드 호출 금지
- **Mock 미사용**: 실제 컴포넌트 간 상호작용 검증

## 패턴 1: 실제 시스템 이벤트 시뮬레이션

### pynput Controller를 사용한 마우스 클릭

```python
from pynput.mouse import Button, Controller

def test_recorder_records_events():
    """실제 마우스 클릭 이벤트가 수집되는지 검증"""
    recorder = Recorder(fps=10)
    mouse = Controller()  # ✅ pynput의 실제 Controller

    # 녹화 시작
    recorder.start()  # ✅ 실제 리스너 시작
    time.sleep(0.1)

    # ✅ 실제 마우스 클릭 시뮬레이션 (시스템 이벤트 발생)
    initial_position = mouse.position
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    session = recorder.stop()

    # ✅ 실제로 수집된 이벤트 검증
    assert len(session.events) >= 1
    click_events = [e for e in session.events if e.event_type == InputEventType.MOUSE_CLICK]
    assert len(click_events) >= 1
```

**핵심 포인트**:
- `Controller()`를 사용하여 실제 시스템 이벤트 생성
- pynput 리스너가 이벤트를 감지하는 전체 흐름 검증
- "클릭 생성 → 리스너 감지 → 이벤트 수집" 전체 파이프라인 테스트

### 키보드 이벤트 시뮬레이션

```python
from pynput.keyboard import Controller, Key

def test_keyboard_events_captured():
    """실제 키보드 입력 이벤트가 수집되는지 검증"""
    collector = InputEventCollector()
    keyboard = Controller()

    collector.start()
    time.sleep(0.1)

    # 실제 키 입력 시뮬레이션
    keyboard.press('a')
    keyboard.release('a')

    time.sleep(0.2)
    collector.stop()

    events = collector.get_events()
    key_events = [e for e in events if e.event_type in [InputEventType.KEY_PRESS, InputEventType.KEY_RELEASE]]
    assert len(key_events) >= 2  # press + release
```

## 패턴 2: 여러 컴포넌트 통합

### ScreenCapture + InputEventCollector 통합

```python
def test_frames_and_events_have_consistent_timestamps():
    """프레임과 이벤트의 타임스탬프가 일관되는지 확인"""
    recorder = Recorder(fps=10)
    mouse = Controller()

    recorder.start()
    time.sleep(0.1)

    # 실제 마우스 클릭 시뮬레이션
    click_time = time.time()
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    session = recorder.stop()

    # 프레임과 이벤트가 모두 수집되었는지 확인
    assert len(session.frames) > 0
    assert len(session.events) > 0

    # 클릭 이벤트 확인
    click_events = [e for e in session.events if e.event_type == InputEventType.MOUSE_CLICK]
    assert len(click_events) >= 1

    # 타임스탬프 범위 확인
    frame_timestamps = [f.timestamp for f in session.frames]

    # 클릭 이벤트의 타임스탬프가 프레임 타임스탬프 범위 내에 있는지
    for click_event in click_events:
        assert min(frame_timestamps) <= click_event.timestamp <= max(frame_timestamps)
```

**핵심 포인트**:
- ScreenCapture와 InputEventCollector가 함께 동작하는지 검증
- 서로 다른 컴포넌트의 타임스탬프가 동기화되는지 확인
- End-to-End 워크플로우 검증

### InputEventCollector + WindowInfoCollector 통합

```python
def test_input_collector_captures_window_info():
    """실제 마우스 클릭 시 윈도우 정보가 포함되는지 확인 (통합 테스트)

    PRD F-03 Pass 조건: app_name 필드 존재
    """
    collector = InputEventCollector()
    mouse = Controller()

    # 콜백으로 이벤트를 수집
    events_collected = []

    def collect_event(event):
        events_collected.append(event)

    collector.add_callback(collect_event)

    # 실제 리스너 시작
    collector.start()
    time.sleep(0.1)

    # ✅ 실제 마우스 클릭 시뮬레이션 (시스템 이벤트 발생)
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    collector.stop()

    # 클릭 이벤트가 수집되었는지 확인 (F-02)
    assert len(events_collected) >= 1

    # 클릭 이벤트 추출
    click_events = [e for e in events_collected if e.event_type == InputEventType.MOUSE_CLICK]
    assert len(click_events) >= 1

    event = click_events[0]

    # F-03 Pass 조건: window_info 필드 존재
    assert hasattr(event, "window_info")

    # macOS에서 실행 중이면 app_name도 확인 (F-03 Pass 조건)
    if event.window_info:
        assert hasattr(event.window_info, "app_name")
        assert event.window_info.app_name is not None
        print(f"✓ 윈도우 정보 수집 성공: {event.window_info.app_name}")
    else:
        print("⚠ WindowInfo가 None (macOS가 아니거나 권한 없음)")
```

**핵심 포인트**:
- 실제 클릭 → pynput 감지 → WindowInfo 수집 → 이벤트 저장 전체 흐름 검증
- PRD Pass 조건을 명확히 검증
- 내부 메서드(`_emit_event`)를 사용하지 않고 실제 흐름 테스트

## 패턴 3: 실제 시스템 리소스 사용

### 화면 캡처 테스트

```python
def test_capture_frame_returns_valid_frame():
    """실제 화면을 캡처하여 유효한 Frame 반환"""
    capture = ScreenCapture()

    with capture.session():
        frame = capture.capture_frame()

        # Frame 검증
        assert frame is not None
        assert hasattr(frame, "timestamp")
        assert hasattr(frame, "image")
        assert isinstance(frame.timestamp, float)
        assert isinstance(frame.image, np.ndarray)

        # RGB 이미지 (H, W, 3)
        assert frame.image.ndim == 3
        assert frame.image.shape[2] == 3
        assert frame.height > 0
        assert frame.width > 0
```

**핵심 포인트**:
- mss 라이브러리를 사용하여 실제 화면 캡처
- 시스템의 실제 화면을 사용하므로 통합 테스트
- Mock 없이 실제 리소스 사용

### 데이터베이스 통합 테스트

```python
def test_save_observation_to_supabase():
    """실제 Supabase DB에 observation 저장"""
    repo = ObservationRepository()

    observation = Observation(
        session_id=test_session_id,
        timestamp=time.time(),
        screenshot_path="test.png",
        events=[],
    )

    # 실제 DB에 저장
    saved = repo.save(observation)

    # 저장된 데이터 검증
    assert saved.id is not None

    # 실제 DB에서 읽기
    loaded = repo.get(saved.id)
    assert loaded.session_id == test_session_id

    # 정리
    repo.delete(saved.id)
```

**핵심 포인트**:
- 실제 Supabase DB 연결 사용
- Mock DB가 아닌 실제 환경에서 테스트
- 데이터 정합성 검증

## 패턴 4: PRD Pass 조건 검증

### F-01: Screenshot Capture 검증

```python
def test_screenshot_capture_pass_condition():
    """PRD F-01 Pass 조건: Before/After 이미지 파일 저장"""
    recorder = Recorder(fps=10)

    session = recorder.record(duration=0.5)

    # F-01 Pass 조건: 프레임이 캡처되어야 함
    assert len(session.frames) >= 3

    # 모든 프레임에 유효한 이미지 데이터가 있는지 확인
    for frame in session.frames:
        assert frame.timestamp > 0
        assert isinstance(frame.image, np.ndarray)
        assert frame.image.ndim == 3
        assert frame.image.shape[2] == 3
```

### F-02: Mouse Event Capture 검증

```python
def test_mouse_event_capture_pass_condition():
    """PRD F-02 Pass 조건: Event JSON 저장"""
    collector = InputEventCollector()
    mouse = Controller()

    collector.start()
    time.sleep(0.1)

    # 실제 마우스 클릭
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    collector.stop()

    events = collector.get_events()

    # F-02 Pass 조건: 이벤트가 수집되어야 함
    assert len(events) >= 1

    # 이벤트 JSON 직렬화 가능 여부 확인
    import json
    event_dict = events[0].__dict__
    json_str = json.dumps(event_dict, default=str)
    assert len(json_str) > 0
```

### F-03: Window Info 검증

```python
def test_window_info_capture_pass_condition():
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

    # F-03 Pass 조건: window_info 필드 존재
    assert hasattr(event, "window_info")

    # macOS에서는 app_name 확인
    if event.window_info:
        assert hasattr(event.window_info, "app_name")
        assert event.window_info.app_name is not None
```

**핵심 포인트**:
- PRD 문서의 Pass 조건을 그대로 검증
- 실제 환경에서만 검증 가능한 조건들
- 주석에 PRD 번호(F-01, F-02, F-03) 명시

## 패턴 5: 시간 기반 동작 검증

### FPS 준수 확인

```python
def test_capture_continuous_respects_fps():
    """연속 캡처가 FPS를 준수하는지 확인"""
    fps = 10
    capture = ScreenCapture(fps=fps)

    with capture.session():
        timestamps = []
        for frame in capture.capture_continuous():
            timestamps.append(frame.timestamp)

            # 5개 프레임 캡처
            if len(timestamps) >= 5:
                break

        # 프레임 간 시간 차이 검증 (오차 허용)
        for i in range(1, len(timestamps)):
            interval = timestamps[i] - timestamps[i - 1]
            expected_interval = 1.0 / fps
            # 50% 오차 허용 (시스템 부하 고려)
            assert abs(interval - expected_interval) < expected_interval * 0.5
```

**핵심 포인트**:
- 실제 시간 흐름을 검증
- 시스템 부하를 고려한 오차 허용
- time.sleep()을 사용한 실제 대기

### Duration 검증

```python
def test_session_duration_matches_recording_time():
    """세션 duration이 실제 녹화 시간과 일치하는지 확인"""
    recorder = Recorder(fps=10)

    expected_duration = 0.5
    session = recorder.record(duration=expected_duration)

    # 오차 허용 (±20%)
    assert abs(session.duration - expected_duration) < expected_duration * 0.2
```

## 패턴 6: Context Manager 검증

```python
def test_collector_context_manager():
    """컨텍스트 매니저로 사용 (실제 리스너 사용)"""
    collector = InputEventCollector()

    with collector:
        assert collector._running
        time.sleep(0.1)

    # 컨텍스트 종료 후 중지됨
    assert not collector._running
```

**핵심 포인트**:
- 실제 리스너 시작/종료 검증
- 리소스 정리 확인

## 언제 통합 테스트를 사용하는가

### 적합한 경우

- ✅ 여러 컴포넌트 간 상호작용
- ✅ 시스템 리소스 사용 (마우스, 화면, DB, 파일)
- ✅ End-to-End 워크플로우
- ✅ PRD Pass 조건 검증
- ✅ 타임스탬프 동기화 검증
- ✅ 실제 사용 시나리오

### 부적합한 경우

- ❌ 순수 로직 검증 (알고리즘)
- ❌ 에러 핸들링만 검증
- ❌ 내부 상태만 검증
- ❌ 빠른 피드백이 필요한 경우

## 일반적인 안티패턴

### ❌ 통합 테스트에서 내부 메서드 호출

```python
# ❌ 잘못된 통합 테스트
def test_input_collector_with_window():
    collector = InputEventCollector()

    with collector:  # ✅ 리스너 시작 (통합 테스트)
        test_event = InputEvent(...)
        collector._emit_event(test_event)  # ❌ 내부 메서드 호출 (단위 테스트 방식)
```

**문제점**:
- 리스너를 시작했지만 실제로 사용하지 않음
- 실제 시스템 이벤트 흐름을 우회
- 통합 테스트의 목적에 부합하지 않음

**해결책**:
```python
# ✅ 올바른 통합 테스트
def test_input_collector_with_window():
    from pynput.mouse import Button, Controller

    collector = InputEventCollector()
    mouse = Controller()  # ✅ 실제 Controller

    collector.start()
    time.sleep(0.1)

    # ✅ 실제 마우스 클릭 시뮬레이션
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    collector.stop()

    events = collector.get_events()
    assert len(events) >= 1
```

### ❌ Mock 사용

```python
# ❌ 통합 테스트에서 Mock 사용
def test_recorder_with_mock():
    recorder = Recorder()

    # ❌ Mock 사용 (통합 테스트에서는 부적절)
    mock_capture = Mock()
    recorder._screen_capture = mock_capture

    recorder.start()
    recorder.stop()
```

**문제점**:
- Mock을 사용하면 실제 통합을 검증할 수 없음
- 통합 테스트의 목적에 부합하지 않음

## 주요 원칙

1. **Real Resources**: 실제 시스템 리소스 사용
2. **No Mocks**: Mock 사용 금지
3. **Public API**: 공개 API만 사용
4. **End-to-End**: 전체 워크플로우 검증
5. **Realistic Scenarios**: 실제 사용 시나리오 테스트

## time.sleep() 사용 가이드

통합 테스트에서 `time.sleep()`은 필수적입니다:

```python
collector.start()
time.sleep(0.1)  # ✅ 리스너가 완전히 시작될 시간 확보

mouse.click(Button.left, 1)

time.sleep(0.2)  # ✅ 이벤트가 처리될 시간 확보
collector.stop()
```

**권장 대기 시간**:
- 리스너 시작 후: 0.1초
- 이벤트 발생 후: 0.2초
- 연속 작업 간: 0.05초

## 요약

통합 테스트는:
- 여러 컴포넌트를 실제로 연결해서 테스트
- 실제 시스템 리소스 사용 (Mock 없음)
- 공개 API만 사용 (내부 메서드 호출 금지)
- 느리지만 실제 동작을 검증
- PRD Pass 조건 검증에 필수적
