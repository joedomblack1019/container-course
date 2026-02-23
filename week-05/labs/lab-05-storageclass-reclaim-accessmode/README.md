![Lab 05 StorageClass Reclaim Policy and Access Modes](../../../assets/generated/week-05-lab-05/hero.png)
![Lab 05 storage class and PVC workflow](../../../assets/generated/week-05-lab-05/flow.gif)

---

# Lab 5: StorageClass Reclaim Policy and Access Modes

**Time:** 55 minutes  
**Objective:** Compare dynamic provisioning behavior, reclaim policy outcomes, and access-mode constraints with live workloads.

---

## CKA Objectives Mapped

- Understand StorageClass behavior and dynamic provisioning
- Work with PV/PVC lifecycle and reclaim policy
- Troubleshoot pending PVC and scheduling/storage mismatches

---

## Background

### The Kubernetes Storage Object Model

Kubernetes separates *what you need* from *how it's provided* using three objects that stack on top of each other:

```
StorageClass           ← policy template: provisioner, reclaim policy, parameters
     ↓  (provisioner creates)
PersistentVolume       ← the actual disk resource: capacity, access mode, node path
     ↑  (PVC binds to)
PersistentVolumeClaim  ← your request: "I need 2Gi, ReadWriteOnce, on the fast class"
     ↑  (pod mounts)
Pod                    ← consumes the PVC as a directory inside the container
```

**Static provisioning (rare):** An admin manually creates PVs ahead of time. PVCs bind to whichever available PV matches.

**Dynamic provisioning (standard today):** You create a PVC. The provisioner controller (installed in the cluster) reads the StorageClass, calls the storage API, creates the disk, creates the PV, and binds the PVC — automatically. You never touch PV objects directly.

---

### What is a StorageClass?

A StorageClass is a policy template. It tells the cluster's provisioner plugin *how* to create a disk when a PVC asks for one.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com       # which plugin creates the disk
reclaimPolicy: Delete              # what happens to the PV when the PVC is deleted
volumeBindingMode: WaitForFirstConsumer  # when to provision (before or after scheduling)
allowVolumeExpansion: true         # can the PVC grow after creation?
parameters:
  type: gp3                        # provisioner-specific disk settings
  iopsPerGB: "10"
