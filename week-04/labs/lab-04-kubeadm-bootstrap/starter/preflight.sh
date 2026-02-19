#!/usr/bin/env bash
set -euo pipefail

sudo kubeadm init phase preflight
swapon --show || true
sudo systemctl status containerd --no-pager || true
sudo systemctl status kubelet --no-pager || true
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward || true
