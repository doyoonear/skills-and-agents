#!/bin/bash
# mission-status.sh — 상태 조회 + 불일치 검사
# Usage: mission-status.sh <mission-slug>
#
# 1. materializer 실행 (state.json 최신화)
# 2. 포맷팅된 상태 테이블 출력
# 3. 불일치 검사 실행 (§13 규칙)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq가 필요합니다: brew install jq" >&2
  exit 1
fi

SLUG="${1:-}"

if [ -z "$SLUG" ]; then
  # slug 미지정 시 활성 미션 탐색
  MISSIONS_TMP=$(mktemp)
  trap "rm -f '$MISSIONS_TMP'" EXIT
  for dir in docs/mission-*/; do
    [ -d "$dir" ] || continue
    [ -f "$dir/mission.json" ] || continue
    slug_name=$(basename "$dir" | sed 's/^mission-//')
    echo "$slug_name" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' || continue
    echo "$slug_name" >> "$MISSIONS_TMP"
  done

  MISSION_COUNT=0
  if [ -s "$MISSIONS_TMP" ]; then
    MISSION_COUNT=$(wc -l < "$MISSIONS_TMP" | tr -d ' ')
  fi

  if [ "$MISSION_COUNT" -eq 0 ]; then
    echo "활성 미션이 없습니다."
    rm -f "$MISSIONS_TMP"
    exit 0
  fi

  if [ "$MISSION_COUNT" -eq 1 ]; then
    SLUG=$(head -1 "$MISSIONS_TMP")
  else
    echo "활성 미션 목록:"
    while read -r m; do
      [ -z "$m" ] && continue
      title=$(jq -r '.title' "docs/mission-${m}/mission.json")
      echo "  - $m: $title"
    done < "$MISSIONS_TMP"
    echo ""
    echo "사용법: mission-status.sh <slug>"
    rm -f "$MISSIONS_TMP"
    exit 0
  fi
  rm -f "$MISSIONS_TMP"
fi

if ! echo "$SLUG" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
  echo "Invalid slug: '$SLUG'" >&2
  exit 1
fi

MISSION_DIR="docs/mission-${SLUG}"

if [ ! -f "$MISSION_DIR/mission.json" ]; then
  echo "Mission not found: $MISSION_DIR" >&2
  exit 1
fi

# ---- 1. Materializer 실행 ----

"$SCRIPT_DIR/mission-materialize.sh" "$SLUG" >/dev/null 2>&1 || true

if [ ! -f "$MISSION_DIR/state.json" ]; then
  echo "state.json 생성 실패" >&2
  exit 1
fi

STATE=$(cat "$MISSION_DIR/state.json")
MISSION=$(cat "$MISSION_DIR/mission.json")

# ---- 2. 추가 불일치 검사 ----

EXTRA_WARNINGS="[]"

# 2a. STALE_STATE 검사 (updatedAt이 10분 이상 오래됨)
# state.json은 방금 materialize했으므로 이 검사는 re-materialize 전 상태에 대한 것
# 여기서는 skip (materializer가 방금 실행됨)

# 2b. ORPHAN_HANDOFF 검사
if [ -d "$MISSION_DIR/handoffs" ]; then
  for hf in "$MISSION_DIR/handoffs"/session-*.md; do
    [ -f "$hf" ] || continue
    hf_name=$(basename "$hf" .md)
    # session-{sessionId} 형식에서 sessionId 추출
    session_id=$(echo "$hf_name" | sed 's/^session-//')

    # 해당 세션의 session.ended 이벤트가 있는지 확인
    has_ended="false"
    event_file="$MISSION_DIR/events/session-${session_id}.jsonl"
    if [ -f "$event_file" ]; then
      if grep -q '"session.ended"' "$event_file" 2>/dev/null; then
        has_ended="true"
      fi
    fi

    if [ "$has_ended" = "false" ]; then
      EXTRA_WARNINGS=$(echo "$EXTRA_WARNINGS" | jq \
        --arg sid "$session_id" \
        --arg now "$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')" \
        '. + [{
          code: "ORPHAN_HANDOFF",
          severity: "info",
          active: true,
          taskId: null,
          sessionIds: [$sid],
          firstSeenAt: $now,
          lastSeenAt: $now,
          message: ("Handoff file exists for " + $sid + " but no session.ended event")
        }]')
    fi
  done
fi

