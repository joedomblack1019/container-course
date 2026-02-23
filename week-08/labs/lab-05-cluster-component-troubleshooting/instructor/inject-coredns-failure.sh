#!/bin/bash
set -e

echo "Injecting CoreDNS failure..."

# Backup current config
kubectl -n kube-system get configmap coredns -o yaml > /tmp/coredns-backup.yaml

# Inject bad forwarding configuration
kubectl -n kube-system patch configmap coredns --type merge -p '{"data":{"Corefile":".:53 {\n    errors\n    health\n    ready\n    forward . 127.0.0.1\n    cache 30\n    loop\n    reload\n    loadbalance\n}\n"}}'

# Restart CoreDNS to apply bad config
kubectl -n kube-system rollout restart deployment/coredns

echo "CoreDNS failure injected. DNS resolution should now fail."