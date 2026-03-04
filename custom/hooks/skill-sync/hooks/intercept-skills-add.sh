#!/usr/bin/env bash
set -euo pipefail

# Parse command from tool input
input_command=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[[ -z "$input_command" ]] && exit 0

# Detect: npx skills add, npx skills install, skills add, skills install
skills_add_pattern='(^|[[:space:];|&])(npx[[:space:]]+)?skills[[:space:]]+(add|install)[[:space:]]'

if [[ $input_command =~ $skills_add_pattern ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use ~/skills-and-agents/install-skill.sh instead. It runs skills add, moves to external/skills/, and creates symlinks automatically.\n\nExample: ~/skills-and-agents/install-skill.sh coreyhaines31/marketingskills"
  }
}
EOF
fi

exit 0
