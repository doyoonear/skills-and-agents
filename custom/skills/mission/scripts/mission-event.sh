#!/bin/bash
# mission-event.sh — 범용 이벤트 기록기
# Usage: mission-event.sh <mission-slug> <session-id> <event-type> [task-id] [payload-json] [caused-by]
#
# session-id가 "new"이면 새 세션 ID를 자동 생성합니다.
# session-id가 "auto"이면 현재 터미널 세션에서 이전에 사용한 ID를 찾거나 새로 생성합니다.
#
# Examples:
#   mission-event.sh my-feature new session.started "" '{"goal":"Phase 1","label":"claude-a"}'
#   mission-event.sh my-feature claude-20260318-a1b2 task.claimed T1
#   mission-event.sh my-feature claude-20260318-a1b2 task.progress T1 '{"step":"2/4","note":"working"}'
#   mission-event.sh my-feature claude-20260318-a1b2 task.done T1 '{"summary":"completed"}'

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq가 필요합니다: brew install jq" >&2
  exit 1
fi

SLUG="${1:-}"
SESSION_ID="${2:-}"
EVENT_TYPE="${3:-}"
TASK_ID="${4:-}"
PAYLOAD_JSON="${5-"{}"}"

if [ -z "$SLUG" ] || [ -z "$SESSION_ID" ] || [ -z "$EVENT_TYPE" ]; then
  echo "Usage: mission-event.sh <mission-slug> <session-id|new|auto> <event-type> [task-id] [payload-json]" >&2
  exit 1
fi

# slug 유효성 검증
if ! echo "$SLUG" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
  echo "Invalid slug: '$SLUG'" >&2
  exit 1
fi

# session ID 유효성 검증 (new/auto 제외)
if [ "$SESSION_ID" != "new" ] && [ "$SESSION_ID" != "auto" ]; then
  if ! echo "$SESSION_ID" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9._-]*$'; then
    echo "Invalid session ID: '$SESSION_ID'" >&2
    exit 1
  fi
fi

# event type allowlist
VALID_TYPES="session.started session.ended task.claimed task.progress task.heartbeat task.done task.released task.blocked task.unblocked mission.compact mission.snapshot"
if ! echo " $VALID_TYPES " | grep -q " $EVENT_TYPE "; then
  echo "Unknown event type: '$EVENT_TYPE'" >&2
  exit 1
fi

# task ID 유효성 검증
if [ -n "$TASK_ID" ]; then
  if ! echo "$TASK_ID" | grep -qE '^[A-Za-z0-9_-]+$'; then
    echo "Invalid task ID: '$TASK_ID'" >&2
    exit 1
  fi
fi

# payload 크기 제한 (10KB)
if [ "${#PAYLOAD_JSON}" -gt 10240 ]; then
  echo "Payload too large: ${#PAYLOAD_JSON} bytes (max 10240)" >&2
  exit 1
fi

MISSION_DIR="docs/mission-${SLUG}"

if [ ! -d "$MISSION_DIR" ]; then
  echo "Mission not found: $MISSION_DIR" >&2
  exit 1
fi

if [ ! -f "$MISSION_DIR/mission.json" ]; then
  echo "mission.json not found in $MISSION_DIR" >&2
  exit 1
fi

MISSION_ID=$(jq -r '.missionId' "$MISSION_DIR/mission.json")

# 이벤트 디렉토리 방어적 생성
mkdir -p "$MISSION_DIR/events"

# 세션 ID 생성/해결
generate_session_id() {
  local date_part
  date_part=$(date '+%Y%m%d')
  local random_hex
  random_hex=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
  local new_id="claude-${date_part}-${random_hex}"

  # 중복 검사
  local attempt=0
  while [ -f "$MISSION_DIR/events/session-${new_id}.jsonl" ] && [ $attempt -lt 10 ]; do
    random_hex=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
    new_id="claude-${date_part}-${random_hex}"
    attempt=$((attempt + 1))
  done

  if [ -f "$MISSION_DIR/events/session-${new_id}.jsonl" ]; then
    echo "Failed to generate unique session ID after 10 attempts" >&2
    exit 1
  fi

  echo "$new_id"
}

if [ "$SESSION_ID" = "new" ]; then
  SESSION_ID=$(generate_session_id)
  echo "SESSION_ID=$SESSION_ID"
elif [ "$SESSION_ID" = "auto" ]; then
  # .mission-session 파일에서 현재 세션 ID 찾기
  SESSION_FILE="$MISSION_DIR/.session-current"
  if [ -f "$SESSION_FILE" ]; then
    SESSION_ID=$(cat "$SESSION_FILE")
  else
    SESSION_ID=$(generate_session_id)
    echo "$SESSION_ID" > "$SESSION_FILE"
    echo "SESSION_ID=$SESSION_ID"
  fi
fi

EVENT_FILE="$MISSION_DIR/events/session-${SESSION_ID}.jsonl"

# 현재 세션의 seq 계산 (현재 줄 수 + 1)
if [ -f "$EVENT_FILE" ]; then
  SEQ=$(wc -l < "$EVENT_FILE" | tr -d ' ')
  SEQ=$((SEQ + 1))
else
  SEQ=1
fi

# 이벤트 ID 생성
DATE_PART=$(date '+%Y%m%d')
SHORT_ID=$(echo "$SESSION_ID" | sed 's/.*-//')
EVENT_ID="evt_${DATE_PART}_${SHORT_ID}_$(printf '%03d' $SEQ)"

# 타임스탬프
TS=$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')

# payload 검증
if ! echo "$PAYLOAD_JSON" | jq empty 2>/dev/null; then
  echo "Invalid payload JSON: $PAYLOAD_JSON" >&2
  exit 1
fi

# 이벤트 JSON 생성 (한 줄) — 모든 값을 jq --arg로 안전하게 전달
EVENT=$(jq -c -n \
  --arg id "$EVENT_ID" \
  --arg ts "$TS" \
  --arg missionId "$MISSION_ID" \
  --arg sessionId "$SESSION_ID" \
  --arg type "$EVENT_TYPE" \
  --argjson seq "$SEQ" \
  --argjson payload "$PAYLOAD_JSON" \
  --arg taskIdRaw "$TASK_ID" \
  '{
    id: $id,
    ts: $ts,
    missionId: $missionId,
    taskId: (if $taskIdRaw == "" then null else $taskIdRaw end),
    sessionId: $sessionId,
    type: $type,
    seq: $seq,
    payload: $payload
  }')

# JSONL append
echo "$EVENT" >> "$EVENT_FILE"

echo "Event recorded: $EVENT_TYPE (seq=$SEQ, session=$SESSION_ID)"

# .session-current 업데이트 (auto 모드용)
echo "$SESSION_ID" > "$MISSION_DIR/.session-current"
