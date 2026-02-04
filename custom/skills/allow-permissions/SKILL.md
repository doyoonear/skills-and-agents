---
name: allow-permissions
description: |
  스크린샷/이미지에서 권한 요청 메시지를 분석하여 필요한 커맨드 권한을 전역 settings.json에 자동 추가.
  다음 요청 시 사용: "/allow-permissions", "권한 추가해줘", "이 커맨드 허용해줘"
  한글 트리거: "권한 추가", "퍼미션 추가", "settings에 권한 추가", "커맨드 허용"
---

# Allow Permissions Skill

스크린샷에서 Claude Code 권한 요청 메시지를 분석하여 전역 settings.json에 필요한 권한을 자동으로 추가합니다.

## Workflow

### Step 1: 이미지 확인

**사용자가 이미지를 직접 제공한 경우:**
- 제공된 모든 이미지를 분석 대상으로 사용

**사용자가 이미지를 제공하지 않은 경우:**
1. 스크린샷 폴더 확인: `~/Documents/screenshot`
2. 사용자에게 몇 개의 최근 스크린샷을 분석할지 질문
3. 기본값: 가장 최근 1개

### Step 2: 이미지 분석

각 이미지에서 권한 요청 패턴 식별:

**일반적인 Claude Code 권한 요청 형식:**
- `Claude wants to run Bash(command)`
- `Claude wants to use Tool(pattern)`
- `Allow once` / `Allow always` 버튼이 표시된 다이얼로그

**추출 대상:**
- Bash 커맨드: `Bash(npm *)`, `Bash(pnpm build)` 등
- Tool 권한: `Read(path)`, `Write(path)`, `Edit(path)` 등
- MCP 도구: `mcp__server__tool` 패턴

**여러 이미지 처리:**
- 모든 이미지에서 추출한 권한을 하나의 목록으로 통합
- 중복 제거 후 처리

### Step 3: 전역 settings.json 확인

경로: `~/.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      ...
    ],
    "deny": [...],
    "ask": [...]
  }
}
```

### Step 4: 권한 추가 로직

**권한 변환 규칙:**

| 이미지에서 추출 | settings.json에 추가 |
|----------------|---------------------|
| `Bash(npm install)` | `Bash(npm *)` (와일드카드 일반화) |
| `Bash(pnpm run dev)` | `Bash(pnpm *)` |
| `Bash(python script.py)` | `Bash(python3 *)` |
| `Read(/path/to/file)` | `Read(~/**)` (경로 일반화) |
| `mcp__server__tool` | `mcp__server__*` (서버 단위 와일드카드) |

**중복 확인:**
- 이미 동일하거나 더 넓은 범위의 권한이 있으면 추가하지 않음
- 예: `Bash(npm *)` 이 있으면 `Bash(npm install)` 추가 불필요

**추가 시 주의:**
- deny 목록과 충돌하지 않는지 확인
- 보안에 민감한 커맨드는 사용자에게 확인 요청

### Step 5: 권한 검증 (이미 권한이 있는 경우)

모든 권한이 이미 등록되어 있는 경우:

1. 각 이미지에서 실행하려던 실제 커맨드 추출
2. 해당 커맨드가 동작하는지 테스트:
   ```bash
   which <command>  # 커맨드 존재 확인
   <command> --version  # 버전 확인 (가능한 경우)
   ```
3. 동작하지 않는 경우:
   - 커맨드 설치 필요 여부 안내
   - PATH 문제인지 확인
   - 권한 패턴이 정확한지 검토

### Step 6: 결과 보고

작업 완료 후 보고 형식:

```
## 권한 추가 결과

### 분석한 이미지
- image1.png, image2.png (총 2개)

### 추가된 권한
- `Bash(newcmd *)`
- `Bash(anothercmd *)`

### 이미 있는 권한 (스킵)
- `Bash(npm *)` - 기존 권한으로 커버됨

### 검증 결과 (해당 시)
- `newcmd`: ✅ 동작 확인
- `othercmd`: ❌ 설치 필요 (`brew install othercmd`)
```

## 보안 주의사항

다음 패턴은 사용자 확인 없이 추가하지 않음:
- `Bash(rm -rf *)` - 위험한 삭제
- `Bash(sudo *)` - 루트 권한
- `Bash(curl * | sh)` - 원격 스크립트 실행
- 패스워드/토큰이 포함된 커맨드
