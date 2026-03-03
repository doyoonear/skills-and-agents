---
name: wrap
description: |
  세션 작업 마무리 자동화. 변경사항을 기능 단위로 커밋 분리, PR 생성, 남은 작업 handoff까지 일괄 수행.
  Use when wrapping up a session, or when user mentions "/wrap", "정리해줘", "세션 마무리", "작업 정리", "wrap up", "마무리해줘".
  Not for individual git commits or branch management.
---

# Wrap - 세션 마무리 자동화

현재 세션에서 작업한 내용을 분석하여 기능 단위 커밋 분리 → PR 생성(세션 리포트 포함) → 조건부 handoff를 순차 수행한다.

## 워크플로우

### 1. 변경사항 분석

```bash
git status
git diff --stat
git diff
git log --oneline -10
```

- staged/unstaged 변경사항과 untracked 파일을 모두 파악
- 현재 브랜치명과 base 브랜치(main) 확인

### 2. 기능 단위 커밋 분리

변경된 파일들을 **기능/로직 의도**별로 그룹핑하여 각각 별도 커밋한다.

**분리 기준:**
- 동일한 기능을 구현하기 위해 함께 변경된 파일들은 하나의 커밋
- 설정 파일 변경, 리팩토링, 버그 수정, 신규 기능은 각각 분리
- 판단이 어려운 경우 사용자에게 확인

**커밋 메시지 형식:**
- 제목: conventional commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:` 등)
- 본문: 해당 커밋의 작업 내용을 **300자 이내**로 요약
- 기존 커밋 히스토리의 언어(한국어/영어)를 따름
- `Co-Authored-By: Claude <noreply@anthropic.com>` 포함

```
feat: 블로그 카드 커버 이미지 지원

Notion 커버 이미지를 블로그 카드에 표시하도록 구현.
- NotionPost 인터페이스에 coverImage 필드 추가
- fetchPublishedPosts에서 page.cover URL 추출
- downloadCoverImage 함수로 로컬 저장
- MDX frontmatter에 coverImage 경로 포함

Co-Authored-By: Claude <noreply@anthropic.com>
```

**커밋 순서:**
1. 인프라/설정 변경
2. 핵심 기능 구현
3. UI/스타일 변경
4. 테스트/문서

### 3. PR 생성 (세션 리포트 포함)

```bash
gh pr create --title "{타이틀}" --body "{본문}"
```

- PR 타이틀: 세션에서 수행한 주요 작업 요약 (70자 이내)
- PR 본문: **세션 리포트 역할**을 겸함. 아래 형식으로 상세하게 작성. HEREDOC 사용.
- base 브랜치: main
- 리모트에 push 필요 시 `-u` 플래그로 push 후 PR 생성
- **머지는 수행하지 않음** (사용자가 직접 머지)

**PR 본문 형식:**

```markdown
## Summary
- {주요 변경사항 1}
- {주요 변경사항 2}

## Changes
| 파일 | 변경 내용 |
|------|-----------|
| {파일 경로} | {변경 설명} |

## Technical Decisions
- {결정}: {이유}

## Commits
| 커밋 | 메시지 |
|------|--------|
| {short hash} | {커밋 메시지} |

## Test Plan
- [ ] {검증 항목}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 4. 조건부 Handoff

PR에서 **완전히 마무리되지 않은 남은 작업**이 있는지 판단한다.

**handoff가 필요한 경우:**
- 이번 PR에 포함되지 않은 후속 작업이 있는 경우
- 알려진 이슈나 임시 워크어라운드가 남아있는 경우
- 다음 세션에서 이어서 작업해야 할 사항이 있는 경우

**handoff가 불필요한 경우:**
- 작업이 완전히 완료되어 후속 작업이 없는 경우

handoff가 필요하다고 판단되면 `/handoff` 스킬을 호출하여 인수인계를 진행한다.

### 5. 완료 보고

수행한 작업 요약:
- 생성된 커밋 수와 각 커밋 메시지
- PR 링크
- handoff 문서 생성 여부 및 경로 (해당 시)
