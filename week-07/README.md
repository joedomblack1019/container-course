# Week 7: Production Kustomize + Metrics Exporting

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

Your GitOps directory is growing. Every week adds more YAML: Redis, HTTPRoutes, Uptime Kuma, NetworkPolicies. If you're still copy/pasting the same manifests into `dev/` and `prod/` — the way we set things up in Weeks 5 and 6 — you're accumulating drift. That duplicated directory structure got you running fast, but it doesn't scale.

This week is about production hygiene:

- **Kustomize like teams actually use it**: `base/` + `overlays/` + reusable **components**
- **Metrics exporting**: stop debugging by vibes. You'll build a tiny exporter that reads real state from Redis (visits, guestbook comments, etc.) and exposes it in Prometheus format.
- **Minimal Prometheus scrape demo**: deploy Prometheus in kind, scrape your exporter, and query metrics.

Helm is still a useful tool, but we won’t spend time re-learning it. If Helm helps you install something quickly, we’ll use it without going deep.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Refactor duplicated Kubernetes YAML into a Kustomize `base/` plus environment overlays `CKA: Cluster Architecture, Installation and Configuration`
2. Use production Kustomize features (patches, `images`, and components) to manage real-world variation `CKA: Cluster Architecture, Installation and Configuration`
3. Explain overlay "dimensions" (environment, cluster, and feature toggles) and how to keep them sane `CKA: Cluster Architecture, Installation and Configuration`
4. Build a Prometheus metrics exporter that reads from Redis and exposes `/metrics` `CKA: Troubleshooting`
5. Deploy Prometheus in kind, verify scraping with basic PromQL queries, and interpret `kubectl top` signals `CKA: Troubleshooting`
6. Execute node lifecycle runbooks (`cordon`, `drain`, `uncordon`) and build a safe upgrade plan `CKA: Cluster Architecture, Installation and Configuration + Troubleshooting`
7. Control pod placement using taints, tolerations, node affinity, and topology spread constraints `CKA: Workloads & Scheduling`

---

## Pre-Class Setup

Verify tools:

```bash
kubectl version --client
kind version
docker version
```

You should still have the Week 5 app + Redis available locally (or be ready to rebuild it).

---

## Key Concepts

### Kustomize In Production: Base + Overlays + Components

The goal is to write shared YAML once, and only encode differences where they belong.

```
base/                      overlays/
  deployment.yaml             dev/
  service.yaml                 kustomization.yaml  (namespace + patches + dev-only components)
  redis.yaml                 prod/
  kustomization.yaml           kustomization.yaml  (namespace + patches)

components/
  uptime-kuma/               (optional “feature” you can include)
  network-policy/
  metrics-exporter/
```

Three common overlay dimensions:
- **Environment overlays**: dev vs prod (replicas, limits, routes, dev-only tools)
- **Cluster overlays**: kind vs shared cluster (image pull, ingress vs gateway, storage)
- **Feature components**: optional services (status pages, exporters, debugging tools)

### Patching (The “Real” Skill)

Kustomize isn’t about templating everything. It’s about patching the few fields that actually differ:
- replicas
- image tags/digests
- resource limits
- hostnames/routes
- enabling/disabling dev-only components

### Metrics Exporting (Prometheus Format)

Exporters are small services that:
1. Read state from somewhere (Redis, DB, API)
2. Expose `/metrics` in Prometheus exposition format

Prometheus scrapes metrics on an interval. You don’t push data to Prometheus; Prometheus pulls it.

### Minimal Prometheus Scrape

We’ll run a single Prometheus in kind with a tiny `prometheus.yml`:
- scrape the exporter service
- query metrics in the Prometheus UI

### Scheduling Constraints: Exam-Pattern YAML

The CKA exam requires writing taint/toleration and nodeAffinity YAML from scratch. These are the two patterns that appear most often:

**Taint a node and add a matching toleration:**

```bash
# Taint the node (operator adds this; often already present on exam nodes)
kubectl taint nodes <node-name> dedicated=gpu:NoSchedule
```

