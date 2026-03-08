# CLAUDE.md

## Project Overview

A unified repository for managing custom and external skills/agents used by Claude Code and other AI agent platforms. Skills are Markdown-based prompt packages that extend AI assistant capabilities. The repository uses symlinks to distribute skills to `~/.claude/skills/`, `~/.claude/agents/`, and `~/.agents/skills/`.

**Primary language:** Markdown (documentation/skill definitions), Bash (installation scripts)
**Supported platforms:** Claude Code, Cursor, Windsurf, Codex CLI (via Agent Skills Standard)

## Repository Structure

```
skills-and-agents/
├── CLAUDE.md               # This file
├── README.md               # User-facing documentation (Korean)
├── install.sh              # Main symlink synchronization script
├── install-skill.sh        # External skill installation wrapper
├── custom/                 # User-created skills/agents (git-managed)
│   ├── skills/             # 48 custom skills
│   ├── agents/             # 4 custom agents
│   └── hooks/              # Claude Code plugin hooks
├── external/               # Community/third-party skills
│   └── skills/             # 74 external skills
└── backup/                 # Local backup (gitignored)
```

### Custom vs External

- **`custom/`** — Self-authored skills/agents. Actively maintained and version-controlled.
- **`external/`** — Community skills installed from sources like awesome-claude-skills, openskills. Kept as-is; minimal modifications.

## Key Commands

```bash
# Sync all symlinks (run after any skill/agent changes)
./install.sh

# Install an external skill (wraps npx skills add)
./install-skill.sh <owner/repo>
./install-skill.sh <owner/repo> -s <skill-name>
./install-skill.sh <owner/repo> --all
```

There is no build system, test suite, or linter. This is a documentation-only repository.

## Skill File Conventions

### Naming

- **All names use kebab-case**: `my-skill-name`, `error-handling-system.md`
- No uppercase, snake_case, or camelCase

### Directory-based skill (recommended for complex skills)

```
custom/skills/my-skill/
├── SKILL.md          # Main skill file (required)
├── prompts/          # Prompt templates (optional)
├── templates/        # JSON/script templates (optional)
├── scripts/          # Helper scripts (optional)
└── references/       # Supporting docs (optional)
```

### Single-file skill

```
custom/skills/my-guide.md
```

### YAML Frontmatter Format

Every skill file must include YAML frontmatter with at minimum `name` and `description`:

```yaml
---
name: skill-name
description: |
  Brief description of the skill.
  Use when [trigger conditions].
  Not for [exclusions].
---

# Skill Title

Instructions and content...
```

The `description` field should include trigger keywords and exclusion conditions so Claude Code knows when to activate the skill.

### Agent Format

Agents are single `.md` files in `custom/agents/` or `external/agents/`:

```markdown
# Agent Name

Description.

## When to Use
- Trigger condition 1
- Trigger condition 2

## Tools Used
- Read, Grep, Glob, Bash, etc.

## Workflow
1. Step 1
2. Step 2

## Checklist
- [ ] Verification item
```

## Git Conventions

- **Commit style:** Conventional commits with Korean messages
  - `feat:` — New skill or feature
  - `refactor:` — Restructuring existing skills
  - `docs:` — Documentation updates
  - `update:` — Enhancements to existing skills
  - `misc:` — Other changes
- **Examples:**
  - `feat: npx skills add 가로채기 hook 추가`
  - `refactor: 시각 검증 루프 도구를 MCP Playwright에서 agent-browser로 전환`

## Architecture Notes

### Symlink Distribution

```
custom/skills/my-skill/ ──symlink──→ ~/.claude/skills/my-skill
                        ──symlink──→ ~/.agents/skills/my-skill

external/skills/some-skill/ ──symlink──→ ~/.claude/skills/some-skill
                            ──symlink──→ ~/.agents/skills/some-skill

custom/agents/my-agent.md ──symlink──→ ~/.claude/agents/my-agent.md
```

`install.sh` cleans old symlinks from this repo before recreating them, so it is safe to run repeatedly.

### Hook/Plugin System

`custom/hooks/skill-sync/` is a Claude Code plugin that:
- Intercepts `npx skills add` commands to auto-organize into `external/skills/`
- Runs `install.sh` after skill changes to keep symlinks in sync

## Important Notes for AI Assistants

1. **Do not modify `external/` skills** — they are third-party and should be kept as-is.
2. **Run `./install.sh` after adding or removing any skill/agent** to sync symlinks.
3. **Follow kebab-case naming** for all new files and directories.
4. **Include YAML frontmatter** with `name` and `description` in all skill files.
5. **Write commit messages in Korean** following the conventional commit format.
6. **README.md is in Korean** — maintain Korean for user-facing documentation.
7. **SKILL.md is the entry point** for directory-based skills — this is the file Claude Code reads.
