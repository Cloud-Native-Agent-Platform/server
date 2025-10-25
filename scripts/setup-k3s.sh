#!/bin/bash
set -e

echo "🚀 Setting up k3s for CNAP development..."

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "📋 Detected OS: ${MACHINE}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

if [ "$MACHINE" = "Mac" ]; then
    echo "🍎 Using k3d for macOS..."

    # Check if k3d is installed
    if ! command -v k3d &> /dev/null; then
        echo "📦 Installing k3d..."
        if command -v brew &> /dev/null; then
            brew install k3d
        else
            echo "❌ Homebrew not found. Installing k3d via curl..."
            curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
        fi
    else
        echo "✅ k3d is already installed"
        k3d version
    fi

    # Check if cluster already exists
    if k3d cluster list | grep -q cnap-dev; then
        echo "✅ k3d cluster 'cnap-dev' already exists"
    else
        echo "🚀 Creating k3d cluster 'cnap-dev'..."
        # Create k3d cluster with:
        # - Port mapping for services (8080:80)
        # - Local registry on port 5001 (5000 is used by macOS AirPlay)
        # - API server port 6550
        k3d cluster create cnap-dev \
            --api-port 6550 \
            --servers 1 \
            --agents 1 \
            --port "8080:80@loadbalancer" \
            --registry-create cnap-registry:0.0.0.0:5001 \
            --wait

        echo "✅ k3d cluster created successfully"
    fi

    # Set up kubeconfig
    echo "🔧 Setting up kubeconfig..."
    k3d kubeconfig merge cnap-dev --kubeconfig-switch-context

elif [ "$MACHINE" = "Linux" ]; then
    echo "🐧 Using native k3s for Linux..."

    # Check if k3s is already installed
    if command -v k3s &> /dev/null; then
        echo "✅ k3s is already installed"
        k3s --version
    else
        echo "📦 Installing k3s..."
        curl -sfL https://get.k3s.io | sh -

        # Wait for k3s to be ready
        echo "⏳ Waiting for k3s to be ready..."
        sleep 10
        sudo k3s kubectl wait --for=condition=Ready node --all --timeout=60s
    fi

    # Set up kubeconfig
    echo "🔧 Setting up kubeconfig..."
    mkdir -p ~/.kube
    sudo k3s kubectl config view --raw | tee ~/.kube/config > /dev/null
    chmod 600 ~/.kube/config

    # Set up local registry
    echo "🐳 Setting up local registry..."
    if ! docker ps | grep -q cnap-registry; then
        docker run -d --restart=always -p 5000:5000 --name cnap-registry registry:2
        echo "✅ Local registry started at localhost:5000"
    else
        echo "✅ Local registry already running"
    fi
else
    echo "❌ Unsupported OS: ${MACHINE}"
    exit 1
fi

# Verify connection
echo "✅ Verifying Kubernetes connection..."
kubectl get nodes

# Create namespace
echo "📁 Creating cnap-dev namespace..."
kubectl create namespace cnap-dev --dry-run=client -o yaml | kubectl apply -f -

echo "✨ k3s setup complete!"
echo ""
echo "📊 Cluster info:"
if [ "$MACHINE" = "Mac" ]; then
    echo "  - Cluster name: cnap-dev"
    echo "  - Local registry: localhost:5001"
    echo "  - HTTP port: 8080 (mapped to LoadBalancer port 80)"
    echo ""
    echo "🔧 Useful k3d commands:"
    echo "  - List clusters: k3d cluster list"
    echo "  - Stop cluster: k3d cluster stop cnap-dev"
    echo "  - Start cluster: k3d cluster start cnap-dev"
    echo "  - Delete cluster: k3d cluster delete cnap-dev"
fi
echo ""
echo "Next steps:"
echo "  1. Build the Docker image: ./scripts/build.sh"
echo "  2. Deploy to k3s: ./scripts/deploy.sh"
