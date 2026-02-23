#!/bin/bash
set -e

echo "Setting up node labels for scheduling lab..."

# Wait for nodes to be ready
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Label nodes with different environments
kubectl label nodes scheduling-worker environment=production --overwrite
kubectl label nodes scheduling-worker2 environment=staging --overwrite
kubectl label nodes scheduling-worker3 environment=development --overwrite

# Add tier labels
kubectl label nodes scheduling-worker tier=frontend --overwrite
kubectl label nodes scheduling-worker2 tier=backend --overwrite
kubectl label nodes scheduling-worker3 tier=database --overwrite

# Add zone labels for topology spreading
kubectl label nodes scheduling-worker topology.kubernetes.io/zone=zone-a --overwrite
kubectl label nodes scheduling-worker2 topology.kubernetes.io/zone=zone-b --overwrite
kubectl label nodes scheduling-worker3 topology.kubernetes.io/zone=zone-c --overwrite

# Pre-taint a node so taints/tolerations are visible from the start
kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule --overwrite

echo "Node labels configured:"
kubectl get nodes --show-labels | grep -E "(NAME|scheduling-)"
echo
echo "Current taints:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
