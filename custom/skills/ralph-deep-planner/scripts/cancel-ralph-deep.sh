#!/bin/bash
# Ralph Deep Loop Cancel Script
# 진행 중인 Ralph Deep 세션을 취소합니다.
#
# 사용법:
#   ./cancel-ralph-deep.sh [--keep-logs] [--keep-handoff] [--keep-plan]
#
# 옵션:
#   --keep-logs: 진행 로그는 삭제하지 않음
#   --keep-handoff: 핸드오프 문서는 삭제하지 않음
#   --keep-plan: 계획 파일(docs/plans/)은 항상 보존 (기본값)

set -euo pipefail

RALPH_DIR=".ralph"
KEEP_LOGS=false
KEEP_HANDOFF=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --keep-logs)
      KEEP_LOGS=true
      shift
      ;;
    --keep-handoff)
      KEEP_HANDOFF=true
      shift
      ;;
    --keep-plan)
      # 계획 파일은 항상 보존하므로 무시
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ ! -d "$RALPH_DIR" ]]; then
  echo "Ralph 세션이 없습니다. (.ralph 디렉토리가 존재하지 않음)"
  exit 0
fi

TASK_SLUG=""
PLAN_FILE=""
if [[ -f "$RALPH_DIR/state.md" ]]; then
  echo "=== 현재 Ralph Deep 세션 정보 ==="
  CURRENT_ITER=$(grep '^iteration:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/iteration: *//' || echo "0")
  MAX_ITER=$(grep '^max_iterations:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/max_iterations: *//' || echo "?")
  PROMISE=$(grep '^completion_promise:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/completion_promise: *//' | tr -d '"' || echo "?")
  STARTED=$(grep '^started_at:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/started_at: *//' | tr -d '"' || echo "?")
  TASK_SLUG=$(grep '^task_slug:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/task_slug: *//' | tr -d '"' || echo "")
  PLANNER_TYPE=$(grep '^planner_type:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/planner_type: *//' | tr -d '"' || echo "standard")
  PLAN_FILE=$(grep '^plan_file:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/plan_file: *//' | tr -d '"' || echo "")

  echo "  - 진행: $CURRENT_ITER/$MAX_ITER 반복"
  echo "  - 완료 조건: $PROMISE"
  echo "  - 시작 시간: $STARTED"
  echo "  - Planner type: $PLANNER_TYPE"
  if [[ -n "$TASK_SLUG" ]]; then
    echo "  - Task slug: $TASK_SLUG"
  fi
  if [[ -n "$PLAN_FILE" ]]; then
    echo "  - 계획 파일: $PLAN_FILE (보존됨)"
  fi
  echo ""
fi

# 핸드오프 폴더 처리
if [[ -n "$TASK_SLUG" ]] && [[ "$KEEP_HANDOFF" == "false" ]]; then
  HANDOFF_DIR="docs/ralph-${TASK_SLUG}"
  if [[ -d "$HANDOFF_DIR" ]]; then
    rm -rf "$HANDOFF_DIR"
    echo "핸드오프 문서 삭제됨: $HANDOFF_DIR"
  fi
elif [[ -n "$TASK_SLUG" ]] && [[ "$KEEP_HANDOFF" == "true" ]]; then
  echo "핸드오프 문서 보존됨: docs/ralph-${TASK_SLUG}/HANDOFF.md"
fi

# 계획 파일은 항상 보존 (docs/plans/는 건드리지 않음)
if [[ -n "$PLAN_FILE" ]]; then
  echo "계획 파일 보존됨: $PLAN_FILE"
fi

# 로그 보존 여부에 따라 삭제
if [[ "$KEEP_LOGS" == "true" ]]; then
  rm -f "$RALPH_DIR/state.md" "$RALPH_DIR/prompt.md"
  echo "Ralph Deep 세션이 취소되었습니다. (로그 보존됨)"
  echo "로그 위치: $RALPH_DIR/progress.log"
else
  rm -rf "$RALPH_DIR"
  echo "Ralph Deep 세션이 취소되었습니다. (모든 파일 삭제됨)"
fi

if [[ "$KEEP_LOGS" == "true" ]] && [[ -f "$RALPH_DIR/progress.log" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] CANCELLED: Ralph Deep session cancelled by user" >> "$RALPH_DIR/progress.log"
fi
