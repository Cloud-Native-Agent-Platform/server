#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_test() { echo -e "${CYAN}[TEST]${NC} $1"; }

NAMESPACE="cnap-dev"
DEPLOYMENT_NAME="cnap-server"
PORT="8080"
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework
run_test() {
    local test_name=$1
    local test_command=$2

    log_test "Running: $test_name"

    if eval "$test_command" &> /dev/null; then
        log_success "PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "FAIL: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

http_test() {
    local test_name=$1
    local url=$2
    local expected=$3

    log_test "HTTP Test: $test_name"

    response=$(curl -s "$url" || echo "FAILED")

    if echo "$response" | grep -q "$expected"; then
        log_success "PASS: $test_name"
        echo "    Response: $response"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "FAIL: $test_name"
        echo "    Expected: $expected"
        echo "    Got: $response"
        ((TESTS_FAILED++))
        return 1
    fi
}

main() {
    echo "🧪 End-to-End Testing for CNAP Server"
    echo "======================================"
    echo ""

    # Setup
    log_info "Setting up test environment..."

    # Verify deployment
    log_info "Verifying deployment..."
    if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Deployment not found. Run ./scripts/test-local.sh first"
        exit 1
    fi

    # Get pod name
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$DEPLOYMENT_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD_NAME" ]; then
        log_error "No pod found for deployment $DEPLOYMENT_NAME"
        exit 1
    fi
    log_success "Found pod: $POD_NAME"
    echo ""

    # Start port forwarding in background
    log_info "Starting port forwarding..."
    kubectl port-forward -n "$NAMESPACE" "$POD_NAME" $PORT:$PORT >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3
    log_success "Port forwarding started (PID: $PF_PID)"
    echo ""

    # Run tests
    log_info "Running tests..."
    echo ""

    # Test 1: Kubernetes resources
    log_info "=== Kubernetes Resource Tests ==="
    run_test "Namespace exists" "kubectl get namespace $NAMESPACE"
    run_test "Deployment exists" "kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE"
    run_test "Service exists" "kubectl get service $DEPLOYMENT_NAME -n $NAMESPACE"
    run_test "Pod is running" "kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}' | grep -q Running"
    run_test "Pod is ready" "kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q True"
    echo ""

    # Test 2: HTTP endpoints
    log_info "=== HTTP Endpoint Tests ==="
    http_test "Health endpoint returns UP" "http://localhost:$PORT/healthz" "UP"
    http_test "Version endpoint returns version" "http://localhost:$PORT/version" "version"
    http_test "Application name is correct" "http://localhost:$PORT/healthz" "cnap-server"
    echo ""

    # Test 3: Container health
    log_info "=== Container Health Tests ==="
    run_test "Container is running" "kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].state.running}' | grep -q 'startedAt'"
    run_test "Container restart count is 0" "[ \$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}') -eq 0 ]"
    run_test "Container image is correct" "kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}' | grep -q cnap-server"
    echo ""

    # Test 4: Resource limits
    log_info "=== Resource Configuration Tests ==="
    run_test "Memory limits configured" "kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.limits.memory}' | grep -q 'Mi'"
    run_test "CPU limits configured" "kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources.limits.cpu}' | grep -q 'm'"
    echo ""

    # Test 5: Application logs
    log_info "=== Application Log Tests ==="
    LOGS=$(kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=200)

    # Check for application startup (Spring Boot logs or successful requests)
    if echo "$LOGS" | grep -qE "(Started CnapServerApplication|Tomcat started on port|DispatcherServlet)"; then
        log_success "PASS: Application started successfully"
        ((TESTS_PASSED++))
    else
        log_error "FAIL: Application start indicators not found"
        ((TESTS_FAILED++))
    fi

    # Only fail if there are ERROR level logs (not just the word "error" in lowercase)
    if echo "$LOGS" | grep -q "ERROR"; then
        log_error "FAIL: ERROR level logs found"
        echo "$LOGS" | grep "ERROR" | head -5
        ((TESTS_FAILED++))
    else
        log_success "PASS: No ERROR level logs"
        ((TESTS_PASSED++))
    fi
    echo ""

    # Test 6: Network connectivity
    log_info "=== Network Connectivity Tests ==="

    # Test service DNS
    SERVICE_DNS="${DEPLOYMENT_NAME}.${NAMESPACE}.svc.cluster.local"
    if kubectl run test-curl --image=curlimages/curl:latest --rm -i --restart=Never -n "$NAMESPACE" -- curl -s "http://${SERVICE_DNS}:${PORT}/healthz" 2>/dev/null | grep -q "UP"; then
        log_success "PASS: Service DNS resolution works"
        ((TESTS_PASSED++))
    else
        log_error "FAIL: Service DNS resolution failed"
        ((TESTS_FAILED++))
    fi
    echo ""

    # Cleanup
    log_info "Cleaning up..."
    kill $PF_PID 2>/dev/null || true
    log_success "Port forwarding stopped"
    echo ""

    # Summary
    echo "======================================"
    log_info "Test Summary:"
    echo ""
    log_success "Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "Failed: $TESTS_FAILED"
    else
        log_info "Failed: $TESTS_FAILED"
    fi
    echo ""

    TOTAL=$((TESTS_PASSED + TESTS_FAILED))
    PASS_RATE=$((TESTS_PASSED * 100 / TOTAL))

    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "✨ All tests passed! ($PASS_RATE%)"
        exit 0
    else
        log_error "❌ Some tests failed ($PASS_RATE% pass rate)"
        exit 1
    fi
}

# Trap to ensure cleanup
cleanup() {
    kill $PF_PID 2>/dev/null || true
}
trap cleanup EXIT

main "$@"
