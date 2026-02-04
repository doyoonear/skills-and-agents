# shadow-py 프로젝트 실제 예시

이 문서는 shadow-py 프로젝트의 실제 테스트 코드 예시와 분류 기준을 설명합니다.

## 전체 테스트 파일 분류

| 파일 | 분류 | 이유 |
|------|------|------|
| test_input_events.py | 단위 | Mock 사용, _emit_event 직접 호출, 내부 로직만 검증 |
| test_keyframe.py | 단위 | 순수 로직만, numpy 배열로 가짜 데이터 생성 |
| test_screen.py | 통합 | 실제 mss로 화면 캡처 (시스템 리소스 사용) |
| test_window.py | 통합 | 실제 PyObjC로 윈도우 정보 가져옴 (시스템 리소스) |
| test_recorder.py | 통합 | ScreenCapture + InputEventCollector + 실제 pynput 클릭 |
| test_input_events_with_window.py | 통합 | InputEventCollector + WindowInfoCollector 통합 |
| test_supabase_integration.py | 통합 | 실제 Supabase DB 연결 |

## 단위 테스트 예시

### test_input_events.py

**특징**: Mock 사용, 내부 메서드 직접 호출, 빠른 실행

#### 1. 콜백 메커니즘 검증

```python
def test_callback_called_on_event():
    """이벤트 발생 시 콜백 호출"""
    collector = InputEventCollector()
    callback = Mock()  # ✅ Mock 사용

    collector.add_callback(callback)

    # ✅ 내부 메서드 직접 호출 (리스너 시작 없이)
    test_event = InputEvent(
        timestamp=time.time(),
        event_type=InputEventType.MOUSE_CLICK,
        x=100,
        y=100,
    )

    collector._emit_event(test_event)

    # 콜백이 호출되었는지 확인
    callback.assert_called_once()
    called_event = callback.call_args[0][0]
    assert called_event.event_type == InputEventType.MOUSE_CLICK
    assert called_event.x == 100
```

**분류 이유**:
- Mock을 사용하여 외부 의존성 제거
- `_emit_event()` 같은 내부 메서드를 직접 호출
- 콜백 메커니즘의 로직만 검증
- 실제 리스너 시작 없이 빠르게 실행

#### 2. 여러 콜백 동시 호출

```python
def test_multiple_callbacks():
    """여러 콜백 등록 및 호출"""
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

**분류 이유**:
- 여러 콜백이 모두 호출되는지 로직만 검증
- Mock으로 실제 콜백 함수 없이 테스트
- 내부 메커니즘만 검증

#### 3. 에러 핸들링

```python
def test_callback_error_does_not_stop_collection():
    """콜백 에러가 수집을 멈추지 않음"""
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

**분류 이유**:
- 에러 핸들링 로직만 검증
- 실제 리스너 없이 내부 메서드로 테스트
- 견고성(robustness) 확인

#### 4. 버퍼 관리

