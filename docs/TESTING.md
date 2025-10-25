# Testing Guide

CNAP Server의 로컬 테스트 환경 구축 및 테스트 가이드입니다.

## 빠른 시작

### 1회 설정
```bash
# k3s 및 로컬 레지스트리 설정
./scripts/setup-k3s.sh

# 환경 검증
./scripts/verify-k3s.sh
```

### 로컬 테스트 실행
```bash
# 전체 환경 구축 및 테스트
./scripts/test-local.sh

# End-to-End 테스트
./scripts/test-e2e.sh
```

## 테스트 스크립트 상세

### 1. `setup-k3s.sh` - k3s 초기 설정

**목적**: k3s 및 로컬 개발 환경 구축

**실행 내용**:
- k3s 설치 (이미 설치되어 있으면 스킵)
- kubeconfig 설정 (~/.kube/config)
- 로컬 Docker 레지스트리 시작 (localhost:5000)
- cnap-dev 네임스페이스 생성

**사용법**:
```bash
./scripts/setup-k3s.sh
```

**출력 예시**:
```
🚀 Setting up k3s for CNAP development...
✅ k3s is already installed
🔧 Setting up kubeconfig...
✅ Verifying k3s connection...
🐳 Setting up local registry...
✅ Local registry started at localhost:5000
📁 Creating cnap-dev namespace...
✨ k3s setup complete!
```

---

### 2. `verify-k3s.sh` - k3s 환경 검증

**목적**: k3s 환경이 올바르게 구축되었는지 검증

**검증 항목**:
1. ✅ k3s 바이너리 설치 확인
2. ✅ k3s 서비스 실행 상태
3. ✅ kubectl 설치 확인
4. ✅ kubeconfig 설정 확인
5. ✅ 클러스터 연결 확인
6. ✅ 노드 상태 확인
7. ✅ Docker 실행 확인
8. ✅ 로컬 레지스트리 확인
9. ✅ 시스템 Pod 상태 확인
10. ✅ cnap-dev 네임스페이스 확인

**사용법**:
```bash
./scripts/verify-k3s.sh
```

**출력 예시**:
```
🔍 k3s Environment Verification
================================

[INFO] Checking k3s installation...
[✓] k3s is installed: k3s version v1.28.3+k3s1
[✓] k3s service is running
[✓] kubectl is installed
[✓] kubeconfig found at ~/.kube/config
[✓] Successfully connected to k3s cluster
[✓] 1 node(s) found
[✓] Docker is running
[✓] Local registry is running on port 5000
[✓] 4/4 system pods are running
[✓] Namespace 'cnap-dev' exists

✨ k3s environment is ready!
```

---

### 3. `test-local.sh` - 로컬 통합 테스트

**목적**: 전체 빌드-배포-검증 자동화

**실행 단계**:
1. **Prerequisites**: 필수 도구 확인 (docker, kubectl, k3s)
2. **k3s Status**: k3s 실행 상태 확인
3. **Local Registry**: 레지스트리 확인/시작
4. **Gradle Wrapper**: Gradle wrapper 초기화
5. **Build**:
   - Gradle 빌드
   - Docker 이미지 빌드
   - 로컬 레지스트리에 푸시
6. **Deploy**: k3s에 배포
7. **Verify**: 배포 검증 및 헬스체크

**사용법**:
```bash
./scripts/test-local.sh
```

**출력 예시**:
```
🚀 Starting local test environment setup...

Step 1/7: Checking prerequisites...
[SUCCESS] Prerequisites checked

Step 2/7: Checking k3s status...
[SUCCESS] k3s cluster is accessible

Step 3/7: Checking local registry...
[SUCCESS] Local registry is running at localhost:5000

Step 4/7: Checking Gradle wrapper...
[SUCCESS] Gradle wrapper found

Step 5/7: Building application...
[INFO] Running Gradle build...
[SUCCESS] Application built successfully
[SUCCESS] Docker image built: localhost:5000/cnap-server:dev
[SUCCESS] Image pushed to registry

Step 6/7: Deploying to k3s...
[SUCCESS] Deployment is ready

Step 7/7: Verifying deployment...
[INFO] Pod status:
NAME                           READY   STATUS    RESTARTS   AGE
cnap-server-xxx               1/1     Running   0          30s

[SUCCESS] Health check passed!
{
  "status": "UP",
  "application": "cnap-server-local",
  "namespace": "cnap-dev",
  "timestamp": 1730000000000
}

✨ Local test environment is ready!

Next steps:
  1. View logs:       ./scripts/logs.sh
  2. Port forward:    ./scripts/port-forward.sh 8080
  3. Access health:   curl http://localhost:8080/healthz
  4. View in OpenLens: Workloads → Pods → cnap-dev namespace
```

---

### 4. `test-e2e.sh` - End-to-End 테스트

**목적**: 배포된 애플리케이션의 종합 테스트

**테스트 카테고리**:

#### A. Kubernetes Resource Tests
- ✅ Namespace 존재 확인
- ✅ Deployment 존재 확인
- ✅ Service 존재 확인
- ✅ Pod Running 상태 확인
- ✅ Pod Ready 상태 확인

#### B. HTTP Endpoint Tests
- ✅ `/healthz` 엔드포인트 (UP 응답)
- ✅ `/version` 엔드포인트 (버전 정보)
- ✅ Application 이름 확인

#### C. Container Health Tests
- ✅ 컨테이너 실행 상태
- ✅ Restart count = 0
- ✅ 컨테이너 이미지 확인

#### D. Resource Configuration Tests
- ✅ Memory limits 설정 확인
- ✅ CPU limits 설정 확인

