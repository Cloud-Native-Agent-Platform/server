# 프로젝트 구조

CNAP Server의 전체 디렉토리 구조와 주요 파일 설명입니다.

## 디렉토리 구조

```
cnap-server/
├── .github/                          # GitHub Actions 워크플로우
│   └── workflows/
│       ├── ci.yml                    # CI: 빌드, 테스트, Lint
│       ├── cd.yml                    # CD: 이미지 빌드 및 레지스트리 푸시
│       └── deploy-k3s.yml            # k3s 배포 워크플로우
│
├── docs/                             # 문서
│   └── DEVELOPMENT.md                # 개발 가이드
│
├── gradle/                           # Gradle 설정
│   └── wrapper/
│       ├── gradle-wrapper.jar        # Gradle Wrapper JAR
│       └── gradle-wrapper.properties # Gradle 버전 설정
│
├── k8s/                              # Kubernetes 매니페스트
│   ├── base/                         # 기본 리소스
│   │   ├── namespace.yaml            # cnap-dev 네임스페이스
│   │   ├── serviceaccount.yaml       # ServiceAccount + RBAC
│   │   ├── deployment.yaml           # Deployment 정의
│   │   ├── service.yaml              # ClusterIP 서비스
│   │   ├── secret.yaml               # 인증 토큰 등
│   │   └── kustomization.yaml        # Kustomize 설정
│   └── overlays/
│       └── local/                    # 로컬 개발 환경
│           ├── kustomization.yaml    # 로컬 오버레이
│           └── deployment-patch.yaml # 리소스 제한 등 패치
│
├── scripts/                          # 유틸리티 스크립트
│   ├── setup-k3s.sh                  # k3s 초기 설정
│   ├── init-gradle-wrapper.sh        # Gradle Wrapper 초기화
│   ├── build.sh                      # Docker 이미지 빌드
│   ├── deploy.sh                     # k3s 배포
│   ├── rebuild-deploy.sh             # 재빌드 + 재배포
│   ├── logs.sh                       # 로그 스트리밍
│   ├── port-forward.sh               # 포트 포워딩
│   └── cleanup.sh                    # 리소스 정리
│
├── src/
│   ├── main/
│   │   ├── kotlin/com/cnap/server/
│   │   │   ├── CnapServerApplication.kt     # 메인 애플리케이션
│   │   │   └── controller/
│   │   │       └── HealthController.kt      # 헬스체크 컨트롤러
│   │   └── resources/
│   │       ├── application.yml              # 기본 설정
│   │       └── application-local.yml        # 로컬 프로파일
│   └── test/
│       └── kotlin/com/cnap/server/
│           ├── CnapServerApplicationTests.kt        # 애플리케이션 테스트
│           └── controller/
│               └── HealthControllerTest.kt          # 컨트롤러 테스트
│
├── .dockerignore                     # Docker 빌드 제외 파일
├── .gitignore                        # Git 제외 파일
├── build.gradle.kts                  # Gradle 빌드 설정
├── Dockerfile                        # 멀티스테이지 Docker 빌드
├── gradle.properties                 # Gradle 속성
├── gradlew                           # Gradle Wrapper (Unix)
├── QUICKSTART.md                     # 빠른 시작 가이드
├── PROJECT_STRUCTURE.md              # 이 파일
├── README.md                         # 프로젝트 개요
└── settings.gradle.kts               # Gradle 설정
```

## 주요 파일 설명

### 빌드 및 설정

| 파일 | 설명 |
|------|------|
| `build.gradle.kts` | Gradle 빌드 스크립트 (Kotlin DSL) |
| `settings.gradle.kts` | Gradle 프로젝트 설정 |
| `gradle.properties` | Gradle JVM 설정 |
| `Dockerfile` | 멀티스테이지 Docker 빌드 정의 |

### 소스 코드

| 파일 | 설명 |
|------|------|
| `CnapServerApplication.kt` | Spring Boot 메인 애플리케이션 |
| `HealthController.kt` | `/healthz`, `/version` 엔드포인트 |

### 설정 파일

| 파일 | 설명 |
|------|------|
| `application.yml` | 기본 Spring Boot 설정 |
| `application-local.yml` | 로컬 개발 환경 설정 |

### Kubernetes

