#!/usr/bin/env bash
set -euo pipefail

svc="${1:?usage: endpoint-check.sh <service-name>}"

selector=$(kubectl get svc "$svc" -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)
endpoints=$(kubectl get endpoints "$svc" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)

echo "service: $svc"
echo "selector.app: ${selector:-<none>}"
echo "endpoints: ${endpoints:-<none>}"

kubectl get pods -l app="$selector" -o wide || true
