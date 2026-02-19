#!/usr/bin/env bash
set -euo pipefail

backup="/tmp/coredns-backup.yaml"
[ -f "$backup" ] || { echo "backup file not found: $backup"; exit 1; }

kubectl apply -f "$backup"
kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kube-system rollout status deployment/coredns --timeout=120s

echo "Restored CoreDNS config from $backup"
