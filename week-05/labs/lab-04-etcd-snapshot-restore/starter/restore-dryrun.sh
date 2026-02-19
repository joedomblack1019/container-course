#!/usr/bin/env bash
# etcd Restore Dry Run - Fill in the blanks
#
# TASK: Validate cert paths from the etcd manifest before restore.
#
# Step 1: Inspect etcd command args
#   kubectl -n kube-system get pod <etcd-pod> -o yaml | grep -E '(--cert-file|--key-file|--trusted-ca-file|--listen-client)'
#
# Step 2: Map server flags to etcdctl flags
#   --trusted-ca-file -> --cacert
#   --cert-file       -> --cert
#   --key-file        -> --key
#
# Step 3: Fill in the placeholders to run snapshot status, then restore into an alternate data dir

set -euo pipefail

ETCD_POD="$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')"

# TODO: Replace ___ with cert paths discovered from etcd manifest
kubectl -n kube-system exec "$ETCD_POD" -- sh -c '
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=___ \
  --cert=___ \
  --key=___ \
  snapshot status /var/lib/etcd-backups/snapshot.db -w table
'

kubectl -n kube-system exec "$ETCD_POD" -- sh -c '
rm -rf /var/lib/etcd-restore-check
ETCDCTL_API=3 etcdctl snapshot restore /var/lib/etcd-backups/snapshot.db \
  --data-dir=/var/lib/etcd-restore-check
'
