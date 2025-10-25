# 개발 가이드

## 개발 환경 설정

### 필수 도구 설치

1. **JDK 21 설치**

```bash
# macOS (Homebrew)
brew install openjdk@21

# Ubuntu
sudo apt install openjdk-21-jdk

# 환경변수 설정
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
```

2. **Docker 설치**

```bash
# macOS
brew install --cask docker

# Ubuntu
sudo apt install docker.io
```

3. **kubectl 설치**

```bash
# macOS
brew install kubectl

# Ubuntu
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

4. **k3s 설치** (로컬 테스트용)

```bash
# 제공된 스크립트 사용
./scripts/setup-k3s.sh
```

## 프로젝트 설정

### IDE 설정

#### IntelliJ IDEA

1. **프로젝트 열기**
   - File → Open → `cnap-server` 디렉토리 선택

2. **JDK 설정**
   - File → Project Structure → Project
   - SDK: 21 선택
   - Language Level: 21

3. **Kotlin 플러그인 설정**
   - Preferences → Plugins
   - Kotlin 플러그인 활성화

4. **Code Style 설정**
   - Preferences → Editor → Code Style → Kotlin
   - "Set from..." → Kotlin style guide

### 로컬 실행

#### IDE에서 실행

1. `CnapServerApplication.kt` 파일 열기
2. `main` 함수 옆 실행 버튼 클릭
3. Edit Configurations에서 환경변수 설정:
   ```
   SPRING_PROFILES_ACTIVE=local
   ```

#### CLI에서 실행

```bash
# 기본 프로파일로 실행
./gradlew bootRun

# local 프로파일로 실행
./gradlew bootRun --args='--spring.profiles.active=local'
```

## 개발 워크플로우

### 기능 개발

1. **브랜치 생성**

```bash
git checkout -b feature/your-feature-name
```

2. **코드 작성**
   - 패키지 구조: `com.cnap.server.<domain>`
   - 컨트롤러: `controller/`
   - 서비스: `service/`
   - 레포지토리: `repository/`
   - 모델: `model/`

3. **테스트 작성**

```bash
# 테스트 파일 위치: src/test/kotlin/com/cnap/server/
# 네이밍: <ClassName>Test.kt
```

4. **빌드 및 테스트**

```bash
# 빌드
./gradlew build

# 테스트만 실행
./gradlew test

# 특정 테스트 실행
./gradlew test --tests "com.cnap.server.controller.HealthControllerTest"
```

### k3s에서 테스트

1. **이미지 빌드**

```bash
./scripts/build.sh
```

2. **배포**

```bash
./scripts/deploy.sh local
```

3. **로그 확인**

```bash
./scripts/logs.sh
```

4. **로컬에서 접근**

```bash
./scripts/port-forward.sh 8080
curl http://localhost:8080/healthz
```

5. **변경 사항 재배포**

```bash
./scripts/rebuild-deploy.sh
```

## 코드 스타일

### Kotlin 코딩 규칙

```kotlin
// 클래스명: PascalCase
class AgentController

// 함수명: camelCase
fun createAgent()

// 상수: UPPER_SNAKE_CASE
const val MAX_RETRY_COUNT = 3

// 프로퍼티: camelCase
val agentName: String

// 들여쓰기: 4 spaces
class Example {
    fun method() {
        if (condition) {
            // code
        }
    }
}
```

### 패키지 구조

```
com.cnap.server/
├── CnapServerApplication.kt
├── config/              # Spring 설정
│   ├── SecurityConfig.kt
│   └── WebConfig.kt
├── controller/          # REST 컨트롤러
│   ├── AgentController.kt
│   └── AgentJobController.kt
├── service/             # 비즈니스 로직
│   ├── AgentService.kt
│   └── AgentJobService.kt
├── repository/          # 데이터 액세스
│   └── (향후 추가)
├── model/               # 도메인 모델
│   ├── dto/            # Data Transfer Objects
│   ├── entity/         # Entity 클래스
│   └── request/        # Request 모델
├── client/             # 외부 클라이언트
│   └── KubernetesClient.kt
├── stream/             # 스트리밍 관련
│   ├── SseEmitter.kt
│   └── WebSocketHandler.kt
└── exception/          # 예외 처리
    └── GlobalExceptionHandler.kt
