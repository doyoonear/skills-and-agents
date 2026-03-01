---
name: wrap
description: |
  세션 작업 마무리 자동화. 변경사항을 기능 단위로 커밋 분리, 세션 리포트 작성 후 커밋, PR 생성까지 일괄 수행.
  Use when wrapping up a session, or when user mentions "/wrap", "정리해줘", "세션 마무리", "작업 정리", "wrap up", "마무리해줘".
  Not for individual git commits or branch management.
---

# Wrap - 세션 마무리 자동화

현재 세션에서 작업한 내용을 분석하여 기능 단위 커밋 분리 → 세션 리포트 작성 & 커밋 → PR 생성을 순차 수행한다.

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
- conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:` 등
- 기존 커밋 히스토리의 언어(한국어/영어)를 따름
- `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` 포함

**커밋 순서:**
1. 인프라/설정 변경
2. 핵심 기능 구현
3. UI/스타일 변경
4. 테스트/문서

### 3. 세션 리포트 작성 & 커밋

프로젝트 루트의 `docs/session-report/` 디렉토리에 리포트를 작성한다. 디렉토리가 없으면 생성.

**파일명:** `{YYYY-MM-DD}-{프로젝트-타이틀-kebab-case}.md`
- 날짜는 작성 당시 날짜
- 프로젝트 타이틀은 작업 내용을 요약하는 짧은 kebab-case 제목

**템플릿:** `references/report-template.md` 참조하여 작성.

리포트를 별도 커밋으로 추가:
```
docs: 세션 리포트 작성 ({날짜})
```

### 4. PR 생성

```bash
gh pr create --title "{타이틀}" --body "{본문}"
```

- PR 타이틀: 세션에서 수행한 주요 작업 요약 (70자 이내)
- PR 본문: Summary, 변경사항, 커밋 목록 포함. HEREDOC 사용.
- base 브랜치: main
- 리모트에 push 필요 시 `-u` 플래그로 push 후 PR 생성
- **머지는 수행하지 않음** (사용자가 직접 머지)

### 5. 완료 보고

수행한 작업 요약:
- 생성된 커밋 수와 각 커밋 메시지
- PR 링크
- 세션 리포트 파일 경로
