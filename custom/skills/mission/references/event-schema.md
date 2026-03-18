# Event Schema Reference

## 공통 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `id` | string | yes | `evt_{YYYYMMDD}_{shortId}_{seq}` |
| `ts` | ISO 8601 | yes | 이벤트 발생 시각 (관찰용) |
| `missionId` | string | yes | 소속 미션 ID |
| `taskId` | string? | no | 대상 태스크 (세션 이벤트는 null) |
| `sessionId` | string | yes | 이벤트를 발생시킨 세션 |
| `type` | string | yes | 이벤트 타입 |
| `seq` | number | yes | 세션 내 순서 번호 (monotonic) |
| `payload` | object | yes | 이벤트별 추가 데이터 |
| `causedBy` | string? | no | 선행 이벤트 ID (인과 추적) |

## 이벤트 타입별 스키마

### session.started

세션이 미션에 참여할 때 발행.

```json
{
  "type": "session.started",
  "taskId": null,
  "payload": {
    "goal": "Phase 2 진행",
    "label": "claude-a"
  }
}
```

### session.ended

세션이 미션에서 이탈할 때 발행.

```json
{
  "type": "session.ended",
  "taskId": null,
  "payload": {
    "handoff": "handoffs/session-claude-20260318-a1b2.md"
  }
}
```

### task.claimed

태스크를 선점할 때 발행.

```json
{
  "type": "task.claimed",
  "taskId": "T1",
  "payload": {}
}
```

### task.progress

진행 상황을 업데이트할 때 발행.

```json
{
  "type": "task.progress",
  "taskId": "T1",
  "payload": {
    "step": "2/4",
    "note": "API 연동 완료"
  }
}
```

### task.heartbeat

장시간 작업 중 활성 신호를 보낼 때 발행.

```json
{
  "type": "task.heartbeat",
  "taskId": "T1",
  "payload": {
    "note": "debugging"
  }
}
```

### task.done

태스크를 완료할 때 발행.

```json
{
  "type": "task.done",
  "taskId": "T1",
  "payload": {
    "summary": "Stripe SDK v7 적용"
  }
}
```

### task.released

선점을 자발적으로 해제할 때 발행.

```json
{
  "type": "task.released",
  "taskId": "T1",
  "payload": {
    "reason": "다른 작업 우선"
  }
}
```

### task.blocked

런타임 블로커 발생 시 발행.

```json
{
  "type": "task.blocked",
  "taskId": "T1",
  "payload": {
    "reason": "API 응답 스펙 확정 대기"
  }
}
```

### task.unblocked

런타임 블로커 해소 시 발행.

```json
{
  "type": "task.unblocked",
  "taskId": "T1",
  "payload": {
    "reason": "API 스펙 확정됨"
  }
}
```

### mission.compact

완료 태스크 압축 시 발행.

```json
{
  "type": "mission.compact",
  "taskId": null,
  "payload": {
    "tasks": ["T1", "T2"],
    "summary": "Phase 1 완료 태스크 압축"
  }
}
```

### mission.snapshot

스냅샷 생성 시 발행.

```json
{
  "type": "mission.snapshot",
  "taskId": null,
  "payload": {
    "path": "snapshots/state-20260318-1030.json"
  }
}
```

## Ordering 규칙

- **전역 정렬**: `ts` → `sessionId` 알파벳순 → `seq` 순
- **경합 판정**: `ts` → `sessionId` 알파벳순 (deterministic tiebreaker)

## Idempotency

- 같은 `id`의 이벤트는 한 번만 적용
- `seq`가 monotonic하지 않으면 skip (corrupted)
- 파싱 불가 줄은 skip + CORRUPTED_EVENT 경고
