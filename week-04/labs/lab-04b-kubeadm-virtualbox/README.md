![Lab 04b kubeadm Full Lifecycle on VirtualBox](../../../assets/generated/week-04-lab-04b/hero.png)
![Lab 04b VirtualBox cluster workflow](../../../assets/generated/week-04-lab-04b/flow.gif)

---

# Lab 4b: kubeadm Full Lifecycle on VirtualBox

**Time:** 120 minutes (can be done as homework)
**Objective:** Experience the complete kubeadm cluster lifecycle on real virtual machines: init, join, CNI installation, upgrade, and reset.

---

## CKA Objectives Mapped

- Prepare underlying infrastructure for installing a Kubernetes cluster
- Create and manage Kubernetes clusters using kubeadm
- Implement and configure a highly-available control plane
- Understand extension interfaces (CNI, CSI, CRI, etc.)
- Perform cluster upgrades and maintenance

---

## Background: Full kubeadm Lifecycle on Real Nodes

This lab is the full version of kubeadm operations on real virtual machines, so it helps to separate installation from bootstrap. `kubeadm` does not provide the Kubernetes binaries; your scripts install `kubelet`, `kubeadm`, `kubectl`, and containerd first, then `kubeadm` assembles those pieces into a working cluster by generating PKI, writing kubeconfig files, producing static pod manifests, and creating bootstrap tokens and RBAC defaults.

Control-plane components come up as static pods from files in `/etc/kubernetes/manifests/`, which kubelet watches directly. That bootstrap path is why cluster creation works even before the API server is online: kubelet starts etcd and kube-apiserver from disk, the API becomes available, then the rest of cluster automation can operate. If these manifests are wrong, the control plane fails at startup regardless of what objects exist in the API.

Every join and etcd command in this lab depends on the PKI that kubeadm creates under `/etc/kubernetes/pki/`. Worker join uses a time-limited bootstrap token plus the CA hash to trust the control plane endpoint, and control-plane-to-control-plane trust uses issued certificates and optional uploaded cert bundles for additional masters. Treat `admin.conf` as a privileged credential file, because your local `~/.kube/config` is copied from it and has cluster-admin rights.

The `NotReady` period after `kubeadm init` is expected until a CNI is installed, because pod networking is not functional yet. Calico or Cilium supplies that missing network layer and brings nodes to `Ready`. In AWS terms, this is similar to launching instances and control software first, then attaching the network policy and routing system that allows workload traffic to flow correctly.

Upgrade flow in this lab follows kubeadm's strict sequencing rules: control plane first, workers second, one minor version at a time, and drain or uncordon around worker maintenance so workloads stay available. Version-skew policy is not advisory; kubelet may be only one minor behind API server, so skipping minors can leave the cluster unsupported or unstable.

If you remember one operational model for this lab, use this: preflight and binaries first, kubeadm bootstrap second, CNI readiness third, then controlled lifecycle actions like join, upgrade, and reset. That model explains why each section exists and where to investigate when something fails. For deeper mechanics, see kubeadm implementation details: https://kubernetes.io/docs/reference/setup-tools/kubeadm/implementation-details/.

---

## Prerequisites

**Local machine requirements:**
- VirtualBox 7.0+ installed
- Vagrant 2.3+ installed (recommended) OR manual VM creation skills
- 8GB+ available RAM (3 VMs × 2GB each + host overhead)
- 20GB+ available disk space

**Alternative for students without VirtualBox:**
- Use cloud VMs (AWS EC2 t3.medium instances)
- Use the existing kind-based lab-04 as a reduced alternative
- This lab can be skipped if infrastructure constraints prevent VM creation

Starter assets for this lab are in [`starter/`](./starter/):

- `Vagrantfile`
- `preflight-check.sh`
- `install-k8s-packages.sh`
- `verify-cluster.sh`
- `swap-cni.sh`

---

## Part 1: Infrastructure Preparation

**Option A: Using Vagrant (Recommended)**

```bash
cd starter/
vagrant up
```

This creates 3 Ubuntu 22.04 VMs:
- `control-plane` (192.168.56.10)
- `worker-1` (192.168.56.11)
- `worker-2` (192.168.56.12)

**Option B: Manual VirtualBox Setup**

Create 3 VMs manually with:
- OS: Ubuntu 22.04 LTS Server
- CPU: 2 cores each
- RAM: 2GB each
- Network: Host-only adapter (192.168.56.0/24)
- Storage: 20GB each

SSH into each VM and proceed to Part 2.

---

## Part 2: Node Preparation (Run on ALL nodes)

SSH into each VM and run the preflight preparation:

```bash
# On control-plane VM
vagrant ssh control-plane
sudo bash /vagrant/preflight-check.sh
sudo bash /vagrant/install-k8s-packages.sh

# On worker-1 VM (new terminal)
vagrant ssh worker-1
sudo bash /vagrant/preflight-check.sh
sudo bash /vagrant/install-k8s-packages.sh

# On worker-2 VM (new terminal)
vagrant ssh worker-2
sudo bash /vagrant/preflight-check.sh
sudo bash /vagrant/install-k8s-packages.sh
```

The scripts handle:
- Disable swap
- Load kernel modules (overlay, br_netfilter)
- Configure sysctl (net.bridge.bridge-nf-call-iptables)
- Install containerd as the CRI
- Install kubeadm, kubelet, kubectl

---

## Part 3: Control Plane Initialization

On the `control-plane` node:

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=192.168.56.10 \
  --apiserver-advertise-address=192.168.56.10

# Configure kubectl for the vagrant user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Important:** Save the `kubeadm join` command output! It looks like:
```
kubeadm join 192.168.56.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Verify control plane components:

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

Expected: Control plane node is `NotReady` because no CNI is installed yet.

---

## Part 4: CNI Installation and Comparison

**First, install Calico:**

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Wait for Calico pods
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=calico-node -n kube-system --timeout=300s

# Verify node becomes Ready
kubectl get nodes
```