| 파일 | 설명 |
|------|------|
| `k8s/base/namespace.yaml` | cnap-dev 네임스페이스 정의 |
| `k8s/base/serviceaccount.yaml` | ServiceAccount, Role, RoleBinding |
| `k8s/base/deployment.yaml` | Deployment 정의 (replica, probes 등) |
| `k8s/base/service.yaml` | ClusterIP Service |
| `k8s/base/secret.yaml` | 인증 토큰 Secret |
| `k8s/overlays/local/` | 로컬 환경 kustomize 오버레이 |

### 스크립트

| 파일 | 용도 |
|------|------|
| `setup-k3s.sh` | k3s 설치, 레지스트리 설정, 네임스페이스 생성 |
| `init-gradle-wrapper.sh` | Gradle Wrapper JAR 다운로드 |
| `build.sh` | Gradle 빌드 + Docker 이미지 빌드/푸시 |
| `deploy.sh` | k3s에 배포 |
| `rebuild-deploy.sh` | 빌드 + 재배포 (개발용) |
| `logs.sh` | Pod 로그 스트리밍 |
| `port-forward.sh` | 서비스 포트 포워딩 |
| `cleanup.sh` | k3s 리소스 정리 |

### CI/CD

| 파일 | 설명 |
|------|------|
| `.github/workflows/ci.yml` | PR/Push 시 빌드, 테스트 |
| `.github/workflows/cd.yml` | main 브랜치에 이미지 빌드/푸시 |
| `.github/workflows/deploy-k3s.yml` | 수동 k3s 배포 워크플로우 |

### 문서

| 파일 | 설명 |
|------|------|
| `README.md` | 프로젝트 개요 및 사용법 |
| `QUICKSTART.md` | 5분 안에 시작하기 |
| `PROJECT_STRUCTURE.md` | 프로젝트 구조 (이 파일) |
| `docs/DEVELOPMENT.md` | 상세 개발 가이드 |

## 개발 워크플로우

### 1. 초기 설정

```bash
./scripts/init-gradle-wrapper.sh  # Gradle Wrapper 초기화
./scripts/setup-k3s.sh            # k3s 환경 설정
```

### 2. 개발 사이클

```bash
# 코드 수정
vim src/main/kotlin/com/cnap/server/...

# 테스트
./gradlew test

# k3s에 배포 및 테스트
./scripts/rebuild-deploy.sh

# 로그 확인
./scripts/logs.sh

# 포트 포워딩 (다른 터미널)
./scripts/port-forward.sh 8080
```

### 3. 정리

```bash
./scripts/cleanup.sh
```

## 다음 구현 단계

### 1. API 레이어

```
src/main/kotlin/com/cnap/server/
├── controller/
│   ├── AgentController.kt          # /api/agents
│   └── AgentJobController.kt       # /api/agent-jobs
├── model/
│   ├── dto/
│   │   ├── AgentDto.kt
│   │   └── AgentJobDto.kt
│   └── request/
│       ├── CreateAgentRequest.kt
│       └── CreateAgentJobRequest.kt
```

### 2. Kubernetes 통합

```
src/main/kotlin/com/cnap/server/
├── client/
│   └── KubernetesClient.kt         # K8s API 클라이언트
├── model/
│   └── crd/
│       ├── Agent.kt                # Agent CRD 모델
│       └── AgentJob.kt             # AgentJob CRD 모델
```

### 3. 스트리밍

```
src/main/kotlin/com/cnap/server/
├── stream/
│   ├── SseHandler.kt               # Server-Sent Events
│   └── WebSocketHandler.kt         # WebSocket (Runner용)
├── queue/
│   └── CommandQueue.kt             # 커맨드 큐
```

### 4. 서비스 레이어

```
src/main/kotlin/com/cnap/server/
└── service/
    ├── AgentService.kt
    ├── AgentJobService.kt
    └── StreamService.kt
```

## 참고

- Spring Boot 3.3.5 문서: https://docs.spring.io/spring-boot/docs/3.3.5/reference/html/
- Kotlin 2.0 문서: https://kotlinlang.org/docs/home.html
- k3s 문서: https://docs.k3s.io/
- Kubernetes Client (fabric8): https://github.com/fabric8io/kubernetes-client
