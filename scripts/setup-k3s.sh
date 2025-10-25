#!/bin/bash
set -e

echo "🚀 Setting up k3s for CNAP development..."

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

# Verify connection
echo "✅ Verifying k3s connection..."
kubectl get nodes

# Set up local registry (optional, for faster image loading)
echo "🐳 Setting up local registry..."
if ! docker ps | grep -q registry:2; then
    docker run -d --restart=always -p 5000:5000 --name registry registry:2
    echo "✅ Local registry started at localhost:5000"
else
    echo "✅ Local registry already running"
fi

# Create namespace
echo "📁 Creating cnap-dev namespace..."
kubectl create namespace cnap-dev --dry-run=client -o yaml | kubectl apply -f -

echo "✨ k3s setup complete!"
echo ""
echo "Next steps:"
echo "  1. Build the Docker image: ./scripts/build.sh"
echo "  2. Deploy to k3s: ./scripts/deploy.sh"
