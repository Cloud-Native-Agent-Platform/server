# CNAP Server 구현 로드맵

Server 구조 문서를 기반으로 한 구현 기능 목록 및 우선순위입니다.

## 📋 전체 구현 목록

### Phase 1: 기본 API 골격 (Week 1)

#### ✅ 완료된 작업
- [x] 프로젝트 구조 설정 (Spring Boot + Kotlin + JDK 21)
- [x] Docker 멀티스테이지 빌드
- [x] k3s 매니페스트 작성
- [x] CI/CD 파이프라인 (GitHub Actions)
- [x] 헬스체크 엔드포인트 (`/healthz`, `/version`)
- [x] 개발 스크립트 (build, deploy, logs 등)

#### 🔨 Epic 1: Domain Models & CRD

**#S-MODEL-001: CRD 모델 정의**
- [ ] `Agent` CRD Kotlin 모델
  - [ ] AgentSpec (name, description, systemPrompt, mcp, integrations, runtime)
  - [ ] AgentStatus (phase, conditions, lastUpdated)
- [ ] `AgentJob` CRD Kotlin 모델
  - [ ] AgentJobSpec (agentRef, parameters, runtime, storage, ttlSecondsAfterFinished)
  - [ ] AgentJobStatus (phase, conditions, podRef, startTime, completionTime, lastError)
- [ ] JobPhase enum (Pending, Running, Succeeded, Failed, Cleaned)

**#S-MODEL-002: DTO 정의**
- [ ] Request DTOs
  - [ ] `CreateAgentRequest`
  - [ ] `CreateAgentJobRequest`
  - [ ] `SendCommandRequest`
- [ ] Response DTOs
  - [ ] `AgentResponse`
  - [ ] `AgentJobResponse`
  - [ ] `CommandAcceptedResponse`
  - [ ] `StreamUrlResponse`
- [ ] Event DTOs
  - [ ] `StreamEvent` (base class)
  - [ ] `TokenEvent`
  - [ ] `MessageEvent`
  - [ ] `LogEvent`
  - [ ] `StatusEvent`
  - [ ] `ErrorEvent`
  - [ ] `DoneEvent`

#### 🔨 Epic 2: Kubernetes Integration

**#S-K8S-001: K8s Client 세팅**
- [ ] Fabric8 Kubernetes Client 의존성 추가
- [ ] KubernetesClientConfiguration 클래스
  - [ ] 네임스페이스 설정 (`cnap.kubernetes.namespace`)
  - [ ] ServiceAccount 자동 인증
  - [ ] 로컬/클러스터 모드 자동 감지
- [ ] KubernetesClient Bean 구성
- [ ] 연결 테스트 및 헬스체크

**#S-K8S-002: CRD 직렬화/역직렬화**
- [ ] `CustomResourceDefinitionContext` 설정
  - [ ] Agent CRD 컨텍스트
  - [ ] AgentJob CRD 컨텍스트
- [ ] Jackson 직렬화 설정
- [ ] CRD YAML 샘플 작성 (테스트용)
- [ ] 단위 테스트

**#S-K8S-003: CRD 연동 서비스**
- [ ] `KubernetesService` 인터페이스 정의
- [ ] Agent 관련 메소드
  - [ ] `createAgent(spec): Agent`
  - [ ] `getAgent(name): Agent?`
  - [ ] `listAgents(page, size): List<Agent>`
  - [ ] `deleteAgent(name): Boolean`
- [ ] AgentJob 관련 메소드
  - [ ] `createAgentJob(spec): AgentJob`
  - [ ] `getAgentJob(id): AgentJob?`
  - [ ] `getAgentJobStatus(id): AgentJobStatus`
  - [ ] `deleteAgentJob(id): Boolean`
- [ ] 에러 처리 (재시도 로직, 타임아웃)

#### 🔨 Epic 3: Agent API

**#S-API-001: Agents CRUD**
- [ ] `AgentController` 생성
- [ ] `POST /api/agents` - Agent 생성
  - [ ] Request validation
  - [ ] K8s CRD 생성
  - [ ] Response 반환
- [ ] `GET /api/agents` - Agent 목록 조회
  - [ ] 페이지네이션 (page, size)
  - [ ] 필터링 (선택)
- [ ] `GET /api/agents/{name}` - Agent 상세 조회
  - [ ] 404 처리
- [ ] `DELETE /api/agents/{name}` - Agent 삭제 (선택)
- [ ] 통합 테스트

---

### Phase 2: Job 관리 (Week 2)

#### 🔨 Epic 4: AgentJob API

**#S-API-002: AgentJobs CRUD**
- [ ] `AgentJobController` 생성
- [ ] `POST /api/agent-jobs` - Job 생성
  - [ ] AgentRef 검증
  - [ ] K8s AgentJob CRD 생성
  - [ ] Stream URL 생성 및 반환
