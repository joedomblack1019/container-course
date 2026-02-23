![Lab 04 Node Lifecycle and Upgrade Planning](../../../assets/generated/week-07-lab-04/hero.png)
![Lab 04 drain cordon upgrade workflow](../../../assets/generated/week-07-lab-04/flow.gif)

---

# Lab 4: Node Lifecycle and Upgrade Planning

**Time:** 60 minutes  
**Objective:** Practice safe node maintenance (`cordon`, `drain`, `uncordon`) and build a kubeadm upgrade plan with version-skew checks.

---

## CKA Objectives Mapped

- Manage node scheduling and maintenance operations
- Plan and execute cluster lifecycle/upgrade tasks safely
- Troubleshoot drain failures and disruption constraints

---

## Background: Node Lifecycle Operations

Node maintenance in Kubernetes is three separate operations with different effects. `cordon` marks a node `SchedulingDisabled`, which stops new placements but leaves existing pods running. `drain` actively evicts pods and then leaves the node cordoned, which is what makes it safe for maintenance. `uncordon` removes the scheduling block so the node can receive new pods again.

`kubectl drain` is not a blind delete; it uses the Eviction API, which checks PodDisruptionBudgets before allowing each pod to move. A PDB encodes availability policy such as minimum healthy replicas, so eviction is denied if moving a pod would violate that threshold. This is the protection that keeps voluntary disruptions like maintenance from becoming accidental outages.

For upgrades, draining first keeps workload continuity while node software changes happen. The standard pattern is cordon and drain a worker, upgrade node packages, run `kubeadm upgrade node`, then uncordon. That sequence keeps traffic on healthy nodes while one node is temporarily out of service.

Version skew rules are strict and drive upgrade order. Kubelet can be at most one minor version behind the API server, the control plane upgrades first, and workers follow. Minor versions cannot be skipped in supported workflows, so a jump like `1.29` to `1.31` must be two sequential upgrades through `1.30`.

At a high level, kubeadm upgrades follow this rhythm: upgrade the `kubeadm` binary on the control-plane node, run `kubeadm upgrade apply` on control plane, then handle workers one at a time with drain, package upgrades, `kubeadm upgrade node`, and uncordon. If one sentence sticks, make it this: no new scheduling during maintenance, no evictions that violate PDB, and no version-skew shortcuts. For deeper detail, use the official upgrade guide: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/.

---

## Prerequisites

This lab uses a dedicated multi-node kind cluster:

```bash
cat <<'EOF' > /tmp/kind-ops.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ops
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

kind create cluster --name ops --config /tmp/kind-ops.yaml
kubectl config use-context kind-ops
kubectl get nodes -o wide
```

Starter assets for this lab are in [`starter/`](./starter/):

- `kind-ops-cluster.yaml`
- `workload-and-pdb.yaml`
- `maintenance.sh`
- `upgrade-checklist.md`
- `upgrade-runbook-template.md`
- `output-formatting-drills.md`

---

## Part 1: Deploy a Drain-Sensitive Workload

Create a deployment and strict PDB:

```bash
kubectl create namespace ops-lab

cat <<'EOF' | kubectl -n ops-lab apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web
EOF
```

Wait for readiness:

```bash
kubectl -n ops-lab get pods -o wide
kubectl -n ops-lab get pdb
```

---

## Part 2: Cordon and Drain

Pick a worker node:

```bash
WORKER="$(kubectl get nodes -o name | grep worker | head -1 | cut -d/ -f2)"
echo "$WORKER"
```

Cordon it:

```bash
kubectl cordon "$WORKER"
kubectl get nodes
```

Attempt drain:

```bash
kubectl drain "$WORKER" --ignore-daemonsets --delete-emptydir-data --timeout=60s
```

Expected: drain fails because PDB `minAvailable: 2` blocks eviction.

Capture evidence:

```bash
kubectl -n ops-lab get events --sort-by=.metadata.creationTimestamp | tail -20
kubectl -n ops-lab describe pdb web-pdb
```

---

## Part 3: Resolve the Block Safely

Allow one disruption:

```bash
kubectl -n ops-lab patch pdb web-pdb --type merge -p '{"spec":{"minAvailable":1}}'
kubectl drain "$WORKER" --ignore-daemonsets --delete-emptydir-data --timeout=120s
```

Validate pods were rescheduled:

```bash
kubectl -n ops-lab get pods -o wide
```

