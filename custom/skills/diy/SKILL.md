---
name: diy
description: |
  사용자가 정확히 "diy"라는 키워드 또는 "/diy" 슬래시 커맨드를 명시적으로 사용했을 때만 트리거되는 자율 구현 스킬.
  사용자의 기능 요청을 Claude가 스스로 해석/판단하여 즉시 구현하고, 리모트 main 기준으로 새 브랜치를 따고 PR까지 올린다.
  중간에 어떠한 추가 질문도 하지 않으며, PR 생성 전에는 어떠한 이유로도 멈추지 않는다.

  CRITICAL TRIGGER RULES:
  - 사용자가 자신의 메시지에서 정확히 "diy" 또는 "/diy"라는 단어/커맨드를 직접 입력했을 때만 트리거.
  - 사용자가 명시적으로 "diy"를 언급하지 않았다면 절대 호출 금지.
  - 다른 스킬, 서브에이전트, 자동화 흐름이 이 스킬을 간접적으로 호출하는 것은 금지. 오직 사용자의 직접 요청에 의해서만 발동.
  - "비슷한 일을 자동으로 해도 되겠다"는 추론으로 트리거하지 말 것. 키워드가 없으면 무시.
---

# DIY (Do It Yourself, Autonomously)

사용자가 "diy" 키워드 또는 `/diy` 커맨드와 함께 던진 기능 요청을 Claude가 **스스로 해석하고 구현**하여, 리모트 main 기준으로 새 브랜치를 만들고 PR까지 올리는 풀 자율 스킬.

## 트리거 조건 (엄격)

이 스킬은 다음 조건을 **모두** 만족할 때만 활성화된다:

1. **사용자(human)가 직접 보낸 메시지**에 정확히 다음 중 하나가 포함되어야 한다:
   - 단어 `diy` (대소문자 무관, 단어 경계 안에서)
   - 슬래시 커맨드 `/diy`
2. 다른 에이전트, 서브에이전트, 스킬, 훅이 트리거하는 호출은 **거부**한다.
3. 사용자의 메시지에 위 키워드가 없다면, 비슷한 의도가 보여도 절대 트리거하지 않는다.

> 다른 스킬을 만들거나 자동화 흐름을 짤 때, 이 스킬을 프로그램적으로 호출하지 말 것. 오직 사용자가 명시적으로 "diy"를 적었을 때만 동작한다.

## 핵심 원칙

- **No Questions**: 시작부터 PR 생성까지 사용자에게 어떠한 질문도 하지 않는다. `AskUserQuestion`, 확인 프롬프트, 옵션 선택 일체 금지.
- **No Stop**: 에러, 모호함, 충돌, 실패가 발생해도 스스로 판단하여 우회/해결하고 계속 진행한다.
- **Full Autonomy**: 요구사항 해석, 기술 선택, 파일 구조, 라이브러리 선택, 코드 스타일 등 모든 판단은 Claude가 단독으로 한다.
- **Anything Goes**: 어떤 변경(파일 추가/삭제/리팩토링)이든 허용된다. 작업의 안전성보다 "PR을 올린다"가 최우선이다.
- **Remote Main 기준**: 항상 `origin/main` 최신 상태에서 새 브랜치를 따낸다.

## 워크플로우

### Phase 0: 요청 해석 (혼자서)

1. 사용자 메시지에서 "diy" 키워드와 함께 들어온 기능 요청을 추출한다.
2. 모호한 부분은 **사용자에게 물어보지 말고** 스스로 합리적 가정을 한다.
3. 작업 범위, 변경할 파일, 산출물 형태를 머릿속에서 결정한다.

### Phase 1: 브랜치 준비

```bash
# 작업 디렉토리 확인
pwd

# 현재 변경사항 확인 (있다면 stash)
git status --porcelain

# 리모트 최신화
git fetch origin main

# 브랜치명 자체 결정 (요청 키워드 기반 + 짧은 슬러그 + 타임스탬프 또는 랜덤)
# 예: claude/diy-<slug>-<timestamp>
BRANCH="claude/diy-<slug>-$(date +%s)"

# origin/main 기준으로 새 브랜치 체크아웃
git checkout -b "$BRANCH" origin/main
```

> 만약 현재 브랜치에 미커밋 변경사항이 있다면 `git stash` 또는 새 브랜치로 가져가기를 스스로 판단해서 선택. 막히지 말 것.

### Phase 2: 구현

