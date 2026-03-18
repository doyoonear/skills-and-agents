---
name: mission
description: |
  멀티세션 미션 관리 시스템. 여러 Claude 세션이 같은 프로젝트에서 동시 작업할 때
  상태 추적, 태스크 조율, 이벤트 기반 라이프사이클을 관리합니다.
  Use when user mentions "/mission", "미션", "mission", "멀티세션", "multi-session".
  Not for simple handoff (use /handoff) or session wrap-up (use /wrap).
---

# Mission — 멀티세션 컨텍스트 관리 시스템

파일 기반 이벤트 소싱으로 여러 Claude 세션의 작업 상태를 추적하고 조율합니다.

## 핵심 원칙

1. `events/session-*.jsonl`이 유일한 동적 진실 원천
2. `state.json`과 `DASHBOARD.md`는 이벤트에서 재생성 가능한 파생물
3. 같은 이벤트 입력 → 항상 같은 state.json (결정적 계산)
4. 경고는 작업을 차단하지 않음 — 사람이 판단하고 조치

## 스크립트 위치

```
skills-and-agents/custom/skills/mission/scripts/
├── mission-create.sh       # 미션 생성
├── mission-event.sh        # 이벤트 기록 (범용 writer)
├── mission-materialize.sh  # materializer (이벤트 → state.json)
├── mission-status.sh       # 상태 조회 + 불일치 검사
└── mission-compact.sh      # compaction + 스냅샷
```

## 명령어

### `/mission create {slug}`

새 미션을 생성합니다.

**실행 프로토콜**:
1. 사용자에게 미션 제목, 설명, 태스크 목록을 대화형으로 질문
2. 태스크 ID는 `T1`, `T2`, ... 형식 권장
3. 각 태스크의 `dependsOn` 설정 (의존하는 태스크 ID 배열)
4. 입력 완료 후 스크립트 실행:
   ```bash
   ~/.claude/skills/mission/scripts/mission-create.sh "{slug}" "{title}" "{description}" '{tasks_json}'
   ```
5. 순환 의존성이 있으면 에러 → 사용자에게 수정 요청
6. 생성 후 `session.started` 이벤트 자동 발행:
   ```bash
   ~/.claude/skills/mission/scripts/mission-event.sh "{slug}" new session.started "" '{"goal":"{goal}","label":"{label}"}'
   ```
7. 반환된 `SESSION_ID`를 기억하고 이후 모든 이벤트에 사용

**slug 규칙**: `[a-z0-9-]`, 시작/끝은 영숫자. 예: `resume-editor-dnd`, `payment-v2`

**tasks_json 형식**:
```json
{
  "T1": {"title": "API 설계", "description": "엔드포인트 정의", "dependsOn": []},
  "T2": {"title": "프론트 구현", "description": "", "dependsOn": ["T1"]},
  "T3": {"title": "테스트", "description": "", "dependsOn": ["T1", "T2"]}
}
```

### `/mission claim {taskId}`

태스크를 선점합니다.

**실행 프로토콜**:
1. materializer 실행으로 state.json 최신화:
   ```bash
   ~/.claude/skills/mission/scripts/mission-materialize.sh "{slug}"
   ```
2. state.json 읽기 → 태스크 상태 확인:
   - `ready == true` 확인 (의존 태스크 모두 완료)
   - `status == "open"` 또는 stale claim 확인
   - `blocked == false` 확인
3. 조건 충족 시 이벤트 발행:
   ```bash
   ~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" task.claimed "{taskId}"
   ```
4. **2단계 확인**: materializer 재실행 → state.json에서 자기가 owner인지 확인
5. owner가 아니면 (다른 세션이 먼저 claim):
   - DUPLICATE_CLAIM 경고 표시
   - 다른 태스크 선택 안내

### `/mission done {taskId}`

태스크를 완료합니다.

**실행 프로토콜**:
1. state.json에서 현재 세션이 owner인지 확인
2. 사용자에게 완료 요약(summary) 질문
3. 이벤트 발행:
   ```bash
   ~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" task.done "{taskId}" '{"summary":"{summary}"}'
   ```
4. materializer 재실행
5. 의존 태스크의 ready 상태 변화 안내

### `/mission status`

현재 미션 상태를 확인합니다. **세션 시작 시 반드시 실행**.

**실행 프로토콜**:
1. `docs/mission-*/` 디렉토리 탐색
2. 활성 미션이 있으면:
   ```bash
   ~/.claude/skills/mission/scripts/mission-status.sh "{slug}"
   ```