Bring node back:

```bash
kubectl uncordon "$WORKER"
kubectl get nodes
```

---

## Part 4: Upgrade Planning and Version Skew Checks

Capture current versions:

```bash
kubectl version
kubectl get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion
```

Collect kubeadm upgrade signals from the control-plane container:

```bash
docker exec ops-control-plane kubeadm version
docker exec ops-control-plane kubeadm upgrade plan || true
```

Build your plan document with:

1. Target Kubernetes version
2. Allowed version skew (control plane vs kubelet)
3. Upgrade order (control plane first, workers next)
4. Rollback and drain strategy per node

---

## Part 5: Incident Triage Pattern

When maintenance fails, always run:

```bash
kubectl describe node "$WORKER"
kubectl -n ops-lab get pdb
kubectl -n ops-lab get events --sort-by=.metadata.creationTimestamp | tail -30
```

Root causes to check first:

- PDB restrictions
- local storage blocking eviction
- DaemonSets ignored incorrectly
- insufficient capacity on remaining nodes

---

## Part 6: Kubeadm Upgrade Simulation (kind)

This is a command-and-decision simulation of the kubeadm upgrade workflow. kind does not support real host package upgrades (`apt-get` + `systemctl restart kubelet`), but it does let you practice the control-plane planning flow and worker maintenance sequence.

Check current versions across the cluster:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion
docker exec ops-control-plane kubeadm version
docker exec ops-control-plane kubectl version --short 2>/dev/null || true
```

Run the control-plane upgrade plan:

```bash
docker exec ops-control-plane kubeadm upgrade plan
```

Capture the output and read it closely. Record available target versions and component version changes.

Document the correct upgrade order:

1. Control plane node first: `kubeadm upgrade apply v1.XX.Y`
2. Then each worker: drain -> upgrade kubelet/kubectl packages -> `kubeadm upgrade node` -> uncordon
3. Version skew rule: kubelet may be up to one minor version behind the API server

Practice the worker maintenance sequence:

```bash
WORKER=$(kubectl get nodes -o name | grep worker | head -1 | cut -d/ -f2)
kubectl drain $WORKER --ignore-daemonsets --delete-emptydir-data
# In a real upgrade: apt-get update && apt-get install kubelet=X.Y.Z kubectl=X.Y.Z
# Then: systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon $WORKER
```

Fill the runbook template with real data from your cluster:

```bash
cp starter/upgrade-runbook-template.md ./upgrade-runbook.md
```

> For full kubeadm upgrade execution, use the KubeVirt VM lab (when available) or the VirtualBox/Vagrant kubeadm scenario. Those environments allow real `apt-get install` and `systemctl restart kubelet` operations.

---

## Bonus: Output Formatting Speed Drills

CKA questions often require extracting specific fields with jsonpath or custom-columns.
Work through [`starter/output-formatting-drills.md`](./starter/output-formatting-drills.md) after completing Part 1 — you only need a running cluster with workloads. Target: 2-3 minutes per drill.

---

## Part 7: Graded JsonPath Output Check

Complete the short graded check using only `-o jsonpath` and/or `--sort-by` queries.

```bash
cp starter/jsonpath-check.txt ./jsonpath-check.txt
# Fill each VALUE using kubectl output-formatting commands
bash starter/validate-jsonpath-check.sh ./jsonpath-check.txt
```

Passing target: 4/4 correct values.

Map this checkpoint to reinforcement scenario: `35-jerry-missing-jsonpath`.

---

## Validation Checklist

You are done when:

- You reproduced a drain failure and proved the PDB cause
- You adjusted policy and drained safely
- You uncordoned and restored normal scheduling
- You produced a version-skew-aware upgrade checklist
- You can explain the correct kubeadm upgrade order (control plane first, workers second)
- You executed drain/uncordon on at least one worker during simulated maintenance
- You filled in the upgrade runbook template with real version data from your cluster
- You passed the graded jsonpath/output-formatting check (`>=4/4`)

---

## Cleanup

```bash
kubectl config use-context kind-lab || true
kind delete cluster --name ops
rm -f /tmp/kind-ops.yaml
```

---

## Reinforcement Scenarios

- `jerry-pod-unschedulable-taint`
- `jerry-node-drain-pdb-blocked`
- `35-jerry-missing-jsonpath`
- `36-jerry-upgrade-skipped`
