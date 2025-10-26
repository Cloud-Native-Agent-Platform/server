# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CNAP (Cloud Native Agent Platform) Server is a Kubernetes-based orchestration server that manages Agent and AgentJob resources. It acts as an intermediary between Connectors (like Discord bots) and Runners (agent runtime in pods), providing HTTP/SSE APIs northbound and WebSocket communication with runners.

**Tech Stack:**
- Kotlin 2.0.20 + Spring Boot 3.3.5
- JDK 21 (uses Virtual Threads)
- Kubernetes (k3s for local development)
- Gradle 8.5 (Kotlin DSL)
- Docker with multi-stage builds

## Development Commands

### Build & Test
```bash
# Build the project
./gradlew build

# Run unit tests only
./gradlew test

# Run specific test
./gradlew test --tests "com.cnap.server.controller.HealthControllerTest"

# Run all tests including integration tests
./gradlew check
```

### Local Development (IDE or CLI)
```bash
# Run Spring Boot application with local profile
./gradlew bootRun --args='--spring.profiles.active=local'

# The application runs on port 8080
# Health check: http://localhost:8080/healthz
```

### Kubernetes (k3s) Development Workflow

**Initial Setup:**
```bash
# 1. Initialize Gradle wrapper
./scripts/init-gradle-wrapper.sh

# 2. Setup k3s cluster and local registry
./scripts/setup-k3s.sh

# 3. Verify k3s installation
./scripts/verify-k3s.sh
```

**Development Cycle:**
```bash
# Build Gradle JAR + Docker image and push to local registry
./scripts/build.sh

# Deploy to k3s (uses Kustomize)
./scripts/deploy.sh local

# Or rebuild + redeploy in one command
./scripts/rebuild-deploy.sh

# View logs (follows pod logs in cnap-dev namespace)
./scripts/logs.sh

# Port forward to access service locally
./scripts/port-forward.sh 8080
# Then access: http://localhost:8080/healthz
```

**Testing:**
```bash
# Run comprehensive local cluster tests (macOS compatible)
./scripts/test-local.sh

# Run E2E tests against deployed application
./scripts/test-e2e.sh

# Cleanup k3s resources
./scripts/cleanup.sh
```

**Important Registry Notes:**
- macOS: Local registry runs on port `5001` (Docker Desktop limitation)
- Linux: Local registry runs on port `5000`
- Image format: `localhost:5001/cnap-server:dev` (macOS) or `localhost:5000/cnap-server:dev` (Linux)
- The build scripts automatically detect the OS and use the correct port

## Architecture

### Three-Tier Communication Model

```
┌──────────────┐
│  Connector   │ (Discord Bot, HTTP clients)
│  (HTTP/SSE)  │
└──────┬───────┘
       │ Northbound: HTTP REST API + SSE/WebSocket for event streaming
       ▼
┌──────────────┐
│ CNAP Server  │
│  (Spring)    │
└──┬────────┬──┘
   │        │
   │        └─────────► Southbound: Kubernetes API (CRD management)
   │                    - Agent CRD (agent definitions)
   │                    - AgentJob CRD (job lifecycle)
   │
   └────────────────► Eastbound: Runner WebSocket
                       (bidirectional streaming with agent pods)
```

### Package Structure Philosophy

The codebase follows standard Spring Boot layering:

```
com.cnap.server/
├── controller/          # REST endpoints (northbound API)
├── service/             # Business logic layer
├── client/              # External integrations (Kubernetes client)
├── model/
│   ├── dto/            # API request/response objects
│   ├── crd/            # Kubernetes CRD models (Agent, AgentJob)
│   └── entity/         # Domain entities (if needed)
├── stream/             # SSE/WebSocket handlers
├── config/             # Spring configuration classes
└── exception/          # Exception handling
```

### Kubernetes Resources (Kustomize-based)

- **Base manifests**: `k8s/base/` - namespace, serviceaccount, RBAC, deployment, service, secrets
- **Environment overlays**: `k8s/overlays/local/` - local development patches (resource limits, image settings)
- **Deployment strategy**: Uses Kustomize for environment-specific configurations
- **Namespace**: All resources deploy to `cnap-dev`
- **ServiceAccount**: `cnap-server-sa` with appropriate RBAC for CRD access

## Configuration

### Environment Variables

Key configuration (set in `application-local.yml` or via environment):

- `CNAP_K8S_NAMESPACE`: Target Kubernetes namespace (default: `cnap-dev`)
- `CNAP_STREAM_MODE`: Streaming mode - `sse` or `ws` (default: `sse`)
- `CNAP_AUTH_TOKEN`: Authentication token (default: `local-dev-token`)
- `SPRING_PROFILES_ACTIVE`: Spring profile - use `local` for development

