#!/bin/bash

# remove-skill.sh
# 스킬을 안전하게 제거합니다. 대체 스킬 확인, symlink 정리, 잔여물 제거를 자동화합니다.
#
# Usage:
#   ./remove-skill.sh <skill-name> [--replace <replacement-skill>] [--force]
#
# Examples:
#   ./remove-skill.sh my-old-skill
#   ./remove-skill.sh my-old-skill --replace my-new-skill
#   ./remove-skill.sh my-old-skill --force

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_SKILLS="$SCRIPT_DIR/custom/skills"
EXTERNAL_SKILLS="$SCRIPT_DIR/external/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
AGENTS_SKILLS="$HOME/.agents/skills"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 인자 파싱
SKILL_NAME=""
REPLACE_WITH=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --replace) REPLACE_WITH="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    -*) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    *) SKILL_NAME="$1"; shift ;;
  esac
done

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: ./remove-skill.sh <skill-name> [--replace <replacement-skill>] [--force]"
  echo ""
  echo "Options:"
  echo "  --replace <name>  대체 스킬을 먼저 확인 후 삭제 (없으면 중단)"
  echo "  --force           확인 프롬프트 없이 강제 삭제"
  echo ""
  echo "Examples:"
  echo "  ./remove-skill.sh old-skill"
  echo "  ./remove-skill.sh old-skill --replace new-skill"
  exit 1
fi

# 스킬 소스 위치 찾기
SOURCE_PATH=""
SOURCE_TYPE=""
if [ -e "$CUSTOM_SKILLS/$SKILL_NAME" ]; then
  SOURCE_PATH="$CUSTOM_SKILLS/$SKILL_NAME"
  SOURCE_TYPE="custom"
elif [ -e "$EXTERNAL_SKILLS/$SKILL_NAME" ]; then
  SOURCE_PATH="$EXTERNAL_SKILLS/$SKILL_NAME"
  SOURCE_TYPE="external"
else
  echo -e "${RED}❌ Skill not found: $SKILL_NAME${NC}"
  echo "   Checked: custom/skills/ and external/skills/"

  # symlink만 남아있는지 확인
  has_orphan=false
  for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS"; do
    link="$dir/$SKILL_NAME"
    if [ -L "$link" ]; then
      echo -e "   ${YELLOW}Found orphan symlink: $link → $(readlink "$link")${NC}"
      has_orphan=true
    fi
  done

  if $has_orphan; then
    echo ""
    echo -e "${YELLOW}Orphan symlinks detected. Remove them? [y/N]${NC}"
    if $FORCE; then
      answer="y"
    else
      read -r answer
    fi
    if [[ "$answer" =~ ^[yY] ]]; then
      for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS"; do
        [ -L "$dir/$SKILL_NAME" ] && rm "$dir/$SKILL_NAME" && echo -e "  ${GREEN}🗑️  Removed: $dir/$SKILL_NAME${NC}"
      done
    fi
  fi
  exit 1
fi

echo "📋 Skill: $SKILL_NAME"
echo "   Source: $SOURCE_TYPE/skills/$SKILL_NAME"

# 대체 스킬 확인
if [ -n "$REPLACE_WITH" ]; then
  replace_exists=false
  for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS"; do
    if [ -e "$dir/$REPLACE_WITH" ]; then
      replace_exists=true
      break
    fi
  done

  if ! $replace_exists; then
    echo -e "${RED}❌ Replacement skill not installed: $REPLACE_WITH${NC}"
    echo "   Install the replacement first, then try again."
    exit 1
  fi
  echo -e "   ${GREEN}✅ Replacement confirmed: $REPLACE_WITH${NC}"
fi

# 삭제 확인
if ! $FORCE; then
  echo ""
  echo -e "${YELLOW}This will:${NC}"
  echo "  1. Remove $SOURCE_TYPE/skills/$SKILL_NAME/"
  echo "  2. Remove symlinks from ~/.claude/skills/ and ~/.agents/skills/"
  echo "  3. Clean up any residual files (.DS_Store, __pycache__)"
  echo ""
  echo -e "${YELLOW}Proceed? [y/N]${NC}"
  read -r answer
  if [[ ! "$answer" =~ ^[yY] ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo ""
echo "🗑️  Removing skill..."

# 1. symlink 제거
for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS"; do
  link="$dir/$SKILL_NAME"
  if [ -L "$link" ]; then
    rm "$link"
    echo -e "  ${GREEN}✅ Removed symlink: $(basename $dir)/$SKILL_NAME${NC}"
  fi
done

# 2. 소스 디렉토리 제거
if [ -d "$SOURCE_PATH" ]; then
  rm -rf "$SOURCE_PATH"
  echo -e "  ${GREEN}✅ Removed source: $SOURCE_TYPE/skills/$SKILL_NAME/${NC}"
elif [ -f "$SOURCE_PATH" ]; then
  rm "$SOURCE_PATH"
  echo -e "  ${GREEN}✅ Removed source: $SOURCE_TYPE/skills/$SKILL_NAME${NC}"
fi

# 3. 잔여물 확인 (다른 위치에 남아있을 수 있음)
residual_count=0
for dir in "$CLAUDE_SKILLS" "$AGENTS_SKILLS"; do
  # 깨진 symlink
  if [ -L "$dir/$SKILL_NAME" ] && [ ! -e "$dir/$SKILL_NAME" ]; then
    rm "$dir/$SKILL_NAME"
    echo -e "  ${GREEN}🧹 Cleaned broken symlink: $(basename $dir)/$SKILL_NAME${NC}"
    residual_count=$((residual_count + 1))
  fi
  # 실제 디렉토리 (symlink이 아닌)
  if [ -d "$dir/$SKILL_NAME" ] && [ ! -L "$dir/$SKILL_NAME" ]; then
    rm -rf "$dir/$SKILL_NAME"
    echo -e "  ${GREEN}🧹 Cleaned residual directory: $(basename $dir)/$SKILL_NAME${NC}"
    residual_count=$((residual_count + 1))
  fi
done

echo ""
echo -e "${GREEN}✨ Done! Skill '$SKILL_NAME' removed.${NC}"
if [ -n "$REPLACE_WITH" ]; then
  echo -e "   Replacement: ${GREEN}$REPLACE_WITH${NC} is active."
fi
