#!/bin/bash

# Skills and Agents Sync Script
# custom과 external의 스킬/에이전트를 ~/.claude/와 ~/.agents/에 symlink합니다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_SKILLS="$SCRIPT_DIR/custom/skills"
CUSTOM_AGENTS="$SCRIPT_DIR/custom/agents"
EXTERNAL_SKILLS="$SCRIPT_DIR/external/skills"
EXTERNAL_AGENTS="$SCRIPT_DIR/external/agents"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents"
AGENTS_SKILLS="$HOME/.agents/skills"

echo "🔄 Syncing skills and agents..."

# 폴더 생성
mkdir -p "$CLAUDE_SKILLS" "$CLAUDE_AGENTS" "$AGENTS_SKILLS"
mkdir -p "$CUSTOM_SKILLS" "$CUSTOM_AGENTS" "$EXTERNAL_SKILLS" "$EXTERNAL_AGENTS"

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

echo ""
echo "✨ Done!"
echo "   .claude/skills: $(ls -1 "$CLAUDE_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
echo "   .claude/agents: $(ls -1 "$CLAUDE_AGENTS" 2>/dev/null | wc -l | tr -d ' ') items"
echo "   .agents/skills: $(ls -1 "$AGENTS_SKILLS" 2>/dev/null | wc -l | tr -d ' ') items"
