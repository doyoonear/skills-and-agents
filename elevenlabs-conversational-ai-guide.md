# ElevenLabs Conversational AI Agent 생성 가이드

ElevenLabs Conversational AI를 사용하여 음성 AI 에이전트를 생성할 때 참고하는 가이드입니다.

다음 요청 시 사용:
- "ElevenLabs 에이전트 만들어줘"
- "음성 AI 에이전트 생성"
- "ElevenLabs workflow 설정"
- "대화형 AI 에이전트 구현"

---

## 1. 핵심 주의사항 (⚠️ 필수 확인)

### 1.1 노드 ID 예약어

```typescript
// ❌ 오류 발생 - "start"는 예약어
nodes: {
  start: { type: 'start', ... }
}

// ✅ 올바른 사용
nodes: {
  start_node: { type: 'start', ... }
}
```

**에러 메시지**: `"Workflow must contain a start node"` (422)

> 노드 ID로 `"start"`, `"end"` 등은 ElevenLabs API 예약어이므로 사용 불가.
> `"start_node"`, `"end_rejected"` 등 다른 이름을 사용해야 함.

### 1.2 LLM 필드 필수

```typescript
// ❌ 오류 발생 - llm 필드 누락
agent: {
  prompt: { prompt: "..." }
}

// ✅ 올바른 사용
agent: {
  prompt: {
    llm: 'gpt-4o-mini',  // 필수!
    prompt: "..."
  }
}
```

### 1.3 비영어 에이전트 TTS 모델 제한

한국어, 일본어, 중국어 등 비영어 에이전트는 특정 TTS 모델만 사용 가능:

```typescript
tts: {
  voice_id: 'nPczCjzI2devNBz1zQrb',
  model_id: 'eleven_turbo_v2_5',  // ✅ 필수 (turbo 또는 flash v2_5만 가능)
}
```

**에러 메시지**: `"Non-english Agents must use turbo or flash v2_5"` (400)

---

## 2. API 요청 구조

### 2.1 기본 구조

```typescript
interface CreateAgentRequest {
  name: string
  conversation_config: {
    tts: TtsConfig
    asr: AsrConfig
    agent: AgentConfig
  }
  workflow?: WorkflowDefinition  // 워크플로우 사용 시
}
```

### 2.2 최소 예시 (워크플로우 없음)

```typescript
const request = {
  name: '테스트 에이전트',
  conversation_config: {
    agent: {
      prompt: {
        llm: 'gpt-4o-mini',
        prompt: '당신은 친절한 어시스턴트입니다.',
      },
      first_message: '안녕하세요!',
      language: 'ko',
    },
    tts: {
      voice_id: 'nPczCjzI2devNBz1zQrb',
      model_id: 'eleven_turbo_v2_5',
    },
    asr: {
      provider: 'elevenlabs',
      language: 'ko',
    },
  },
}
```

### 2.3 워크플로우 포함 예시

```typescript
const request = {
  name: '워크플로우 에이전트',
  conversation_config: { ... },
  workflow: {
    nodes: {
      start_node: {        // ⚠️ "start" 아님!
        type: 'start',
        position: { x: 0, y: 0 },
        edge_order: ['start_to_main'],
      },
      main_agent: {
        type: 'override_agent',
        label: '메인 대화',
        position: { x: 200, y: 0 },
        additional_prompt: '추가 지시사항...',
        edge_order: ['main_to_end'],
      },
      end_node: {
        type: 'end',
        position: { x: 400, y: 0 },
      },
    },
    edges: {
      start_to_main: {
        source: 'start_node',
        target: 'main_agent',
        forward_condition: { type: 'unconditional' },
      },
      main_to_end: {
        source: 'main_agent',
        target: 'end_node',
        forward_condition: {
          type: 'llm',
          condition: '사용자가 대화를 종료하려고 함',
        },
      },
    },
  },
}
```

---

## 3. 노드 타입

| 타입 | 용도 | 필수 필드 |
|------|------|-----------|
| `start` | 대화 시작점 | `type`, `position` |
| `override_agent` | 대화 진행 (프롬프트 오버라이드) | `type`, `label`, `position` |
| `end` | 대화 종료 | `type`, `position` |
| `tool` | 도구 실행 | `type`, `tool_id`, `position` |
| `standalone_agent` | 다른 에이전트로 전환 | `type`, `agent_id`, `position` |
| `phone_number` | 전화번호 전환 | `type`, `phone_number`, `position` |

