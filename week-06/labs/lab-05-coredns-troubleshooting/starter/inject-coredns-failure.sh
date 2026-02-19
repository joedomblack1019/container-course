#!/usr/bin/env bash
set -euo pipefail

backup="/tmp/coredns-backup.yaml"
kubectl -n kube-system get configmap coredns -o yaml > "$backup"

kubectl -n kube-system get configmap coredns -o yaml \
  | sed 's#/etc/resolv.conf#127.0.0.1#' \
  | kubectl apply -f -

kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kube-system rollout status deployment/coredns --timeout=120s

echo "Injected CoreDNS fault. Backup saved at $backup"
