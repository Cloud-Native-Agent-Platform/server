#!/bin/bash

echo "🧹 Cleaning up CNAP Server deployment..."

kubectl delete -k k8s/overlays/local || true

echo "✅ Cleanup complete!"
echo ""
echo "To completely remove k3s:"
echo "  /usr/local/bin/k3s-uninstall.sh"
