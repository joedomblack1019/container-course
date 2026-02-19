#!/usr/bin/env bash
set -euo pipefail

kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab
kubectl auth can-i get pods/log --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab
kubectl auth can-i list nodes --as=system:serviceaccount:rbac-lab:auditor