### Spring Profiles

- **default**: Minimal configuration
- **local**: Development mode with DEBUG logging, full management endpoints, relaxed security

## Development Guidelines

### Kotlin Code Style

- Follow Kotlin official style guide
- Use `camelCase` for functions/properties
- Use `PascalCase` for classes
- Use `UPPER_SNAKE_CASE` for constants
- Prefer data classes for DTOs
- Use Kotlin coroutines for async operations (this project uses coroutines + Spring WebFlux)
- **Comments and logging**: Only add comments and debug logging when absolutely necessary. Code should be self-documenting through clear naming and structure. Avoid redundant comments that simply restate what the code does.

### Testing Strategy

- **Unit tests**: `src/test/kotlin/` - test business logic in isolation
- **Integration tests**: Use `@SpringBootTest` with `@AutoConfigureMockMvc` for API testing
- **E2E tests**: `./scripts/test-e2e.sh` validates deployment in k3s
- Test file naming: `<ClassName>Test.kt`

### Working with Kubernetes CRDs

The project manages custom Kubernetes resources:

1. **Agent CRD**: Defines long-lived agent configurations
   - Spec: name, systemPrompt, MCP integrations, runtime settings
   - Status: phase, conditions, lastUpdated

2. **AgentJob CRD**: Represents individual job executions
   - Spec: agentRef, parameters, storage, TTL
   - Status: phase (Pending/Running/Succeeded/Failed), podRef, timestamps

Use the `KubernetesClient` service layer (to be implemented) for all CRD operations rather than direct kubectl calls.

### Git Workflow

- Main branch: `main`
- Feature branches: `feature/your-feature-name`
- Commits should be in Korean (project language)
- CI/CD runs on push/PR (GitHub Actions)

## CI/CD Workflows

### GitHub Actions

1. **ci.yml**: Runs on push/PR - builds, tests, creates Docker image
2. **cd.yml**: On main branch - builds and pushes to GitHub Container Registry
3. **deploy-k3s.yml**: Manual deployment workflow (supports dev/staging/production)

## Debugging

### Local Debugging

- Run application in IDE with `local` profile
- Set breakpoints as needed
- Adjust log levels in `application-local.yml`:
  ```yaml
  logging:
    level:
      com.cnap: TRACE
      org.springframework: DEBUG
  ```

### k3s Debugging

```bash
# View pod logs
kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server -f

# Check pod status
kubectl get pods -n cnap-dev

# Describe pod for events
kubectl describe pod -n cnap-dev <pod-name>

# Exec into pod
POD_NAME=$(kubectl get pods -n cnap-dev -l app.kubernetes.io/name=cnap-server -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n cnap-dev $POD_NAME -- /bin/sh

# Check all resources
kubectl get all -n cnap-dev
```

## Common Issues

### ImagePullBackOff in k3s

```bash
# Check if local registry is running
docker ps | grep registry

# Verify image is in registry
curl http://localhost:5001/v2/_catalog  # macOS
curl http://localhost:5001/v2/cnap-server/tags/list

# Rebuild and push
./scripts/build.sh
```

### Pod Not Starting

- Check resource limits in `k8s/overlays/local/deployment-patch.yaml`
- Verify serviceaccount has correct RBAC permissions
- Check application logs for startup errors

### Gradle Build Issues

```bash
# Clean build cache
./gradlew clean

# Re-download dependencies
./gradlew build --refresh-dependencies
```

## Implementation Roadmap

The project is following a phased implementation plan documented in `docs/IMPLEMENTATION_ROADMAP.md`:

- **Phase 1 (Week 1)**: ✅ Basic API skeleton, health checks, k8s deployment
- **Phase 2 (Week 2)**: 🚧 Domain models (CRD, DTOs), Kubernetes client integration, Agent CRUD API
- **Phase 3 (Week 3)**: AgentJob API, SSE streaming
- **Phase 4 (Week 4)**: WebSocket for Runners, command queueing

When implementing new features, refer to the roadmap for context and dependencies between epics.

## Useful Resources

- Project docs: `docs/` directory
  - `QUICKSTART.md`: Quick start guide
  - `DEVELOPMENT.md`: Detailed development guide
  - `PROJECT_STRUCTURE.md`: Directory structure explanation
  - `TESTING.md`: Testing guide
- README.md: Korean-language project overview
- Kubernetes manifests: `k8s/base/` and `k8s/overlays/`
