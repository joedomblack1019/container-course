#!/bin/bash
set -e

echo "Installing metrics-server for resource monitoring..."

# Install metrics-server for kind
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for metrics-server
kubectl rollout status deployment/metrics-server -n kube-system --timeout=60s

echo "Deploying resource hog..."

# Deploy resource hog first
kubectl apply -f starter/resource-hog.yaml

# Wait a moment for hog to consume resources
sleep 10

echo "Resource hog deployed. Some victim-app replicas should be Pending due to resource exhaustion."