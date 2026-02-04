---
name: git-pr-workflow
description: |
  Git 브랜치 생성부터 PR merge까지 전체 워크플로우를 자동화합니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "PR 올려줘"
  - "브랜치 만들고 PR 생성해줘"
  - "변경사항 커밋하고 PR 만들어줘"
  - "git workflow 실행해줘"
  - "/pr"
---

# Git PR Workflow

변경사항 분석 → 브랜치 생성 → 기능별 커밋 → rebase → PR 생성 → merge까지 자동화합니다.

## 워크플로우 개요

```
1. 변경사항 분석
2. 브랜치명 확인 (사용자 입력)
3. 기능별 자동 커밋
4. main 최신화 & rebase
5. 브랜치 푸시
6. PR 생성 (제목 확인)
7. Rebase merge
```

## 실행 단계

### 1단계: 사전 검증

```bash
# Git 저장소인지 확인
git rev-parse --git-dir

# gh CLI 인증 확인
gh auth status

# 현재 브랜치 확인
git branch --show-current

# 변경사항 존재 확인
git status --porcelain
```

**검증 실패 시:**
- Git 저장소가 아니면: 에러 메시지 출력 후 종료
- gh 인증 안됨: `gh auth login` 안내
- 변경사항 없음: "커밋할 변경사항이 없습니다" 출력 후 종료

### 2단계: 변경사항 분석

```bash
# staged + unstaged 변경사항
git status --porcelain

# 변경 내용 확인
git diff
git diff --cached
```

**분석 내용:**
- 변경된 파일 목록 수집
- 파일 경로/확장자 기반으로 기능 그룹 추론
- 각 파일의 변경 내용 요약

### 3단계: 브랜치명 결정

AskUserQuestion 도구로 브랜치명 확인:

```
질문: 브랜치명을 입력해주세요
제안: feat/[변경사항-요약] 또는 fix/[이슈-요약]
옵션:
  - AI가 분석한 제안 브랜치명 1
  - AI가 분석한 제안 브랜치명 2
  - Other (직접 입력)
```

**브랜치 생성:**
```bash
# 현재 main이 아니고 이미 feature 브랜치면 그대로 사용할지 확인
git checkout -b <브랜치명>
```

### 4단계: 기능별 자동 커밋

**파일 그룹화 로직:**

1. **디렉토리 기반**: 같은 디렉토리의 파일들을 우선 그룹화
2. **연관성 분석**:
   - 컴포넌트 + 스타일 + 테스트 파일 → 하나의 커밋
   - API 엔드포인트 + 타입 정의 → 하나의 커밋
   - 설정 파일들 → 별도 커밋
3. **변경 유형**:
   - 새 파일 추가
   - 기존 파일 수정
   - 파일 삭제

**커밋 메시지 형식:**
```
<type>(<scope>): <description>

- 변경사항 1
- 변경사항 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**type 종류:**
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `style`: 스타일/포맷 변경
- `docs`: 문서 변경
- `test`: 테스트 추가/수정
- `chore`: 설정, 빌드 관련

**커밋 실행:**
```bash
# 그룹별로 반복
git add <파일들>
git commit -m "<메시지>"
```

### 5단계: Main 최신화 & Rebase

```bash
# main 최신화
git fetch origin main

# rebase 실행
git rebase origin/main
```

**충돌 발생 시:**
- 충돌 파일 목록 출력
- 사용자에게 수동 해결 안내
- `git rebase --continue` 또는 `git rebase --abort` 안내
- 워크플로우 일시 중단

### 6단계: 브랜치 푸시

```bash
git push -u origin <브랜치명>
```

**force push 필요 시 (rebase 후):**
```bash
git push -u origin <브랜치명> --force-with-lease
```

### 7단계: PR 생성

AskUserQuestion으로 PR 제목 확인:

```
질문: PR 제목을 확인해주세요
제안: [AI가 생성한 PR 제목]
옵션:
  - 제안된 제목 사용
  - Other (직접 입력)
```

**PR 본문 형식 (Summary + Checklist):**
```markdown
## Summary
- 주요 변경사항 1
- 주요 변경사항 2
- 주요 변경사항 3

## Changes
- `path/to/file1.ts`: 변경 설명
- `path/to/file2.ts`: 변경 설명

## Test Checklist
- [ ] 로컬에서 빌드 확인
- [ ] 관련 기능 테스트 완료
- [ ] 코드 리뷰 요청

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**PR 생성:**
```bash
gh pr create --title "<제목>" --body "$(cat <<'EOF'
<본문>
EOF
)"
```

### 8단계: Rebase Merge

```bash
# PR URL 출력
gh pr view --web

# merge 실행
gh pr merge --rebase --delete-branch
```

**merge 실패 시:**
- CI 체크 실패: 체크 상태 출력, 수동 확인 안내
- 리뷰 필요: 리뷰어 할당 안내
- 충돌: 최신 main으로 rebase 필요 안내

## 사용자 확인 포인트

이 워크플로우에서 사용자 입력이 필요한 시점:

| 단계 | 확인 내용 | 기본값 |
|------|----------|--------|
| 3 | 브랜치명 | AI 제안 |
| 7 | PR 제목 | AI 생성 |

## 에러 처리

### 일반 에러
- 각 git 명령 실행 후 exit code 확인
- 실패 시 현재 상태 출력하고 복구 방법 안내

### Rebase 충돌
```
⚠️ Rebase 중 충돌이 발생했습니다.

충돌 파일:
- path/to/conflicted/file.ts

해결 방법:
1. 충돌 파일을 수동으로 수정
2. git add <파일>
3. git rebase --continue

또는 rebase 취소:
git rebase --abort
```

### PR 생성 실패
```
⚠️ PR 생성에 실패했습니다.

원인: [에러 메시지]

확인사항:
- gh auth status 로 인증 상태 확인
- 동일 브랜치의 기존 PR이 있는지 확인
```

## 주의사항

1. **main 브랜치 보호**: main에서 직접 실행하면 새 브랜치 생성 필수
2. **force push**: rebase 후에만 --force-with-lease 사용
3. **CI 체크**: merge 전 CI 통과 확인 권장
4. **리뷰 정책**: 팀 리뷰 정책에 따라 자동 merge 비활성화 가능

## 선택적 기능

### 드라이런 모드
실제 실행 없이 어떤 작업이 수행될지 미리 확인:
```
/pr --dry-run
```

### 커밋만 실행
PR 생성 없이 커밋까지만:
```
/pr --commit-only
```

### 기존 브랜치 사용
새 브랜치 생성 없이 현재 브랜치에서 진행:
```
/pr --current-branch
```
