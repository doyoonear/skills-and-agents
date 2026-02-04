# Skills and Agents Repository

Claude Code와 다른 AI 에이전트에서 사용하는 커스텀 스킬과 에이전트를 관리하는 통합 레포지토리입니다.

## 구조

```
skills-and-agents/
├── README.md
├── install.sh              # symlink 동기화 스크립트
├── custom/                 # 직접 작성한 스킬/에이전트
│   ├── skills/            # 커스텀 스킬 (44개)
│   └── agents/            # 커스텀 에이전트 (4개)
├── external/              # 외부에서 가져온 스킬/에이전트
│   ├── skills/            # 외부 스킬 (41개)
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

### External 스킬 추가

외부 소스에서 스킬을 가져올 때:

```bash
# 1. external/skills/에 복사
cp -r /path/to/external-skill external/skills/

# 2. symlink 동기화
./install.sh

# 3. Git commit
git add external/skills/external-skill
git commit -m "Add external skill: external-skill"
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

## 백업

`backup/` 폴더는 `.gitignore`에 포함되어 있으며, 로컬 백업 용도로 사용됩니다.

## License

MIT
