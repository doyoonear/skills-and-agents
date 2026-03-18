#!/bin/bash
# mission-materialize.sh — Deterministic Materializer
# 모든 이벤트를 리플레이하여 state.json + DASHBOARD.md 생성
# Usage: mission-materialize.sh <mission-slug>

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "jq가 필요합니다: brew install jq" >&2
  exit 1
fi

# ---- DASHBOARD.md 생성 함수 (설계문서 §12 형식) ----
generate_dashboard() {
  local dir="$1"
  local state="$2"
  local mission="$3"

  local desc
  desc=$(echo "$mission" | jq -r '.description')
  local slug_name
  slug_name=$(basename "$dir" | sed 's/^mission-//')
  local updated
  updated=$(echo "$state" | jq -r '.updatedAt')

  {
    echo "# Mission: ${slug_name}"
    echo ""
    echo "> ${desc}"
    echo ""

    # 현재 상태 테이블
    echo "## 현재 상태"
    echo ""
    echo "| Task | 상태 | 담당 | 마지막 업데이트 | 비고 |"
    echo "|------|------|------|-------------|------|"

    echo "$state" | jq -r --argjson mission "$mission" '
      .tasks | to_entries | sort_by(.key)[] |
      select(.value.status != "archived") |
      .key as $id |
      ($mission.tasks[$id].title // $id) as $title |
      (
        if .value.status == "done" then "done"
        elif .value.status == "in_progress" then
          "in_progress" + (if .value.lastProgress.step then " (" + .value.lastProgress.step + ")" else "" end)
        elif .value.status == "claimed" then "claimed"
        else "open" end
      ) as $status_text |
      (
        if .value.status == "done" then "✅"
        elif .value.status == "in_progress" then "🔄"
        elif .value.status == "claimed" then "🔒"
        else "⏳" end
      ) as $icon |
      (
        (.value.lastActivity // "-") | if . != "-" then (split("T")[0] + " " + (split("T")[1] | split("+")[0] | split(".")[0] | .[0:5])) else "-" end
      ) as $time |
      (
        [
          (if .value.blocked then "blocked: " + (.value.blockedReason // "unknown") else null end),
          (if .value.ready == false and (.value.blockedByTaskIds | length) > 0 then
            "blocked by " + (.value.blockedByTaskIds | join(", "))
          else null end)
        ] | map(select(. != null)) | join("; ")
      ) as $notes |
      "| \($id): \($title) | \($icon) \($status_text) | \(.value.ownerLabel // "-") | \($time) | \($notes) |"
    '

    echo ""

    # 활성 세션
    echo "## 활성 세션"
    echo ""

    local active_count
    active_count=$(echo "$state" | jq '.activeSessions | length')
    if [ "$active_count" -eq 0 ]; then
      echo "(없음)"
    else
      echo "| 세션 | 현재 작업 | 마지막 활동 |"
      echo "|------|----------|------------|"
      echo "$state" | jq -r '
        .activeSessions[] |
        (.sessionId) as $sid |
        (
          [.] | . as $sessions |
          [$sessions[0]] | . as $s |
          (input_line_number // 0) | . as $dummy |
          $sid
        ) as $lookup_sid |
        (.lastActivity // "-") | if . != "-" then (split("T")[0] + " " + (split("T")[1] | split("+")[0] | split(".")[0] | .[0:5])) else "-" end |
        . as $time |
        "| \(.sessionLabel // $sid) (\($sid)) | - | \($time) |"
      ' 2>/dev/null || echo "$state" | jq -r '
        .activeSessions[] |
        "| \(.sessionLabel) (\(.sessionId)) | - | \(.lastActivity // "-") |"
      '
    fi

    echo ""

    # 경고
    local warn_count
    warn_count=$(echo "$state" | jq '[.warnings[] | select(.active == true)] | length')
    if [ "$warn_count" -gt 0 ]; then
      echo "## 경고"
      echo ""
      echo "$state" | jq -r '
        [.warnings[] | select(.active == true)][] |
        "- " + (
          if .severity == "error" then "ERROR"
          elif .severity == "warning" then "WARN"
          else "INFO" end
        ) + " [" + .code + "] " + .message
      '
      echo ""
    fi

    # Archived 태스크
    local archived_count
    archived_count=$(echo "$state" | jq '.archivedTasks | keys | length')
    if [ "$archived_count" -gt 0 ]; then
      echo "## 완료 요약 (archived)"
      echo ""
      echo "| Task | 완료 시각 | 담당 | 요약 |"
      echo "|------|----------|------|------|"
      echo "$state" | jq -r '
        .archivedTasks | to_entries | sort_by(.key)[] |
        "| \(.key): \(.value.title // "-") | \(.value.doneAt // "-") | \(.value.owner // "-") | \(.value.summary // "-") |"
      '
      echo ""
    fi

    echo "---"
    echo "*자동 생성: ${updated} | materializer v1*"
  } > "$dir/DASHBOARD.md"
}

# ---- 인자 파싱 ----

SLUG="${1:-}"

if [ -z "$SLUG" ]; then
  echo "Usage: mission-materialize.sh <mission-slug>" >&2
  exit 1
fi

if ! echo "$SLUG" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
  echo "Invalid slug: '$SLUG'" >&2
  exit 1
fi

MISSION_DIR="docs/mission-${SLUG}"

if [ ! -f "$MISSION_DIR/mission.json" ]; then
  echo "mission.json not found: $MISSION_DIR/mission.json" >&2
  exit 1
fi

# schemaVersion 검사
SCHEMA_VER=$(jq -r '.schemaVersion // 0' "$MISSION_DIR/mission.json")
if [ "$SCHEMA_VER" != "1" ]; then
  echo "SCHEMA_MISMATCH: mission.json schemaVersion=$SCHEMA_VER, materializer supports 1" >&2
  exit 1
fi

MISSION_JSON=$(cat "$MISSION_DIR/mission.json")

# ---- 1. 이벤트 수집 ----

EVENTS_DIR="$MISSION_DIR/events"
EVENTS_TMP=$(mktemp)
CORRUPTED_TMP=$(mktemp)

# 임시 파일 정리 보장
cleanup() {
  rm -f "$EVENTS_TMP" "$CORRUPTED_TMP"
}
trap cleanup EXIT

if [ -d "$EVENTS_DIR" ]; then
  for event_file in "$EVENTS_DIR"/session-*.jsonl; do
    [ -f "$event_file" ] || continue
    line_num=0
    while IFS= read -r line || [ -n "$line" ]; do
      line_num=$((line_num + 1))
      [ -z "$line" ] && continue
      if echo "$line" | jq empty 2>/dev/null; then
        echo "$line" >> "$EVENTS_TMP"
      else
        fname=$(basename "$event_file")
        echo "{\"file\":\"${fname}\",\"line\":${line_num}}" >> "$CORRUPTED_TMP"
      fi
    done < "$event_file"
  done
fi

# 이벤트가 없으면 빈 배열로 처리
if [ ! -s "$EVENTS_TMP" ]; then
  echo '[]' > "$EVENTS_TMP"
fi

# ---- 2. 스냅샷 기반 시작점 결정 ----

SNAPSHOT_BASE="null"
SNAPSHOTS_DIR="$MISSION_DIR/snapshots"

if [ -d "$SNAPSHOTS_DIR" ]; then
  LATEST_SNAPSHOT=""
  for snap in "$SNAPSHOTS_DIR"/state-*.json; do
    [ -f "$snap" ] || continue
    if [ -z "$LATEST_SNAPSHOT" ] || [ "$snap" \> "$LATEST_SNAPSHOT" ]; then
      LATEST_SNAPSHOT="$snap"
    fi
  done

  if [ -n "$LATEST_SNAPSHOT" ] && [ -f "$LATEST_SNAPSHOT" ]; then
    SNAPSHOT_BASE="\"$(basename "$LATEST_SNAPSHOT")\""
  fi
fi

# ---- 3. jq로 전체 상태 계산 (결정적) ----

NOW=$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')
STALE_TIMEOUT=1800

# stale claim을 위한 기준 시각 계산 (현재 - 30분, ISO 문자열)
if date -v -30M '+%Y-%m-%dT%H:%M:%S+00:00' >/dev/null 2>&1; then
  # macOS date
  STALE_THRESHOLD=$(date -u -v -${STALE_TIMEOUT}S '+%Y-%m-%dT%H:%M:%S+00:00')
else
  # GNU date fallback
  STALE_THRESHOLD=$(date -u -d "-${STALE_TIMEOUT} seconds" '+%Y-%m-%dT%H:%M:%S+00:00')
fi

STATE_JSON=$(jq -n \
  --argjson mission "$MISSION_JSON" \
  --slurpfile events "$EVENTS_TMP" \
  --arg now "$NOW" \
  --arg staleThreshold "$STALE_THRESHOLD" \
  --argjson snapshotBase "$SNAPSHOT_BASE" \
  '
  # Handle empty events (file contains just [])
  (if ($events | length) == 1 and ($events[0] | type) == "array"
   then []
   else $events end) as $raw_events |

  # Sort events globally: ts -> sessionId -> seq
  ($raw_events | sort_by([.ts, .sessionId, .seq])) as $sorted |

  # Deduplicate by event id
  ($sorted | unique_by(.id)) as $unique_events |

  # Initial task state from mission.json
  (reduce ($mission.tasks | to_entries[]) as $entry (
    {};
    .[$entry.key] = {
      status: "open",
      ready: (($entry.value.dependsOn // []) | length == 0),
      blocked: false,
      blockedByTaskIds: ($entry.value.dependsOn // []),
      blockedReason: null,
      owner: null,
      ownerLabel: null,
      claimedAt: null,
      doneAt: null,
      summary: null,
      lastProgress: null,
      lastActivity: null
    }
  )) as $initial_tasks |

  # Replay events
  (reduce $unique_events[] as $evt (
    {
      tasks: $initial_tasks,
      archivedTasks: {},
      sessions: {},
      lastEventIds: {},
      warnings: []
    };

    # Track last event per session
    .lastEventIds[$evt.sessionId] = $evt.id |

    # Track sessions
    (if $evt.type == "session.started" then
      .sessions[$evt.sessionId] = {
        sessionId: $evt.sessionId,
        sessionLabel: ($evt.payload.label // $evt.sessionId),
        startedAt: $evt.ts,
        endedAt: null,
        lastActivity: $evt.ts
      }
    elif $evt.type == "session.ended" then
      if .sessions[$evt.sessionId] != null then
        .sessions[$evt.sessionId].endedAt = $evt.ts |
        .sessions[$evt.sessionId].lastActivity = $evt.ts
      else . end
    else . end) |

    # Update session lastActivity for any event
    (if .sessions[$evt.sessionId] != null then
      .sessions[$evt.sessionId].lastActivity = $evt.ts
    else . end) |

    # Process task events
    (if $evt.taskId != null and .tasks[$evt.taskId] != null then
      (
        if $evt.type == "task.claimed" then
          if .tasks[$evt.taskId].status == "open" then
            .tasks[$evt.taskId].status = "claimed" |
            .tasks[$evt.taskId].owner = $evt.sessionId |
            .tasks[$evt.taskId].ownerLabel = (.sessions[$evt.sessionId].sessionLabel // $evt.sessionId) |
            .tasks[$evt.taskId].claimedAt = $evt.ts |
            .tasks[$evt.taskId].lastActivity = $evt.ts
          elif .tasks[$evt.taskId].owner != null and .tasks[$evt.taskId].owner != $evt.sessionId then
            .warnings += [{
              code: "DUPLICATE_CLAIM",
              severity: "warning",
              active: true,
              taskId: $evt.taskId,
              sessionIds: [$evt.sessionId, .tasks[$evt.taskId].owner],
              firstSeenAt: $evt.ts,
              lastSeenAt: $evt.ts,
              message: ("Task " + $evt.taskId + ": duplicate claim by " + $evt.sessionId + " (owner: " + (.tasks[$evt.taskId].owner // "none") + ")")
            }]
          else . end

        elif $evt.type == "task.progress" then
          if .tasks[$evt.taskId].owner == $evt.sessionId or .tasks[$evt.taskId].owner == null then
            .tasks[$evt.taskId].status = "in_progress" |
            .tasks[$evt.taskId].lastProgress = {
              step: ($evt.payload.step // null),
              note: ($evt.payload.note // null),
              ts: $evt.ts
            } |
            .tasks[$evt.taskId].lastActivity = $evt.ts |
            if .tasks[$evt.taskId].owner == null then
              .tasks[$evt.taskId].owner = $evt.sessionId |
              .tasks[$evt.taskId].ownerLabel = (.sessions[$evt.sessionId].sessionLabel // $evt.sessionId)
            else . end
          else . end

        elif $evt.type == "task.heartbeat" then
          .tasks[$evt.taskId].lastActivity = $evt.ts

        elif $evt.type == "task.done" then
          .tasks[$evt.taskId].status = "done" |
          .tasks[$evt.taskId].doneAt = $evt.ts |
          .tasks[$evt.taskId].summary = ($evt.payload.summary // null) |
          .tasks[$evt.taskId].lastActivity = $evt.ts

        elif $evt.type == "task.released" then
          .tasks[$evt.taskId].status = "open" |
          .tasks[$evt.taskId].owner = null |
          .tasks[$evt.taskId].ownerLabel = null |
          .tasks[$evt.taskId].claimedAt = null |
          .tasks[$evt.taskId].lastActivity = $evt.ts

        elif $evt.type == "task.blocked" then
          .tasks[$evt.taskId].blocked = true |
          .tasks[$evt.taskId].blockedReason = ($evt.payload.reason // null) |
          .tasks[$evt.taskId].lastActivity = $evt.ts

        elif $evt.type == "task.unblocked" then
          .tasks[$evt.taskId].blocked = false |
          .tasks[$evt.taskId].blockedReason = null |
          .tasks[$evt.taskId].lastActivity = $evt.ts

        else . end
      )
    elif $evt.type == "mission.compact" then
      # Move done tasks to archivedTasks
      reduce (($evt.payload.tasks // [])[]) as $tid (.;
        if .tasks[$tid] != null and .tasks[$tid].status == "done" then
          .archivedTasks[$tid] = (
            if $evt.payload.archived != null and $evt.payload.archived[$tid] != null then
              $evt.payload.archived[$tid] + { archivedAt: $evt.ts }
            else
              {
                title: ($mission.tasks[$tid].title // $tid),
                doneAt: .tasks[$tid].doneAt,
                owner: .tasks[$tid].owner,
                summary: .tasks[$tid].summary,
                archivedAt: $evt.ts
              }
            end
          ) |
          .tasks[$tid].status = "archived"
        else . end
      )
    else . end)
  )) as $state |

  # Recalculate ready + blockedByTaskIds based on current done/archived status
  ($state | reduce (.tasks | keys[]) as $tid (.;
    ($mission.tasks[$tid].dependsOn // []) as $deps |
    ([$deps[] | select(. as $d |
      $state.tasks[$d].status != "done" and $state.tasks[$d].status != "archived"
    )]) as $blocking |
    .tasks[$tid].ready = ($blocking | length == 0) |
    .tasks[$tid].blockedByTaskIds = $blocking
  )) as $final_state |

  # Build active sessions list
  ([$final_state.sessions | to_entries[] |
    select(.value.endedAt == null) |
    {
      sessionId: .value.sessionId,
      sessionLabel: .value.sessionLabel,
      lastActivity: .value.lastActivity
    }
  ]) as $active_sessions |

  # Stale claim detection (ISO string comparison)
  (reduce ($final_state.tasks | to_entries[]) as $entry (
    $final_state.warnings;
    if $entry.value.owner != null
       and $entry.value.status != "done"
       and $entry.value.lastActivity != null
       and ($entry.value.lastActivity < $staleThreshold)
    then
      . + [{
        code: "STALE_CLAIM",
        severity: "warning",
        active: true,
        taskId: $entry.key,
        sessionIds: [$entry.value.owner],
        firstSeenAt: $now,
        lastSeenAt: $now,
        message: ("Task " + $entry.key + ": no activity from " + $entry.value.owner + " since " + $entry.value.lastActivity)
      }]
    else . end
  )) as $all_warnings |

  # Build final state.json
  {
    schemaVersion: 1,
    missionId: $mission.missionId,
    updatedAt: $now,
    materializedFrom: {
      lastEventIds: $final_state.lastEventIds,
      snapshotBase: $snapshotBase
    },
    tasks: $final_state.tasks,
    archivedTasks: $final_state.archivedTasks,
    activeSessions: $active_sessions,
    warnings: $all_warnings
  }
')

# ---- 4. CORRUPTED_EVENT 경고 추가 ----

if [ -s "$CORRUPTED_TMP" ]; then
  CORRUPTED_JSON=$(jq -s '.' "$CORRUPTED_TMP")
  STATE_JSON=$(echo "$STATE_JSON" | jq \
    --argjson corrupted "$CORRUPTED_JSON" \
    --arg now "$NOW" \
    '.warnings += [
      $corrupted[] |
      {
        code: "CORRUPTED_EVENT",
        severity: "error",
        active: true,
        taskId: null,
        sessionIds: [],
        firstSeenAt: $now,
        lastSeenAt: $now,
        message: ("Corrupted event line in " + .file + " at line " + (.line | tostring))
      }
    ]')
fi

# ---- 5. 수렴 규칙 (동시 실행 안전) ----

NEW_LAST_IDS=$(echo "$STATE_JSON" | jq -c '.materializedFrom.lastEventIds')

SHOULD_WRITE=true
if [ -f "$MISSION_DIR/state.json" ]; then
  CURRENT_LAST_IDS=$(jq -c '.materializedFrom.lastEventIds // {}' "$MISSION_DIR/state.json" 2>/dev/null || echo '{}')

  IS_SUPERSET=$(jq -n \
    --argjson new_ids "$NEW_LAST_IDS" \
    --argjson cur_ids "$CURRENT_LAST_IDS" \
    '[$cur_ids | to_entries[] | select(.value as $v | $new_ids[.key] == null or $new_ids[.key] < $v)] | length == 0')

  if [ "$IS_SUPERSET" != "true" ]; then
    SHOULD_WRITE=false
    echo "Skipped write: more recent state already exists" >&2
  fi
fi

if [ "$SHOULD_WRITE" = "true" ]; then
  echo "$STATE_JSON" | jq '.' > "$MISSION_DIR/state.json.tmp"
  mv "$MISSION_DIR/state.json.tmp" "$MISSION_DIR/state.json"

  generate_dashboard "$MISSION_DIR" "$STATE_JSON" "$MISSION_JSON" 2>/dev/null || true

  echo "Materialized: $MISSION_DIR/state.json"
fi
