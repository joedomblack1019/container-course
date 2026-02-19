#!/usr/bin/env bash
set -euo pipefail

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

kubectl get nodes -o wide
kubectl get pods -n kube-system
