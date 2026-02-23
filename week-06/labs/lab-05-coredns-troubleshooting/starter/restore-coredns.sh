#!/usr/bin/env bash
set -euo pipefail

backup="/tmp/coredns-backup.yaml"
[ -f "$backup" ] || { echo "backup file not found: $backup"; exit 1; }

corefile=$(awk '
  /^  Corefile:[[:space:]]*\|/ { in_block=1; next }
  in_block {
    if ($0 !~ /^    /) exit
    sub(/^    /, "")
    print
  }
' "$backup")

[ -n "$corefile" ] || { echo "could not parse Corefile from: $backup"; exit 1; }

tmp_manifest=$(mktemp)
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
} > "$tmp_manifest"

kubectl apply -f "$tmp_manifest"
rm -f "$tmp_manifest"

kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kube-system rollout status deployment/coredns --timeout=120s

echo "Restored CoreDNS config from $backup"