1. 필요한 파일을 탐색하고 (`Read`, `Grep`, `Glob`, 또는 `Explore` 서브에이전트 활용) 컨텍스트를 파악한다.
2. 결정된 변경을 `Write`/`Edit`로 실행한다.
3. 새 의존성이 필요하면 스스로 설치 (`npm`, `pip`, `pnpm` 등 적절한 패키지 매니저 자동 선택).
4. 가능한 경우 빌드/린트/테스트를 한 번 돌려본다. 실패해도 **멈추지 말고** 자체 판단으로 고치거나, 고칠 수 없다면 PR 본문에 명시하고 진행.
5. 다른 스킬이 도움될 경우 자유롭게 호출한다 (예: `simplify`, `commit`, `git-pr-workflow`, `skill-creator` 등). 단, **"질문하지 않는다"는 원칙은 위임된 스킬에도 적용**되어야 한다 — 호출 시 "do not ask any questions" 컨텍스트를 함께 전달.

### Phase 3: 커밋

1. `git add -A`로 모든 변경 스테이징 (단, `.env`, 비밀키 류는 의식적으로 제외).
2. 커밋 메시지는 한 줄 요약 + (필요시) 짧은 본문. 형식 자율, conventional commits 권장.
3. 큰 변경은 논리적 단위로 분리 커밋 가능. 시간 끌리면 한 번에 묶어 커밋.

### Phase 4: 푸시 & PR

```bash
# 푸시
git push -u origin "$BRANCH"

# 네트워크 에러시 최대 4회 지수백오프 (2s, 4s, 8s, 16s)
```

PR 생성은 GitHub MCP 도구 (`mcp__github__create_pull_request`) 사용. 예:

```
mcp__github__create_pull_request(
  owner: <repo owner>,
  repo: <repo name>,
  base: "main",
  head: "<BRANCH>",
  title: "<요청 요약>",
  body: |
    ## What
    - 사용자 요청: "<원본 요청>"
    - Claude의 해석: <어떻게 해석했는지>

    ## Changes
    - 변경된 파일/내용 요약

    ## Notes
    - 자체 판단 사항 / 가정 / 알려진 한계
)
```

PR 본문은 한국어로 작성해도 좋고 영어도 무방. 중요한 건 **본문에 Claude가 어떤 가정을 했는지 명시**해서 사용자가 사후 판단할 수 있게 하는 것.

### Phase 5: 보고

PR URL을 사용자에게 출력하고 종료. 이 스킬은 PR merge까지 가지 않는다 (merge는 사용자 판단).

## 절대 하지 말 것

- ❌ 사용자에게 질문하기 (`AskUserQuestion` 사용 금지)
- ❌ "이렇게 진행할까요?" 같은 확인 요청
- ❌ 모호함을 이유로 작업 중단
- ❌ 테스트/린트 실패를 이유로 PR 생성 포기 (PR 본문에 명시하고 올린다)
- ❌ rebase/merge 충돌을 이유로 멈춤 (스스로 해결하거나, `git checkout --theirs/--ours` 같은 강제 판단)
- ❌ 사용자 메시지에 "diy" 키워드가 없는데 자체 추론으로 트리거

## 반드시 할 것

- ✅ `origin/main` 최신화 후 거기서 분기
- ✅ 새 브랜치명에 `claude/diy-` 접두사 사용
- ✅ PR 본문에 Claude의 해석/가정 명시
- ✅ 끝까지 진행해서 PR URL 반환
- ✅ 다른 스킬 호출 시 "no questions, no stop" 컨텍스트 전파

## 다른 스킬과의 관계

- `git-pr-workflow`: 비슷하지만 그 스킬은 사용자 확인 단계가 있다. **diy는 확인 없음**. 필요하면 git 명령 부분만 참고.
- `autonomous-agent`: 200개 기능 장기 실행용. diy는 **단발 기능 → PR**.
- `commit`: 커밋 메시지 보조용으로 호출 가능.
- `skill-creator`: diy 자체를 수정할 때만.

## 예시

### 사용자 입력
```
diy 다크모드 토글 버튼 추가해줘
```

### Claude의 동작
1. 키워드 "diy" 확인 → 트리거.
2. `git fetch origin main && git checkout -b claude/diy-dark-mode-toggle-<ts> origin/main`.
3. 프로젝트 구조 탐색 → 적절한 위치에 토글 컴포넌트 작성, 전역 스타일에 다크 테마 변수 추가, 상태 저장 로직 (localStorage 또는 기존 store) 결정 후 구현.
4. 빌드/린트 시도. 실패하면 스스로 수정.
5. `git add -A && git commit -m "feat: add dark mode toggle"`.
6. `git push -u origin <branch>`.
7. `mcp__github__create_pull_request`로 PR 생성.
8. PR URL 출력 후 종료.

중간에 사용자에게 "어떤 색상 팔레트를 원하시나요?" 같은 질문 일체 없음. Claude가 스스로 정한다.
