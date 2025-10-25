#!/bin/bash
set -e

OVERLAY="${1:-local}"

echo "🚀 Deploying CNAP Server to k3s..."
echo "Using overlay: $OVERLAY"

# Apply kustomization
kubectl apply -k "k8s/overlays/$OVERLAY"

echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s \
  deployment/cnap-server -n cnap-dev

echo "✅ Deployment complete!"
echo ""
echo "📊 Deployment status:"
kubectl get pods -n cnap-dev -l app.kubernetes.io/name=cnap-server

echo ""
echo "🔍 To view logs:"
echo "  kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server -f"
echo ""
echo "🌐 To access the service:"
echo "  kubectl port-forward -n cnap-dev svc/cnap-server 8080:8080"
echo "  Then visit: http://localhost:8080/healthz"
