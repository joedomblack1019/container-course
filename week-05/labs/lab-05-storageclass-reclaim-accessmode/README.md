# Lab 5: StorageClass Reclaim Policy and Access Modes

**Time:** 55 minutes  
**Objective:** Compare dynamic provisioning behavior, reclaim policy outcomes, and access-mode constraints with live workloads.

---

## CKA Objectives Mapped

- Understand StorageClass behavior and dynamic provisioning
- Work with PV/PVC lifecycle and reclaim policy
- Troubleshoot pending PVC and scheduling/storage mismatches

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
