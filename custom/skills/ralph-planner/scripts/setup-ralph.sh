#!/bin/bash
# Ralph Loop Setup Script
# Ralph 세션을 초기화하고 상태 파일을 생성합니다.
#
# 사용법:
#   ./setup-ralph.sh "<프롬프트>" [--max-iterations N] [--completion-promise "TEXT"]
#
# 예시:
#   ./setup-ralph.sh "버그 수정해줘" --max-iterations 30 --completion-promise "BUGFIX_DONE"

set -euo pipefail

# 기본값
MAX_ITERATIONS=30
COMPLETION_PROMISE="DONE"
PROMPT=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$PROMPT" ]]; then
        PROMPT="$1"
      fi
      shift
      ;;
  esac
done

# 프롬프트 필수 체크
if [[ -z "$PROMPT" ]]; then
  echo "오류: 프롬프트가 필요합니다."
  echo "사용법: ./setup-ralph.sh \"<프롬프트>\" [--max-iterations N] [--completion-promise \"TEXT\"]"
  exit 1
fi

# 상태 디렉토리 생성
RALPH_DIR=".ralph"
mkdir -p "$RALPH_DIR"

# 세션 ID 생성 (터미널 세션 ID 또는 PID 기반)
TERM_SID="${TERM_SESSION_ID:-${ITERM_SESSION_ID:-$$}}"

# 현재 시간
STARTED_AT=$(date '+%Y-%m-%dT%H:%M:%S')

# 상태 파일 생성
cat > "$RALPH_DIR/state.md" << EOF
---
term_session_id: "$TERM_SID"
iteration: 0
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
started_at: "$STARTED_AT"
---
EOF

# 프롬프트 파일 저장
echo "$PROMPT" > "$RALPH_DIR/prompt.md"

# 진행 상황 로그 초기화
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STARTED: Ralph Loop initialized" > "$RALPH_DIR/progress.log"
echo "  - Max iterations: $MAX_ITERATIONS" >> "$RALPH_DIR/progress.log"
echo "  - Completion promise: $COMPLETION_PROMISE" >> "$RALPH_DIR/progress.log"
echo "  - Terminal session: $TERM_SID" >> "$RALPH_DIR/progress.log"

# 결과 출력
echo "=== Ralph Loop 초기화 완료 ==="
echo ""
echo "상태 파일: $RALPH_DIR/state.md"
echo "프롬프트 파일: $RALPH_DIR/prompt.md"
echo "진행 로그: $RALPH_DIR/progress.log"
echo ""
echo "설정:"
echo "  - 최대 반복: $MAX_ITERATIONS회"
echo "  - 완료 조건: $COMPLETION_PROMISE"
echo "  - 세션 ID: $TERM_SID"
echo ""
echo "이제 Claude에게 프롬프트를 전달하면 Stop Hook이 자동으로 루프를 관리합니다."
echo "취소하려면: ./cancel-ralph.sh"
