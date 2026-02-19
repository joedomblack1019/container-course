# Lab 4: kubeadm Bootstrap Foundations

**Time:** 75 minutes  
**Objective:** Bootstrap a disposable kubeadm control plane, inspect core admin artifacts, and practice safe reset/join workflows.

---

## CKA Objectives Mapped

- Prepare infrastructure for cluster install
- Create and manage clusters with kubeadm
- Understand control-plane components and static pod manifests
- Troubleshoot bootstrap and node-join failures

---

## Lab Safety and Scope

This lab is for a **disposable environment only**. Do not run these commands on a shared class cluster or production system.

- Recommended substrate: dedicated VM with `sudo` and systemd
- Not recommended: your Week 4 shared Talos environment
- Optional: run with an instructor-provided kubeadm sandbox VM image

---

## Prerequisites

Before you begin, confirm:

```bash
kubectl version --client
kubeadm version
kubelet --version
crictl --version || echo "crictl optional but recommended"
```

You also need:

- Container runtime running (`containerd` or CRI-O)
- Swap disabled (`swapon --show` should be empty)
- Required kernel/network settings enabled

Starter assets for this lab are in [`starter/`](./starter/):

- `preflight.sh`
- `bootstrap.sh`
- `reset.sh`

---

## Part 1: Preflight Checks

Run kubeadm preflight checks and inspect the output.

```bash
sudo kubeadm init phase preflight
```

If checks fail, fix root causes instead of skipping:

```bash
sudo systemctl status kubelet --no-pager
sudo systemctl status containerd --no-pager
swapon --show
lsmod | grep br_netfilter || true
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward
```

Minimal baseline (if missing):

```bash
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

---

## Part 2: Initialize a Single Control Plane

Choose a pod CIDR and bootstrap:

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs
```

Configure kubectl for your user:

```bash
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
```

Confirm API access:

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

---

## Part 3: Install CNI and Verify Node Readiness

Without CNI, node status usually stays `NotReady`.

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl get nodes -w
```

Expected end state:

- control-plane node reports `Ready`
- CoreDNS and CNI pods become `Running`

---

## Part 4: Inspect Admin Artifacts (CKA-Focused)

Identify where kubeadm wrote critical files:

```bash
sudo ls -1 /etc/kubernetes/
sudo ls -1 /etc/kubernetes/manifests
sudo ls -1 /etc/kubernetes/pki | head -20
```

Interpret what you see:

- `/etc/kubernetes/manifests`: static pod definitions (API server, etcd, scheduler, controller-manager)
- `/etc/kubernetes/*.conf`: kubeconfig files for admin and components
- `/etc/kubernetes/pki`: cluster certificates and keys

Check control-plane static pods:

```bash
kubectl get pods -n kube-system -o wide
```

---

## Part 5: Join Workflow (Concept + Command Capture)

Generate a join command you would run on a worker node:

```bash
kubeadm token create --print-join-command
```

Capture and explain each segment:

- API endpoint
- token
- discovery hash

If you have a second VM, execute the command there and validate:

```bash
kubectl get nodes
```

---

## Part 6: Failure Checkpoint

Common issue: wrong context after setup. Confirm current context and kubeconfig.

```bash
kubectl config current-context
kubectl cluster-info
```

Common issue: kubelet not healthy:

```bash
sudo journalctl -u kubelet -n 80 --no-pager
kubectl describe node "$(kubectl get nodes -o name | head -1 | cut -d/ -f2)"
```

Write down:

1. Symptom observed
2. Command that proved the issue
3. Fix applied

---

## Part 7: Reset and Rebuild (Safe Practice)

Practice teardown so you can recover quickly during exam-style work:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
rm -rf "$HOME/.kube/config"
```

Optional cleanup:

```bash
sudo systemctl restart containerd kubelet
```

Then repeat Part 2 and verify you can bootstrap again without notes.

---

## Validation Checklist

You are done when all are true:

- `kubeadm init` completed successfully
- Node reached `Ready` after CNI install
- You located static manifests and cert paths
- You generated and explained a valid join command
- You executed a full `kubeadm reset` and understood rebuild steps

---

## Mapping to Reinforcement Scenarios

- `jerry-rbac-denied` (authorization checks in the next lab)
- `jerry-node-notready-kubelet` (node recovery under pressure)
