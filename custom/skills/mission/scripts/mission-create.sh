#!/bin/bash
# mission-create.sh — 미션 디렉토리 + mission.json 생성
# Usage: mission-create.sh <slug> <title> <description> [tasks_json]
#   tasks_json: jq-compatible JSON string of tasks object
#
# Example:
#   mission-create.sh my-feature "Feature Title" "Description" \
#     '{"T1":{"title":"Task 1","description":"","dependsOn":[]}}'

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "jq가 필요합니다: brew install jq" >&2
  exit 1
fi

SLUG="${1:-}"
TITLE="${2:-}"
DESC="${3:-}"
TASKS_JSON="${4-"{}"}"

if [ -z "$SLUG" ] || [ -z "$TITLE" ]; then
  echo "Usage: mission-create.sh <slug> <title> <description> [tasks_json]" >&2
  exit 1
fi

# slug 유효성 검증: [a-z0-9-] 패턴만 허용
if ! echo "$SLUG" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
  echo "Invalid slug: '$SLUG' (허용: [a-z0-9-], 시작/끝은 영숫자)" >&2
  exit 1
fi

MISSION_DIR="docs/mission-${SLUG}"

# 중복 미션 방지
if [ -d "$MISSION_DIR" ]; then
  echo "Mission directory already exists: $MISSION_DIR" >&2
  exit 1
fi

MISSION_ID="mission_${SLUG//-/_}"
CREATED_AT=$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')

# tasks_json 유효성 검증
if ! echo "$TASKS_JSON" | jq empty 2>/dev/null; then
  echo "Invalid tasks JSON" >&2
  exit 1
fi

# 순환 의존성 검증 (위상 정렬 — jq로 구현)
CYCLE_CHECK=$(echo "$TASKS_JSON" | jq -r '
  # Build adjacency list from dependsOn
  . as $tasks |
  [keys[]] as $all_ids |

  # Kahn algorithm: find nodes with in-degree 0, remove them iteratively
  { remaining: $tasks, sorted: [], changed: true } |
  until(.changed == false;
    .changed = false |
    .remaining as $rem |
    reduce ($rem | keys[]) as $id (.;
      if ($rem[$id].dependsOn // [] | map(select(. as $dep | $rem | has($dep))) | length) == 0
      then
        .sorted += [$id] |
        .remaining = (.remaining | del(.[$id])) |
        .changed = true
      else .
      end
    )
  ) |
  if (.remaining | keys | length) > 0
  then "CYCLE:" + (.remaining | keys | join(","))
  else "OK"
  end
')

if [ "${CYCLE_CHECK%%:*}" = "CYCLE" ]; then
  echo "Circular dependency detected in tasks: ${CYCLE_CHECK#CYCLE:}" >&2
  exit 1
fi

# 존재하지 않는 의존성 참조 검증
INVALID_DEPS=$(echo "$TASKS_JSON" | jq -r '
  . as $tasks |
  [keys[]] as $all_ids |
  [
    to_entries[] |
    .key as $id |
    (.value.dependsOn // [])[] |
    select(. as $dep | $all_ids | index($dep) | not) |
    "\($id) -> \(.)"
  ] |
  if length > 0 then join(", ") else "OK" end
')

if [ "$INVALID_DEPS" != "OK" ]; then
  echo "Invalid dependency references: $INVALID_DEPS" >&2
  exit 1
fi

# 디렉토리 구조 생성
mkdir -p "$MISSION_DIR/events"
mkdir -p "$MISSION_DIR/snapshots"
mkdir -p "$MISSION_DIR/handoffs"

# mission.json 생성
jq -n \
  --argjson schema 1 \
  --arg missionId "$MISSION_ID" \
  --arg title "$TITLE" \
  --arg desc "$DESC" \
  --arg createdAt "$CREATED_AT" \
  --argjson tasks "$TASKS_JSON" \
  '{
    schemaVersion: $schema,
    missionId: $missionId,
    title: $title,
    description: $desc,
    createdAt: $createdAt,
    tasks: $tasks
  }' > "$MISSION_DIR/mission.json"

echo "Mission created: $MISSION_DIR"
echo "  missionId: $MISSION_ID"
echo "  title: $TITLE"
echo "  tasks: $(echo "$TASKS_JSON" | jq 'keys | length') task(s)"
