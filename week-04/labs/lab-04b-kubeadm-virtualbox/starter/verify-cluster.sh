#!/bin/bash
set -e

echo "=== Kubernetes Cluster Verification ==="

echo "1. Checking node status..."
kubectl get nodes -o wide

echo ""
echo "2. Checking system pods..."
kubectl get pods -n kube-system

echo ""
echo "3. Checking cluster info..."
kubectl cluster-info

echo ""
echo "4. Checking CNI installation..."
kubectl get pods -n kube-system | grep -E "(calico|cilium|flannel|kindnet)" || echo "No CNI pods found"

echo ""
echo "5. Testing pod deployment..."
kubectl run verify-pod --image=nginx:1.20 --restart=Never --rm -i --timeout=60s -- echo "Cluster is working!"

echo ""
echo "6. Checking component status..."
kubectl get componentstatuses 2>/dev/null || echo "componentstatuses deprecated in newer versions"

echo ""
echo "7. Testing DNS resolution..."
kubectl run dns-test --image=busybox:1.36 --restart=Never --rm -i --timeout=30s -- nslookup kubernetes.default.svc.cluster.local

echo ""
echo "8. Node resource status..."
kubectl top nodes 2>/dev/null || echo "Metrics server not installed - this is normal"

echo ""
echo "=== Cluster verification completed successfully ==="