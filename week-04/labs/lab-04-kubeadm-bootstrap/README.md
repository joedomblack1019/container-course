![Lab 04 kubeadm Bootstrap Foundations](../../../assets/generated/week-04-lab-04/hero.png)
![Lab 04 kubeadm init and node join workflow](../../../assets/generated/week-04-lab-04/flow.gif)

---

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

## Background: What kubeadm Does

`kubeadm` is a bootstrap tool, not the Kubernetes runtime itself. The binaries such as `kubelet`, `kube-apiserver`, `etcd`, `kube-controller-manager`, and `kube-scheduler` are already installed before you run this lab. `kubeadm init` wires those components into a functioning control plane by generating PKI assets, writing static pod manifests, creating kubeconfig files, creating bootstrap tokens for joins, and applying baseline RBAC so components can talk securely.

The control plane components come up as static pods, which is a special bootstrap path. `kubelet` watches `/etc/kubernetes/manifests/` directly on disk and launches whatever pod manifests are present there, even before an API server is reachable. That is how Kubernetes starts itself: kubelet starts the API server as a static pod, then the API server can serve the rest of the cluster objects. The closest AWS analogy is EC2 user data that runs at boot before the instance is registered with higher-level services.

PKI is central to every command in this lab. Kubernetes components authenticate and encrypt traffic with TLS, and kubeadm creates a cluster CA plus component certificates under `/etc/kubernetes/pki/`. When you later run `etcdctl`, flags like `--cacert`, `--cert`, and `--key` are mandatory because etcd uses mutual TLS and validates both client and server identity.

The `.conf` files kubeadm writes are kubeconfig files for different identities and components, including `/etc/kubernetes/admin.conf`, `/etc/kubernetes/controller-manager.conf`, and `/etc/kubernetes/scheduler.conf`. Each kubeconfig carries the API endpoint, CA trust, and client credentials for that actor. Your local `~/.kube/config` is usually a copy of `admin.conf`, which means full cluster-admin access; treat it like `~/.aws/credentials` with admin keys.

Preflight checks are guardrails against real failure modes, not ceremony. Swap, missing `br_netfilter`, disabled IP forwarding, or a dead container runtime can all produce partial startup symptoms that look random later, such as kubelet flapping, networking failures, or control-plane pods repeatedly restarting. Fixing these early is faster than debugging a half-initialized cluster.

After `kubeadm init`, you should expect static pod manifests in `/etc/kubernetes/manifests/`, certs in `/etc/kubernetes/pki/`, kubeconfigs in `/etc/kubernetes/`, and a printed join command containing token and discovery hash. The node often stays `NotReady` until a CNI is installed because pod networking is not configured yet; start troubleshooting with `kubectl get pods -n kube-system`, `journalctl -u kubelet`, and the files kubeadm generated. For deeper details, see the kubeadm implementation details page: https://kubernetes.io/docs/reference/setup-tools/kubeadm/implementation-details/.

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

> **Reference:** [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

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

The output looks like:

```
kubeadm join 192.168.1.10:6443 \
  --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:abc123...
```

Anatomy of each segment — you must be able to explain all three on the CKA exam:

| Segment | Meaning |
|---|---|
| `192.168.1.10:6443` | API server endpoint workers dial during join |
| `--token abcdef.0123456789abcdef` | Short-lived bootstrap token (format `<6chars>.<16chars>`). Default TTL is **24 hours**; after expiry the token is useless and a new one must be generated with `kubeadm token create --print-join-command`. List active tokens with `kubeadm token list`. |
| `--discovery-token-ca-cert-hash sha256:...` | SHA-256 hash of the cluster CA public key. The joining worker verifies this hash against the certificate the API server presents, preventing a man-in-the-middle from redirecting the join to a rogue cluster. |

To regenerate a join command after the original token expires (common in exam scenarios where you are adding a node late):

```bash
kubeadm token create --print-join-command
```

If you have a second VM, execute the printed command there as root and then validate on the control-plane:

```bash
kubectl get nodes
```

> **Reference:** [kubeadm join](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/) | [Bootstrap tokens](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/)

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
