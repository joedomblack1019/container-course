#!/usr/bin/env bash
set -euo pipefail

sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
rm -rf "$HOME/.kube/config"
sudo systemctl restart containerd kubelet || true