- [ ] `GET /api/agent-jobs/{id}` - Job 조회
  - [ ] 상태 조회 (K8s에서)
  - [ ] 404 처리
- [ ] `DELETE /api/agent-jobs/{id}` - Job 종료
  - [ ] K8s CRD 삭제 요청
  - [ ] 세션 정리
- [ ] 통합 테스트

**#S-API-003: Commands 엔드포인트**
- [ ] `POST /api/agent-jobs/{id}/commands`
  - [ ] Request validation (type, content)
  - [ ] Command Queue에 enqueue
  - [ ] Job 존재 여부 확인
  - [ ] 응답 반환 (accepted, enqueuedAt)
- [ ] Command 타입 enum (MESSAGE, TOOL, CONTROL)
- [ ] 테스트

#### 🔨 Epic 5: Command Queue

**#S-CORE-001: Command Queue 구현**
- [ ] `CommandQueue` 인터페이스
  - [ ] `enqueue(jobId, command): Boolean`
  - [ ] `dequeue(jobId): Command?`
  - [ ] `size(jobId): Int`
  - [ ] `clear(jobId)`
- [ ] 인메모리 구현 (`InMemoryCommandQueue`)
  - [ ] ConcurrentHashMap<JobId, Queue<Command>>
  - [ ] 최대 크기 제한
  - [ ] 타임아웃 설정
- [ ] Command 모델
  - [ ] commandId (UUID)
  - [ ] jobId
  - [ ] type
  - [ ] payload
  - [ ] enqueuedAt
- [ ] 단위 테스트

**#S-CORE-002: Command Queue Service**
- [ ] `CommandQueueService`
  - [ ] enqueueCommand(jobId, command)
  - [ ] getNextCommand(jobId)
  - [ ] acknowledgeCommand(commandId)
  - [ ] getQueueSize(jobId)
- [ ] 에러 처리
  - [ ] QueueFullException
  - [ ] JobNotFoundException

---

### Phase 3: 스트리밍 (Week 3)

#### 🔨 Epic 6: Connector Streaming (북측)

**#S-API-004: SSE 스트리밍 구현**
- [ ] `GET /api/agent-jobs/{id}/events`
  - [ ] SseEmitter 생성 및 반환
  - [ ] Job 존재 여부 확인
  - [ ] StreamHub 구독
  - [ ] 타임아웃 처리
  - [ ] 연결 해제 처리
- [ ] SSE Event 포맷
  - [ ] `event: <type>`
  - [ ] `data: <json>`
- [ ] 테스트 (MockMvc + SSE)

**#S-API-005: WebSocket 스트리밍 (선택)**
- [ ] `GET /ws/agent-jobs/{id}`
  - [ ] WebSocket 핸들러
  - [ ] 세션 관리
  - [ ] 양방향 메시지 처리
- [ ] WebSocket 설정 (WebSocketConfigurer)
- [ ] 테스트

**#S-CORE-002: Stream Hub 구현**
- [ ] `StreamHub` 인터페이스
  - [ ] `subscribe(jobId, subscriber): Subscription`
  - [ ] `unsubscribe(subscriptionId)`
  - [ ] `publish(jobId, event)`
  - [ ] `getSubscriberCount(jobId): Int`
- [ ] 인메모리 구현 (`InMemoryStreamHub`)
  - [ ] Pub-Sub 패턴
  - [ ] ConcurrentHashMap<JobId, Set<Subscriber>>
  - [ ] Event 버퍼링 (최근 N개, 선택)
- [ ] `Subscriber` 인터페이스
  - [ ] `onEvent(event)`
  - [ ] `onError(error)`
  - [ ] `onComplete()`
- [ ] 단위 테스트

#### 🔨 Epic 7: Runner WebSocket (동측)

**#S-RUN-001: WS 세션 핸들러**
- [ ] `GET /ws/runner/sessions/{jobId}`
  - [ ] WebSocket 연결 수립
  - [ ] 핸드셰이크 프로토콜 (hello, ack)
  - [ ] 세션 등록
- [ ] `RunnerSessionManager`
  - [ ] registerSession(jobId, session)
  - [ ] unregisterSession(jobId)
  - [ ] getSession(jobId): WebSocketSession?
  - [ ] 타임아웃 처리
- [ ] 세션 상태 추적
  - [ ] CONNECTING, CONNECTED, DISCONNECTED
- [ ] 테스트

**#S-RUN-002: 메시지 스키마/밸리데이션**
- [ ] Inbound 메시지 (Server → Runner)
  - [ ] `CommandMessage` - 커맨드 전달
  - [ ] `SessionControlMessage` - 세션 제어