```

## 테스트 작성 가이드

### 단위 테스트

```kotlin
@SpringBootTest
class AgentServiceTest {

    @Autowired
    private lateinit var agentService: AgentService

    @Test
    fun `should create agent successfully`() {
        // given
        val request = CreateAgentRequest(
            name = "test-agent",
            description = "Test agent"
        )

        // when
        val result = agentService.createAgent(request)

        // then
        assertNotNull(result)
        assertEquals("test-agent", result.name)
    }
}
```

### 통합 테스트

```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
class AgentControllerIntegrationTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    fun `should return health status`() {
        mockMvc.perform(get("/healthz"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.status").value("UP"))
    }
}
```

## 디버깅

### 로컬 디버깅

1. **IDE 디버거 사용**
   - IntelliJ: 중단점 설정 후 Debug 모드로 실행

2. **로그 레벨 조정**

```yaml
# application-local.yml
logging:
  level:
    com.cnap: TRACE
    org.springframework: DEBUG
```

### k3s 환경 디버깅

1. **Pod 로그 확인**

```bash
kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server -f
```

2. **Pod에 접속**

```bash
POD_NAME=$(kubectl get pods -n cnap-dev -l app.kubernetes.io/name=cnap-server -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n cnap-dev $POD_NAME -- /bin/sh
```

3. **이벤트 확인**

```bash
kubectl get events -n cnap-dev --sort-by='.lastTimestamp'
```

## 일반적인 문제 해결

### Gradle 빌드 실패

```bash
# Gradle 캐시 정리
./gradlew clean

# Gradle Wrapper 재다운로드
rm -rf ~/.gradle/wrapper/dists/gradle-8.5-bin
./gradlew wrapper
```

### k3s Pod가 ImagePullBackOff 상태

```bash
# 로컬 레지스트리 확인
docker ps | grep registry

# 이미지가 레지스트리에 있는지 확인
curl http://localhost:5000/v2/_catalog

# 이미지 재빌드 및 푸시
./scripts/build.sh
```

### k3s 서비스가 응답하지 않음

```bash
# 서비스 확인
kubectl get svc -n cnap-dev

# 엔드포인트 확인
kubectl get endpoints -n cnap-dev cnap-server

# Pod 상태 확인
kubectl get pods -n cnap-dev
```

## 성능 최적화

### JVM 튜닝

```yaml
# k8s/base/deployment.yaml
env:
  - name: JAVA_OPTS
    value: >-
      -XX:+UseContainerSupport
      -XX:MaxRAMPercentage=75.0
      -XX:+UseG1GC
      -XX:MaxGCPauseMillis=100
```

### Spring Boot 최적화

```yaml
# application.yml
spring:
  threads:
    virtual:
      enabled: true  # Virtual Threads (JDK 21)
```

## 유용한 명령어

### Gradle

```bash
# 의존성 트리
./gradlew dependencies

# 프로젝트 정보
./gradlew projects

# 태스크 목록
./gradlew tasks
```

### Kubernetes

```bash
# 리소스 모니터링
kubectl top pods -n cnap-dev

# 설정 확인
kubectl get configmap -n cnap-dev

# Secret 확인
kubectl get secret -n cnap-dev

# 모든 리소스 확인
kubectl get all -n cnap-dev
```

### Docker

```bash
# 실행중인 컨테이너
docker ps

# 이미지 목록
docker images

# 로컬 레지스트리의 이미지
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/cnap-server/tags/list
```

## 다음 단계

1. [API 명세서](./API.md) 참고하여 API 구현
2. [아키텍처 문서](./ARCHITECTURE.md) 참고하여 구조 이해
3. 이슈 트래커에서 작업 선택
4. PR 생성 및 리뷰 요청
