---
name: autonomous-agent
description: |
  장기 실행 자율 코딩 에이전트입니다.
  다음과 같은 요청 시 이 skill을 사용하세요:
  - "논스탑 에이전트로 [앱] 만들어줘"
  - "자율 에이전트 시작"
  - "/autonomous [설명]"
  - "논스탑 계속", "에이전트 재개"
  한글 트리거: "논스탑", "자율 에이전트", "장기 실행" 등의 요청이 있을 때 사용.
---

# Autonomous Agent (논스탑 에이전트)

Anthropic의 autonomous-coding 패턴을 구현한 장기 실행 자율 코딩 에이전트입니다.
수 시간~하루에 걸쳐 200개의 기능을 순차적으로 구현합니다.

## 핵심 개념: Two-Agent Pattern

```
┌─────────────────────────────────────────────────────────────┐
│  Session 1: Initializer Agent                               │
│  - 앱 명세 분석                                              │
│  - feature_list.json 생성 (200개 기능)                       │
│  - 프로젝트 구조 설정                                         │
│  - Git 초기화                                                │
└─────────────────────────────────────────────────────────────┘
                          ↓ (3초 후 자동)
┌─────────────────────────────────────────────────────────────┐
│  Session 2+: Coding Agent                                   │
│  - feature_list.json 로드                                   │
│  - 미완료 기능 선택 → 구현 → 테스트 → 커밋                    │
│  - 3초 후 다음 기능으로 자동 진행                              │
└─────────────────────────────────────────────────────────────┘
```

## 워크플로우

### Phase 1: 세션 타입 결정

```
프로젝트 디렉토리에서 feature_list.json 확인
├── 없음 → Initializer Agent 모드
└── 있음 → Coding Agent 모드
```

### Phase 2: Initializer Agent (첫 세션)

**참조**: `prompts/initializer.md`

1. 사용자 요청에서 앱 명세 추출
2. 기술 스택 결정 (풀스택 기본)
3. 200개 기능 목록 생성 (`feature_list.json`)
4. 프로젝트 구조 생성
5. `init.sh` 생성 (개발 서버 시작 스크립트)
6. `claude-progress.txt` 초기화
7. Git 초기 커밋
8. **"3초 후 Coding Agent를 시작합니다..." 출력**

### Phase 3: Coding Agent (이후 세션)

**참조**: `prompts/coding.md`

1. `pwd` 확인
2. `feature_list.json` 로드
3. Git 로그로 이전 진행 상황 파악
4. `init.sh` 실행 (개발 서버 시작)
5. 미완료(`passing: false`) 기능 중 첫 번째 선택
6. 기능 구현
7. 테스트 (가능한 경우)
8. `feature_list.json` 업데이트 (`passing: true`)
9. Git 커밋: `feat(카테고리): 기능명`
10. `claude-progress.txt` 업데이트
11. **아직 남은 기능이 있으면 → "3초 후 다음 기능을 시작합니다..."**

### Phase 4: 완료

모든 기능 완료 시:
1. 최종 검증 (lint, type check, build)
2. 완료 보고
3. "AUTONOMOUS_DONE" 출력

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `feature_list.json` | 기능 목록 및 상태 (Source of Truth) |
| `claude-progress.txt` | 세션별 진행 노트 |
| `init.sh` | 개발 서버 시작 스크립트 |

## 세션 시작 체크리스트

```markdown
각 세션 시작 시 반드시 확인:
1. [ ] pwd로 작업 디렉토리 확인
2. [ ] feature_list.json 존재 여부 확인
3. [ ] Git 로그로 이전 작업 내용 파악
4. [ ] init.sh 실행 (개발 서버 시작)
5. [ ] 기본 기능 테스트로 앱 상태 확인
```

## 자동 재시작 규칙

```
기능 구현 완료 후:
1. feature_list.json의 completed_features 업데이트
2. 남은 기능 확인
   ├── 있음 → "3초 후 다음 기능을 시작합니다..." 출력 후 계속
   └── 없음 → "모든 기능이 완료되었습니다!" 출력 후 종료
```

## 재개 방법

세션이 중단된 경우:
```
"논스탑 계속" 또는 "에이전트 재개"
```
→ Coding Agent가 마지막 미완료 기능부터 계속

## 기능 카테고리 (풀스택)

| 카테고리 | 예상 개수 |
|----------|----------|
| Setup & Config | 10-15 |
| Database | 15-20 |
| Authentication | 15-20 |
| API Endpoints | 30-40 |
| Frontend Pages | 30-40 |
| Components | 40-50 |
| State Management | 10-15 |
| Styling | 15-20 |
| Testing | 15-20 |
| Deployment | 5-10 |

## 주의사항

1. **긴 실행 시간**: 200개 기능은 수 시간~하루 소요
2. **Git 커밋**: 각 기능마다 커밋 → 롤백 용이
3. **진행 상황 저장**: feature_list.json이 항상 최신 상태 유지
4. **테스트**: 가능하면 각 기능 구현 후 테스트 실행

## 예시

### 시작
```
사용자: 논스탑 에이전트로 Todo 앱 만들어줘
Claude: [Initializer Agent 시작]
        → 앱 명세 분석
        → 200개 기능 목록 생성
        → 프로젝트 구조 설정
        → "3초 후 Coding Agent를 시작합니다..."
```

### 재개
```
사용자: 논스탑 계속
Claude: [Coding Agent 시작]
        → feature_list.json 로드 (150/200 완료)
        → 기능 #151부터 계속
```
