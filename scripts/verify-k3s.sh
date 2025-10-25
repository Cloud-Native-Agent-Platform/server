#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

echo "🔍 k3s Environment Verification"
echo "================================"
echo ""

# Check 1: k3s binary
log_info "Checking k3s installation..."
if command -v k3s &> /dev/null; then
    K3S_VERSION=$(k3s --version | head -n1)
    log_success "k3s is installed: $K3S_VERSION"
else
    log_error "k3s is not installed"
    log_info "Run: ./scripts/setup-k3s.sh"
    exit 1
fi

# Check 2: k3s service status
log_info "Checking k3s service status..."
if sudo systemctl is-active --quiet k3s 2>/dev/null; then
    log_success "k3s service is running"
elif pgrep -x "k3s" > /dev/null; then
    log_success "k3s process is running"
else
    log_error "k3s is not running"
    log_info "Start with: sudo systemctl start k3s"
    exit 1
fi

# Check 3: kubectl
log_info "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | head -n1)
    log_success "kubectl is installed: $KUBECTL_VERSION"
else
    log_error "kubectl is not installed"
    exit 1
fi

# Check 4: kubeconfig
log_info "Checking kubeconfig..."
if [ -f "$HOME/.kube/config" ]; then
    log_success "kubeconfig found at ~/.kube/config"
elif [ -f "/etc/rancher/k3s/k3s.yaml" ]; then
    log_warning "kubeconfig found at /etc/rancher/k3s/k3s.yaml but not in ~/.kube/"
    log_info "Copy with: sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config"
else
    log_error "kubeconfig not found"
    exit 1
fi

# Check 5: Cluster connection
log_info "Checking cluster connection..."
if kubectl cluster-info &> /dev/null; then
    log_success "Successfully connected to k3s cluster"
    CLUSTER_INFO=$(kubectl cluster-info | head -n1)
    echo "    $CLUSTER_INFO"
else
    log_error "Cannot connect to k3s cluster"
    exit 1
fi

# Check 6: Nodes
log_info "Checking nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODE_COUNT" -gt 0 ]; then
    log_success "$NODE_COUNT node(s) found"
    kubectl get nodes --no-headers | while read line; do
        echo "    $line"
    done
else
    log_error "No nodes found"
    exit 1
fi

# Check 7: Docker
log_info "Checking Docker..."
if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        log_success "Docker is running"
    else
        log_error "Docker daemon is not running"
        exit 1
    fi
else
    log_error "Docker is not installed"
    exit 1
fi

# Check 8: Local registry
log_info "Checking local registry..."
if docker ps | grep -q "registry:2"; then
    REGISTRY_PORT=$(docker port registry 2>/dev/null | grep 5000 | cut -d: -f2)
    log_success "Local registry is running on port ${REGISTRY_PORT:-5000}"
else
    log_warning "Local registry is not running"
    log_info "Start with: docker run -d -p 5000:5000 --name registry registry:2"
fi

# Check 9: System pods
log_info "Checking system pods..."
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo 0)

if [ "$SYSTEM_PODS" -gt 0 ]; then
    log_success "$RUNNING_PODS/$SYSTEM_PODS system pods are running"
    kubectl get pods -n kube-system --no-headers | while read line; do
        echo "    $line"
    done
else
    log_warning "No system pods found (cluster may be starting)"
fi

# Check 10: CNAP namespace
log_info "Checking CNAP namespace..."
if kubectl get namespace cnap-dev &> /dev/null; then
    log_success "Namespace 'cnap-dev' exists"
    POD_COUNT=$(kubectl get pods -n cnap-dev --no-headers 2>/dev/null | wc -l)
    if [ "$POD_COUNT" -gt 0 ]; then
        echo "    Pods in cnap-dev: $POD_COUNT"
        kubectl get pods -n cnap-dev --no-headers | while read line; do
            echo "      $line"
        done
    fi
else
    log_warning "Namespace 'cnap-dev' does not exist (will be created on first deploy)"
fi

# Summary
echo ""
echo "================================"
log_success "✨ k3s environment is ready!"
echo ""
log_info "Quick commands:"
echo "  • View all pods:     kubectl get pods -A"
echo "  • View nodes:        kubectl get nodes"
echo "  • View services:     kubectl get svc -A"
echo "  • View events:       kubectl get events -A --sort-by='.lastTimestamp'"
echo ""
log_info "Test environment:"
echo "  • Run test:          ./scripts/test-local.sh"
echo "  • Deploy:            ./scripts/deploy.sh local"
echo "  • View logs:         ./scripts/logs.sh"
echo "  • Port forward:      ./scripts/port-forward.sh 8080"
