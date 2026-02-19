#!/bin/bash
set -e

echo "=== CNI Plugin Swap Utility ==="

show_usage() {
    echo "Usage: $0 [calico|cilium|remove-current]"
    echo ""
    echo "Examples:"
    echo "  $0 calico    # Install Calico CNI"
    echo "  $0 cilium    # Install Cilium CNI"
    echo "  $0 remove-current # Remove current CNI (nodes will go NotReady)"
    exit 1
}

install_calico() {
    echo "Installing Calico CNI..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

    echo "Waiting for Calico pods to be ready..."
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=calico-node -n kube-system --timeout=300s

    echo "Calico installation completed!"
    kubectl get pods -n kube-system | grep calico
}

install_cilium() {
    echo "Installing Cilium CNI..."

    # Download cilium CLI if not present
    if ! command -v cilium &> /dev/null; then
        echo "Downloading Cilium CLI..."
        curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
        sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
        rm cilium-linux-amd64.tar.gz
    fi

    cilium install

    echo "Waiting for Cilium to be ready..."
    cilium status --wait

    echo "Cilium installation completed!"
    kubectl get pods -n kube-system | grep cilium
}

remove_current() {
    echo "Removing current CNI..."

    # Try to remove Calico
    if kubectl get pods -n kube-system | grep -q calico; then
        echo "Removing Calico..."
        kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml 2>/dev/null || true
    fi

    # Try to remove Cilium
    if command -v cilium &> /dev/null && cilium status &>/dev/null; then
        echo "Removing Cilium..."
        cilium uninstall
    fi

    echo "CNI removed. Nodes will go NotReady until new CNI is installed."
}

case "$1" in
    calico)
        install_calico
        ;;
    cilium)
        install_cilium
        ;;
    remove-current)
        remove_current
        ;;
    *)
        show_usage
        ;;
esac

echo ""
echo "Current node status:"
kubectl get nodes