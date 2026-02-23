![Lab 07 Resource Observation with kubectl top](../../../assets/generated/week-07-lab-07/hero.png)
![Lab 07 kubectl top and resource triage workflow](../../../assets/generated/week-07-lab-07/flow.gif)

---

# Lab 7: Resource Observation with kubectl top

**Time:** 30–40 minutes
**Objective:** Enable metrics-server in kind, run a zoo of workloads with distinct resource profiles, and use `kubectl top` as a primary diagnostic tool.

---

## CKA Objectives Mapped

- Use `kubectl top` to monitor node and pod resource consumption
- Distinguish CPU and memory units in metrics output
- Differentiate resource *requests* (scheduling reservations) from *actual* usage
- Identify resource hogs using sort flags and label selectors

---

## Background

`kubectl top` is the built-in cluster thermometer. It reads live resource metrics from **metrics-server** — a lightweight aggregator that scrapes usage stats from each kubelet's `/stats/summary` endpoint every 60 seconds. Without it, `kubectl top` returns:

```
Error from server (ServiceUnavailable): the server is currently unable to handle the request (get nodes.metrics.k8s.io)
```

Two things you must be clear on before reading top output:

**CPU** is expressed in **millicores** (`m`). 1000m = 1 core. A pod showing `450m` is using nearly half a CPU core. The `%` column on nodes shows usage relative to *allocatable* CPU, not raw capacity.

**Memory** is expressed in **mebibytes** (`Mi`) or gibibytes (`Gi`). Unlike CPU, memory is not compressible — a pod that uses 300Mi *holds* that memory until it exits. A node that has 2Gi total with 1.8Gi in use has very little headroom.

**Requests vs actual:** `kubectl top` shows what a pod *is actually consuming right now*. `kubectl describe pod` shows its *requests* — what the scheduler reserved for it. A pod can be far under or over its request; limits throttle or OOM-kill it if it exceeds them. In a healthy cluster, actual usage sits somewhere below the limit.

---

## Prerequisites

This lab uses a dedicated two-worker kind cluster:

```bash
cat <<'EOF' > /tmp/kind-resource.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: resource-lab
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

kind create cluster --name resource-lab --config /tmp/kind-resource.yaml
kubectl config use-context kind-resource-lab
kubectl get nodes
```

You should see three nodes (`resource-lab-control-plane`, `resource-lab-worker`, `resource-lab-worker2`) all in `Ready` state.

Starter assets for this lab are in [`starter/`](./starter/):

- `kind-resource-cluster.yaml`
- `workload-zoo.yaml`
- `challenge-validate.sh`

---

## Part 1: Install metrics-server

metrics-server ships with TLS verification enabled by default, which requires real certificates. kind uses self-signed certs, so we need to disable that check.

```bash
# Install upstream metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for kind: add --kubelet-insecure-tls to skip cert validation
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for rollout
kubectl -n kube-system rollout status deployment/metrics-server --timeout=90s
```

Now wait for metrics to populate (metrics-server collects its first scrape ~15–30 seconds after pods are running, but the API may take up to 60 seconds before it starts returning data):

```bash
# Poll until this works — it will fail briefly then succeed
kubectl top nodes
```

Expected output (values will differ):

```
NAME                          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
resource-lab-control-plane    98m          2%     610Mi           32%
resource-lab-worker           35m          0%     290Mi           15%
resource-lab-worker2          34m          0%     288Mi           15%
```

If you see `Error from server (ServiceUnavailable)`, wait 30 seconds and retry — metrics-server needs time to collect its first round of scrapes.

---

## Part 2: Read a Quiet Cluster

Before deploying any workloads, take a baseline reading.

```bash
# Node-level view
kubectl top nodes

# Pod-level view across the whole cluster
kubectl top pods --all-namespaces
```

Look at the `kube-system` pods. Note which system pods are using the most CPU and memory. You'll see `etcd`, `kube-apiserver`, `kube-controller-manager`, and now `metrics-server` itself.

```bash
# Sort system pods by memory
kubectl top pods -n kube-system --sort-by=memory
```

This is your idle baseline. Keep this window open as a reference.

---

## Part 3: Deploy the Workload Zoo

Deploy four workloads with distinct resource profiles into the `resource-lab` namespace:

| Workload | Profile | Expected top output |
|---|---|---|
| `cpu-burner` (×2 replicas) | Maxes CPU limit | ~450–500m CPU per pod |
| `memory-hog` (×1) | Holds ~250Mi RAM, near-zero CPU | ~5m CPU, ~270Mi memory |
| `idle-worker` (×3 nginx) | Nearly idle | ~1–2m CPU, ~4–8Mi memory |
| `batch-processor` (Job, ×4 tasks, 2 parallel) | Moderate CPU, completes | ~150–250m CPU while running |

```bash
kubectl apply -f starter/workload-zoo.yaml
```

Watch everything come up:

```bash
kubectl -n resource-lab get pods -w
```

The `batch-processor` Job runs moderate CPU work and completes in ~60 seconds. The other three Deployments run indefinitely. Wait until all Deployment pods are `Running` before moving to Part 4.

---

## Part 4: kubectl top pods — Core Commands

Give metrics-server a minute to collect from the new pods, then work through these commands:

**Basic view:**

```bash
kubectl top pods -n resource-lab
```

**Sort by CPU (descending):**

```bash
kubectl top pods -n resource-lab --sort-by=cpu
```

The two `cpu-burner` pods should be at the top, each near 500m. This is the most common triage command when a node shows high CPU.

**Sort by memory:**

```bash
kubectl top pods -n resource-lab --sort-by=memory
```

`memory-hog` should be at the top, far above the idle nginx pods despite having very low CPU.

