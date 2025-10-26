#!/bin/bash

PORT="${1:-8080}"

echo "🌐 Port forwarding CNAP Server to localhost:$PORT..."
echo "Press Ctrl+C to stop"
echo ""
kubectl port-forward -n cnap-dev svc/cnap-server "$PORT:8080"