**Explore what Calico created:**

```bash
# CRDs created by Calico
kubectl get crd | grep calico

# Calico system pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=calico-node
kubectl get daemonset -n kube-system calico-node

# NetworkPolicy support test
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-policy
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
EOF

kubectl get networkpolicy
kubectl delete networkpolicy test-policy
```

**Now swap to Cilium (optional demonstration):**

```bash
# Remove Calico
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Install Cilium
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
cilium install

# Verify Cilium
cilium status
kubectl get crd | grep cilium
```

For this lab, you can choose either CNI. Calico is simpler to install.

---

## Part 5: Worker Node Join

On `worker-1` and `worker-2`, run the join command from Part 3:

```bash
# On worker-1
sudo kubeadm join 192.168.56.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# On worker-2
sudo kubeadm join 192.168.56.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

If the token expired (after 24 hours), generate a new one on the control plane:

```bash
# On control-plane
kubeadm token create --print-join-command
```

---

## Part 6: Cluster Verification

Back on the control plane, verify the complete cluster:

```bash
kubectl get nodes -o wide
kubectl get pods -A

# Run the verification script
bash /vagrant/verify-cluster.sh
```

Deploy a test workload across nodes:

```bash
kubectl create deployment nginx-test --image=nginx:1.20 --replicas=3
kubectl scale deployment nginx-test --replicas=3
kubectl get pods -o wide

# Verify cross-node networking
kubectl run network-test --image=busybox:1.36 --rm -it --restart=Never -- \
  nslookup kubernetes.default.svc.cluster.local
```

---

## Part 7: Cluster Upgrade (v1.31 → v1.32)

**Upgrade the control plane first:**

```bash
# On control-plane
sudo apt update
sudo apt-cache madison kubeadm | grep 1.32

# Install new kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm='1.32.0-*'
sudo apt-mark hold kubeadm

# Plan the upgrade
sudo kubeadm upgrade plan

# Apply the upgrade
sudo kubeadm upgrade apply v1.32.0

# Upgrade kubelet and kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet='1.32.0-*' kubectl='1.32.0-*'
sudo apt-mark hold kubelet kubectl

# Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

kubectl get nodes
```

**Upgrade worker nodes:**

```bash
# On worker-1
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm='1.32.0-*'
sudo apt-mark hold kubeadm

sudo kubeadm upgrade node

sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet='1.32.0-*' kubectl='1.32.0-*'
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

**On control plane, drain and uncordon each worker:**

```bash
kubectl drain worker-1 --ignore-daemonsets --force
# Wait for worker-1 upgrade to complete
kubectl uncordon worker-1

kubectl drain worker-2 --ignore-daemonsets --force
# Wait for worker-2 upgrade to complete
kubectl uncordon worker-2

kubectl get nodes
```

---

## Part 8: HA Control Plane (Optional - requires 4th VM)

If you have resources for a 4th VM, demonstrate multi-master setup:

```bash
# On control-plane during init, add:
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=192.168.56.10 \
  --upload-certs

# Join second control plane with --control-plane flag
sudo kubeadm join 192.168.56.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <cert-key>
```

Inspect etcd quorum and API server availability.

---

## Part 9: Cluster Reset and Cleanup

**Reset all nodes:**

```bash
# On each node
sudo kubeadm reset --force
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/etcd/

# Remove CNI config (if it persists)
sudo rm -rf /etc/cni/net.d/
sudo rm -rf /opt/cni/bin/

# Reset iptables (optional)
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

**Destroy VMs:**

```bash
# Exit all SSH sessions first
vagrant destroy -f
```

---

## Part 10: Extension Interface Inspection

During the lab, explicitly identify:

**CRI (Container Runtime Interface):**
- containerd socket: `/var/run/containerd/containerd.sock`
- kubelet CRI config: `/var/lib/kubelet/config.yaml`

**CNI (Container Network Interface):**
- CNI config: `/etc/cni/net.d/`
- CNI binaries: `/opt/cni/bin/`
- What happens when CNI is missing (Part 3 - node stays NotReady)

**CSI (Container Storage Interface):**
- No external CSI in this minimal setup
- Local storage only
- Understand where cloud CSI drivers would plug in

---

## Validation Checklist

You are done when:

- You've successfully initialized a control plane with kubeadm
- You've joined 2 worker nodes to form a 3-node cluster
- You've installed and compared at least 2 CNI plugins
- You've performed a cluster upgrade across all nodes
- You've understood the role of CRI, CNI, and CSI interfaces
- You've reset and cleaned up all cluster state

---

## Troubleshooting Common Issues

**"kubeadm init" fails with preflight checks:**
- Ensure swap is disabled: `sudo swapoff -a`
- Check required ports: `sudo ss -tlnp | grep :6443`

**Node stays "NotReady":**
- CNI not installed: Install Calico or Cilium
- Check kubelet logs: `sudo journalctl -u kubelet -f`

**"kubeadm join" fails:**
- Token expired: Generate new token on control plane
- Network connectivity: `ping 192.168.56.10` from worker

**Upgrade fails:**
- Version skew: Can only upgrade one minor version at a time
- Pods not draining: Check for PodDisruptionBudgets

---

## Reinforcement Connection

This lab connects to these gym scenarios:
- `jerry-kubeconfig-context-confusion`
- `jerry-node-notready-kubelet`
- `jerry-static-pod-misconfigured`

And these other labs:
- `lab-04-kubeadm-bootstrap` (kind-based quick version)
- `lab-07-extension-interfaces` (CRI/CNI/CSI discovery)
