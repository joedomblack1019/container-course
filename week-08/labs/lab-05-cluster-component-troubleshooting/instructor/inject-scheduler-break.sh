#!/bin/bash
set -e

echo "Injecting kube-scheduler failure..."

# Get control plane node name
NODE=$(kubectl get nodes -o name | grep control-plane | head -1 | cut -d/ -f2)

# Backup current scheduler manifest
docker exec "$NODE" cp /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/kube-scheduler-backup.yaml

# Inject bad flag into scheduler manifest
docker exec "$NODE" sed -i 's/--bind-address=127.0.0.1/--bind-address=999.999.999.999/' /etc/kubernetes/manifests/kube-scheduler.yaml

echo "Scheduler failure injected. New pods should now stuck Pending."
echo "Control plane node: $NODE"