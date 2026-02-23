![Lab 04 etcd Snapshot and Restore Drill](../../../assets/generated/week-05-lab-04/hero.png)
![Lab 04 etcd backup and restore workflow](../../../assets/generated/week-05-lab-04/flow.gif)

---

# Lab 4: etcd Snapshot and Restore Drill

**Time:** 55 minutes  
**Objective:** Practice etcd backup discipline and rehearse a safe restore workflow with evidence collection.

---

## CKA Objectives Mapped

- Back up and restore cluster state
- Troubleshoot control-plane data-path incidents
- Validate recovery evidence under time pressure

---

## Background: etcd and Why This Matters

etcd is the control plane's persistent source of truth. It is loosely like Parameter Store in that it is a key-value system, but if you lose etcd you lose the cluster's full memory, not just one parameter set. Every object you create through the API server, including Deployments, Pods, ConfigMaps, Secrets, RBAC rules, Services, and Endpoints, is serialized into key-value entries there. The API server, scheduler, and controller manager are mostly stateless processes around that data store: they read desired state from etcd, act on it, then write status changes back.

If etcd data is lost, the cluster loses memory of what should exist. Some containers may continue running briefly because kubelet already has local pod instructions, but normal operations break quickly: scheduling stalls, rollouts stop, service discovery drifts, and new writes fail or become meaningless. In AWS terms, this is closer to losing the full control-state database for an account than losing one EC2 instance or one EBS volume.

A snapshot is a point-in-time copy of the entire etcd database. `etcdctl snapshot save` asks a live etcd member to produce a consistent snapshot file while the cluster is running, and that file contains all keys known at that moment. `etcdutl snapshot restore` then expands that file into a fresh etcd data directory so a member can start from restored state.

The certificate flags are not optional with `etcdctl` because etcd uses mutual TLS. `--cacert` verifies the etcd server certificate, and `--cert` plus `--key` present the client identity; missing or mismatched files are rejected by design. In kubeadm-based clusters these files are typically under `/etc/kubernetes/pki/etcd/`. `etcdutl` is different because it operates offline on files directly and does not open a network TLS session, so restore commands do not need endpoint or cert flags.

Operationally, restore is a data-path swap: snapshot first, stop or isolate the running member, restore into a target data directory, repoint etcd to that directory, then restart and validate cluster objects. This lab rehearses that sequence safely by restoring to an alternate path in kind so you learn the flow without damaging live state. For deeper reference, see the official etcd backup and restore task: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/.

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

The etcd container image is distroless — it contains only `etcdctl`, `etcdutl`, and `etcd`, no shell or standard utilities. Save the snapshot directly into `/var/lib/etcd/`, which already exists as a mounted volume:

> **CKA exam note:** On the exam, etcd runs on a real node (not kind). Save to a path on the hostPath volume (e.g. `/var/lib/etcd/`) or copy off-node with `scp` from the control-plane host.

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
# kubectl cp uses tar internally — not available in distroless etcd images.
# In kind, /var/lib/etcd is a hostPath mount, so copy from the node container:
CONTROL_PLANE=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' \
  -o jsonpath='{.items[0].metadata.name}')
docker cp "${CONTROL_PLANE}:/var/lib/etcd/snapshot.db" ./artifacts/snapshot.db
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

## Part 6: Production Restore Sequence (CKA Exam Pattern)

The non-destructive rehearsal in Part 4 proves your snapshot is valid. The CKA exam tests the **full restore sequence** — including how you swap a running etcd member to a restored data directory. This sequence is what the exam actually expects you to execute on a kubeadm node.

> This section is command-level documentation. You do not need to execute it against your kind cluster (kind's etcd is inside the control-plane container and the static pod manifest is read-only from the host). Study the sequence and commands; the kind lab validates the snapshot/restore mechanics.

**The full kubeadm restore procedure:**

```bash
# 1. Move the etcd static pod manifest out of place so kubelet stops etcd.
#    The API server goes down with it — this is intentional.
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/etcd.yaml.bak

# Wait a few seconds for kubelet to notice the manifest is gone and stop the pod.
# etcd and kube-apiserver are both down now.

# 2. Restore the snapshot to a new data directory.
#    etcdutl is offline — no TLS certs, no endpoint needed.
sudo etcdutl snapshot restore /path/to/snapshot.db \
  --data-dir=/var/lib/etcd-restored

# 3. Edit the static pod manifest to point etcd at the restored data directory.
#    Open /tmp/etcd.yaml.bak and change (or add) the --data-dir flag:
#
#    containers:
#    - command:
#      - etcd
#      - --data-dir=/var/lib/etcd-restored   ← change from /var/lib/etcd
#
#    Also update the hostPath volumes block to match:
#    volumes:
#    - hostPath:
#        path: /var/lib/etcd-restored        ← change from /var/lib/etcd
#        type: DirectoryOrCreate
#      name: etcd-data
sudo vi /tmp/etcd.yaml.bak

# 4. Move the manifest back. kubelet sees the file, starts etcd pointing at the restored dir.
sudo mv /tmp/etcd.yaml.bak /etc/kubernetes/manifests/etcd.yaml

# 5. Wait for etcd to come up, then verify the API server recovers.
#    Static pods can take 30-60 seconds to restart.
kubectl get nodes
kubectl -n kube-system get pods -l component=etcd
```

**After restore, verify your marker ConfigMap reflects the snapshot point-in-time:**

```bash
kubectl -n etcd-lab get configmap restore-marker -o jsonpath='{.data.build}'; echo
# Should return: before-snapshot
# If it returns: after-snapshot — the restore picked up post-snapshot state (wrong snapshot)
```

**Why the static pod manifest edit matters:** `etcd --data-dir` is the path to the on-disk BoltDB files. If you restore to `/var/lib/etcd-restored` but the static pod manifest still points to `/var/lib/etcd`, etcd starts from the old (un-restored) directory and nothing changes. Updating the manifest is the step most exam candidates miss.

> **Reference:** [Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/) | [etcdutl snapshot restore](https://etcd.io/docs/v3.5/op-guide/recovery/)

---

## Part 6b: Recovery Runbook Template

Document this sequence in your notes:

1. Capture current cluster symptom
2. Snapshot etcd before risky actions (`etcdctl snapshot save`)
3. Verify snapshot metadata (`etcdutl snapshot status`)
4. Move etcd static pod manifest out of `/etc/kubernetes/manifests/` to stop etcd
5. Restore snapshot to a new data directory (`etcdutl snapshot restore --data-dir=...`)
6. Edit the static pod manifest: update `--data-dir` and the matching `hostPath` volume
7. Move manifest back — kubelet restarts etcd at the restored directory
8. Validate core objects and workload health (`kubectl get nodes`, `kubectl get pods -A`)

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
