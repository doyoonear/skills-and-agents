#!/bin/bash
# mission-compact.sh — Compaction + 스냅샷 생성
# 완료 태스크에 대한 mission.compact 이벤트를 발행하고 스냅샷을 생성합니다.
# materializer가 compact 이벤트를 처리하여 archivedTasks로 이동합니다.
# Usage: mission-compact.sh <mission-slug> [session-id]
#
# 원본 이벤트는 보존합니다 (삭제하지 않음).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq &>/dev/null; then
  echo "jq가 필요합니다: brew install jq" >&2
  exit 1
fi

SLUG="${1:-}"
SESSION_ID="${2:-auto}"

if [ -z "$SLUG" ]; then
  echo "Usage: mission-compact.sh <mission-slug> [session-id]" >&2
  exit 1
fi

MISSION_DIR="docs/mission-${SLUG}"

if [ ! -f "$MISSION_DIR/mission.json" ]; then
  echo "Mission not found: $MISSION_DIR" >&2
  exit 1
fi

# Materializer 실행으로 최신 state 확보
"$SCRIPT_DIR/mission-materialize.sh" "$SLUG" >/dev/null 2>&1 || true

if [ ! -f "$MISSION_DIR/state.json" ]; then
  echo "state.json not found" >&2
  exit 1
fi

STATE=$(cat "$MISSION_DIR/state.json")
MISSION=$(cat "$MISSION_DIR/mission.json")

# 완료 태스크 수 확인 (이미 archived된 것 제외)
DONE_COUNT=$(echo "$STATE" | jq '[.tasks | to_entries[] | select(.value.status == "done")] | length')
THRESHOLD=5

if [ "$DONE_COUNT" -lt "$THRESHOLD" ]; then
  echo "Compaction not needed: only ${DONE_COUNT} done tasks (threshold: ${THRESHOLD})"
  exit 0
fi

echo "Compacting ${DONE_COUNT} done tasks..."

# 1. 완료 태스크의 archived 메타데이터 구성
ARCHIVED_META=$(echo "$STATE" | jq -c --argjson mission "$MISSION" '
  [.tasks | to_entries[] | select(.value.status == "done") |
    {
      key: .key,
      value: {
        title: ($mission.tasks[.key].title // .key),
        doneAt: .value.doneAt,
        owner: .value.owner,
        summary: .value.summary
      }
    }
  ] | from_entries
')

DONE_TASK_IDS=$(echo "$STATE" | jq -c '[.tasks | to_entries[] | select(.value.status == "done") | .key]')

# 2. mission.compact 이벤트 발행 (archived 메타 포함)
"$SCRIPT_DIR/mission-event.sh" "$SLUG" "$SESSION_ID" mission.compact "" \
  "{\"tasks\":${DONE_TASK_IDS},\"archived\":${ARCHIVED_META},\"summary\":\"Compacted ${DONE_COUNT} done tasks\"}"

# 3. 스냅샷 생성 — materializer 재실행 후 현재 state를 스냅샷
"$SCRIPT_DIR/mission-materialize.sh" "$SLUG" >/dev/null 2>&1 || true

mkdir -p "$MISSION_DIR/snapshots"
SNAP_NAME="state-$(date '+%Y%m%d-%H%M').json"
cp "$MISSION_DIR/state.json" "$MISSION_DIR/snapshots/${SNAP_NAME}"

# 4. mission.snapshot 이벤트 발행
"$SCRIPT_DIR/mission-event.sh" "$SLUG" "$SESSION_ID" mission.snapshot "" \
  "{\"path\":\"snapshots/${SNAP_NAME}\"}"

# 5. 최종 Materializer 재실행 (DASHBOARD.md 갱신)
"$SCRIPT_DIR/mission-materialize.sh" "$SLUG" >/dev/null 2>&1 || true

echo "Compaction complete:"
echo "  - ${DONE_COUNT} tasks archived"
echo "  - Snapshot: snapshots/${SNAP_NAME}"
echo "  - Original events preserved"
