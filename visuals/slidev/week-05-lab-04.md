---
theme: default
title: Week 05 Lab 04 - etcd Snapshot and Restore Drill
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "05"
lab: "Lab 04 · etcd Snapshot and Restore Drill"
---

# etcd Snapshot and Restore Drill
## Lab 04

- Capture consistent etcd snapshot data with cert-authenticated `etcdctl`
- Validate snapshot metadata and copy evidence artifact locally
- Rehearse restore into alternate data dir (non-destructive)
- Practice cert-path failure triage for incident response

---
layout: win95
windowTitle: "etcd Recovery Sequence"
windowIcon: "💾"
statusText: "Week 05 · Lab 04 · Backup and rehearse restore"
---

## Safe Incident Pattern

| Step | Purpose |
|---|---|
| Snapshot | Preserve control-plane state point-in-time |
| Status check | Prove snapshot integrity before crisis |
| Restore rehearsal | Validate data-path recovery mechanics |
| Failure checkpoint | Recognize wrong cert/path error signatures |

---
layout: win95
windowTitle: "Cert Flag Mapping"
windowIcon: "🔐"
statusText: "Week 05 · Lab 04 · etcdctl TLS flags"
---

## Server Flags to Client Flags

| etcd server flag | etcdctl flag |
|---|---|
| `--cert-file` | `--cert` |
| `--key-file` | `--key` |
| `--trusted-ca-file` | `--cacert` |
| `--listen-client-urls` | `--endpoints` |

> `etcdutl` snapshot operations are offline file operations, so they do not require endpoint/TLS flags.

---
layout: win95-terminal
termTitle: "Command Prompt — setup marker and discover cert paths"
---

<Win95Terminal
  title="Command Prompt — pre-snapshot setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'ETCD_POD=&quot;$(kubectl -n kube-system get pods -l component=etcd -o jsonpath=\'{.items[0].metadata.name}\')&quot;' },
    { type: 'input', text: 'kubectl create namespace etcd-lab' },
    { type: 'input', text: 'kubectl -n etcd-lab create configmap restore-marker --from-literal=build=&quot;before-snapshot&quot;' },
    { type: 'input', text: 'kubectl -n etcd-lab get configmap restore-marker -o yaml' },
    { type: 'input', text: 'kubectl -n kube-system get pod &quot;$ETCD_POD&quot; -o yaml | grep -E \'(--cert-file|--key-file|--trusted-ca-file|--listen-client)\'' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — snapshot capture and status"
---

<Win95Terminal
  title="Command Prompt — snapshot"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/lib/etcd/snapshot.db' },
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdutl snapshot status /var/lib/etcd/snapshot.db -w table' },
    { type: 'input', text: 'mkdir -p ./artifacts' },
    { type: 'input', text: 'CONTROL_PLANE=$(kubectl get nodes --selector=\'node-role.kubernetes.io/control-plane\' -o jsonpath=\'{.items[0].metadata.name}\')' },
    { type: 'input', text: 'docker cp &quot;${CONTROL_PLANE}:/var/lib/etcd/snapshot.db&quot; ./artifacts/snapshot.db' },
    { type: 'input', text: 'ls -lh ./artifacts/snapshot.db' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — post-snapshot mutation and restore rehearsal"
---

<Win95Terminal
  title="Command Prompt — restore dry run"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n etcd-lab create configmap restore-marker --from-literal=build=&quot;after-snapshot&quot; -o yaml --dry-run=client | kubectl apply -f -' },
    { type: 'input', text: 'kubectl -n etcd-lab get configmap restore-marker -o jsonpath=\'{.data.build}\'; echo' },
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdutl snapshot restore /var/lib/etcd/snapshot.db --data-dir=/var/lib/etcd-restore-check' },
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdutl snapshot status /var/lib/etcd-restore-check/member/snap/db -w table' },
    { type: 'success', text: 'Restore rehearsal path validated' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — cert failure signatures and cleanup"
---

<Win95Terminal
  title="Command Prompt — failure checkpoint"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/tmp/does-not-exist.crt member list' },
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key member list || true' },
    { type: 'input', text: 'kubectl delete namespace etcd-lab' },
    { type: 'input', text: 'rm -rf ./artifacts' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 04 — Key Commands"
windowIcon: "📋"
statusText: "Week 05 · Lab 04 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl config use-context kind-lab` | Use local kind cluster |
| `ETCD_POD="$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')"` | Resolve etcd pod name |
| `kubectl create namespace etcd-lab` | Create lab namespace |
| `kubectl -n etcd-lab create configmap restore-marker --from-literal=build="before-snapshot"` | Create pre-snapshot marker |
| `kubectl -n kube-system get pod "$ETCD_POD" -o yaml | grep -E '(--cert-file|--key-file|--trusted-ca-file|--listen-client)'` | Discover cert paths |
| `kubectl -n kube-system exec "$ETCD_POD" -- etcdctl ... snapshot save /var/lib/etcd/snapshot.db` | Save etcd snapshot |
| `kubectl -n kube-system exec "$ETCD_POD" -- etcdutl snapshot status /var/lib/etcd/snapshot.db -w table` | Validate snapshot metadata |
| `docker cp "${CONTROL_PLANE}:/var/lib/etcd/snapshot.db" ./artifacts/snapshot.db` | Copy snapshot evidence locally |
| `kubectl -n etcd-lab create configmap restore-marker --from-literal=build="after-snapshot" -o yaml --dry-run=client | kubectl apply -f -` | Mutate state post-snapshot |
| `kubectl -n kube-system exec "$ETCD_POD" -- etcdutl snapshot restore /var/lib/etcd/snapshot.db --data-dir=/var/lib/etcd-restore-check` | Restore to alternate data dir |
| `kubectl -n kube-system exec "$ETCD_POD" -- etcdutl snapshot status /var/lib/etcd-restore-check/member/snap/db -w table` | Verify restored DB file |
| `kubectl -n kube-system exec "$ETCD_POD" -- etcdctl --cacert=/tmp/does-not-exist.crt member list` | Simulate missing CA cert error |
| `kubectl -n kube-system exec "$ETCD_POD" -- etcdctl ... --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key member list || true` | Simulate wrong cert/key error |
| `kubectl delete namespace etcd-lab` | Cleanup namespace |
| `rm -rf ./artifacts` | Cleanup local artifacts |
