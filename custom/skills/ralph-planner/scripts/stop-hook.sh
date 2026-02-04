#!/bin/bash
# Ralph Loop Stop Hook
# Claude Code의 종료를 가로채서 반복 실행을 관리합니다.
# exit 0: 종료 허용 | exit 2: 종료 차단 + 프롬프트 재주입

set -euo pipefail

# 상태 디렉토리 및 파일 경로
RALPH_DIR=".ralph"
STATE_FILE="$RALPH_DIR/state.md"
PROMPT_FILE="$RALPH_DIR/prompt.md"
PROGRESS_LOG="$RALPH_DIR/progress.log"

# 상태 파일이 없으면 Ralph 세션이 아님 → 정상 종료
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# 세션 ID 격리 (다중 세션 버그 방지)
CURRENT_TERM_SID="${TERM_SESSION_ID:-${ITERM_SESSION_ID:-$$}}"
STATE_TERM_SID=$(grep '^term_session_id:' "$STATE_FILE" 2>/dev/null | sed 's/term_session_id: *//' | tr -d '"' || echo "")

if [[ -n "$STATE_TERM_SID" ]] && [[ "$STATE_TERM_SID" != "null" ]] && [[ -n "$CURRENT_TERM_SID" ]]; then
  if [[ "$STATE_TERM_SID" != "$CURRENT_TERM_SID" ]]; then
    # 다른 터미널 세션이므로 간섭하지 않음
    exit 0
  fi
fi

# 현재 반복 횟수 및 최대 반복 횟수 읽기
CURRENT_ITER=$(grep '^iteration:' "$STATE_FILE" 2>/dev/null | sed 's/iteration: *//' || echo "0")
MAX_ITER=$(grep '^max_iterations:' "$STATE_FILE" 2>/dev/null | sed 's/max_iterations: *//' || echo "50")
COMPLETION_PROMISE=$(grep '^completion_promise:' "$STATE_FILE" 2>/dev/null | sed 's/completion_promise: *//' | tr -d '"' || echo "")

# stdin에서 Claude의 마지막 출력 읽기 (hook input JSON)
HOOK_INPUT=$(cat)
CLAUDE_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.transcript // ""' 2>/dev/null || echo "$HOOK_INPUT")

# 완료 조건 체크: completion-promise가 출력에 포함되어 있으면 종료
if [[ -n "$COMPLETION_PROMISE" ]] && echo "$CLAUDE_OUTPUT" | grep -q "$COMPLETION_PROMISE"; then
  # 진행 상황 로깅
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMPLETED: Found completion promise '$COMPLETION_PROMISE' at iteration $CURRENT_ITER" >> "$PROGRESS_LOG"

  # 상태 파일 정리 (선택적: 주석 해제하면 자동 정리)
  # rm -rf "$RALPH_DIR"

  echo "Ralph Loop 완료! (반복 $CURRENT_ITER회, 완료 조건: $COMPLETION_PROMISE)"
  exit 0
fi

# 최대 반복 횟수 체크
if [[ "$CURRENT_ITER" -ge "$MAX_ITER" ]]; then
  # 진행 상황 로깅
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] MAX_ITERATIONS: Reached limit of $MAX_ITER iterations" >> "$PROGRESS_LOG"

  echo "Ralph Loop 중단: 최대 반복 횟수 도달 ($MAX_ITER회)"
  echo "완료 조건 '$COMPLETION_PROMISE'이 충족되지 않았습니다."
  exit 0
fi

# 반복 카운터 증가
NEW_ITER=$((CURRENT_ITER + 1))
sed -i.bak "s/^iteration: .*/iteration: $NEW_ITER/" "$STATE_FILE" && rm -f "$STATE_FILE.bak"

# 진행 상황 로깅
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ITERATION $NEW_ITER/$MAX_ITER: Continuing..." >> "$PROGRESS_LOG"

# 프롬프트 재주입 (exit 2로 종료 차단)
if [[ -f "$PROMPT_FILE" ]]; then
  echo ""
  echo "=== Ralph Loop: 반복 $NEW_ITER/$MAX_ITER ==="
  echo ""
  echo "/compact"  # 컨텍스트 초기화로 장시간 세션 안정성 확보
  echo ""
  cat "$PROMPT_FILE"
  exit 2
else
  echo "오류: 프롬프트 파일을 찾을 수 없습니다 ($PROMPT_FILE)"
  exit 0
fi
