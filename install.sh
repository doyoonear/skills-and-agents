#!/bin/bash

# Skills and Agents Sync Script
# custom과 external의 스킬/에이전트를 ~/.claude/와 ~/.agents/에 symlink합니다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_SKILLS="$SCRIPT_DIR/custom/skills"
CUSTOM_AGENTS="$SCRIPT_DIR/custom/agents"
EXTERNAL_SKILLS="$SCRIPT_DIR/external/skills"
EXTERNAL_AGENTS="$SCRIPT_DIR/external/agents"
CUSTOM_HOOKS="$SCRIPT_DIR/custom/hooks"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents"
AGENTS_SKILLS="$HOME/.agents/skills"

echo "🔄 Syncing skills and agents..."

# 폴더 생성
mkdir -p "$CLAUDE_SKILLS" "$CLAUDE_AGENTS" "$AGENTS_SKILLS"
mkdir -p "$CUSTOM_SKILLS" "$CUSTOM_AGENTS" "$EXTERNAL_SKILLS" "$EXTERNAL_AGENTS" "$CUSTOM_HOOKS"

# 스킬 디렉토리가 유효한지 검증 (SKILL.md 또는 plugin.json 또는 하위 SKILL.md 존재)
is_valid_skill() {
  local dir="$1"
  [ -f "$dir/SKILL.md" ] && return 0
  [ -f "$dir/.claude-plugin/plugin.json" ] && return 0
  # 하위 폴더에 SKILL.md가 있는 멀티스킬 래퍼
  find "$dir" -maxdepth 3 -name "SKILL.md" -print -quit 2>/dev/null | grep -q . && return 0
  # .md 단일 파일 스킬 (디렉토리가 아닌 경우)
  return 1
}

# 기존 skills-and-agents 관련 symlink 정리
echo "📦 Cleaning old symlinks..."
for link in "$CLAUDE_SKILLS"/* "$CLAUDE_AGENTS"/* "$AGENTS_SKILLS"/*; do
  if [ -L "$link" ]; then
    target=$(readlink "$link")
    if [[ "$target" == *"skills-and-agents"* ]]; then
      rm "$link"
    fi
  fi
done

# Custom 스킬 symlink
echo "🔗 Linking custom skills..."
for skill in "$CUSTOM_SKILLS"/*; do
  [ -e "$skill" ] || continue
  name=$(basename "$skill")

  # 유효성 검사: 빈 디렉토리 스킵
  if [ -d "$skill" ] && ! is_valid_skill "$skill"; then
    echo "  ⚠️  Skipped (no SKILL.md or plugin.json): $name"
    continue
  fi

  # ~/.claude/skills에 symlink
  target="$CLAUDE_SKILLS/$name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$skill" "$target"
    echo "  ✅ Linked to .claude/skills: $name"
  fi

  # ~/.agents/skills에 symlink
  target="$AGENTS_SKILLS/$name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$skill" "$target"
    echo "  ✅ Linked to .agents/skills: $name"
  fi
done

# External 스킬 symlink
echo "🔗 Linking external skills..."
for skill in "$EXTERNAL_SKILLS"/*; do
  [ -e "$skill" ] || continue
  name=$(basename "$skill")

  # 유효성 검사: 빈 디렉토리 스킵
  if [ -d "$skill" ] && ! is_valid_skill "$skill"; then
    echo "  ⚠️  Skipped (no SKILL.md or plugin.json): $name"
    continue
  fi

  # ~/.claude/skills에 symlink
  target="$CLAUDE_SKILLS/$name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$skill" "$target"
    echo "  ✅ Linked to .claude/skills: $name"
  fi

  # ~/.agents/skills에 symlink
  target="$AGENTS_SKILLS/$name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$skill" "$target"
    echo "  ✅ Linked to .agents/skills: $name"
  fi
done

# Custom 에이전트 symlink
echo "🔗 Linking custom agents..."
for agent in "$CUSTOM_AGENTS"/*; do
  [ -e "$agent" ] || continue
  name=$(basename "$agent")
  target="$CLAUDE_AGENTS/$name"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$agent" "$target"
    echo "  ✅ Linked: $name"
  fi
done

# External 에이전트 symlink
echo "🔗 Linking external agents..."
for agent in "$EXTERNAL_AGENTS"/*; do
  [ -e "$agent" ] || continue
  name=$(basename "$agent")
  target="$CLAUDE_AGENTS/$name"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$agent" "$target"
    echo "  ✅ Linked: $name"
  fi
done

# Custom hooks symlink (플러그인으로 등록)
echo "🔗 Linking custom hooks..."
for hook in "$CUSTOM_HOOKS"/*; do
  [ -e "$hook" ] || continue
  name=$(basename "$hook")

  # ~/.claude/skills에 symlink (플러그인 디스커버리)
  target="$CLAUDE_SKILLS/$name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$hook" "$target"
    echo "  ✅ Linked to .claude/skills: $name"
  fi

  # ~/.agents/skills에 symlink
  target="$AGENTS_SKILLS/$name"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ln -s "$hook" "$target"
    echo "  ✅ Linked to .agents/skills: $name"
  fi
done

# 무결성 검증: 깨진 symlink 탐지 및 제거
echo ""
echo "🔍 Verifying symlink integrity..."
broken_count=0
for dir in "$CLAUDE_SKILLS" "$CLAUDE_AGENTS" "$AGENTS_SKILLS"; do
  for link in "$dir"/*; do
    [ -L "$link" ] || continue
    if [ ! -e "$link" ]; then
      name=$(basename "$link")
      echo "  🗑️  Removing broken symlink: $name (in $(basename $(dirname $link)))"
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
echo "✨ Done!"
echo "   .claude/skills: $(ls -1 "$CLAUDE_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
echo "   .claude/agents: $(ls -1 "$CLAUDE_AGENTS" 2>/dev/null | wc -l | tr -d ' ') items"
echo "   .agents/skills: $(ls -1 "$AGENTS_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