3. 없으면 mission-status.sh 대신 직접:
   ```bash
   ~/.claude/skills/mission/scripts/mission-materialize.sh "{slug}"
   ```
4. state.json 읽기 → 포맷팅된 상태 표시:
   - 태스크별 상태 테이블
   - 활성 세션 목록
   - active 경고 강조
   - ready 상태 태스크 안내
5. 이전 세션의 claimed 태스크가 있으면 이어서 진행할지 질문

### `/mission touch {taskId}`

Heartbeat 이벤트를 발행합니다. 장시간 작업 시 stale claim 방지용.

```bash
~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" task.heartbeat "{taskId}" '{"note":"{note}"}'
```

### `/mission release {taskId}`

선점을 자발적으로 해제합니다.

```bash
~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" task.released "{taskId}" '{"reason":"{reason}"}'
```

### `/mission block {taskId} "{reason}"`

런타임 블로커를 기록합니다.

```bash
~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" task.blocked "{taskId}" '{"reason":"{reason}"}'
```

### `/mission unblock {taskId}`

런타임 블로커를 해소합니다.

```bash
~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" task.unblocked "{taskId}" '{"reason":"{reason}"}'
```

### `/mission compact`

완료 태스크를 압축하고 스냅샷을 생성합니다.

```bash
~/.claude/skills/mission/scripts/mission-compact.sh "{slug}"
```

### `/mission materialize`

state.json + DASHBOARD.md를 강제 재생성합니다.

```bash
~/.claude/skills/mission/scripts/mission-materialize.sh "{slug}"
```

### `/mission task add {id} "{title}"`

미션에 태스크를 추가합니다.

**실행 프로토콜**:
1. 사용자에게 태스크 설명, 의존성 질문
2. mission.json 수정 (jq 사용)
3. 순환 의존성 재검증
4. materializer 재실행

## 세션 시작 프로토콜

새 세션이 시작되면 **반드시** 다음을 수행:

1. `docs/mission-*/` 디렉토리 탐색
2. 활성 미션이 있으면:
   a. 기존 세션 ID가 있는지 확인 (`.session-current` 파일)
   b. 없으면 새 세션 시작:
      ```bash
      ~/.claude/skills/mission/scripts/mission-event.sh "{slug}" new session.started "" '{"goal":"{goal}","label":"{label}"}'
      ```
   c. `/mission status` 실행
   d. ready 상태 태스크 안내
   e. 이전 세션의 claimed 태스크가 있으면 이어서 진행할지 질문

## 세션 종료 프로토콜

세션 종료 시:

1. claimed 태스크가 남아있으면 경고 + release 여부 질문
2. handoff 파일 생성 안내:
   - 미션 모드: `handoffs/session-{sessionId}.md`에 기록
3. session.ended 이벤트 발행:
   ```bash
   ~/.claude/skills/mission/scripts/mission-event.sh "{slug}" "{sessionId}" session.ended "" '{"handoff":"handoffs/session-{sessionId}.md"}'
   ```
4. materializer 재실행

## 세션 ID 관리

- 형식: `{agent}-{YYYYMMDD}-{8자리 hex}`
- 예: `claude-20260318-a1b2c3d4`
- `new`: 새 세션 ID 자동 생성
- `auto`: `.session-current` 파일에서 기존 ID 조회, 없으면 새로 생성
- 세션 ID는 이벤트 파일명으로 사용: `events/session-{sessionId}.jsonl`

## 경고 유형

| code | severity | 해소 가능 | 설명 |
|------|----------|----------|------|
| STALE_CLAIM | warning | yes | claim 후 30분 활동 없음 |
| DUPLICATE_CLAIM | warning | yes | 같은 태스크에 복수 세션이 claim |
| CORRUPTED_EVENT | error | no | 이벤트 로그에 파싱 불가 줄 |
| ORPHAN_HANDOFF | info | yes | handoff 파일 있으나 session.ended 없음 |
| DONE_NO_HANDOFF | info | yes | done 이벤트 있으나 handoff 없음 |
| STALE_STATE | warning | yes | state.json이 오래됨 |
| SCHEMA_MISMATCH | error | no | schemaVersion 불일치 |

## Heartbeat 사용 가이드

장시간 집중 작업 시 stale claim을 방지하려면 주기적으로 heartbeat를 보내세요:

```
/mission touch {taskId}
```

권장 주기: 20분마다 (stale timeout은 30분)

## 참고

- 설계문서: `references/event-schema.md`
- 모든 데이터는 `cat`으로 즉시 확인 가능
- 외부 의존성: `jq`만 필요 (`brew install jq`)
- 스크립트는 Bash 3.2 호환 (macOS 기본)
