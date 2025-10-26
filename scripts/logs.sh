#!/bin/bash

echo "📋 Tailing CNAP Server logs..."
kubectl logs -n cnap-dev -l app.kubernetes.io/name=cnap-server -f --tail=100
