#!/usr/bin/env bash
set -euo pipefail

kubectl -n storage-lab get pvc
kubectl get pv
kubectl -n storage-lab get events --sort-by=.metadata.creationTimestamp | tail -30