#### E. Application Log Tests
- ✅ 애플리케이션 시작 메시지 확인
- ✅ 에러 로그 부재 확인

#### F. Network Connectivity Tests
- ✅ Service DNS 해석 테스트

**사용법**:
```bash
# test-local.sh 실행 후
./scripts/test-e2e.sh
```

**출력 예시**:
```
🧪 End-to-End Testing for CNAP Server
======================================

[SUCCESS] Found pod: cnap-server-xxx
[SUCCESS] Port forwarding started

Running tests...

=== Kubernetes Resource Tests ===
[TEST] Running: Namespace exists
[✓] PASS: Namespace exists
[TEST] Running: Deployment exists
[✓] PASS: Deployment exists
[TEST] Running: Service exists
[✓] PASS: Service exists
[TEST] Running: Pod is running
[✓] PASS: Pod is running
[TEST] Running: Pod is ready
[✓] PASS: Pod is ready

=== HTTP Endpoint Tests ===
[TEST] HTTP Test: Health endpoint returns UP
[✓] PASS: Health endpoint returns UP
    Response: {"status":"UP",...}
[TEST] HTTP Test: Version endpoint returns version
[✓] PASS: Version endpoint returns version
    Response: {"version":"dev",...}

=== Container Health Tests ===
[✓] PASS: Container is running
[✓] PASS: Container restart count is 0
[✓] PASS: Container image is correct

=== Resource Configuration Tests ===
[✓] PASS: Memory limits configured
[✓] PASS: CPU limits configured

=== Application Log Tests ===
[✓] PASS: Application started successfully
[✓] PASS: No errors in logs

=== Network Connectivity Tests ===
[✓] PASS: Service DNS resolution works

======================================
[INFO] Test Summary:

[✓] Passed: 17
[INFO] Failed: 0

✨ All tests passed! (100%)
```

---

## 테스트 워크플로우

### 초기 설정 (1회만)
```bash
# 1. k3s 환경 구축
./scripts/setup-k3s.sh

# 2. 환경 검증
./scripts/verify-k3s.sh
```

### 개발 사이클
```bash
# 코드 수정
vim src/main/kotlin/...

# 빌드 및 배포
./scripts/test-local.sh

# E2E 테스트 실행
./scripts/test-e2e.sh

# 로그 확인
./scripts/logs.sh

# 수동 테스트 (다른 터미널)
./scripts/port-forward.sh 8080
curl http://localhost:8080/healthz
```

### 빠른 재배포
```bash
# 코드 수정 후
./scripts/rebuild-deploy.sh

# 또는
./scripts/test-local.sh  # 전체 빌드부터
```

---

## 문제 해결

### k3s가 시작되지 않음
```bash
# k3s 로그 확인
sudo journalctl -u k3s -f

# k3s 재시작
sudo systemctl restart k3s

# k3s 상태 확인
sudo systemctl status k3s
```

### Pod가 ImagePullBackOff 상태
```bash
# 원인: 로컬 레지스트리에 이미지 없음
# 해결:
./scripts/build.sh

# 레지스트리 확인
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/cnap-server/tags/list
```

### Pod가 CrashLoopBackOff 상태
```bash
# 로그 확인
kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server

# Pod 상세 확인
kubectl describe pod -n cnap-dev <pod-name>

# 이벤트 확인
kubectl get events -n cnap-dev --sort-by='.lastTimestamp'
```

### 테스트 실패 디버깅
```bash
# 1. 환경 검증
./scripts/verify-k3s.sh

# 2. Pod 상태 확인
kubectl get pods -n cnap-dev

# 3. 로그 확인
kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server --tail=100

# 4. 수동 헬스체크
./scripts/port-forward.sh 8080
curl -v http://localhost:8080/healthz

# 5. Pod 내부 접속
kubectl exec -it -n cnap-dev <pod-name> -- /bin/sh
```

---

## CI/CD 통합

GitHub Actions는 동일한 스크립트를 사용합니다:

```yaml
# .github/workflows/ci.yml
- name: Setup k3s
  run: ./scripts/setup-k3s.sh

- name: Run tests
  run: ./scripts/test-local.sh

- name: Run E2E tests
  run: ./scripts/test-e2e.sh
```

---

## 성능 벤치마크

### 로컬 환경에서의 예상 시간

| 단계 | 시간 | 비고 |
|------|------|------|
| k3s 초기 설치 | 1-2분 | 최초 1회만 |
| Gradle 빌드 | 30-60초 | 캐시 사용 시 빠름 |
| Docker 빌드 | 1-2분 | 레이어 캐싱 사용 |
| k3s 배포 | 30초 | Pod 시작 시간 포함 |
| E2E 테스트 | 30-45초 | 17개 테스트 |
| **전체 (최초)** | **5-8분** | setup + build + test |
| **전체 (재배포)** | **2-3분** | build + test만 |

---

## 모범 사례

### 1. 테스트 전 항상 검증
```bash
./scripts/verify-k3s.sh
```

### 2. 로그 모니터링
```bash
# 별도 터미널에서
./scripts/logs.sh
```

### 3. OpenLens 사용
- 실시간 Pod 상태 확인
- 로그 스트리밍
- 리소스 사용률 모니터링

### 4. 정기적인 정리
```bash
# 오래된 리소스 정리
./scripts/cleanup.sh

# 필요시 완전 재설정
./scripts/cleanup.sh
./scripts/setup-k3s.sh
./scripts/test-local.sh
```

---

## 다음 단계

- [Development Guide](DEVELOPMENT.md) - 개발 가이드
- [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md) - 구현 계획
- [Quick Start](QUICKSTART.md) - 빠른 시작 가이드

---

**Last Updated**: 2025-10-25
