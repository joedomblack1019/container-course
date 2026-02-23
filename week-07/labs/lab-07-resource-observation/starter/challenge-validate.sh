#!/usr/bin/env bash
# validate.sh — checks student answers for the kubectl top challenge
# Usage: bash challenge-validate.sh <answers-file>
set -euo pipefail

ANSWERS="${1:-challenge-answers.txt}"

if [[ ! -f "$ANSWERS" ]]; then
  echo "Usage: $0 <answers-file>"
  echo ""
  echo "Create challenge-answers.txt with one answer per line:"
  echo "  Q1: <pod-name>"
  echo "  Q2: <pod-name>"
  echo "  Q3: <yes|no>"
  echo "  Q4: <number>m"
  exit 1
fi

pass=0
fail=0

check() {
  local q="$1"
  local expected="$2"
  local actual
  actual=$(grep -i "^${q}:" "$ANSWERS" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $q"
    ((pass++))
  else
    echo "  FAIL  $q  (got: '$actual', expected: '$expected')"
    ((fail++))
  fi
}

echo ""
echo "=== kubectl top Challenge Validation ==="
echo ""

# Q1: highest CPU pod — cpu-burner pods top the list
# Accept any pod whose name starts with cpu-burner
actual_q1=$(grep -i "^Q1:" "$ANSWERS" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if echo "$actual_q1" | grep -q "^cpu-burner"; then
  echo "  PASS  Q1"
  ((pass++))
else
  echo "  FAIL  Q1  (got: '$actual_q1', expected: a pod starting with 'cpu-burner')"
  ((fail++))
fi

# Q2: highest memory pod — memory-hog
actual_q2=$(grep -i "^Q2:" "$ANSWERS" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if echo "$actual_q2" | grep -q "^memory-hog"; then
  echo "  PASS  Q2"
  ((pass++))
else
  echo "  FAIL  Q2  (got: '$actual_q2', expected: a pod starting with 'memory-hog')"
  ((fail++))
fi

# Q3: are any nodes above 80% CPU? In a small kind cluster with cpu-burner running, likely yes
actual_q3=$(grep -i "^Q3:" "$ANSWERS" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [[ "$actual_q3" == "yes" || "$actual_q3" == "no" ]]; then
  echo "  PASS  Q3  (any clear answer is accepted — the point is reading the % column)"
  ((pass++))
else
  echo "  FAIL  Q3  (got: '$actual_q3', expected: 'yes' or 'no')"
  ((fail++))
fi

# Q4: cpu-burner request is 250m — check they know to use kubectl describe
actual_q4=$(grep -i "^Q4:" "$ANSWERS" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [[ "$actual_q4" == "250m" ]]; then
  echo "  PASS  Q4"
  ((pass++))
else
  echo "  FAIL  Q4  (got: '$actual_q4', expected: '250m')"
  ((fail++))
fi

echo ""
echo "Result: $pass/4 correct"
echo ""

if [[ $fail -eq 0 ]]; then
  echo "All checks passed."
else
  echo "Review the kubectl top output and retry."
  echo "Hint for Q1/Q2: kubectl top pods -n resource-lab --sort-by=cpu"
  echo "Hint for Q4:    kubectl describe pod -n resource-lab -l app=cpu-burner | grep -A2 Requests"
fi