**Filter by label:**

```bash
# Only the compute tier
kubectl top pods -n resource-lab -l tier=compute

# Only the web tier
kubectl top pods -n resource-lab -l tier=web
```

Label selectors let you scope top to a single service stack in a busy cluster.

**Cross-namespace view:**

```bash
kubectl top pods --all-namespaces --sort-by=cpu
```

Now you can see your `cpu-burner` pods competing with system pods for the top spots.

**Node view with context:**

```bash
kubectl top nodes
```

Compare this to the baseline from Part 2. You should see CPU% on the workers climbing due to the cpu-burner Deployment.

---

## Part 5: Requests vs Actual

Resource *requests* are what the scheduler uses to decide placement. Actual usage is what `kubectl top` shows. They are often different — understanding the gap is how you right-size workloads.

Pick one of the `cpu-burner` pods:

```bash
CPU_POD=$(kubectl get pods -n resource-lab -l app=cpu-burner -o name | head -1 | cut -d/ -f2)
echo "$CPU_POD"
```

Check its requests:

```bash
kubectl -n resource-lab describe pod "$CPU_POD" | grep -A4 "Requests:"
```

Output:
```
    Requests:
      cpu:     250m
      memory:  64Mi
```

Check its actual usage:

```bash
kubectl top pod -n resource-lab "$CPU_POD"
```

The actual CPU will be close to the limit (500m), which is **double the request**. This is how a workload can legitimately consume more than it requested — requests are a *minimum reservation*, not a *ceiling* (that's what limits are for).

Now do the same for `memory-hog`:

```bash
MEM_POD=$(kubectl get pods -n resource-lab -l app=memory-hog -o name | head -1 | cut -d/ -f2)
kubectl -n resource-lab describe pod "$MEM_POD" | grep -A4 "Requests:"
kubectl top pod -n resource-lab "$MEM_POD"
```

The memory request is 300Mi but actual usage is closer to 270Mi — the request over-provisioned slightly. CPU actual usage is nearly 0m despite a 50m request, because the workload genuinely does nothing but sleep.

**Key insight:** A cluster that appears "full" based on requests may have plenty of real headroom. A cluster that looks lightly loaded can be hitting CPU saturation. `kubectl top` tells you what is actually happening.

---

## Part 6: Observe the Batch Job Lifecycle

If the `batch-processor` Job is still running, watch its pods in top:

```bash
kubectl top pods -n resource-lab --sort-by=cpu
```

Batch pods will show moderate CPU (~150–250m each). Once the Job completes, those pods move to `Completed` status and disappear from `kubectl top` output:

```bash
kubectl -n resource-lab get pods -l app=batch-processor
kubectl top pods -n resource-lab
```

Completed pods hold no CPU or memory — resources are returned to the node immediately. This is the operational difference between a short Job and a long-running Deployment from a resource perspective.

Check Job status:

```bash
kubectl -n resource-lab describe job batch-processor | grep -E "Completions|Succeeded|Failed"
```

---

## Part 7: Graded Challenge

Answer these four questions using only `kubectl top` and `kubectl describe`. Do not look at pod YAML.

Create a file called `challenge-answers.txt` with this structure:

```text
Q1: <full pod name of the pod using the most CPU in resource-lab>
Q2: <full pod name of the pod using the most memory in resource-lab>
Q3: <yes or no — is any node above 60% CPU?>
Q4: <CPU request for cpu-burner pods, in millicores with the m suffix>
```

Example:

```text
Q1: cpu-burner-6d7f8b9c5-xk2vp
Q2: memory-hog-7c9b4d8f6-rl3wm
Q3: yes
Q4: 250m
```

Validate your answers:

```bash
bash starter/challenge-validate.sh challenge-answers.txt
```

Passing target: **4/4**.

---

## Discovery Questions

1. **Units:** A node shows `CPU(cores): 1250m`. How many full cores is that? If the node has 4 allocatable cores, what is the CPU%?

2. **Lag:** You just deployed a new CPU-intensive pod. `kubectl top pods` still doesn't show it 10 seconds later. Is this a bug? What is the metrics-server scrape interval and why does it matter?

3. **Limits vs Requests:** The `cpu-burner` pod has a request of 250m and a limit of 500m. If the node has no other workloads, will `kubectl top` show 250m or 500m (or something else)? Why?

4. **Memory growth:** A pod starts showing steadily increasing memory in `kubectl top` over 30 minutes without any corresponding increase in traffic. What should you suspect, and what command would you run next?

5. **Missing from top:** A pod is in `Running` state but never appears in `kubectl top pods`. What are two possible explanations?

---

## Cleanup

```bash
kubectl config use-context kind-lab 2>/dev/null || true
kind delete cluster --name resource-lab
rm -f /tmp/kind-resource.yaml
```

---

## Key Takeaways

- `kubectl top` requires metrics-server; in kind, patch it with `--kubelet-insecure-tls`
- CPU is in millicores (`m`), memory in `Mi`/`Gi`; `%` on nodes is relative to allocatable, not raw capacity
- `--sort-by=cpu` and `--sort-by=memory` are the fastest path to finding resource hogs
- Requests are scheduling reservations; actual usage can be higher (up to the limit) or much lower
- Completed Job pods disappear from `kubectl top` — resources are released immediately
- Use label selectors (`-l tier=compute`) to scope top to a single service in a crowded namespace

---

## Reinforcement Scenarios

- `27-jerry-resource-hog-hunt` — identify and evict a CPU-hungry pod under time pressure
- `28-jerry-hpa-not-scaling` — metrics-server missing or broken; HPA cannot scale
- `jerry-hpa-not-scaling` (gym) — HPA troubleshooting starting from a dead metrics-server
