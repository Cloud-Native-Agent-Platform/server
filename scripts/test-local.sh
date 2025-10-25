#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="localhost:5000/cnap-server"
IMAGE_TAG="dev"
NAMESPACE="cnap-dev"
DEPLOYMENT_NAME="cnap-server"
SERVICE_NAME="cnap-server"
PORT="8080"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed"
        exit 1
    fi
}

wait_for_pod() {
    local namespace=$1
    local label=$2
    local timeout=${3:-120}

    log_info "Waiting for pod with label $label in namespace $namespace..."

    if kubectl wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout="${timeout}s" 2>/dev/null; then
        log_success "Pod is ready"
        return 0
    else
        log_error "Pod failed to become ready within ${timeout}s"
        return 1
    fi
}

# Main script
main() {
    log_info "🚀 Starting local test environment setup..."
    echo ""

    # Step 1: Check prerequisites
    log_info "Step 1/7: Checking prerequisites..."
    check_command "docker"
    check_command "kubectl"
    check_command "k3s" || log_warning "k3s not found. Run ./scripts/setup-k3s.sh first"
    log_success "Prerequisites checked"
    echo ""

    # Step 2: Check k3s status
    log_info "Step 2/7: Checking k3s status..."
    if sudo systemctl is-active --quiet k3s 2>/dev/null || pgrep -x "k3s" > /dev/null; then
        log_success "k3s is running"
    else
        log_error "k3s is not running. Starting k3s..."
        if [ -f "/usr/local/bin/k3s" ]; then
            sudo systemctl start k3s 2>/dev/null || {
                log_error "Failed to start k3s"
                exit 1
            }
            sleep 5
        else
            log_error "k3s is not installed. Run ./scripts/setup-k3s.sh"
            exit 1
        fi
    fi

    kubectl get nodes >/dev/null 2>&1 || {
        log_error "Cannot connect to k3s cluster"
        exit 1
    }
    log_success "k3s cluster is accessible"
    echo ""

    # Step 3: Check local registry
    log_info "Step 3/7: Checking local registry..."
    if docker ps | grep -q "registry:2"; then
        log_success "Local registry is running at localhost:5000"
    else
        log_warning "Local registry not found. Starting..."
        docker run -d --restart=always -p 5000:5000 --name registry registry:2
        sleep 3
        log_success "Local registry started"
    fi
    echo ""

    # Step 4: Initialize Gradle wrapper if needed
    log_info "Step 4/7: Checking Gradle wrapper..."
    if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
        log_warning "Gradle wrapper not found. Initializing..."
        ./scripts/init-gradle-wrapper.sh
        log_success "Gradle wrapper initialized"
    else
        log_success "Gradle wrapper found"
    fi
    echo ""

    # Step 5: Build application
    log_info "Step 5/7: Building application..."
    log_info "Running Gradle build..."
    ./gradlew build -x test --no-daemon --quiet || {
        log_error "Gradle build failed"
        exit 1
    }
    log_success "Application built successfully"

    log_info "Building Docker image..."
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" . --quiet || {
        log_error "Docker build failed"
        exit 1
    }
    log_success "Docker image built: ${IMAGE_NAME}:${IMAGE_TAG}"

    log_info "Pushing to local registry..."
    docker push "${IMAGE_NAME}:${IMAGE_TAG}" --quiet || {
        log_error "Docker push failed"
        exit 1
    }
    log_success "Image pushed to registry"
    echo ""

    # Step 6: Deploy to k3s
    log_info "Step 6/7: Deploying to k3s..."

    # Check if namespace exists
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log_info "Namespace $NAMESPACE already exists"
    else
        log_info "Creating namespace $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi

    # Apply Kubernetes manifests
    log_info "Applying Kubernetes manifests..."
    kubectl apply -k k8s/overlays/local/ || {
        log_error "Failed to apply manifests"
        exit 1
    }

    # Wait for deployment to be ready
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=120s || {
        log_error "Deployment failed to become ready"
        log_info "Showing pod status:"
        kubectl get pods -n "$NAMESPACE"
        log_info "Showing pod logs:"
        kubectl logs -n "$NAMESPACE" -l app.kubernetes.io/name="$DEPLOYMENT_NAME" --tail=50 || true
        exit 1
    }

    log_success "Deployment is ready"
    echo ""

    # Step 7: Verify deployment
    log_info "Step 7/7: Verifying deployment..."

    # Get pod status
    log_info "Pod status:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$DEPLOYMENT_NAME"

    # Get service info
    log_info "Service info:"
    kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME"

    # Test health endpoint via port-forward
    log_info "Testing health endpoint..."

    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$DEPLOYMENT_NAME" -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$POD_NAME" ]; then
        log_error "No pod found"
        exit 1
    fi

    log_info "Testing health check on pod: $POD_NAME"

    # Port forward in background
    kubectl port-forward -n "$NAMESPACE" "$POD_NAME" $PORT:$PORT >/dev/null 2>&1 &
    PF_PID=$!

    # Wait for port forward to be ready
    sleep 3

    # Test health endpoint
    HEALTH_RESPONSE=$(curl -s http://localhost:$PORT/healthz || echo "FAILED")

    # Kill port forward
    kill $PF_PID 2>/dev/null || true

    if echo "$HEALTH_RESPONSE" | grep -q "UP"; then
        log_success "Health check passed!"
        echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
    else
        log_error "Health check failed"
        log_info "Response: $HEALTH_RESPONSE"
        exit 1
    fi

    echo ""
    log_success "✨ Local test environment is ready!"
    echo ""
    log_info "Next steps:"
    echo "  1. View logs:       ./scripts/logs.sh"
    echo "  2. Port forward:    ./scripts/port-forward.sh $PORT"
    echo "  3. Access health:   curl http://localhost:$PORT/healthz"
    echo "  4. View in OpenLens: Workloads → Pods → $NAMESPACE namespace"
    echo ""
    log_info "To rebuild and redeploy: ./scripts/rebuild-deploy.sh"
    log_info "To cleanup: ./scripts/cleanup.sh"
}

# Cleanup function
cleanup_on_error() {
    log_error "Script failed. Cleaning up..."
    kill $PF_PID 2>/dev/null || true
    exit 1
}

trap cleanup_on_error ERR

# Run main function
main "$@"