```yaml
# Pod spec that tolerates the taint and lands on the GPU node
spec:
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "gpu"
      effect: "NoSchedule"
  nodeSelector:
    dedicated: gpu   # still need a selector/affinity to land on the right node
```

**`requiredDuringSchedulingIgnoredDuringExecution` nodeAffinity (hard requirement):**

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                  - us-east-1a
                  - us-east-1b
```

**`preferredDuringSchedulingIgnoredDuringExecution` (soft preference with weight):**

```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - key: node-type
                operator: In
                values:
                  - high-memory
```

> **`required` vs `preferred`:** Required leaves a pod `Pending` forever if no matching node exists. Preferred schedules on the best-match node but falls back if the preferred condition is not met. Use required only when placement truly cannot compromise; use preferred for performance or cost hints.

> **Reference:** [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) | [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)

### Node Lifecycle + kubeadm Upgrade Sequence

The CKA exam tests both node maintenance commands and the kubeadm upgrade order. These must be memorized — there is no partial credit for the wrong sequence.

**Node maintenance (drain before maintenance, uncordon after):**

```bash
# 1. Stop new pods from landing on the node
kubectl cordon <node-name>

# 2. Evict all evictable pods (checks PodDisruptionBudgets)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 3. Do your maintenance (reboot, package upgrade, etc.)

# 4. Return the node to service
kubectl uncordon <node-name>
```

**kubeadm upgrade sequence (control-plane first, then workers one at a time):**

```bash
# On the control-plane node:
# 1. Upgrade kubeadm binary to the target version
apt-get install -y kubeadm=1.X.Y-*

# 2. Verify the upgrade plan (checks skew, shows component versions)
kubeadm upgrade plan

# 3. Apply the upgrade (upgrades kube-apiserver, controller-manager, scheduler, etcd)
kubeadm upgrade apply v1.X.Y

# 4. Upgrade kubelet and kubectl on the control-plane node
apt-get install -y kubelet=1.X.Y-* kubectl=1.X.Y-*
systemctl daemon-reload && systemctl restart kubelet

