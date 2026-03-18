#!/bin/bash

# Skills and Agents Sync Script
# custom과 external의 스킬/에이전트를 ~/.claude/와 ~/.agents/에 symlink합니다.
#
# Usage:
#   ./install.sh          일반 설치 (symlink 생성)
#   ./install.sh --check  헬스체크 (변경 없이 문제만 탐지)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_SKILLS="$SCRIPT_DIR/custom/skills"
CUSTOM_AGENTS="$SCRIPT_DIR/custom/agents"
EXTERNAL_SKILLS="$SCRIPT_DIR/external/skills"
EXTERNAL_AGENTS="$SCRIPT_DIR/external/agents"
CUSTOM_HOOKS="$SCRIPT_DIR/custom/hooks"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_AGENTS="$HOME/.claude/agents"
AGENTS_SKILLS="$HOME/.agents/skills"

# 스킬 디렉토리가 유효한지 검증 (SKILL.md 또는 plugin.json 또는 하위 SKILL.md 존재)
is_valid_skill() {
  local dir="$1"
  [ -f "$dir/SKILL.md" ] && return 0
  [ -f "$dir/.claude-plugin/plugin.json" ] && return 0
  # 하위 폴더에 SKILL.md가 있는 멀티스킬 래퍼
  find "$dir" -maxdepth 3 -name "SKILL.md" -print -quit 2>/dev/null | grep -q . && return 0
  return 1
}

# --check 모드 감지
CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=true
fi

# --check 모드: 변경 없이 문제만 탐지
if $CHECK_MODE; then
  echo "🔍 Skills Health Check (dry-run, no changes)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  issues=0

  # 1. 깨진 symlink 탐지
  echo ""
  echo "📎 Broken symlinks:"
  for dir in "$CLAUDE_SKILLS" "$CLAUDE_AGENTS" "$AGENTS_SKILLS"; do
    for link in "$dir"/*; do
      [ -L "$link" ] || continue
      if [ ! -e "$link" ]; then
        echo "  ❌ $(basename $dir)/$(basename $link) → $(readlink $link)"
        issues=$((issues + 1))
      fi
    done
  done
  [ "$issues" -eq 0 ] && echo "  ✅ None"

  # 2. 빈 스킬 디렉토리 (SKILL.md도 plugin.json도 없음)
  echo ""
  echo "📂 Empty skill directories (no SKILL.md or plugin.json):"
  empty_count=0
  for base in "$CUSTOM_SKILLS" "$EXTERNAL_SKILLS"; do
    for skill in "$base"/*; do
      [ -d "$skill" ] || continue
      name=$(basename "$skill")
      if ! is_valid_skill "$skill"; then
        echo "  ⚠️  $(basename $(dirname $(dirname $skill)))/skills/$name"
        empty_count=$((empty_count + 1))
        issues=$((issues + 1))
      fi
    done
  done
  [ "$empty_count" -eq 0 ] && echo "  ✅ None"

  # 3. symlink이 있지만 소스가 skills-and-agents에 없는 경우 (고아 스킬)
  echo ""
  echo "👻 Orphan symlinks (target outside skills-and-agents, not from .agents):"
  orphan_count=0
  for link in "$CLAUDE_SKILLS"/*; do
    [ -L "$link" ] || continue
    [ -e "$link" ] || continue
    target=$(readlink "$link")
    if [[ "$target" != *"skills-and-agents"* ]] && [[ "$target" != *".agents"* ]]; then
      echo "  ⚠️  $(basename $link) → $target"
      orphan_count=$((orphan_count + 1))
    fi
  done
  [ "$orphan_count" -eq 0 ] && echo "  ✅ None"

  # 4. skills-and-agents에 있지만 symlink이 없는 경우 (미연결)
  echo ""
  echo "🔗 Unlinked skills (in repo but no symlink in ~/.claude/skills/):"
  unlinked_count=0
  for base in "$CUSTOM_SKILLS" "$EXTERNAL_SKILLS"; do
    for skill in "$base"/*; do
      [ -e "$skill" ] || continue
      name=$(basename "$skill")
      # 빈 디렉토리는 건너뜀
      if [ -d "$skill" ] && ! is_valid_skill "$skill"; then
        continue
      fi
      if [ ! -L "$CLAUDE_SKILLS/$name" ] && [ ! -e "$CLAUDE_SKILLS/$name" ]; then
        echo "  ⚠️  $name (in $(basename $(dirname $(dirname $skill)))/skills/)"
        unlinked_count=$((unlinked_count + 1))
        issues=$((issues + 1))
      fi
    done
  done
  [ "$unlinked_count" -eq 0 ] && echo "  ✅ None"

  # 5. 잔여물 탐지 (.DS_Store만 있는 디렉토리, __pycache__ 등)
  echo ""
  echo "🧹 Residual directories (only .DS_Store or __pycache__):"
  residual_count=0
  for base in "$CUSTOM_SKILLS" "$EXTERNAL_SKILLS"; do
    for skill in "$base"/*; do
      [ -d "$skill" ] || continue
      name=$(basename "$skill")
      # 실제 콘텐츠 파일이 있는지 확인 (.DS_Store, __pycache__ 제외)
      real_files=$(find "$skill" -not -name ".DS_Store" -not -path "*/__pycache__/*" -not -path "*/__pycache__" -not -name "." -type f 2>/dev/null | head -1)
      if [ -z "$real_files" ]; then
        echo "  🗑️  $(basename $(dirname $(dirname $skill)))/skills/$name"
        residual_count=$((residual_count + 1))
        issues=$((issues + 1))
      fi
    done
  done
  [ "$residual_count" -eq 0 ] && echo "  ✅ None"

  # 요약
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  total_skills=$(ls -1 "$CLAUDE_SKILLS" 2>/dev/null | wc -l | tr -d ' ')
  echo "📊 Total installed: $total_skills skills"
  if [ "$issues" -eq 0 ]; then
    echo "✅ All healthy! No issues found."
  else
    echo "⚠️  Found $issues issue(s). Run ./install.sh to fix."
  fi
  exit 0
fi

echo "🔄 Syncing skills and agents..."

# 폴더 생성
mkdir -p "$CLAUDE_SKILLS" "$CLAUDE_AGENTS" "$AGENTS_SKILLS"
mkdir -p "$CUSTOM_SKILLS" "$CUSTOM_AGENTS" "$EXTERNAL_SKILLS" "$EXTERNAL_AGENTS" "$CUSTOM_HOOKS"

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
