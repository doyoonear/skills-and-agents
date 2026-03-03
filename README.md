# Skills and Agents Repository

Claude Code와 다른 AI 에이전트에서 사용하는 커스텀 스킬과 에이전트를 관리하는 통합 레포지토리입니다.

## 구조

```
skills-and-agents/
├── README.md
├── install.sh              # symlink 동기화 스크립트
├── install-skill.sh        # 외부 스킬 설치 래퍼 (skills CLI + 자동 정리)
├── custom/                 # 직접 작성한 스킬/에이전트
│   ├── skills/            # 커스텀 스킬 (44개)
│   └── agents/            # 커스텀 에이전트 (4개)
├── external/              # 외부에서 가져온 스킬/에이전트
│   ├── skills/            # 외부 스킬 (47개)
│   └── agents/            # 외부 에이전트 (0개)
└── backup/                # 로컬 백업 (gitignore)
```

## Custom vs External

### Custom
- 직접 작성하고 유지보수하는 스킬/에이전트
- 프로젝트 특화 로직, 개인 워크플로우 등
- Git으로 버전 관리 및 공유

### External
- 커뮤니티나 외부 소스에서 가져온 스킬/에이전트
- awesome-claude-skills, openskills 등에서 설치
- 원본 유지하며 필요시 커스터마이징

## 설치

```bash
git clone https://github.com/doyoonear/skills-and-agents.git ~/skills-and-agents
cd ~/skills-and-agents
./install.sh
```

`install.sh`는 다음 위치에 symlink를 생성합니다:
- `~/.claude/skills/` - Claude Code용 스킬
- `~/.claude/agents/` - Claude Code용 에이전트
- `~/.agents/skills/` - 범용 에이전트 스킬 (Cursor, Windsurf 등)

## 스킬 추가/변경

### Custom 스킬 추가

1. `custom/skills/` 폴더에 스킬 추가 (폴더 또는 `.md` 파일)
2. `./install.sh` 실행하여 symlink 동기화
3. Git commit & push

**폴더 형식** (권장):
```
custom/skills/my-skill/
├── SKILL.md        # 메인 스킬 파일
├── scripts/        # 스크립트 (선택)
├── references/     # 참고 문서 (선택)
└── assets/         # 리소스 파일 (선택)
```

**단일 파일 형식**:
```
custom/skills/my-guide.md
```

### SKILL.md 예시

```yaml
---
name: my-skill
description: 스킬 설명 및 트리거 키워드
---

# My Skill

스킬 지시사항...
```

### External 스킬 추가 (skills CLI 래퍼)

`install-skill.sh`를 사용하면 skills CLI로 설치한 스킬을 자동으로 `external/skills/`에 정리하고 symlink까지 생성합니다.

```bash
cd ~/Desktop/dev_else/_my-projects/skills-and-agents

# 레포의 전체 스킬 목록 확인 후 선택 설치
./install-skill.sh coreyhaines31/marketingskills

# 특정 스킬만 지정 설치
./install-skill.sh coreyhaines31/marketingskills -s ab-test-setup

# 레포의 모든 스킬 일괄 설치
./install-skill.sh coreyhaines31/marketingskills --all
```

**패키지 이름 형식** — 아래 세 가지 모두 동일하게 동작합니다:

```bash
# GitHub 축약형 (owner/repo) — 권장
./install-skill.sh coreyhaines31/marketingskills

# GitHub 전체 URL
./install-skill.sh https://github.com/coreyhaines31/marketingskills

# .git 확장자 포함 URL
./install-skill.sh https://github.com/coreyhaines31/marketingskills.git
```

**동작 흐름:**
1. `npx skills add <package> -g` 실행 (글로벌 설치)
2. `~/.agents/skills/`에 생긴 새 스킬을 `external/skills/`로 자동 이동
3. `install.sh` 실행하여 symlink 재생성 (`~/.agents/skills/`, `~/.claude/skills/`)

### External 스킬 수동 추가

래퍼 없이 직접 추가할 때:

```bash
# 1. external/skills/에 복사
cp -r /path/to/external-skill external/skills/

# 2. symlink 동기화
./install.sh
```

## 에이전트 관리

에이전트는 `custom/agents/` 또는 `external/agents/`에 `.md` 파일로 추가합니다.

```bash
# 커스텀 에이전트 추가
echo "# My Agent" > custom/agents/my-agent.md
./install.sh
```

## 다른 AI 에이전트 지원

현재 지원하는 플랫폼:
- **Claude Code**: `~/.claude/skills/`, `~/.claude/agents/`
- **범용 에이전트 (Cursor, Windsurf 등)**: `~/.agents/skills/`

다른 플랫폼 symlink가 필요하면 `install.sh`를 수정하세요.

## Agentation & Agent-Browser 사용 가이드

UI 시각적 피드백 + AI 자율 디자인 리뷰를 위한 도구 세트입니다.

### 구성 요소

