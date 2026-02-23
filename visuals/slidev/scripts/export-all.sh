#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

decks=(
  win95-showcase
  week-01-overview
  week-01-lab-01
  week-01-lab-02
  week-01-lab-03
  week-01-lab-04
  week-02-overview
  week-02-lab-01
  week-02-lab-02
  week-02-lab-03
  week-03-overview
  week-03-lab-01
  week-03-lab-02
  week-03-lab-03
  week-04-overview
  week-04-lab-01
  week-04-lab-02
  week-04-lab-03
  week-04-lab-04
  week-04-lab-04b
  week-04-lab-05
  week-04-lab-06
  week-04-lab-07
  week-04-lab-08
  week-04-rbac-authz
  week-04-pod-security-admission
  week-05-overview
  week-05-lab-01
  week-05-lab-02
  week-05-lab-03
  week-05-lab-04
  week-05-lab-05
  week-06-overview
  week-06-lab-01
  week-06-lab-02
  week-06-lab-03
  week-06-lab-04
  week-06-lab-05
  week-06-lab-06
  week-07-overview
  week-07-lab-01
  week-07-lab-02
  week-07-lab-03
  week-07-lab-04
  week-07-lab-05
  week-07-lab-06
  week-07-lab-07
  week-07-lab-08
  week-08-overview
  week-08-lab-01
  week-08-lab-02
  week-08-lab-03
  week-08-lab-04
  week-08-lab-05
  week-08-lab-06
  week-08-gitops-loop
)

for deck in "${decks[@]}"; do
  echo "==> Exporting ${deck}"
  "${SCRIPT_DIR}/export-deck.sh" "${deck}"
done

echo "All decks exported."
