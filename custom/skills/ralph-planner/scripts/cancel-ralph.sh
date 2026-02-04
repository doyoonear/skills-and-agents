#!/bin/bash
# Ralph Loop Cancel Script
# 진행 중인 Ralph 세션을 취소합니다.
#
# 사용법:
#   ./cancel-ralph.sh [--keep-logs]
#
# 옵션:
#   --keep-logs: 진행 로그는 삭제하지 않음

set -euo pipefail

RALPH_DIR=".ralph"
KEEP_LOGS=false

# 인자 파싱
while [[ $# -gt 0 ]]; do
  case $1 in
    --keep-logs)
      KEEP_LOGS=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# 상태 파일 확인
if [[ ! -d "$RALPH_DIR" ]]; then
  echo "Ralph 세션이 없습니다. (.ralph 디렉토리가 존재하지 않음)"
  exit 0
fi

# 현재 상태 표시
if [[ -f "$RALPH_DIR/state.md" ]]; then
  echo "=== 현재 Ralph 세션 정보 ==="
  CURRENT_ITER=$(grep '^iteration:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/iteration: *//' || echo "0")
  MAX_ITER=$(grep '^max_iterations:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/max_iterations: *//' || echo "?")
  PROMISE=$(grep '^completion_promise:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/completion_promise: *//' | tr -d '"' || echo "?")
  STARTED=$(grep '^started_at:' "$RALPH_DIR/state.md" 2>/dev/null | sed 's/started_at: *//' | tr -d '"' || echo "?")

  echo "  - 진행: $CURRENT_ITER/$MAX_ITER 반복"
  echo "  - 완료 조건: $PROMISE"
  echo "  - 시작 시간: $STARTED"
  echo ""
fi

# 로그 보존 여부에 따라 삭제
if [[ "$KEEP_LOGS" == "true" ]]; then
  # 상태 파일과 프롬프트만 삭제, 로그는 보존
  rm -f "$RALPH_DIR/state.md" "$RALPH_DIR/prompt.md"
  echo "Ralph 세션이 취소되었습니다. (로그 보존됨)"
  echo "로그 위치: $RALPH_DIR/progress.log"
else
  # 전체 삭제
  rm -rf "$RALPH_DIR"
  echo "Ralph 세션이 취소되었습니다. (모든 파일 삭제됨)"
fi

# 진행 로그에 취소 기록 (보존 모드일 때만)
if [[ "$KEEP_LOGS" == "true" ]] && [[ -f "$RALPH_DIR/progress.log" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] CANCELLED: Session cancelled by user" >> "$RALPH_DIR/progress.log"
fi
