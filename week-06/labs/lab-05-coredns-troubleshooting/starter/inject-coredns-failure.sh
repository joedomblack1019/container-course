#!/usr/bin/env bash
set -euo pipefail

backup="/tmp/coredns-backup.yaml"
corefile=$(kubectl -n kube-system get configmap coredns -o go-template='{{index .data "Corefile"}}')

{
  cat <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
EOF
  printf '%s\n' "$corefile" | sed 's/^/    /'
} > "$backup"

kubectl -n kube-system get configmap coredns -o yaml \
  | sed 's#/etc/resolv.conf#127.0.0.1#' \
  | kubectl apply -f -

kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kube-system rollout status deployment/coredns --timeout=120s

echo "Injected CoreDNS fault. Backup saved at $backup"
