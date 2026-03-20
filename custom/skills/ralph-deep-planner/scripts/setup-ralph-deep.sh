#!/bin/bash
# Ralph Deep Loop Setup Script
# Ralph Deep 세션을 초기화하고 상태 파일 및 핸드오프 문서를 생성합니다.
# planner_type: deep으로 설정하여 stop-hook에서 분기 처리됩니다.
#
# 사용법:
#   ./setup-ralph-deep.sh "<프롬프트>" [--max-iterations N] [--completion-promise "TEXT"] [--task-slug "slug"] [--plan-file "path"]
#
# 예시:
#   ./setup-ralph-deep.sh "결제 마이그레이션" --max-iterations 50 --completion-promise "FEATURE_DONE" --task-slug "payment-migration" --plan-file "docs/plans/2026-03-09-feat-payment-migration-plan.md"

set -euo pipefail

MAX_ITERATIONS=30
COMPLETION_PROMISE="DONE"
TASK_SLUG=""
PLAN_FILE=""
PROMPT=""

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
    --plan-file)
      PLAN_FILE="$2"
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

if [[ -z "$PROMPT" ]]; then
  echo "오류: 프롬프트가 필요합니다."
  echo "사용법: ./setup-ralph-deep.sh \"<프롬프트>\" [--max-iterations N] [--completion-promise \"TEXT\"] [--task-slug \"slug\"] [--plan-file \"path\"]"
  exit 1
fi

if [[ -z "$TASK_SLUG" ]]; then
  echo "오류: --task-slug가 필요합니다."
  exit 1
fi

RALPH_DIR=".ralph"
mkdir -p "$RALPH_DIR"

HANDOFF_DIR="docs/ralph-${TASK_SLUG}"
HANDOFF_FILE="$HANDOFF_DIR/HANDOFF.md"
mkdir -p "$HANDOFF_DIR"

TERM_SID="${TERM_SESSION_ID:-${ITERM_SESSION_ID:-$$}}"
STARTED_AT=$(date '+%Y-%m-%dT%H:%M:%S')

# 상태 파일 생성 (planner_type: deep 포함)
cat > "$RALPH_DIR/state.md" << EOF
---
term_session_id: "$TERM_SID"
iteration: 0
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
task_slug: "$TASK_SLUG"
planner_type: "deep"
plan_file: "$PLAN_FILE"
started_at: "$STARTED_AT"
---
EOF

echo "$PROMPT" > "$RALPH_DIR/prompt.md"

# 핸드오프 문서 초기 생성 (plan_file 참조 포함)
cat > "$HANDOFF_FILE" << EOF
# HANDOFF: ${TASK_SLUG}

## 마지막 업데이트
- 세션: 초기화
- 시간: $(date '+%Y-%m-%d %H:%M')

## 참조 문서
- 계획 파일: ${PLAN_FILE}

## Task Checklist
(Claude가 계획 파일의 Implementation Plan을 기반으로 업데이트)

## 현재 Phase 상세
아직 시작되지 않음.

## 의사결정 기록
(없음)

## 학습 기록 (Compound Learning)
(Phase별 학습 내용이 조건부로 기록됩니다)

## 발견한 이슈 / 주의사항
(없음)

## 다음 세션이 해야 할 일
1. 계획 파일(${PLAN_FILE})을 읽고 Implementation Plan 파악
2. Phase 1부터 시작
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] STARTED: Ralph Deep Loop initialized" > "$RALPH_DIR/progress.log"
echo "  - Max iterations: $MAX_ITERATIONS" >> "$RALPH_DIR/progress.log"
echo "  - Completion promise: $COMPLETION_PROMISE" >> "$RALPH_DIR/progress.log"
echo "  - Task slug: $TASK_SLUG" >> "$RALPH_DIR/progress.log"
echo "  - Planner type: deep" >> "$RALPH_DIR/progress.log"
echo "  - Plan file: $PLAN_FILE" >> "$RALPH_DIR/progress.log"
echo "  - Terminal session: $TERM_SID" >> "$RALPH_DIR/progress.log"

echo "=== Ralph Deep Loop 초기화 완료 ==="
echo ""
echo "상태 파일: $RALPH_DIR/state.md"
echo "프롬프트 파일: $RALPH_DIR/prompt.md"
echo "진행 로그: $RALPH_DIR/progress.log"
echo "핸드오프 문서: $HANDOFF_FILE"
echo "계획 파일: $PLAN_FILE"
echo ""
echo "설정:"
echo "  - 최대 반복: ${MAX_ITERATIONS}회"
echo "  - 완료 조건: $COMPLETION_PROMISE"
echo "  - Task slug: $TASK_SLUG"
echo "  - Planner type: deep"
echo "  - 세션 ID: $TERM_SID"
echo ""
echo "이제 Claude에게 프롬프트를 전달하면 Stop Hook이 자동으로 루프를 관리합니다."
echo "취소하려면: ~/.claude/skills/ralph-deep-planner/scripts/cancel-ralph-deep.sh"
