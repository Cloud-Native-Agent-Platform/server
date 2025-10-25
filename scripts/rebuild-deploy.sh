#!/bin/bash
set -e

echo "🔄 Rebuilding and redeploying CNAP Server..."

# Build
./scripts/build.sh

# Force restart deployment
echo "🔄 Restarting deployment..."
kubectl rollout restart deployment/cnap-server -n cnap-dev

# Wait for rollout
kubectl rollout status deployment/cnap-server -n cnap-dev

echo "✅ Rebuild and redeploy complete!"
./scripts/deploy.sh local