# 2c. DONE_NO_HANDOFF 검사
DONE_SESSIONS=$(echo "$STATE" | jq -r '
  [.tasks | to_entries[] | select(.value.status == "done") | .value.owner] | unique[]
')

for sid in $DONE_SESSIONS; do
  [ -z "$sid" ] && continue
  [ "$sid" = "null" ] && continue
  if [ ! -f "$MISSION_DIR/handoffs/session-${sid}.md" ]; then
    EXTRA_WARNINGS=$(echo "$EXTRA_WARNINGS" | jq \
      --arg sid "$sid" \
      --arg now "$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')" \
      '. + [{
        code: "DONE_NO_HANDOFF",
        severity: "info",
        active: true,
        taskId: null,
        sessionIds: [$sid],
        firstSeenAt: $now,
        lastSeenAt: $now,
        message: ("Session " + $sid + " completed tasks but has no handoff file")
      }]')
  fi
done

# 기존 warnings + 추가 warnings 병합 (중복 제거)
ALL_WARNINGS=$(echo "$STATE" | jq --argjson extra "$EXTRA_WARNINGS" '
  .warnings + $extra | unique_by([.code, .taskId, (.sessionIds | sort | join(","))])
')

# ---- 3. 포맷팅된 출력 ----

TITLE=$(echo "$MISSION" | jq -r '.title')
DESC=$(echo "$MISSION" | jq -r '.description')

echo "# Mission: ${SLUG}"
echo "  ${TITLE}"
echo "  ${DESC}"
echo ""

# 태스크 상태 테이블
echo "## 태스크 상태"
echo ""

echo "$STATE" | jq -r '
  .tasks | to_entries | sort_by(.key)[] |
  (
    if .value.status == "done" then "  ✅"
    elif .value.status == "in_progress" then "  🔄"
    elif .value.status == "claimed" then "  🔒"
    else "  ⏳" end
  ) + " " + .key + ": " + (
    if .value.status == "done" then "done"
    elif .value.status == "in_progress" then
      "in_progress" + (if .value.lastProgress.step then " (" + .value.lastProgress.step + ")" else "" end)
    elif .value.status == "claimed" then "claimed"
    else "open" end
  ) + " | " + (
    if .value.ownerLabel then .value.ownerLabel else "-" end
  ) + (
    if .value.blocked then " | 🚫 " + (.value.blockedReason // "blocked") else "" end
  ) + (
    if .value.ready == false and (.value.blockedByTaskIds | length) > 0 then
      " | ⏳ blocked by " + (.value.blockedByTaskIds | join(", "))
    else "" end
  )
'

echo ""

# 활성 세션
echo "## 활성 세션"
echo ""

ACTIVE_COUNT=$(echo "$STATE" | jq '.activeSessions | length')
if [ "$ACTIVE_COUNT" -eq 0 ]; then
  echo "  (없음)"
else
  echo "$STATE" | jq -r '
    .activeSessions[] |
    "  👤 " + .sessionLabel + " (" + .sessionId + ") | 마지막: " + (.lastActivity // "-")
  '
fi

echo ""

# 경고
ACTIVE_WARNINGS=$(echo "$ALL_WARNINGS" | jq '[.[] | select(.active == true)]')
WARN_COUNT=$(echo "$ACTIVE_WARNINGS" | jq 'length')

if [ "$WARN_COUNT" -gt 0 ]; then
  echo "## 경고 (${WARN_COUNT}건)"
  echo ""
  echo "$ACTIVE_WARNINGS" | jq -r '.[] |
    "  " + (
      if .severity == "error" then "❌"
      elif .severity == "warning" then "⚠️"
      else "ℹ️" end
    ) + " [" + .code + "] " + .message
  '
  echo ""
fi

# Ready 태스크 안내
READY_TASKS=$(echo "$STATE" | jq -r '
  [.tasks | to_entries[] | select(.value.ready == true and .value.status == "open")] |
  if length > 0 then
    "## 작업 가능한 태스크\n\n" + (
      [.[] | "  → " + .key + ": " + (.value | if .blocked then "(blocked) " else "" end)] | join("\n")
    )
  else "" end
')

if [ -n "$READY_TASKS" ]; then
  echo -e "$READY_TASKS"
  echo ""
fi

echo "---"
echo "Updated: $(echo "$STATE" | jq -r '.updatedAt')"
