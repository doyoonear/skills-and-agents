#!/bin/bash

# Skills Sync Script
# custom과 external의 스킬만 ~/.claude/skills, ~/.agents/skills, ~/.codex/skills에 symlink합니다.
# Agent 정의, 전역 지침, 설정, extension은 이 repo에서 관리하지 않습니다.
#
# Usage:
#   ./install.sh          일반 설치 (symlink 생성)
#   ./install.sh --check  헬스체크 (변경 없이 문제만 탐지)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_SKILLS="$SCRIPT_DIR/custom/skills"
EXTERNAL_SKILLS="$SCRIPT_DIR/external/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents" # deprecated cleanup only
AGENTS_SKILLS="$HOME/.agents/skills"
PI_SKILLS="$HOME/.pi/agent/skills"
CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"
PI_ONLY_SKILLS=" completion-review deep-plan "

is_pi_only_skill() {
  [[ "$PI_ONLY_SKILLS" == *" $1 "* ]]
}

cleanup_pi_duplicate_skills() {
  [ -d "$PI_SKILLS" ] || return 0
  local backup_root=""
  local moved=0
  local name
  for item in "$PI_SKILLS"/*; do
    [ -d "$item" ] || continue
    [ ! -L "$item" ] || continue
    name=$(basename "$item")
    is_pi_only_skill "$name" && continue
    [ -e "$AGENTS_SKILLS/$name" ] || continue

    if [ -z "$backup_root" ]; then
      backup_root="$PI_SKILLS/.dedupe-backup/$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$backup_root"
    fi
    mv "$item" "$backup_root/$name"
    echo "  📦 Moved duplicate Pi skill to backup: $name"
    moved=$((moved + 1))
  done
  if [ "$moved" -gt 0 ]; then
    echo "  ✅ Pi skill duplicates removed (backup: ${backup_root/#$HOME/~})"
  fi
}

# 스킬 디렉토리가 유효한지 검증 (SKILL.md 또는 plugin.json 또는 하위 SKILL.md 존재)
is_valid_skill() {
  local dir="$1"
  [ -f "$dir/SKILL.md" ] && return 0
  [ -f "$dir/.claude-plugin/plugin.json" ] && return 0
  find "$dir" -maxdepth 3 -name "SKILL.md" -print -quit 2>/dev/null | grep -q . && return 0
  return 1
}

is_repo_managed_link() {
  local link="$1"
  local target=""
  local resolved=""

  [ -L "$link" ] || return 1
  target=$(readlink "$link")
  [[ "$target" == *"skills-and-agents"* ]] && return 0

  resolved=$(realpath "$link" 2>/dev/null || true)
  [[ "$resolved" == "$SCRIPT_DIR"* ]] && return 0

  return 1
}

link_skill_to_targets() {
  local skill="$1"
  local name
  local target
  name=$(basename "$skill")

  if [ -d "$skill" ] && ! is_valid_skill "$skill"; then
    echo "  ⚠️  Skipped (no SKILL.md or plugin.json): $name"
    return 0
  fi

  for target_dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS" "$CODEX_SKILLS"; do
    target="$target_dir/$name"
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      ln -s "$skill" "$target"
      echo "  ✅ Linked to ${target_dir/#$HOME/~}: $name"
    fi
  done
}

CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=true
fi

if $CHECK_MODE; then
  echo "🔍 Skills Health Check (dry-run, no changes)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  issues=0

  echo ""
  echo "📎 Broken skill symlinks:"
  broken_count=0
  for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS" "$CODEX_SKILLS"; do
    for link in "$dir"/*; do
      [ -L "$link" ] || continue
      if [ ! -e "$link" ]; then
        echo "  ❌ ${dir/#$HOME/~}/$(basename "$link") → $(readlink "$link")"
        broken_count=$((broken_count + 1))
        issues=$((issues + 1))
      fi
    done
  done
  [ "$broken_count" -eq 0 ] && echo "  ✅ None"

  echo ""
  echo "📂 Empty skill directories (no SKILL.md or plugin.json):"
  empty_count=0
  for base in "$CUSTOM_SKILLS" "$EXTERNAL_SKILLS"; do
    for skill in "$base"/*; do
      [ -d "$skill" ] || continue
      name=$(basename "$skill")
      if ! is_valid_skill "$skill"; then
        echo "  ⚠️  $(basename "$(dirname "$(dirname "$skill")")")/skills/$name"
        empty_count=$((empty_count + 1))
        issues=$((issues + 1))
      fi
    done
  done
  [ "$empty_count" -eq 0 ] && echo "  ✅ None"

  echo ""
  echo "🔗 Unlinked skills (in repo but missing from at least one skill target):"
  unlinked_count=0
  for base in "$CUSTOM_SKILLS" "$EXTERNAL_SKILLS"; do
    for skill in "$base"/*; do
      [ -e "$skill" ] || continue
      name=$(basename "$skill")
      if [ -d "$skill" ] && ! is_valid_skill "$skill"; then
        continue
      fi
      for target_dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS" "$CODEX_SKILLS"; do
        if [ ! -L "$target_dir/$name" ] && [ ! -e "$target_dir/$name" ]; then
          echo "  ⚠️  $name missing in ${target_dir/#$HOME/~}"
          unlinked_count=$((unlinked_count + 1))
          issues=$((issues + 1))
        fi
      done
    done
  done
  [ "$unlinked_count" -eq 0 ] && echo "  ✅ None"

  echo ""
  echo "🚫 Deprecated repo-managed agent symlinks:"
  deprecated_count=0
  if [ -d "$CLAUDE_AGENTS" ]; then
    for link in "$CLAUDE_AGENTS"/*; do
      if is_repo_managed_link "$link"; then
        echo "  ⚠️  ${link/#$HOME/~} → $(readlink "$link")"
        deprecated_count=$((deprecated_count + 1))
        issues=$((issues + 1))
      fi
    done
  fi
  [ "$deprecated_count" -eq 0 ] && echo "  ✅ None"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  total_skills=$(ls -1 "$CLAUDE_SKILLS" 2>/dev/null | wc -l | tr -d ' ')
  echo "📊 Total installed: $total_skills skills"
  if [ "$issues" -eq 0 ]; then
    echo "✅ All healthy! No issues found."
  else
    echo "⚠️  Found $issues issue(s). Run ./install.sh to fix link issues."
  fi
  exit 0
fi

echo "🔄 Syncing skills only..."

mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS" "$PI_SKILLS" "$CODEX_SKILLS"
mkdir -p "$CUSTOM_SKILLS" "$EXTERNAL_SKILLS"

# 기존 skills-and-agents 관련 skill symlink 정리
# Deprecated: ~/.claude/agents에 남은 repo-managed agent symlink도 제거하되 새로 생성하지 않는다.
echo "📦 Cleaning old repo-managed symlinks..."
for link in "$CLAUDE_SKILLS"/* "$AGENTS_SKILLS"/* "$CODEX_SKILLS"/* "$CLAUDE_AGENTS"/*; do
  if is_repo_managed_link "$link"; then
    rm "$link"
    echo "  🗑️  Removed: ${link/#$HOME/~}"
  fi
done

echo "🔗 Linking custom skills..."
for skill in "$CUSTOM_SKILLS"/*; do
  [ -e "$skill" ] || continue
  link_skill_to_targets "$skill"
done

echo "🔗 Linking external skills..."
for skill in "$EXTERNAL_SKILLS"/*; do
  [ -e "$skill" ] || continue
  link_skill_to_targets "$skill"
done

echo ""
echo "🔍 Verifying skill symlink integrity..."
broken_count=0
for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS" "$CODEX_SKILLS"; do
  for link in "$dir"/*; do
    [ -L "$link" ] || continue
    if [ ! -e "$link" ]; then
      name=$(basename "$link")
      echo "  🗑️  Removing broken symlink: $name (in ${dir/#$HOME/~})"
      rm "$link"
      broken_count=$((broken_count + 1))
    fi
  done
done
if [ "$broken_count" -eq 0 ]; then
  echo "  ✅ All symlinks valid"
else
  echo "  ⚠️  Removed $broken_count broken symlink(s)"
fi

echo ""
echo "🧹 Removing duplicate Pi skills..."
cleanup_pi_duplicate_skills

echo ""
echo "✨ Done!"
echo "   .claude/skills: $(ls -1 "$CLAUDE_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
echo "   .agents/skills: $(ls -1 "$AGENTS_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
echo "   .codex/skills: $(ls -1 "$CODEX_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
