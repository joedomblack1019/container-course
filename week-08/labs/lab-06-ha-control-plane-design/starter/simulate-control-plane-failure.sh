#!/usr/bin/env bash
set -euo pipefail

FAILED_NODE="${1:-ha-control-plane2}"
docker stop "$FAILED_NODE"
kubectl get nodes
kubectl get pods -n kube-system | grep -E 'etcd|kube-apiserver|kube-controller-manager|kube-scheduler'
