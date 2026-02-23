#!/bin/bash
set -euo pipefail

ANSWERS_FILE="${1:-./jsonpath-check.txt}"

if [ ! -f "$ANSWERS_FILE" ]; then
  echo "Answers file not found: $ANSWERS_FILE"
  echo "Usage: bash starter/validate-jsonpath-check.sh ./jsonpath-check.txt"
  exit 1
fi

get_value() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" "$ANSWERS_FILE" || true)"
  echo "${line#*=}" | tr -d '[:space:]'
}

expected_control_plane="$(kubectl get nodes --sort-by=.metadata.name -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/control-plane=="")].metadata.name}')"
expected_first_pod="$(kubectl -n ops-lab get pods --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[0].metadata.name}')"
expected_first_pod_node="$(kubectl -n ops-lab get pods --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[0].spec.nodeName}')"
total_nodes="$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | wc -w | tr -d '[:space:]')"
control_plane_nodes="$(echo "$expected_control_plane" | wc -w | tr -d '[:space:]')"
expected_worker_count="$((total_nodes - control_plane_nodes))"

actual_control_plane="$(get_value CONTROL_PLANE_NODE)"
actual_first_pod="$(get_value FIRST_OPS_POD_BY_CREATION)"
actual_first_pod_node="$(get_value FIRST_OPS_POD_NODE)"
actual_worker_count="$(get_value WORKER_COUNT)"

score=0
total=4

check() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS  $label"
    score=$((score + 1))
  else
    echo "FAIL  $label"
    echo "      expected: $expected"
    echo "      actual:   $actual"
  fi
}

check "CONTROL_PLANE_NODE" "$expected_control_plane" "$actual_control_plane"
check "FIRST_OPS_POD_BY_CREATION" "$expected_first_pod" "$actual_first_pod"
check "FIRST_OPS_POD_NODE" "$expected_first_pod_node" "$actual_first_pod_node"
check "WORKER_COUNT" "$expected_worker_count" "$actual_worker_count"

echo ""
echo "Score: ${score}/${total}"

if [ "$score" -lt 4 ]; then
  echo "Result: not yet passing. Re-run your jsonpath/sort-by commands and try again."
  exit 1
fi

echo "Result: pass."