---

## 4. 엣지 조건 타입

| 타입 | 용도 | 예시 |
|------|------|------|
| `unconditional` | 무조건 전환 | `{ type: 'unconditional' }` |
| `llm` | LLM이 자연어 조건 평가 | `{ type: 'llm', condition: '사용자가 동의함' }` |
| `result` | 도구 실행 결과 기반 | `{ type: 'result', successful: true }` |
| `expression` | 변수 기반 조건 | `{ type: 'expression', expression: '...' }` |

---

## 5. Dynamic Variables (컨텍스트 주입)

### 5.1 개념

- 프롬프트에 `{{variable_name}}` 형태로 변수 정의
- SDK에서 대화 시작 시 실제 값 주입
- ElevenLabs 권장 방식 (프롬프트 템플릿과 값 분리)

### 5.2 프롬프트에 변수 정의

```typescript
const BASE_PROMPT = `
# 대상 정보
- 연령대: {{age_group}}
- 거주 지역: {{region}}
- 자녀 수: {{children}}명

# 호칭 규칙
- 70대 이상이거나 손주가 있으면: "어르신"
- 그 외: "고객님"
`
```

### 5.3 SDK에서 값 전달

```typescript
const conversation = await Conversation.startSession({
  signedUrl,
  dynamicVariables: {
    age_group: '60대',
    region: '서울',
    children: '2',
  },
})
```

### 5.4 지원 타입

- `string` (기본)
- `number` → string으로 변환하여 전달
- `boolean` → string으로 변환하여 전달

---

## 6. Signed URL vs Agent ID 직접 사용

### 6.1 비교

| 항목 | Agent ID 직접 | Signed URL |
|------|---------------|------------|
| 보안 | ❌ 낮음 (누구나 접근) | ✅ 높음 (인증 필요) |
| 비용 관리 | ❌ 제한 불가 | ✅ 사용자별 제한 가능 |
| 구현 복잡도 | ✅ 간단 | ⚠️ Edge Function 필요 |
| 적합 상황 | 데모, 내부 테스트 | 프로덕션 |

### 6.2 Agent ID 직접 사용 (간단)

```typescript
const conversation = await Conversation.startSession({
  agentId: 'your-agent-id',  // 공개됨 - 비용 위험!
})
```

### 6.3 Signed URL 사용 (권장)

```typescript
// 1. 서버에서 Signed URL 획득
const { signed_url } = await fetch('/api/get-signed-url', {
  headers: { Authorization: `Bearer ${token}` }
})

// 2. Signed URL로 연결 (15분 유효)
const conversation = await Conversation.startSession({
  signedUrl: signed_url,
})
```

### 6.4 Signed URL 캐싱 전략

- ElevenLabs Signed URL 유효 시간: **15분**
- 권장 캐시 시간: **10분** (만료 전 갱신 여유)
- 대화 시작 직전에 획득하여 만료 위험 최소화

---

## 7. 일반적인 에러와 해결

| 에러 메시지 | 원인 | 해결 |
|------------|------|------|
| `Workflow must contain a start node` | 노드 ID로 "start" 사용 | `start_node` 등 다른 ID 사용 |
| `Non-english Agents must use turbo or flash v2_5` | 한국어에 구버전 TTS | `eleven_turbo_v2_5` 사용 |
| `llm field required` | agent.prompt.llm 누락 | llm 필드 추가 |
| `Unauthorized` | API 키 누락/만료 | ELEVENLABS_API_KEY 확인 |

---

## 8. 환경별 SDK 선택

| 환경 | 런타임 | 권장 방식 |
|------|--------|-----------|
| React/Vite | 브라우저 | `@elevenlabs/elevenlabs-js` SDK |
| Node.js | Node | `@elevenlabs/elevenlabs-js` SDK |
| Supabase Edge Functions | Deno | `fetch`로 REST API 직접 호출 |

---

## 9. 참고 문서

- [Create Agent API](https://elevenlabs.io/docs/api-reference/agents/create)
- [Agent Workflows](https://elevenlabs.io/docs/agents-platform/customization/agent-workflows)
- [Dynamic Variables](https://elevenlabs.io/docs/agents-platform/customization/personalization/dynamic-variables)
- [TypeScript SDK](https://elevenlabs.io/docs/agents-platform/libraries/java-script)
