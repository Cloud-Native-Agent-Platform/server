# CNAP Server

CNAP (Cloud Native Agent Platform) Server는 Agent와 AgentJob을 관리하고, Connector와 Runner 간의 통신을 중계하는 핵심 서버입니다.

## 아키텍처

```
┌──────────────┐
│  Connector   │ (Discord Bot)
│  (HTTP/SSE)  │
└──────┬───────┘
       │ HTTP API + SSE/WebSocket
       ▼
┌──────────────┐
│ CNAP Server  │
│  (Spring)    │
└──┬────────┬──┘
   │        │
   │        └─────────► Kubernetes API (CRD)
   │                    - Agent
   │                    - AgentJob
   │
   └────────────────► Runner (WebSocket)
                       (Pod 내부 에이전트)
```

## 주요 기능

- **북측 인터페이스**: Connector를 위한 HTTP API + 스트리밍 (SSE/WebSocket)
- **동측 인터페이스**: Runner와의 양방향 스트림 통신
- **남측 인터페이스**: Kubernetes CRD 관리 (Agent/AgentJob)

## 기술 스택

- **Language**: Kotlin 2.0.20
- **Framework**: Spring Boot 3.3.5
- **JDK**: 21
- **Container**: Docker
- **Orchestration**: Kubernetes (k3s)
- **Build**: Gradle 8.5

## 빠른 시작

자세한 내용은 [Quick Start Guide](docs/QUICKSTART.md)를 참고하세요.

```bash
# 1. Gradle Wrapper 초기화
./scripts/init-gradle-wrapper.sh

# 2. k3s 설치 및 설정
./scripts/setup-k3s.sh

# 3. 빌드 및 배포
./scripts/build.sh
./scripts/deploy.sh local

# 4. 포트 포워딩 및 확인
./scripts/port-forward.sh 8080
curl http://localhost:8080/healthz
```

## 개발 워크플로우

### 로컬 개발

```bash
# Spring Boot 애플리케이션 실행 (IDE 또는 CLI)
./gradlew bootRun --args='--spring.profiles.active=local'
```

### 코드 변경 후 재배포

```bash
# 빌드 + 재배포 (자동 롤아웃)
./scripts/rebuild-deploy.sh
```

### 로그 확인

```bash
# 실시간 로그 스트리밍
./scripts/logs.sh
```

### 정리

```bash
# k3s에서 애플리케이션 제거
./scripts/cleanup.sh
```

## 프로젝트 구조

자세한 구조는 [Project Structure](docs/PROJECT_STRUCTURE.md)를 참고하세요.

```
cnap-server/
├── src/                          # 소스 코드
├── k8s/                          # Kubernetes 매니페스트
├── scripts/                      # 개발 스크립트
├── docs/                         # 문서
│   ├── QUICKSTART.md            # 빠른 시작 가이드
│   ├── DEVELOPMENT.md           # 개발 가이드
│   ├── PROJECT_STRUCTURE.md     # 프로젝트 구조
│   └── IMPLEMENTATION_ROADMAP.md # 구현 로드맵
├── .github/workflows/            # CI/CD
├── Dockerfile                    # Docker 빌드
└── build.gradle.kts              # Gradle 빌드
```

## API 엔드포인트

### 헬스체크

```bash
# 헬스 상태 확인
GET /healthz

# 버전 정보
GET /version
```

### Agent API (예정)

```bash
# Agent 생성
POST /api/agents

# Agent 목록 조회
GET /api/agents

# Agent 상세 조회
GET /api/agents/{name}
```

### AgentJob API (예정)

```bash
# Job 생성
POST /api/agent-jobs

# Job 조회
GET /api/agent-jobs/{id}

# Job 삭제
DELETE /api/agent-jobs/{id}

# 커맨드 전송
POST /api/agent-jobs/{id}/commands

# 이벤트 스트리밍 (SSE)
GET /api/agent-jobs/{id}/events
```

## 환경 변수

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `CNAP_K8S_NAMESPACE` | Kubernetes 네임스페이스 | `default` |
| `CNAP_STREAM_MODE` | 스트리밍 모드 (sse/ws) | `sse` |
| `CNAP_AUTH_TOKEN` | 인증 토큰 | `dev-token` |
| `SPRING_PROFILES_ACTIVE` | Spring 프로파일 | `default` |

## CI/CD

### GitHub Actions 워크플로우

1. **CI (ci.yml)**: 코드 푸시/PR 시 빌드, 테스트, Docker 이미지 빌드
2. **CD (cd.yml)**: main 브랜치 푸시 시 이미지 빌드 및 GitHub Container Registry에 푸시
3. **Deploy (deploy-k3s.yml)**: 수동 트리거로 k3s에 배포

### 배포 워크플로우

```bash
# GitHub Actions에서 수동 배포
# Repository → Actions → Deploy to k3s → Run workflow
# - Environment: dev/staging/production 선택
# - Image tag: 배포할 이미지 태그 입력
```

## 테스트

```bash
# 단위 테스트 실행
./gradlew test

# 통합 테스트 실행
./gradlew integrationTest

# 모든 테스트 실행
./gradlew check
```

## 문제 해결

### k3s 연결 오류

```bash
# kubeconfig 확인
kubectl get nodes

# k3s 재시작
sudo systemctl restart k3s
```

### Docker 이미지 빌드 실패

```bash
# Docker 데몬 확인
docker ps

# 빌드 캐시 정리
docker builder prune
```

### Pod가 시작되지 않음

```bash
# Pod 상태 확인
kubectl get pods -n cnap-dev

# Pod 로그 확인
kubectl logs -n cnap-dev <pod-name>

# Pod 이벤트 확인
kubectl describe pod -n cnap-dev <pod-name>
```

## 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다.

## 문서

- [Quick Start Guide](docs/QUICKSTART.md) - 5분 안에 시작하기
- [Development Guide](docs/DEVELOPMENT.md) - 상세 개발 가이드
- [Testing Guide](docs/TESTING.md) - 로컬 테스트 환경 및 E2E 테스트
- [Project Structure](docs/PROJECT_STRUCTURE.md) - 프로젝트 구조 설명
- [Implementation Roadmap](docs/IMPLEMENTATION_ROADMAP.md) - 구현 계획 및 진행 상황

## 관련 프로젝트

- **Connector**: Discord Bot (Connector)
- **Controller**: Kubernetes Operator (CRD Controller)
- **Runner**: Pod 내부 Agent Runtime

## 문의

이슈가 있으시면 GitHub Issues를 통해 제보해주세요.
