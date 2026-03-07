#!/usr/bin/env bash
set -euo pipefail

# Pre-commit gate hook
# git commit 명령 감지 시 verification-loop + security check 자동 실행
# 실패하면 커밋을 차단한다.

# Parse command from tool input
input_command=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[[ -z "$input_command" ]] && exit 0

# Only trigger on git commit commands
git_commit_pattern='(^|[[:space:];|&])git[[:space:]]+commit([[:space:]]|$)'
if ! [[ $input_command =~ $git_commit_pattern ]]; then
  exit 0
fi

errors=()

# ============================================================
# Gate 1: Security Check (CRITICAL - 자격증명 노출 검사)
# ============================================================

# Get staged files
staged_files=$(git diff --cached --name-only 2>/dev/null) || staged_files=""

if [[ -n "$staged_files" ]]; then
  # Check for hardcoded secrets in staged changes
  secret_patterns=(
    'password\s*[:=]\s*["\x27][^"\x27]{3,}'
    'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{3,}'
    'secret\s*[:=]\s*["\x27][^"\x27]{3,}'
    'token\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{10,}'
    'AKIA[0-9A-Z]{16}'
    'sk-[a-zA-Z0-9]{20,}'
    'ghp_[a-zA-Z0-9]{36}'
  )

  staged_diff=$(git diff --cached 2>/dev/null) || staged_diff=""

  for pattern in "${secret_patterns[@]}"; do
    matches=$(echo "$staged_diff" | grep -Pn "^\+" | grep -Pi "$pattern" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      errors+=("🔴 CRITICAL: 하드코딩된 시크릿 감지\n$matches")
      break
    fi
  done

  # Check if .env files are being committed
  env_files=$(echo "$staged_files" | grep -E '\.env($|\.)' 2>/dev/null || true)
  if [[ -n "$env_files" ]]; then
    errors+=("🔴 CRITICAL: .env 파일 커밋 시도 감지: $env_files")
  fi
fi

# ============================================================
# Gate 2: Verification Loop (빌드 → 테스트 → 린트)
# ============================================================

# Detect project type and run appropriate checks
project_root=$(git rev-parse --show-toplevel 2>/dev/null) || project_root="."

if [[ -f "$project_root/package.json" ]]; then
  # Check for available scripts
  has_script() {
    jq -e ".scripts[\"$1\"] // empty" "$project_root/package.json" > /dev/null 2>&1
  }

  # Detect package manager
  if [[ -f "$project_root/pnpm-lock.yaml" ]]; then
    pm="pnpm"
  elif [[ -f "$project_root/yarn.lock" ]]; then
    pm="yarn"
  else
    pm="npm run"
  fi

  # Step 1: TypeScript type check
  if has_script "typecheck"; then
    if ! $pm typecheck 2>&1; then
      errors+=("🔴 빌드 실패: typecheck 에러 발견. 수정 후 다시 커밋하세요.")
    fi
  elif [[ -f "$project_root/tsconfig.json" ]]; then
    if ! npx tsc --noEmit 2>&1; then
      errors+=("🔴 빌드 실패: TypeScript 컴파일 에러. 수정 후 다시 커밋하세요.")
    fi
  fi

  # Step 2: Tests (if build passed)
  if [[ ${#errors[@]} -eq 0 ]]; then
    if has_script "test"; then
      if ! $pm test 2>&1; then
        errors+=("🔴 테스트 실패: 실패한 테스트를 수정 후 다시 커밋하세요.")
      fi
    fi
  fi

  # Step 3: Lint (if tests passed)
  if [[ ${#errors[@]} -eq 0 ]]; then
    if has_script "lint"; then
      if ! $pm lint 2>&1; then
        errors+=("🟡 린트 실패: lint 에러를 수정 후 다시 커밋하세요.")
      fi
    fi
  fi

elif [[ -f "$project_root/pyproject.toml" ]] || [[ -f "$project_root/setup.py" ]]; then
  # Python project
  # Step 1: Type check
  if command -v ty &> /dev/null; then
    if ! ty check 2>&1; then
      errors+=("🔴 타입 체크 실패: ty check 에러. 수정 후 다시 커밋하세요.")
    fi
  elif command -v mypy &> /dev/null; then
    if ! mypy . 2>&1; then
      errors+=("🔴 타입 체크 실패: mypy 에러. 수정 후 다시 커밋하세요.")
    fi
  fi

  # Step 2: Tests
  if [[ ${#errors[@]} -eq 0 ]]; then
    if command -v pytest &> /dev/null; then
      if ! pytest 2>&1; then
        errors+=("🔴 테스트 실패: 실패한 테스트를 수정 후 다시 커밋하세요.")
      fi
    fi
  fi

  # Step 3: Lint
  if [[ ${#errors[@]} -eq 0 ]]; then
    if command -v ruff &> /dev/null; then
      if ! ruff check . 2>&1; then
        errors+=("🟡 린트 실패: ruff check 에러를 수정 후 다시 커밋하세요.")
      fi
    fi
  fi
fi

# ============================================================
# Result: 차단 또는 허용
# ============================================================

if [[ ${#errors[@]} -gt 0 ]]; then
  error_msg=""
  for err in "${errors[@]}"; do
    error_msg+="$err\n"
  done

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Pre-commit gate 실패:\\n\\n${error_msg}\\n검증을 통과한 후 다시 커밋하세요."
  }
}
EOF
fi

exit 0
