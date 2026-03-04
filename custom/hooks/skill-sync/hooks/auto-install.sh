#!/usr/bin/env bash
set -euo pipefail

# Parse the file path from tool input
file_path=$(jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[[ -z "$file_path" ]] && exit 0

SKILLS_DIR="$HOME/skills-and-agents"

# Only trigger when files are written to custom/skills/ or external/skills/
if [[ "$file_path" == "$SKILLS_DIR/custom/skills/"* ]] || \
   [[ "$file_path" == "$SKILLS_DIR/external/skills/"* ]]; then
  bash "$SKILLS_DIR/install.sh" > /dev/null 2>&1
fi

exit 0
