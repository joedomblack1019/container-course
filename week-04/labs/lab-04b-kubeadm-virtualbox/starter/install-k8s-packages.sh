#!/bin/bash
set -e

echo "=== Installing Kubernetes Packages ==="

K8S_VERSION="1.31"

# Add Kubernetes apt repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Update package lists
apt-get update

# Install kubelet, kubeadm, kubectl
apt-get install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service
systemctl enable kubelet

echo "=== Package installation completed ==="
echo "Installed versions:"
kubeadm version --output=short
kubelet --version
kubectl version --client --output=yaml

echo ""
echo "=== Ready for kubeadm init/join ==="