```

Key fields and their meaning:

| Field | Options | Effect |
|-------|---------|--------|
| `provisioner` | `rancher.io/local-path`, `ebs.csi.aws.com`, `disk.csi.azure.com`, ... | Which plugin creates the PV |
| `reclaimPolicy` | `Delete` (default), `Retain` | What happens to the PV when its PVC is deleted |
| `volumeBindingMode` | `Immediate`, `WaitForFirstConsumer` | When to provision and bind the PV |
| `allowVolumeExpansion` | `true` / `false` | Whether PVCs can grow after creation |
| `parameters` | provisioner-specific | Disk type, IOPS, encryption, filesystem, tier, etc. |

**`reclaimPolicy: Delete`** — When you delete the PVC, Kubernetes automatically deletes the PV and the underlying storage. Data is permanently gone. Good for scratch space or stateless workloads.

**`reclaimPolicy: Retain`** — When you delete the PVC, the PV stays in a `Released` state with data intact. An operator must manually inspect, clean, and re-bind or delete it. Required when data must survive accidental PVC deletion, or when you need an audit trail.

> **CKA exam gotcha — `Released` ≠ `Available`:** A PV in `Released` state still has a `claimRef` pointing at the deleted PVC. Kubernetes will NOT rebind it to a new PVC automatically, even if the new claim matches perfectly. To recycle a Retained PV for reuse you must manually remove the `claimRef` from the PV spec: `kubectl edit pv <name>` → delete the `claimRef` block → PV transitions to `Available` and can be bound again. Getting this wrong under exam pressure is very common.

**`reclaimPolicy: Recycle`** — Deprecated since Kubernetes 1.11 and removed from most CSI provisioners. If you encounter it in older clusters or exam scenarios, it triggered a basic `rm -rf` scrub of the volume before making it `Available` again. Never use it in new clusters; it may still appear in legacy multiple-choice questions.

**`volumeBindingMode: WaitForFirstConsumer`** — The PV is not created until a pod that uses the PVC is scheduled to a node. The provisioner then creates the disk in the same zone as the pod. This is critical in cloud deployments — if you use `Immediate` with a cloud block disk, the disk might be created in `us-east-1a` while the pod schedules to `us-east-1b`, and the mount will fail.

---

### Access Modes

Access modes constrain how many nodes and pods can mount a volume simultaneously. **Kubernetes does not enforce this — the storage backend does.** If the provisioner or storage driver doesn't support the requested access mode, the PVC stays `Pending` forever.

| Mode | Abbreviation | Meaning | Requires |
|------|-------------|---------|---------|
| `ReadWriteOnce` | RWO | One node can mount read/write at a time | Any block storage |
| `ReadOnlyMany` | ROX | Many nodes can mount read-only simultaneously | Network storage |
| `ReadWriteMany` | RWX | Many nodes can mount read/write simultaneously | Network filesystem (NFS, CephFS, EFS, Azure Files) |
| `ReadWriteOncePod` | RWOP | Exactly one pod (not node) can mount read/write | CSI block storage with RWOP support |

**The RWO vs RWX distinction is the most common source of confusion.**

A cloud block disk (AWS EBS, Azure Disk, GCE Persistent Disk) is a virtual hard drive. Like a USB drive, it physically attaches to **one virtual machine at a time**. That's RWO. If you request RWX on a block disk provisioner, the PVC will stay `Pending` — the provisioner literally cannot do it.

RWX requires a **network filesystem**: multiple nodes open a TCP connection to a central NFS or distributed filesystem server and all read/write simultaneously. This is slower but enables shared storage across pods on different nodes.

`ReadWriteOnce` allows multiple pods on the **same node** to mount the volume concurrently. If you need strict single-pod exclusivity (e.g., for a database that can't have two instances touching the same files), use `ReadWriteOncePod` — but check that your CSI driver supports it.

> **CKA exam trap — RWX on block storage:** Exam questions sometimes ask you to create a PVC with `ReadWriteMany` access. If the cluster's StorageClass uses a block storage provisioner (EBS, Azure Disk, local-path), the PVC will stay permanently `Pending` with an event like `volume plugin does not support access mode ReadWriteMany`. The fix is either switching to an NFS-backed StorageClass, or (if the question allows) changing the access mode to `ReadWriteOnce`. Always check `kubectl get storageclass` and `kubectl describe pvc` before assuming a provisioner bug.

---

### The local-path Provisioner

In this lab (and in all kind and k3s clusters) you're using `rancher.io/local-path`. It's the default provisioner that stores data directly on the node's filesystem, under `/var/local-path-provisioner/` by default.

**Docs:** https://github.com/rancher/local-path-provisioner

**What it does:**
- When a PVC is created (and a pod is scheduled with `WaitForFirstConsumer`), it creates a directory on that node
- The kubelet bind-mounts that directory into the container
- On PVC deletion with `Delete` policy, it removes the directory

**Limitations that matter for this lab:**

| Capability | local-path | Why |
|-----------|-----------|-----|
| `ReadWriteOnce` | ✅ Supported | It's just a local directory |
| `ReadWriteMany` | ❌ Not supported | Would require sharing across nodes — it's a local dir |
| `ReadOnlyMany` | ❌ Not supported | Same reason |
| `volumeMode: Block` | ❌ Not supported | No raw block device API |
| `allowVolumeExpansion` | ⚠️ Limited | The filesystem can grow but local-path may not resize gracefully |
| Multi-node safety | ❌ Not safe | If the pod reschedules to a different node, the data stays on the original node |

local-path is excellent for development (kind, k3s, Raspberry Pi) and terrible for production. In production you use a cloud or network-backed CSI driver.

---

### Cloud Storage Backends

In managed clusters (EKS, AKS, GKE), storage comes from cloud-managed virtual disks via CSI (Container Storage Interface) drivers. Each cloud ships a default StorageClass out of the box:

| Cloud | Storage Service | Provisioner | Access Modes | Notes |
|-------|----------------|-------------|--------------|-------|
| AWS EKS | EBS (gp3) | `ebs.csi.aws.com` | RWO only | Zone-locked; 1 VM at a time |
| AWS EKS | EFS | `efs.csi.aws.com` | RWX | Shared NFS; cross-zone |
| Azure AKS | Azure Disk | `disk.csi.azure.com` | RWO only | Zone-locked; 1 VM at a time |
| Azure AKS | Azure Files | `file.csi.azure.com` | RWO, RWX | SMB/NFS share; cross-zone |
| GKE | Persistent Disk | `pd.csi.storage.gke.io` | RWO only | Zone-locked; 1 VM at a time |
| GKE | Filestore | `filestore.csi.storage.gke.io` | RWX | Managed NFS; cross-zone |

How a cloud block disk attaches under the hood (EBS example):

```
1. PVC created with storageClassName: gp3
2. EBS CSI controller calls AWS API: CreateVolume in us-east-1a
3. EBS volume created (appears in AWS console as a 10Gi disk)
4. Pod scheduled to a node in us-east-1a
5. EBS CSI node driver calls AWS API: AttachVolume to that EC2 instance
6. Volume appears as /dev/nvme1n1 on the node
7. kubelet formats it (ext4) and bind-mounts into the container at mountPath
8. Pod sees a normal directory; writes go to the EBS volume
9. Pod deleted → volume detached from EC2 instance
10. PVC deleted (Delete policy) → AWS API: DeleteVolume
```

The zone-locking problem: EBS volumes are created in a specific availability zone. If your pod reschedules to a node in a different AZ, the mount fails — the volume cannot follow it. This is why `WaitForFirstConsumer` is mandatory for cloud block storage: it ensures the volume is created in the AZ where the pod actually lands.

For workloads that need to survive AZ failures, you need a network filesystem (EFS/Azure Files/Filestore) or a distributed block storage layer like Portworx, Rook/Ceph, or Longhorn.

> **Reference:** [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) | [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) | [Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) | [Reclaim Policy](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)

---

## Prerequisites

Use your local kind cluster:

```bash
kubectl config use-context kind-lab
kubectl get storageclass
```

Create a dedicated namespace:

```bash
kubectl create namespace storage-lab
```

Starter assets for this lab are in [`starter/`](./starter/):

- `storageclasses.yaml`
- `pvc-delete.yaml` / `writer-delete.yaml`
- `pvc-retain.yaml` / `writer-retain.yaml`
- `pvc-rwx.yaml`
- `pvc-block.yaml`
- `inspect.sh`

---

## Part 1: Create StorageClasses

Create one class with `Delete`, one with `Retain`, and one expandable class:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-delete
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-retain
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-expandable
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

Verify:

```bash
kubectl get storageclass local-delete local-retain local-expandable
```

---

## Part 2: Dynamic Provisioning with `Delete`

Create PVC + writer pod:

```bash
cat <<'EOF' | kubectl -n storage-lab apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-delete
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-delete
---
apiVersion: v1
kind: Pod
metadata:
  name: writer-delete
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo delete-policy > /data/policy.txt && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-delete
EOF
```

Confirm bind:

```bash
kubectl -n storage-lab get pvc pvc-delete
kubectl -n storage-lab get pod writer-delete
kubectl get pv | grep pvc-delete || true
```

---

## Part 3: Dynamic Provisioning with `Retain`

Create second PVC + pod:

```bash
cat <<'EOF' | kubectl -n storage-lab apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-retain
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-retain
---
apiVersion: v1
kind: Pod
metadata:
  name: writer-retain
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo retain-policy > /data/policy.txt && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-retain
EOF
```

Validate:

```bash
kubectl -n storage-lab get pvc pvc-retain
kubectl get pv | grep pvc-retain || true
```

---

## Part 4: Observe Reclaim Behavior

Delete pods first, then PVCs:

```bash
kubectl -n storage-lab delete pod writer-delete writer-retain
kubectl -n storage-lab delete pvc pvc-delete pvc-retain
```

Inspect resulting PV state:

```bash
kubectl get pv
```

Expected:

- `local-delete` volume should be cleaned up automatically
- `local-retain` volume should remain in `Released`/retained state until manual action

If you want to reuse the retained PV, practice the manual reclaim:

```bash
# Find the PV name
kubectl get pv

