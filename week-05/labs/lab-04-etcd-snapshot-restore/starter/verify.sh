#!/usr/bin/env bash
set -euo pipefail

ETCD_POD="$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')"

kubectl -n kube-system exec "$ETCD_POD" -- etcdutl snapshot status /var/lib/etcd-backups/snapshot.db -w table
kubectl -n kube-system exec "$ETCD_POD" -- ls -la /var/lib/etcd-restore-check | head -20
