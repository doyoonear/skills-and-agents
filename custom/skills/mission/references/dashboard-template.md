# Dashboard Template Reference

materializer가 DASHBOARD.md를 생성할 때 사용하는 형식입니다.

## 형식

```markdown
# Mission: {slug}

> {mission.json의 description}

## 현재 상태

| Task | 상태 | 담당 | 마지막 업데이트 | 비고 |
|------|------|------|-------------|------|
| T1: {title} | {status_icon} {status} | {ownerLabel} | {lastActivity} | {notes} |

## 활성 세션

| 세션 | 현재 작업 | 마지막 활동 |
|------|----------|------------|
| {label} ({sessionId}) | {current_task} | {lastActivity} |

## 경고

- {severity_icon} [{code}] {message}

## 완료 요약 (archived)

| Task | 완료 시각 | 담당 | 요약 |
|------|----------|------|------|
| {id}: {title} | {doneAt} | {ownerLabel} | {summary} |

---
*자동 생성: {updatedAt} | materializer v1*
```

## 상태 아이콘

| status | icon |
|--------|------|
| done | ✅ |
| in_progress | 🔄 |
| claimed | 🔒 |
| open | ⏳ |
| blocked | 🚫 |

## 비고 필드 규칙

- blocked by 의존 태스크: `blocked by T1, T2`
- 런타임 blocked: `🚫 {reason}`
- progress step: `(2/4)`