# Edit the PV and delete the entire claimRef block
kubectl edit pv <pv-name>
# Remove: claimRef: { ... }

# Confirm it's now Available
kubectl get pv
```

A PV only transitions back to `Available` after the `claimRef` is cleared. This is the manual step most people forget under exam pressure.

> **Reference:** [Reclaiming PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)

---

## Part 5: Access Mode Failure (`ReadWriteMany` on local-path)

Create an intentionally unsatisfied claim:

```bash
cat <<'EOF' | kubectl -n storage-lab apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx
spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-delete
EOF
```

Check status and events:

```bash
kubectl -n storage-lab get pvc pvc-rwx
kubectl -n storage-lab describe pvc pvc-rwx
kubectl -n storage-lab get events --sort-by=.metadata.creationTimestamp | tail -20
```

Record:

1. Why the claim stays `Pending`
2. Which storage backend capability is missing

---

## Part 6: Volume Mode - Block vs Filesystem

Most PVCs use `volumeMode: Filesystem` (the default), which mounts storage as a directory. `volumeMode: Block` exposes raw block devices for applications that manage their own filesystem.

Create a block mode PVC:

```bash
kubectl apply -f starter/pvc-block.yaml
```

Check the PVC status:

```bash
kubectl -n storage-lab get pvc pvc-block-mode
kubectl -n storage-lab describe pvc pvc-block-mode
```

Note the difference in `kubectl describe pvc` output:
- `volumeMode: Block` vs default `Filesystem`
- Local-path provisioner may not support Block mode

Expected: The PVC likely stays `Pending` because most local storage provisioners don't support Block mode. This demonstrates the learning point about provisioner capabilities.

Check the error:

```bash
kubectl -n storage-lab get events --sort-by=.metadata.creationTimestamp | tail -10
```

Block mode is primarily used by:
- Database applications (PostgreSQL, MySQL) that manage their own filesystem
- High-performance storage applications
- Applications requiring raw block device access

Compare with filesystem mode:

```bash
cat <<'EOF' | kubectl -n storage-lab apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-filesystem
spec:
  accessModes: ["ReadWriteOnce"]
  volumeMode: Filesystem
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-delete
---
apiVersion: v1
kind: Pod
metadata:
  name: filesystem-pod
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo 'Filesystem mount' > /data/test.txt && ls -la /data && sleep 3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-filesystem
EOF
```

This should succeed, demonstrating the difference between `volumeMounts` (filesystem) and `volumeDevices` (block).

---

## Part 7: PVC Expansion

Create a PVC using the expandable StorageClass:

```bash
cat <<'EOF' | kubectl -n storage-lab apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-expandable
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-expandable
---
apiVersion: v1
kind: Pod
metadata:
  name: writer-expandable
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "df -h /data && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-expandable
EOF
```

Check the current size:

```bash
kubectl -n storage-lab get pvc pvc-expandable
```

Expand the PVC:

```bash
kubectl -n storage-lab patch pvc pvc-expandable -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'
```

Observe resize status and conditions:

```bash
kubectl -n storage-lab get pvc pvc-expandable
kubectl -n storage-lab describe pvc pvc-expandable
```

Attempt expansion on a non-expandable class:

```bash
kubectl -n storage-lab apply -f starter/pvc-delete.yaml
kubectl -n storage-lab patch pvc pvc-delete -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}' || true
```

Expected: error indicates `allowVolumeExpansion` is not enabled for that StorageClass.

Important: PVC expansion is one-way. You can increase size, but you cannot shrink a PVC.

---

## Part 8: Triage Checklist

When PVCs are `Pending`, use:

```bash
kubectl get storageclass
kubectl -n <ns> describe pvc <name>
kubectl get pv
kubectl -n <ns> get events --sort-by=.metadata.creationTimestamp | tail -30
```

Always verify:

- correct `storageClassName`
- supported access mode
- requested capacity
- provisioner health

---

## Validation Checklist

You are done when:

- You provisioned claims with both `Delete` and `Retain` reclaim policies
- You observed different PV cleanup behavior after PVC deletion
- You reproduced a real access-mode mismatch and captured the event evidence
- You expanded a PVC from 1Gi to 2Gi using `kubectl patch`
- You verified that expansion fails on a StorageClass without `allowVolumeExpansion`

---

## Cleanup

```bash
kubectl -n storage-lab delete pvc pvc-rwx pvc-block-mode pvc-filesystem pvc-expandable pvc-delete --ignore-not-found
kubectl -n storage-lab delete pod filesystem-pod writer-expandable --ignore-not-found
kubectl delete namespace storage-lab
kubectl delete storageclass local-delete local-retain local-expandable
```

---

## Reinforcement Scenarios

- `jerry-pvc-pending-storageclass`
- `jerry-reclaim-policy-surprise`
