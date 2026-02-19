#!/usr/bin/env bash
# etcd Snapshot - Fill in the blanks
#
# TASK: Find the correct cert paths by examining the etcd pod manifest.
#
# Step 1: Get the etcd pod manifest to find cert paths
#   kubectl -n kube-system get pod <etcd-pod> -o yaml | grep -A20 'command:'
#
# Step 2: Look for these flags in the etcd command:
#   --cert-file        -> use as --cert
#   --key-file         -> use as --key
#   --trusted-ca-file  -> use as --cacert
#
# Step 3: Fill in the blanks below and run this script

set -euo pipefail

ETCD_POD="$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')"

kubectl -n kube-system exec "$ETCD_POD" -- mkdir -p /var/lib/etcd-backups

# TODO: Replace the ___ placeholders with the correct paths from the etcd manifest
kubectl -n kube-system exec "$ETCD_POD" -- sh -c '
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=___ \
  --cert=___ \
  --key=___ \
  snapshot save /var/lib/etcd-backups/snapshot.db
'
