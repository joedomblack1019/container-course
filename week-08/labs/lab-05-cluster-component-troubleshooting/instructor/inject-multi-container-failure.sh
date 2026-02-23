#!/bin/bash
set -e

echo "Injecting multi-container pod failure..."

# Deploy the multi-container app (init container will fail due to missing service)
kubectl apply -f starter/multi-container-pod.yaml

echo "Multi-container pod deployed. Pod should show Init:CrashLoopBackOff due to missing config-service."