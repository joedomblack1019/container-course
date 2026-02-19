# Lab 7: Extension Interfaces Deep Dive

**Time:** 35 minutes
**Objective:** Explore and understand the CRI, CNI, and CSI extension interfaces that enable Kubernetes to work with different container runtimes, networks, and storage systems.

---

## CKA Objectives Mapped

- Understand extension interfaces (CNI, CSI, CRI, etc.)
- Troubleshoot cluster components and extension failures
- Inspect and understand cluster architecture

---

## Prerequisites

Use your local kind cluster:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Starter assets for this lab are in [`starter/`](./starter/):

- `extension-worksheet.md`

---

## Part 1: Container Runtime Interface (CRI) Discovery

The CRI enables Kubernetes to work with different container runtimes (containerd, CRI-O, Docker).

Identify your cluster's container runtime:

```bash
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
echo
kubectl get nodes -o wide
```

Inspect CRI details on a kind node:

```bash
# Get into the kind node container
docker exec -it kind-lab-control-plane bash

# Inside the node, check CRI socket
ls -la /run/containerd/containerd.sock
ps aux | grep containerd

# Check crictl configuration
crictl info | head -20
exit
```

Key observations:
- containerd is the CRI implementation
- Socket path: `/run/containerd/containerd.sock`
- kubelet communicates with containerd via this socket
- crictl is the CLI tool for CRI debugging

---

## Part 2: Container Network Interface (CNI) Discovery

CNI plugins handle pod networking. Kind uses kindnet (a simple CNI) by default.

Inspect CNI configuration on a node:

```bash
# Get into the kind node
docker exec -it kind-lab-control-plane bash

# CNI configuration directory
ls -la /etc/cni/net.d/
cat /etc/cni/net.d/10-kindnet.conflist

# CNI binaries location
ls -la /opt/cni/bin/
exit
```

Find CNI-related pods:

```bash
kubectl get pods -n kube-system | grep -E "(kindnet|flannel|calico|cilium)"
kubectl describe pod -n kube-system -l app=kindnet
```

Compare CNI options (documentation exploration):

**Kindnet** (what kind uses):
- Simple overlay network
- No NetworkPolicy support
- Minimal feature set

**Calico**:
- NetworkPolicy support
- BGP routing capability
- Creates CRDs: `kubectl get crd | grep calico`

**Cilium**:
- eBPF-based networking
- Advanced security features
- Creates CRDs: `kubectl get crd | grep cilium`

Test what happens if CNI fails:

```bash
# Simulate CNI failure by deleting the CNI pod
kubectl delete pod -n kube-system -l app=kindnet

# Try creating a test pod
kubectl run cni-test --image=nginx:1.20 --rm -it --restart=Never -- echo "test"

# Observe - the new pod may get stuck in ContainerCreating
kubectl get pod cni-test
kubectl describe pod cni-test

# Clean up
kubectl delete pod cni-test --ignore-not-found

# CNI pod should have been recreated automatically
kubectl get pods -n kube-system -l app=kindnet
```

---

## Part 3: Container Storage Interface (CSI) Discovery

CSI enables Kubernetes to work with different storage systems. Kind uses rancher/local-path-provisioner.

Inspect the storage setup:

```bash
kubectl get storageclass
kubectl describe storageclass standard
```

Find CSI or storage-related pods:

```bash
kubectl get pods -n kube-system | grep -E "(csi|storage|local-path)"
kubectl describe pod -n local-path-storage -l app=local-path-provisioner
```

CSI driver pattern (for cloud environments):

**AWS EBS CSI Driver** structure:
- DaemonSet: `ebs-csi-node` (runs on each node)
- Deployment: `ebs-csi-controller` (cluster-wide controller)
- StorageClass points to `ebs.csi.aws.com` provisioner

**CSI Socket location** (on real nodes):
- `/var/lib/kubelet/plugins/ebs.csi.aws.com/csi.sock`

Test storage provisioning:

```bash
kubectl create namespace csi-test

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: csi-test
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
  namespace: csi-test
spec:
  containers:
  - name: test
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: test-vol
      mountPath: /data
  volumes:
  - name: test-vol
    persistentVolumeClaim:
      claimName: test-pvc
EOF

kubectl -n csi-test get pvc,pod
kubectl get pv
```

Observe the dynamic provisioning in action:

```bash
kubectl -n csi-test describe pvc test-pvc
kubectl get pv -o yaml | grep -A5 -B5 local-path
```

---

## Part 4: Extension Interface Troubleshooting Patterns

When extension interfaces fail, you'll see specific symptoms:

**CRI Failure Symptoms:**
- Pods stuck in `ContainerCreating`
- kubelet logs show CRI socket errors
- `crictl` commands fail

**CNI Failure Symptoms:**
- Pods get IP addresses but can't communicate
- New pods stuck in `ContainerCreating` with network setup errors
- Nodes go `NotReady`

**CSI Failure Symptoms:**
- PVCs stuck in `Pending`
- Pod scheduling failures with volume attachment errors
- Storage controller pod crashes

Practice diagnosis commands:

```bash
# CRI troubleshooting
kubectl describe node | grep -A10 "Container Runtime"
kubectl get events --sort-by=.metadata.creationTimestamp | grep -i cri

# CNI troubleshooting
kubectl get nodes -o wide
kubectl describe node | grep -A5 -B5 "PodCIDR"

# CSI troubleshooting
kubectl get crd | grep storage
kubectl get pods -A | grep csi
```

---

## Part 5: Extension Interface Summary Worksheet

Fill out this table based on your observations:

| Interface | Implementation | Socket/Config Path | System Pods | What Breaks When Missing |
|-----------|----------------|-------------------|-------------|-------------------------|
| CRI | containerd | /run/containerd/containerd.sock | containerd process | Containers won't start |
| CNI | kindnet | /etc/cni/net.d/10-kindnet.conflist | kindnet DaemonSet | Pod networking fails |
| CSI | local-path-provisioner | N/A (not full CSI) | local-path-provisioner | Dynamic storage fails |

---

## Validation Checklist

You are done when:

- You can identify your cluster's CRI, CNI, and CSI implementations
- You understand where configuration files and sockets are located
- You can predict what fails when each interface is misconfigured
- You've practiced basic troubleshooting commands for each interface

---

## Cleanup

```bash
kubectl delete namespace csi-test
```

---

## Reinforcement Scenario

- `jerry-wrong-cni-config`