- [ ] Outbound 메시지 (Runner → Server)
  - [ ] `TokenMessage` - 토큰 스트리밍
  - [ ] `MessageMessage` - 완성 메시지
  - [ ] `LogMessage` - 로그
  - [ ] `StatusMessage` - 상태 변경
  - [ ] `ErrorMessage` - 에러
  - [ ] `DoneMessage` - 완료
- [ ] JSON 직렬화/역직렬화
- [ ] 밸리데이션 (@Valid 어노테이션)
- [ ] 단위 테스트

**#S-RUN-003: 커맨드 Fan-out**
- [ ] `CommandDispatcher`
  - [ ] Command Queue → Runner 전달
  - [ ] commandId 기반 ack 처리
  - [ ] 재시도 로직 (선택)
- [ ] 백그라운드 워커
  - [ ] 각 Job별 큐 폴링
  - [ ] Runner 연결 상태 확인
  - [ ] 전송 실패 처리
- [ ] 테스트

**#S-RUN-004: 이벤트 브리지**
- [ ] Runner 이벤트 → StreamHub 전파
  - [ ] `onTokenEvent` → publish to StreamHub
  - [ ] `onMessageEvent` → publish to StreamHub
  - [ ] `onLogEvent` → publish to StreamHub
  - [ ] `onStatusEvent` → publish to StreamHub
  - [ ] `onErrorEvent` → publish to StreamHub
  - [ ] `onDoneEvent` → publish to StreamHub
- [ ] 이벤트 변환 로직
- [ ] 이벤트 필터링 (선택)
- [ ] 통합 테스트

---

### Phase 4: 통합 및 안정화 (Week 4)

#### 🔨 Epic 8: 상태 동기화

**#S-K8S-003: Job 상태 폴링/Watch**
- [ ] `AgentJobStatusWatcher`
  - [ ] K8s Watch API 사용
  - [ ] 또는 주기적 폴링 (간단)
- [ ] 상태 변경 감지
  - [ ] Pending → Running
  - [ ] Running → Succeeded/Failed
- [ ] StreamHub에 상태 이벤트 발행
- [ ] 테스트

#### 🔨 Epic 9: 에러 처리

**#S-ERR-001: 에러 코드 테이블**
- [ ] `ErrorCode` enum
  - [ ] AGENT_NOT_FOUND (404)
  - [ ] AGENT_JOB_NOT_FOUND (404)
  - [ ] AGENT_ALREADY_EXISTS (409)
  - [ ] INVALID_REQUEST (400)
  - [ ] QUEUE_FULL (429)
  - [ ] RUNNER_DISCONNECTED (503)
  - [ ] KUBERNETES_ERROR (500)
  - [ ] INTERNAL_ERROR (500)
- [ ] 에러 메시지 매핑

**#S-ERR-002: 공통 에러 응답 포맷**
- [ ] `ErrorResponse` DTO
  ```kotlin
  {
    "code": "AGENT_NOT_FOUND",
    "message": "Agent 'test-agent' not found",
    "timestamp": 1730000000000,
    "path": "/api/agents/test-agent"
  }
  ```
- [ ] `GlobalExceptionHandler`
  - [ ] @ExceptionHandler 메소드들
  - [ ] HTTP 상태 코드 매핑
  - [ ] 로깅
- [ ] 스트림 에러 이벤트 포맷
- [ ] 테스트

**#S-ERR-003: Exception 계층**
- [ ] `CnapException` (base)
- [ ] `AgentNotFoundException`
- [ ] `AgentJobNotFoundException`
- [ ] `AgentAlreadyExistsException`
- [ ] `CommandQueueFullException`
- [ ] `RunnerDisconnectedException`
- [ ] `KubernetesClientException`
- [ ] `InvalidRequestException`

#### 🔨 Epic 10: Configuration & Operations

**#S-OPS-001: 환경설정 바인딩**
- [ ] `CnapProperties` Configuration Class
  ```kotlin
  @ConfigurationProperties("cnap")
  data class CnapProperties(
    val kubernetes: KubernetesProperties,
    val stream: StreamProperties,
    val auth: AuthProperties,
    val queue: QueueProperties
  )
  ```
- [ ] 프로파일별 설정
  - [ ] application.yml (default)
  - [ ] application-local.yml
  - [ ] application-dev.yml
  - [ ] application-prod.yml
- [ ] 설정 검증 (@Validated)

**#S-OPS-002: Monitoring & Metrics**
- [ ] Actuator 엔드포인트 확장
  - [ ] `/actuator/metrics` - 커스텀 메트릭
  - [ ] Active WebSocket sessions
  - [ ] Command queue sizes
  - [ ] Stream subscriber counts
- [ ] Custom HealthIndicator
  - [ ] K8s 연결 상태
  - [ ] Runner 세션 상태
- [ ] 로깅 개선
  - [ ] 구조화된 로그 (JSON)
  - [ ] MDC (Mapped Diagnostic Context)

