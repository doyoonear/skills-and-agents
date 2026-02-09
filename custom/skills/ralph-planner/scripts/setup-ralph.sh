#!/bin/bash
# Ralph Loop Setup Script
# Ralph 세션을 초기화하고 상태 파일 및 핸드오프 문서를 생성합니다.
#
# 사용법:
#   ./setup-ralph.sh "<프롬프트>" [--max-iterations N] [--completion-promise "TEXT"] [--task-slug "slug"]
#
# 예시:
#   ./setup-ralph.sh "버그 수정해줘" --max-iterations 30 --completion-promise "BUGFIX_DONE" --task-slug "fix-login-bug"

set -euo pipefail

# 기본값
MAX_ITERATIONS=30
COMPLETION_PROMISE="DONE"
TASK_SLUG=""
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
    --task-slug)
      TASK_SLUG="$2"
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
  echo "사용법: ./setup-ralph.sh \"<프롬프트>\" [--max-iterations N] [--completion-promise \"TEXT\"] [--task-slug \"slug\"]"
  exit 1
fi

# task-slug 필수 체크
if [[ -z "$TASK_SLUG" ]]; then
  echo "오류: --task-slug가 필요합니다."
  echo "예시: --task-slug \"dark-mode-toggle\""
  exit 1
fi

# 상태 디렉토리 생성
RALPH_DIR=".ralph"
mkdir -p "$RALPH_DIR"

# 핸드오프 디렉토리 생성
HANDOFF_DIR="docs/ralph-${TASK_SLUG}"
HANDOFF_FILE="$HANDOFF_DIR/HANDOFF.md"
mkdir -p "$HANDOFF_DIR"

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
task_slug: "$TASK_SLUG"
started_at: "$STARTED_AT"
---
EOF

# 프롬프트 파일 저장
echo "$PROMPT" > "$RALPH_DIR/prompt.md"

# 핸드오프 문서 초기 생성
cat > "$HANDOFF_FILE" << EOF
# HANDOFF: ${TASK_SLUG}

## 마지막 업데이트
- 세션: 초기화
- 시간: $(date '+%Y-%m-%d %H:%M')

## Task Checklist
(Claude가 프롬프트의 Implementation Plan을 기반으로 업데이트)

## 현재 Phase 상세
아직 시작되지 않음.

## 의사결정 기록
(없음)

## 발견한 이슈 / 주의사항
(없음)

## 다음 세션이 해야 할 일
1. Implementation Plan의 Phase 1부터 시작
EOF

# 진행 상황 로그 초기화
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STARTED: Ralph Loop initialized" > "$RALPH_DIR/progress.log"
echo "  - Max iterations: $MAX_ITERATIONS" >> "$RALPH_DIR/progress.log"
echo "  - Completion promise: $COMPLETION_PROMISE" >> "$RALPH_DIR/progress.log"
echo "  - Task slug: $TASK_SLUG" >> "$RALPH_DIR/progress.log"
echo "  - Terminal session: $TERM_SID" >> "$RALPH_DIR/progress.log"

# 결과 출력
echo "=== Ralph Loop 초기화 완료 ==="
echo ""
echo "상태 파일: $RALPH_DIR/state.md"
echo "프롬프트 파일: $RALPH_DIR/prompt.md"
echo "진행 로그: $RALPH_DIR/progress.log"
echo "핸드오프 문서: $HANDOFF_FILE"
echo ""
echo "설정:"
echo "  - 최대 반복: $MAX_ITERATIONS회"
echo "  - 완료 조건: $COMPLETION_PROMISE"
echo "  - Task slug: $TASK_SLUG"
echo "  - 세션 ID: $TERM_SID"
echo ""
echo "이제 Claude에게 프롬프트를 전달하면 Stop Hook이 자동으로 루프를 관리합니다."
echo "취소하려면: ./cancel-ralph.sh"
