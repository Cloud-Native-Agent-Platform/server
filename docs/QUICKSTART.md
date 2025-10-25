# Quick Start Guide

k3s 위에 CNAP Server를 빠르게 실행하는 가이드입니다.

## Prerequisites

- macOS or Linux
- Docker Desktop 설치됨
- 최소 4GB RAM 가용

## 5분 안에 시작하기

### 1. Gradle Wrapper 초기화 (최초 1회)

```bash
./scripts/init-gradle-wrapper.sh
```

### 2. k3s 설치 및 설정

```bash
# k3s 설치, 로컬 레지스트리 설정, 네임스페이스 생성
./scripts/setup-k3s.sh
```

이 스크립트는:
- k3s를 설치합니다 (이미 설치되어 있으면 스킵)
- kubeconfig를 설정합니다
- 로컬 Docker 레지스트리(localhost:5000)를 시작합니다
- cnap-dev 네임스페이스를 생성합니다

### 3. 빌드 및 배포

```bash
# Docker 이미지 빌드 및 푸시
./scripts/build.sh

# k3s에 배포
./scripts/deploy.sh local
```

### 4. 확인

```bash
# 터미널 1: 포트 포워딩
./scripts/port-forward.sh 8080

# 터미널 2: 헬스체크
curl http://localhost:8080/healthz
```

예상 응답:
```json
{
  "status": "UP",
  "application": "cnap-server-local",
  "namespace": "cnap-dev",
  "timestamp": 1730000000000
}
```

## 로그 확인

```bash
./scripts/logs.sh
```

## 코드 변경 후 재배포

```bash
./scripts/rebuild-deploy.sh
```

## 정리

```bash
# k3s에서 애플리케이션 제거
./scripts/cleanup.sh

# k3s 완전 제거 (선택사항)
/usr/local/bin/k3s-uninstall.sh
```

## 다음 단계

- [README.md](./README.md) - 전체 문서
- [docs/DEVELOPMENT.md](./docs/DEVELOPMENT.md) - 개발 가이드
- API 구현 시작

## 문제 해결

### k3s가 설치되지 않음

```bash
# macOS에서는 sudo 권한 필요
# Linux 시스템에 따라 다를 수 있음
```

### Docker 레지스트리 오류

```bash
# 레지스트리 재시작
docker stop registry && docker rm registry
docker run -d --restart=always -p 5000:5000 --name registry registry:2
```

### Pod가 Running 상태가 아님

```bash
# Pod 상태 확인
kubectl get pods -n cnap-dev

# 상세 정보 확인
kubectl describe pod -n cnap-dev <pod-name>

# 로그 확인
kubectl logs -n cnap-dev <pod-name>
```

### JDK 21이 없음

```bash
# macOS
brew install openjdk@21

# Ubuntu
sudo apt install openjdk-21-jdk
```

## 유용한 명령어

```bash
# kubectl 단축키
alias k=kubectl
alias kgp='kubectl get pods -n cnap-dev'
alias klogs='kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server -f'

# k3s 상태 확인
sudo systemctl status k3s

# k3s 재시작
sudo systemctl restart k3s
```
