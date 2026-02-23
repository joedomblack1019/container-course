![Lab 06 HA Control Plane Design and Simulation](../../../assets/generated/week-08-lab-06/hero.png)
![Lab 06 HA control plane design workflow](../../../assets/generated/week-08-lab-06/flow.gif)

---

# Lab 6: HA Control Plane Design and Simulation

**Time:** 40 minutes  
**Objective:** Design an HA control-plane topology and validate quorum/failure behavior in a multi-control-plane kind simulation.

---

## CKA Objectives Mapped

- Configure high-availability control plane concepts
- Understand etcd quorum requirements
- Validate failure domains and recovery sequencing

---

## Background: What HA Control Plane Really Means

High availability for Kubernetes control plane means preserving API and control-state continuity when a control-plane node fails. The scheduler and controller manager are replicated for process availability, but etcd quorum is the hard gate for write safety and cluster memory. Without etcd quorum, the API may still answer some reads briefly, yet the control plane cannot reliably commit state changes.

Quorum math is why odd member counts matter. With `N` etcd members, quorum is `floor(N/2)+1`, so a 3-member control plane tolerates one failure, while a 5-member setup tolerates two. A 2-member design is worse than 3 because it still tolerates only one failure but increases split-brain risk and operational complexity, which is why production guidance favors odd counts.

An HA API endpoint is a stable address in front of multiple API servers, typically via a load balancer and health checks. Think of it like an internal ALB or NLB target set for API servers: clients and kubelets use one endpoint, while back-end control-plane nodes can rotate during failures. This stable endpoint is what keeps kubelets and operators from reconfiguring clients every time one node is replaced.

When one control-plane node is down and quorum remains, existing workloads continue and new scheduling can still happen because surviving API server, scheduler, and controller-manager instances keep reconciling state. If quorum is lost, pods already running may continue temporarily because kubelet acts locally, but cluster-level operations such as new deployments, scaling, and controller updates degrade or halt. That is why recovery order starts with API and quorum validation before workload-level triage.

This lab uses kind to simulate those behaviors safely, not to replicate production HA networking and certificate distribution in full detail. The goal is operational reasoning: identify tolerated failures, verify quorum, and follow a deterministic recovery sequence. For production implementation details, use the kubeadm HA guide: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/.

---

## Scope Note

This lab is an **architecture and operations simulation**.  
kind helps visualize HA behavior, but it is not a production kubeadm HA deployment.

---

## Part 1: Build a Multi-Control-Plane Cluster

Create a kind config:

```bash
cat <<'EOF' > /tmp/kind-ha.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ha
nodes:
- role: control-plane
- role: control-plane
- role: control-plane
- role: worker
- role: worker
EOF
```

Create the cluster:

```bash
kind create cluster --name ha --config /tmp/kind-ha.yaml
kubectl config use-context kind-ha
kubectl get nodes -o wide
```

Starter assets for this lab are in [`starter/`](./starter/):

- `kind-ha-cluster.yaml`
- `simulate-control-plane-failure.sh`
- `ha-runbook-template.md`

Expected:

- 3 control-plane nodes
- 2 worker nodes

---

## Part 2: Inspect Control Plane and etcd Quorum

List control-plane pods:

```bash
kubectl -n kube-system get pods -o wide | grep -E 'etcd|kube-apiserver|kube-controller-manager|kube-scheduler'
```

Inspect etcd members:

```bash
for pod in $(kubectl -n kube-system get pods -l component=etcd -o name); do
  echo "=== $pod ==="
  kubectl -n kube-system exec "${pod#pod/}" -- sh -c '
  ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list | head -5'
done
```

Write down:

- number of members
- quorum requirement (`N/2 + 1`)

---

## Part 3: Simulate Control-Plane Failure

Find the node containers:

```bash
docker ps --format '{{.Names}}' | grep '^ha-'
```

Stop one control-plane node:

```bash
docker stop ha-control-plane2
```

Validate API and workloads still function:

```bash
kubectl get nodes
kubectl create namespace ha-lab
kubectl -n ha-lab create deployment smoke --image=nginx:1.27 --replicas=2
kubectl -n ha-lab rollout status deploy/smoke
```

Interpretation:

- API stayed available because quorum remained
- Workloads continue when one control plane is down

---

## Part 4: Recover Failed Control Plane

Start the failed node:

```bash
docker start ha-control-plane2
kubectl get nodes -w
```

Confirm etcd and control-plane pods stabilize:

```bash
kubectl -n kube-system get pods -o wide | grep control-plane2
```

---

## Part 5: HA Design Worksheet

Answer these in your notes:

1. Where is the stable API endpoint in an HA kubeadm design?
2. What breaks when quorum is lost?
3. How many control-plane failures can this topology tolerate?
4. What is your incident runbook order for one failed control-plane node?

Suggested runbook order:

1. Confirm API health
2. Check etcd quorum/membership
3. Restore failed node or replace member
4. Re-validate scheduler/controller activity
5. Verify workload health and events

---

## Validation Checklist

You are done when:

- HA cluster created with 3 control-plane nodes
- etcd member list inspected and quorum explained
- One control-plane node failure simulated and recovered
- You produced a short HA incident runbook

---

## Cleanup

```bash
kubectl config use-context kind-lab || true
kind delete cluster --name ha
rm -f /tmp/kind-ha.yaml
```
