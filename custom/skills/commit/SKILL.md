---
name: commit
description: |
  현재 변경사항을 빠르게 커밋. git status/diff 분석 → 커밋 메시지 생성 → 커밋 수행.
  Use when user mentions "/commit", "커밋해줘", "커밋", "변경사항 저장", "commit this", "save changes".
  Not for session wrap-up with PR (use /wrap), branch management, or push.
---

# Commit - 빠른 커밋

현재 변경사항을 분석하여 적절한 커밋 메시지와 함께 커밋한다. PR/push 없이 커밋만 수행.

## 워크플로우

### 1. 변경사항 파악

- 현재 상태: !`git status`
- 변경 통계: !`git diff --stat`
- 변경 내용: !`git diff`
- 최근 커밋: !`git log --oneline -5`

- staged/unstaged/untracked 모두 파악
- 변경 없으면 "커밋할 변경사항이 없습니다" 보고 후 종료

### 2. 커밋 단위 판단

변경사항이 **단일 목적**이면 하나의 커밋, **여러 목적**이면 분리한다.

**단일 커밋 기준:**
- 모든 변경이 하나의 기능/수정/개선에 속할 때
- 파일 수가 적고 변경 의도가 명확할 때

**분리 기준 (2개 이상 커밋):**
- 설정 변경 + 기능 구현처럼 성격이 다른 변경이 섞여 있을 때
- 판단이 어려우면 사용자에게 확인

### 3. 커밋 메시지 작성

**형식:**
- 제목: conventional commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:` 등)
- 본문: 변경 내용 요약 (간결하게)
- 기존 커밋 히스토리의 언어(한국어/영어)를 따름
- `Co-Authored-By: Claude <noreply@anthropic.com>` 포함

```
docs: 이력서 데이터 업데이트

토스증권/당근마켓 이력서 선택 항목 변경.

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 4. 커밋 수행

```bash
# 파일별로 명시적 staging (git add -A 사용 금지)
git add <파일1> <파일2> ...

# HEREDOC으로 커밋
git commit -m "$(cat <<'EOF'
feat: 커밋 메시지

본문.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

- `.env`, credentials 등 민감 파일은 제외하고 경고
- pre-commit hook 실패 시: 수정 후 **새 커밋** 생성 (amend 금지)

### 5. 완료 보고

```
✅ 커밋 완료
├── 커밋: {short hash} {메시지}
├── 파일: {N}개 변경
└── 브랜치: {브랜치명}
```

## 하지 않는 것

- push하지 않음
- PR 생성하지 않음
- 브랜치 생성/변경하지 않음
- handoff 문서 생성하지 않음
