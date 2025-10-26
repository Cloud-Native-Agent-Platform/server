#!/bin/bash
set -e

# Detect OS and set registry port accordingly
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    # macOS uses port 5001 (5000 is used by AirPlay)
    REGISTRY_PORT="${REGISTRY_PORT:-5001}"
else
    # Linux uses port 5000
    REGISTRY_PORT="${REGISTRY_PORT:-5000}"
fi

IMAGE_NAME="${IMAGE_NAME:-localhost:$REGISTRY_PORT/cnap-server}"
IMAGE_TAG="${IMAGE_TAG:-dev}"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "🏗️  Building CNAP Server..."
echo "Image: $FULL_IMAGE"

# Check if gradle wrapper jar exists
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "📦 Gradle wrapper not found, initializing..."
    ./scripts/init-gradle-wrapper.sh
fi

# Build with Gradle first (optional, Docker will rebuild anyway)
echo "🔨 Running Gradle build..."
./gradlew build -x test --no-daemon || echo "⚠️  Gradle build failed, continuing with Docker build..."

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t "$FULL_IMAGE" .

# Push to local registry
echo "📤 Pushing to local registry..."
docker push "$FULL_IMAGE"

echo "✅ Build complete: $FULL_IMAGE"
echo ""
echo "To deploy to k3s, run: ./scripts/deploy.sh"