#### 🔨 Epic 11: Security & Auth (MVP)

**#S-SEC-001: 인증**
- [ ] Static Bearer Token 검증
  - [ ] `AuthenticationFilter`
  - [ ] `Authorization: Bearer <token>` 헤더 검증
- [ ] 환경변수에서 토큰 로드
- [ ] 개발 환경 무인증 모드 (선택)
- [ ] 테스트

**#S-SEC-002: CORS 설정**
- [ ] `WebConfig`
  - [ ] CORS 허용 (개발 환경)
  - [ ] Allowed origins
  - [ ] Allowed methods
  - [ ] Allowed headers

---

### Phase 5: 테스트 & 문서화 (Week 5)

#### 🔨 Epic 12: 테스트

**#S-TEST-001: 단위 테스트**
- [ ] Controller 테스트 (MockMvc)
- [ ] Service 로직 테스트
- [ ] K8s Client Mock 테스트
- [ ] Command Queue 테스트
- [ ] Stream Hub 테스트
- [ ] 코드 커버리지 80% 목표

**#S-TEST-002: 통합 테스트**
- [ ] API 엔드투엔드 테스트
  - [ ] Agent CRUD
  - [ ] AgentJob CRUD
  - [ ] Commands
- [ ] WebSocket 통신 테스트
- [ ] SSE 스트리밍 테스트
- [ ] 실제 k3s 환경 테스트 (선택)

**#S-TEST-003: 성능 테스트**
- [ ] 부하 테스트 (Gatling, JMeter)
- [ ] 동시 연결 테스트
- [ ] 메모리 프로파일링

#### 🔨 Epic 13: 문서화

**#S-DOC-001: API 문서**
- [ ] OpenAPI/Swagger 설정
  - [ ] springdoc-openapi 의존성
  - [ ] API 어노테이션 추가
  - [ ] `/swagger-ui.html` 접근
- [ ] API 명세서 작성 (docs/API.md)
- [ ] 요청/응답 예시

**#S-DOC-002: 아키텍처 문서**
- [ ] 시퀀스 다이어그램 업데이트
- [ ] 컴포넌트 다이어그램
- [ ] 배포 아키텍처
- [ ] docs/ARCHITECTURE.md

**#S-DOC-003: 운영 가이드**
- [ ] 모니터링 가이드
- [ ] 트러블슈팅
- [ ] 성능 튜닝
- [ ] docs/OPERATIONS.md

---

## 📊 진행 상황 추적

### ✅ 완료 (7/13 epics)
- Epic 0: 환경 구축 ✅

### 🚧 진행 중 (0/13 epics)
- 없음

### 📝 대기 중 (13/13 epics)
- Epic 1: Domain Models & CRD
- Epic 2: Kubernetes Integration
- Epic 3: Agent API
- Epic 4: AgentJob API
- Epic 5: Command Queue
- Epic 6: Connector Streaming
- Epic 7: Runner WebSocket
- Epic 8: 상태 동기화
- Epic 9: 에러 처리
- Epic 10: Configuration & Operations
- Epic 11: Security & Auth
- Epic 12: 테스트
- Epic 13: 문서화

---

## 🎯 다음 액션

### 우선순위 1 (즉시 시작)
1. **#S-MODEL-001**: CRD 모델 정의
2. **#S-K8S-001**: K8s Client 세팅
3. **#S-API-001**: Agents CRUD API

### 우선순위 2 (Week 1 완료 후)
4. **#S-API-002**: AgentJobs CRUD
5. **#S-CORE-001**: Command Queue 구현

### 우선순위 3 (Week 2 완료 후)
6. **#S-API-004**: SSE 스트리밍
7. **#S-RUN-001**: Runner WebSocket 세션

---

## 📝 참고 사항

### MVP 범위
- 인메모리 큐/버퍼 (영속화 없음)
- 단일 서버 인스턴스 (수평 확장 고려 안함)
- 간단한 인증 (Static Token)
- 베스트에포트 메시지 전달

### 제외 사항 (Post-MVP)
- 프로덕션 보안/권한
- 감사 로그
- 멀티테넌시
- 광범위한 상태 영속화
- 수평 확장/샤딩
- 복잡한 네트워킹

### 기술 스택
- Kotlin 2.0.20
- Spring Boot 3.3.5
- JDK 21
- Fabric8 Kubernetes Client 6.10.0
- WebSocket (Spring)
- SSE (SseEmitter)

---

## 🔗 관련 문서

- [README.md](../README.md) - 프로젝트 개요
- [QUICKSTART.md](../QUICKSTART.md) - 빠른 시작
- [DEVELOPMENT.md](./DEVELOPMENT.md) - 개발 가이드
- [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md) - 프로젝트 구조

---

**Last Updated**: 2025-10-25
**Version**: 1.0.0
