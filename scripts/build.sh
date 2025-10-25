#!/bin/bash
set -e

IMAGE_NAME="${IMAGE_NAME:-localhost:5000/cnap-server}"
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
