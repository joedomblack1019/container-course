#!/usr/bin/env bash
# etcd Restore Dry Run
#
# etcd 3.6+: snapshot status and snapshot restore use `etcdutl` (offline tool).
# No TLS certs or --endpoints needed — these commands read/write files directly.
#
# Step 1: Inspect etcd command args (still needed for snapshot save)
#   kubectl -n kube-system get pod <etcd-pod> -o yaml | grep -E '(--cert-file|--key-file|--trusted-ca-file|--listen-client)'
#
# Step 2: Run snapshot status to validate the file, then restore to an alternate data dir

set -euo pipefail

ETCD_POD="$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')"

# snapshot status is an offline operation — no certs or endpoints needed
kubectl -n kube-system exec "$ETCD_POD" -- etcdutl \
  snapshot status /var/lib/etcd-backups/snapshot.db -w table

kubectl -n kube-system exec "$ETCD_POD" -- sh -c '
rm -rf /var/lib/etcd-restore-check
etcdutl snapshot restore /var/lib/etcd-backups/snapshot.db \
  --data-dir=/var/lib/etcd-restore-check
'