```python
def test_buffer_overflow_removes_old_events():
    """버퍼 가득 차면 오래된 이벤트 제거"""
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

**분류 이유**:
- 버퍼 관리 로직만 검증
- 내부 상태 검증
- 알고리즘의 정확성만 확인

### test_keyframe.py

**특징**: 순수 로직만, 가짜 데이터 생성, 알고리즘 검증

```python
def test_extract_pairs_with_single_click():
    """단일 클릭 이벤트에서 Before/After 프레임 쌍 추출"""
    # 고정된 base_time 사용
    base_time = 1000.0
    frames = [
        Frame(timestamp=base_time + 0.0, image=np.zeros((100, 100, 3), dtype=np.uint8)),
        Frame(timestamp=base_time + 0.1, image=np.zeros((100, 100, 3), dtype=np.uint8)),
        Frame(timestamp=base_time + 0.2, image=np.zeros((100, 100, 3), dtype=np.uint8)),
        Frame(timestamp=base_time + 0.5, image=np.zeros((100, 100, 3), dtype=np.uint8)),
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

    # After 프레임은 클릭 후
    assert pair.after_frame.timestamp >= pair.trigger_event.timestamp

    # 트리거 이벤트 확인
    assert pair.trigger_event.event_type == InputEventType.MOUSE_CLICK
    assert pair.trigger_event.timestamp == base_time + 0.15
```

**분류 이유**:
- numpy로 가짜 이미지 데이터 생성
- 실제 시스템 리소스 없이 알고리즘만 검증
- 키프레임 추출 로직의 정확성만 확인

## 통합 테스트 예시

### test_recorder.py (올바른 통합 테스트 패턴)

**특징**: ScreenCapture + InputEventCollector + 실제 pynput 클릭

#### 1. 이벤트 수집 검증

```python
def test_recorder_records_events():
    """녹화 중 이벤트가 수집되는지 확인 (실제 마우스 클릭)"""
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

**분류 이유**:
- pynput Controller로 실제 마우스 클릭 시뮬레이션
- Recorder = ScreenCapture + InputEventCollector 통합
- 실제 시스템 이벤트 흐름 검증
- "클릭 생성 → 리스너 감지 → 이벤트 수집" 전체 파이프라인 테스트

#### 2. 프레임과 이벤트 동기화

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

**분류 이유**:
- 여러 컴포넌트(ScreenCapture + InputEventCollector)의 동기화 검증
- 실제 타임스탬프 일관성 확인
- End-to-End 워크플로우 테스트

### test_input_events_with_window.py (수정 후)

**특징**: InputEventCollector + WindowInfoCollector 통합, PRD F-03 검증

#### Before (잘못된 통합 테스트)

```python
# ❌ 잘못된 통합 테스트
def test_input_collector_captures_window_info():
    collector = InputEventCollector()

    events_collected = []

    def collect_event(event):
        events_collected.append(event)

    collector.add_callback(collect_event)

    with collector:  # ✅ 리스너 시작 (통합 테스트)
        test_event = InputEvent(...)  # ❌ 가짜 이벤트 생성
        collector._emit_event(test_event)  # ❌ 내부 메서드 호출 (단위 테스트 방식)

    # ...
```

**문제점**:
- 리스너는 시작했지만 실제 시스템 이벤트를 사용하지 않음
- `_emit_event()` 내부 메서드를 직접 호출
- 실제 흐름 "클릭 → pynput 감지 → WindowInfo 수집 → 이벤트 저장"을 우회

#### After (올바른 통합 테스트)

```python
# ✅ 올바른 통합 테스트
def test_input_collector_captures_window_info():
    """실제 마우스 클릭 시 윈도우 정보가 포함되는지 확인 (통합 테스트)

    PRD F-03 Pass 조건: app_name 필드 존재
    """
    collector = InputEventCollector()
    mouse = Controller()  # ✅ pynput의 실제 Controller

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

**분류 이유**:
- pynput Controller로 실제 마우스 클릭
- 실제 WindowInfoCollector가 활성 윈도우 정보 수집
- PRD F-03 Pass 조건 검증
- 전체 통합 흐름 테스트

### test_screen.py

**특징**: 실제 mss로 화면 캡처

```python
def test_capture_frame_returns_valid_frame():
    """프레임 캡처가 유효한 Frame 객체를 반환하는지 확인"""
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

**분류 이유**:
- mss 라이브러리로 실제 화면 캡처
- 시스템의 실제 화면 사용
- Mock 없이 실제 리소스 사용

### test_supabase_integration.py

**특징**: 실제 Supabase DB 연결

```python
def test_save_and_retrieve_session():
    """세션 저장 및 조회 (실제 Supabase DB)"""
    repo = SessionRepository()

    session = Session(
        user_id="test_user",
        start_time=time.time(),
    )

    # 실제 DB에 저장
    saved = repo.save(session)

    # 저장된 데이터 검증
    assert saved.id is not None

    # 실제 DB에서 읽기
    loaded = repo.get(saved.id)
    assert loaded.user_id == "test_user"

    # 정리
    repo.delete(saved.id)
```

**분류 이유**:
- 실제 Supabase DB 연결 사용
- Mock DB가 아닌 실제 환경에서 테스트
- 데이터 정합성 검증

## PRD Pass 조건 검증 예시

### F-01: Screenshot Capture

```python
def test_recorder_captures_frames():
    """녹화 중 프레임이 캡처되는지 확인"""
    recorder = Recorder(fps=10)

    session = recorder.record(duration=0.5)

    # F-01 Pass 조건: 0.5초 동안 fps=10이면 약 5개 프레임 예상
    assert len(session.frames) >= 3
    assert len(session.frames) <= 10

    # 프레임 검증
    for frame in session.frames:
        assert frame.timestamp > 0
        assert isinstance(frame.image, np.ndarray)
        assert frame.image.ndim == 3
        assert frame.image.shape[2] == 3
```

### F-02: Mouse Event Capture

```python
def test_recorder_records_events():
    """녹화 중 이벤트가 수집되는지 확인 (실제 마우스 클릭)"""
    recorder = Recorder(fps=10)
    mouse = Controller()

    recorder.start()
    time.sleep(0.1)

    # 실제 마우스 클릭 시뮬레이션
    initial_position = mouse.position
    mouse.click(Button.left, 1)

    time.sleep(0.2)
    session = recorder.stop()

    # F-02 Pass 조건: 클릭 이벤트가 수집되었는지 확인
    assert len(session.events) >= 1
    click_events = [e for e in session.events if e.event_type == InputEventType.MOUSE_CLICK]
    assert len(click_events) >= 1
```

### F-03: Window Info

```python
def test_input_collector_captures_window_info():
    """실제 마우스 클릭 시 윈도우 정보가 포함되는지 확인

    PRD F-03 Pass 조건: app_name 필드 존재
    """
    collector = InputEventCollector()
    mouse = Controller()

    # ... (실제 클릭 시뮬레이션) ...

    event = click_events[0]

    # F-03 Pass 조건: window_info 필드 존재
    assert hasattr(event, "window_info")

    # macOS에서 실행 중이면 app_name도 확인
    if event.window_info:
        assert hasattr(event.window_info, "app_name")
        assert event.window_info.app_name is not None
```

## 핵심 교훈

### 1. 통합 테스트에서 내부 메서드 호출 금지

**❌ 잘못됨**:
```python
with collector:
    collector._emit_event(test_event)  # 내부 메서드 직접 호출
```

**✅ 올바름**:
```python
collector.start()
mouse.click(Button.left, 1)  # 실제 시스템 이벤트
collector.stop()
```

### 2. PRD Pass 조건은 통합 테스트로 검증

PRD 문서의 Pass 조건(F-01, F-02, F-03)은 실제 환경에서만 검증 가능:
- F-01: 실제 화면 캡처 필요
- F-02: 실제 마우스 이벤트 필요
- F-03: 실제 윈도우 정보 수집 필요

### 3. 테스트 분류 체크리스트

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

## 요약

| 측면 | 단위 테스트 (test_input_events.py) | 통합 테스트 (test_recorder.py) |
|------|-------------------------------------|-------------------------------|
| 예시 | test_callback_called_on_event | test_recorder_records_events |
| Mock | Mock() 사용 | 사용 안 함 |
| 내부 메서드 | _emit_event() 직접 호출 | 호출 안 함 |
| 시스템 이벤트 | 없음 | mouse.click() 사용 |
| 리스너 | 시작 안 함 | collector.start() |
| 검증 대상 | 콜백 메커니즘 로직 | 실제 이벤트 수집 흐름 |
| 속도 | 빠름 (ms) | 느림 (초) |