| 항목 | 종류 | 역할 |
|------|------|------|
| `agentation` | 스킬 | 프로젝트에 `<Agentation />` 툴바 세팅 |
| `agentation-self-driving` | 스킬 | AI가 자율적으로 브라우저를 순회하며 디자인 비평 |
| `agentation-mcp` | MCP 서버 | 에이전트 ↔ 브라우저 주석 실시간 양방향 통신 |
| `agent-browser` | CLI 도구 + 스킬 | AI 에이전트 전용 브라우저 자동화 |

### 사전 요구사항

```bash
# agent-browser CLI (전역 설치)
npm install -g agent-browser
agent-browser install  # Chromium 다운로드

# MCP 서버 설정 — Claude Code (~/.claude/settings.json)
# mcpServers에 아래 추가:
# "agentation": { "command": "npx", "args": ["-y", "agentation-mcp", "server"] }

# MCP 서버 설정 — Codex CLI (~/.codex/config.toml)
# [mcp_servers.agentation]
# command = "npx"
# args = ["-y", "agentation-mcp", "server"]
```

### 사용법 1: 프로젝트 세팅 (1회)

프로젝트에 Agentation 툴바를 추가합니다. 한 번만 실행하면 됩니다.

```
# Claude Code
/agentation

# Codex CLI
$agentation
```

스킬이 자동으로:
1. `pnpm add agentation -D` (또는 프로젝트의 패키지 매니저)
2. `app/layout.tsx`에 `<Agentation />` 컴포넌트 추가 (dev 환경 only)

### 사용법 2: 수동 피드백 (사람이 직접)

세팅 후 브라우저에서 개발 서버를 열면 Agentation 툴바가 나타납니다.

```
1. UI 요소 위에 마우스 올리고 클릭
2. "이 버튼 색상 바꿔줘" 같은 피드백 작성
3. "Copy" 버튼 → 마크다운 복사 → AI 에이전트에 붙여넣기
```

복사된 내용에는 CSS 선택자, React 컴포넌트명, 계산된 스타일이 포함되어 에이전트가 정확한 위치를 바로 파악합니다.

**MCP 연결 시** 복사-붙여넣기 없이 에이전트에게 직접 요청:
```
주석 확인해서 수정해줘
```

### 사용법 3: AI 자율 디자인 리뷰

AI가 headed 브라우저를 열고, 마우스를 직접 움직이며 페이지를 순회하고 디자인 비평을 남깁니다. 사용자는 실시간으로 구경할 수 있습니다.

```
# 기본 사용
/agentation-self-driving
localhost:3000 페이지 디자인 리뷰해줘

# 특정 페이지 + 관점 지정
/agentation-self-driving
localhost:3000/blog/my-post 타이포그래피랑 간격 위주로 비평해줘

# 특정 영역 집중
/agentation-self-driving
홈페이지 히어로 섹션이랑 CTA 배치 검토해줘
```

AI가 남기는 비평 예시:

| 대상 | 주석 내용 |
|------|-----------|
| 히어로 헤드라인 | "h1과 서브헤딩 사이 간격이 8px로 너무 좁다. 16-24px로 늘리면 시각적 계층이 명확해진다." |
| 블로그 카드 | "카드 간 간격이 불규칙하다. gap: 24px로 통일하고, 호버 시 subtle shadow 추가 권장." |
| CTA 버튼 | "버튼이 주변 텍스트와 시각적 가중치가 비슷하다. 배경색 대비를 높이고 padding 확대." |

### 사용법 4: 풀 자율 모드 (2세션)

**터미널 2개**를 열어 리뷰 + 코드 수정을 동시에 실행합니다.

**세션 1 — 디자인 비평:**
```
/agentation-self-driving
localhost:3000 전체 페이지 디자인 리뷰해줘
```

**세션 2 — 코드 자동 수정:**
```
agentation 주석 감시하면서 들어오는 피드백 자동으로 코드에 반영해줘
```

세션1이 브라우저에서 주석을 남기면, 세션2가 MCP를 통해 실시간으로 받아서 코드를 수정합니다.

### 호환 플랫폼

| 기능 | Claude Code | Codex CLI | Cursor | 기타 |
|------|------------|-----------|--------|------|
| `/agentation` 스킬 | `/agentation` | `$agentation` | 자동 감지 | Agent Skills 표준 지원 도구 |
| MCP 연동 | settings.json | config.toml | 설정 필요 | MCP 지원 도구 |
| `agent-browser` | 지원 | 지원 | 지원 | 대부분 지원 |

### 참고 링크

- [Agentation 공식 사이트](https://agentation.dev)
- [Agentation 설치 가이드](https://agentation.dev/install)
- [agent-browser GitHub](https://github.com/vercel-labs/agent-browser)
- [Agent Skills Standard](https://agentskills.io)

## 백업

`backup/` 폴더는 `.gitignore`에 포함되어 있으며, 로컬 백업 용도로 사용됩니다.

## License

MIT
