#!/usr/bin/env bash
set -euo pipefail

WORKER="${1:-$(kubectl get nodes -o name | grep worker | head -1 | cut -d/ -f2)}"

echo "Target worker: $WORKER"
kubectl cordon "$WORKER"
kubectl drain "$WORKER" --ignore-daemonsets --delete-emptydir-data --timeout=60s || true
kubectl get nodes
