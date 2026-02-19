# Lab 4: etcd Snapshot and Restore Drill

**Time:** 55 minutes  
**Objective:** Practice etcd backup discipline and rehearse a safe restore workflow with evidence collection.

---

## CKA Objectives Mapped

- Back up and restore cluster state
- Troubleshoot control-plane data-path incidents
- Validate recovery evidence under time pressure

---

## Safety Warning

This lab uses a **safe rehearsal path** by restoring snapshots into an alternate directory first.  
Do not replace live etcd data directories in production during this exercise.

---

## Prerequisites

Use a local kind cluster (not shared cluster):

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Find your etcd pod:

```bash
ETCD_POD="$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')"
echo "$ETCD_POD"
```

Starter assets for this lab are in [`starter/`](./starter/):

- `snapshot.sh`
- `restore-dryrun.sh`
- `verify.sh`

---

## Part 1: Create a Recovery Marker

Create a marker ConfigMap so you can verify state capture timing:

```bash
kubectl create namespace etcd-lab
kubectl -n etcd-lab create configmap restore-marker --from-literal=build="before-snapshot"
kubectl -n etcd-lab get configmap restore-marker -o yaml
```

---

## Part 1.5: Discover etcd Certificate Paths

On the CKA exam, you must find cert paths yourself. Practice that now.

Inspect the etcd pod spec to find the certificate arguments:

```bash
kubectl -n kube-system get pod "$ETCD_POD" -o yaml | grep -E '(--cert-file|--key-file|--trusted-ca-file|--listen-client)'
```

Map etcd flags to etcdctl flags:

| etcd server flag       | etcdctl flag |
|------------------------|--------------|
| `--cert-file`          | `--cert`     |
| `--key-file`           | `--key`      |
| `--trusted-ca-file`    | `--cacert`   |
| `--listen-client-urls` | `--endpoints` |

Write these down. You'll use them in every etcdctl command for the rest of this lab.

---

## Part 2: Take a Snapshot

The etcd container image is distroless — it contains only `etcdctl` and `etcd`, no shell or standard utilities. Save the snapshot directly into `/var/lib/etcd/`, which already exists as a mounted volume:

```bash
kubectl -n kube-system exec "$ETCD_POD" -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db
```

Validate snapshot metadata:

```bash
kubectl -n kube-system exec "$ETCD_POD" -- etcdutl \
  snapshot status /var/lib/etcd/snapshot.db -w table
```

> `etcdutl` is the offline utility for snapshot operations in etcd 3.6+. It reads the file directly — no TLS flags or `--endpoints` needed.

Copy snapshot locally as evidence:

```bash
mkdir -p ./artifacts
kubectl -n kube-system cp "${ETCD_POD}:/var/lib/etcd/snapshot.db" ./artifacts/snapshot.db
ls -lh ./artifacts/snapshot.db
```

---

## Part 3: Mutate State After Snapshot

Change the marker so there is a visible difference:

```bash
kubectl -n etcd-lab create configmap restore-marker --from-literal=build="after-snapshot" -o yaml --dry-run=client | kubectl apply -f -
kubectl -n etcd-lab get configmap restore-marker -o jsonpath='{.data.build}'; echo
```

Expected now: `after-snapshot`.

---

## Part 4: Rehearse Restore (Non-Destructive)

Restore into an alternate data directory inside the etcd pod. `etcdutl snapshot restore` creates the `--data-dir` automatically — no shell or mkdir needed:

```bash
kubectl -n kube-system exec "$ETCD_POD" -- etcdutl \
  snapshot restore /var/lib/etcd/snapshot.db \
  --data-dir=/var/lib/etcd-restore-check
```

Confirm restore output directory exists:

```bash
kubectl -n kube-system exec "$ETCD_POD" -- etcdutl \
  snapshot status /var/lib/etcd-restore-check/member/snap/db -w table
```

This proves your snapshot can be restored and is not corrupt.

---

## Part 5: Failure Checkpoint (Intentional Cert Errors)

`etcdutl` is offline and needs no certs. To learn cert failure signatures, use an **online** command like `member list` instead.

Run with a missing CA cert:

```bash
kubectl -n kube-system exec "$ETCD_POD" -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/tmp/does-not-exist.crt \
  member list
```

Now run with the wrong cert/key pair (peer cert instead of server cert):

```bash
kubectl -n kube-system exec "$ETCD_POD" -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list || true
```

Capture both error messages and write down:

1. What failed
2. Which flag/path was wrong
3. How the wrong-file-path error differs from wrong-cert error
4. How you would detect this quickly in an incident

---

## Part 6: Recovery Runbook Template

Document this sequence in your notes:

1. Capture current cluster symptom
2. Snapshot etcd before risky actions
3. Verify snapshot status
4. Stop API writes (maintenance window)
5. Restore snapshot to target data-dir
6. Restart components
7. Validate core objects and workload health

---

## Validation Checklist

You are done when:

- Snapshot file exists and `snapshot status` returns valid metadata
- Local evidence file is copied to `./artifacts/snapshot.db`
- Restore rehearsal to alternate data directory succeeds
- You can explain different cert failure signals (missing CA path vs wrong cert/key)

---

## Cleanup

```bash
kubectl delete namespace etcd-lab
rm -rf ./artifacts
```

> The snapshot and restore-check directories live inside the etcd container's ephemeral filesystem. They are gone when the pod is replaced or the kind cluster is deleted — no in-pod cleanup needed.

---

## Reinforcement Scenario

- `jerry-etcd-snapshot-missing`