# On each worker node (drain from control-plane, then SSH to worker):
kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data
# (on the worker node:)
apt-get install -y kubeadm=1.X.Y-* kubelet=1.X.Y-* kubectl=1.X.Y-*
kubeadm upgrade node
systemctl daemon-reload && systemctl restart kubelet
# (back on control-plane:)
kubectl uncordon <worker>
```

> **Version skew rule:** Kubelet can lag the API server by at most one minor version. Control plane must upgrade first. Minor versions cannot be skipped — `1.29 → 1.31` requires a stop at `1.30`. **Reference:** [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/) | [kubeadm Upgrade](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

---

## Labs

### Lab 1: Production Kustomize (Refactor Your GitOps Tree)

📁 See [labs/lab-01-production-kustomize/](./labs/lab-01-production-kustomize/)

You will:
- Convert duplicated `dev/` + `prod/` manifests into `base/` + overlays
- Introduce at least one reusable component (dev-only tooling)
- Validate with `kubectl kustomize` and submit via GitOps

### Lab 2: Build a Redis Metrics Exporter

📁 See [labs/lab-02-metrics-exporter/](./labs/lab-02-metrics-exporter/)

You will:
- Build a small exporter container that reads Redis keys (visits, guestbook counts)
- Deploy it into kind alongside the app + Redis
- Verify `/metrics` output

### Lab 3: Scrape With Prometheus (kind)

📁 See [labs/lab-03-prometheus-scrape/](./labs/lab-03-prometheus-scrape/)

You will:
- Deploy Prometheus with a minimal scrape config
- Confirm exporter targets are `UP`
- Run a few PromQL queries against your metrics

### Lab 4: Node Lifecycle + Upgrade Planning

📁 See [labs/lab-04-node-lifecycle-and-upgrade/](./labs/lab-04-node-lifecycle-and-upgrade/)

You will:
- Run node maintenance workflows (`cordon`, `drain`, `uncordon`) in a multi-node kind cluster
- Diagnose and resolve a drain blocked by disruption constraints
- Build a version-skew and upgrade-order checklist for kubeadm-based clusters
- Map practice to `jerry-node-drain-pdb-blocked` runbooks

### Lab 5: Scheduling Constraints and Placement Control

📁 See [labs/lab-06-scheduling-constraints/](./labs/lab-06-scheduling-constraints/)

You will:
- Use taints, tolerations, nodeSelector, and nodeAffinity to control pod placement
- Spread pods across failure domains with topologySpreadConstraints and podAntiAffinity
- Diagnose and fix scheduling failures from impossible constraints

### Lab 6 (Optional Extension): HPA Autoscaling

📁 See [labs/lab-05-hpa-autoscaling/](./labs/lab-05-hpa-autoscaling/)

### Lab 7: Resource Observation with kubectl top

📁 See [labs/lab-07-resource-observation/](./labs/lab-07-resource-observation/)

You will:
- Install and configure metrics-server in a kind cluster (with the `--kubelet-insecure-tls` patch required for kind's self-signed certs)
- Deploy a zoo of workloads with distinct resource profiles: a CPU burner, a memory hog, idle nginx replicas, and a batch Job
- Use `kubectl top nodes` and `kubectl top pods` with sort flags and label selectors to identify resource consumers
- Distinguish resource *requests* (scheduling reservations visible in `kubectl describe`) from *actual* usage (reported by `kubectl top`)
- Complete a graded 4-question challenge using only `kubectl top` and `kubectl describe`

---

## Generated Visualizations

### Lab 6 (Optional Extension): HPA Autoscaling Timeline

![HPA Timeline](../assets/generated/week-07-hpa-autoscaling-fullcycle/hpa_timeline.png)

![Deployment Replica Timeline](../assets/generated/week-07-hpa-autoscaling-fullcycle/deployment_replica_timeline.png)

---

## Discovery Questions

1. What is the difference between a Kustomize overlay and a Kustomize component? When would you use each?
2. If both a base and an overlay set the same field, which wins and why?
3. Why do Prometheus exporters usually expose a `/metrics` endpoint instead of pushing metrics somewhere?
4. Your exporter is running, but Prometheus shows `UP=0`. What are the first three things you would check?
5. Name one example of an environment difference (dev vs prod) that belongs in an overlay, not in the base.
6. A node has the taint `gpu=true:NoSchedule`. You deploy a pod without any tolerations. What happens, and how would you fix it without removing the taint?

---

## Homework

Homework exercises run in your DevContainer via **gymctl** (the [container-gym](https://github.com/shart-cloud/container-gym) CLI).

| Exercise | Time | Focus |
|----------|------|-------|
| `jerry-kustomize-drift` | 25 min | Base/overlays refactor + patch debugging |
| `jerry-exporter-missing-metrics` | 25 min | Exporter correctness + scrape debugging |
| `jerry-prometheus-target-down` | 25 min | Network/DNS/service debugging for scrapes |
| `jerry-pod-unschedulable-taint` | 25 min | Scheduler constraints, taints, and placement recovery |
| `27-jerry-resource-hog-hunt` | 20 min | `kubectl top` triage — identify and evict a CPU hog |
| `35-jerry-missing-jsonpath` | 20 min | Fast field extraction with `-o jsonpath` and `--sort-by` |
| `36-jerry-upgrade-skipped` | 25 min | kubeadm upgrade order, skew checks, and plan/apply workflow |
| `jerry-hpa-not-scaling` *(optional extension)* | 25 min | metrics-server and HPA troubleshooting |

---

## Resources

- Kustomize: https://kustomize.io/
- kubectl kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
- Prometheus exposition format: https://prometheus.io/docs/instrumenting/exposition_formats/
- Prometheus getting started: https://prometheus.io/docs/prometheus/latest/getting_started/
- Safely Drain a Node: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
- Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
- Node Affinity: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity
- kubeadm Upgrade: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

---

## Next Week Preview

Week 8 closes the loop — GitOps with ArgoCD + CI validation:
- Install ArgoCD on your kind cluster with Helm
- ApplicationSets to manage dev + prod overlays from one definition
- The rollback lesson: why Git is the source of truth, not the ArgoCD UI
- GitHub Actions CI pipeline to validate YAML before it merges
