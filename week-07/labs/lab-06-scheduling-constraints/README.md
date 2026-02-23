![Lab 06 Scheduling Constraints Deep Dive](../../../assets/generated/week-07-lab-06/hero.png)
![Lab 06 affinity taint toleration workflow](../../../assets/generated/week-07-lab-06/flow.gif)

---

# Lab 6: Scheduling Constraints Deep Dive

**Time:** 55 minutes
**Objective:** Control pod scheduling using taints/tolerations, nodeAffinity, podAntiAffinity, and topologySpreadConstraints to achieve optimal placement and distribution.

---

## CKA Objectives Mapped

- Configure Pod admission and scheduling (limits, node affinity, etc.)
- Understand scheduling constraints and node selectors
- Troubleshoot application failure (scheduling issues)

---

## Background: How the Scheduler Makes Decisions

As covered in the week overview, the scheduler places pods based on resource availability by default, then ranks eligible nodes with scoring rules. Without extra constraints, it treats nodes as mostly interchangeable and does not infer your failure domains, hardware tiers, compliance boundaries, or workload intent. That default is fine for simple workloads, but production systems usually need explicit placement rules.

Kubernetes gives you two different control surfaces that solve different problems. Taints and tolerations are node-driven: the node declares who is allowed, and pods need matching tolerations to land there, which is ideal for dedicated capacity like GPU or special hardware nodes and for lifecycle signals like maintenance. Affinity and anti-affinity are pod-driven: the workload declares where it prefers or requires placement relative to node labels or other pods, which is how you encode topology and availability intent in app manifests.

Taint effects define how strongly the node pushes workloads away. `NoSchedule` blocks new pods without a matching toleration but leaves existing pods alone, `PreferNoSchedule` is a soft avoidance signal the scheduler can break if needed, and `NoExecute` blocks new placements and evicts existing non-tolerating pods. That last behavior is why `NoExecute` appears in node-health scenarios when Kubernetes needs to clear unhealthy placements.

Affinity rules also split into hard and soft modes. `requiredDuringSchedulingIgnoredDuringExecution` is a hard gate and leaves a pod Pending forever if no node matches, while `preferredDuringSchedulingIgnoredDuringExecution` adds weighted preferences that improve placement but still allow fallback when the preferred condition is unavailable. `IgnoredDuringExecution` means label changes after startup do not automatically evict already-running pods.

For spreading, `podAntiAffinity` and `topologySpreadConstraints` look similar but behave differently under pressure. Hard anti-affinity says "never co-locate these replicas on the same topology key," which can deadlock scheduling if the cluster is too small. Topology spread instead targets balanced counts within a skew threshold, which is usually a better fit for HA because it can keep placements progressing while still controlling concentration. The official scheduler docs are the best deep reference for all of these knobs: https://kubernetes.io/docs/concepts/scheduling-eviction/.

Use `nodeSelector` when you just need exact label matching and nothing else. Use `nodeAffinity` when you need expressive operators and hard-versus-soft behavior. Use taints and tolerations when nodes must reserve capacity or enforce lifecycle restrictions. Use `podAntiAffinity` when strict separation is more important than utilization. Use `topologySpreadConstraints` when balanced distribution across nodes or zones is the primary goal.

---

## Prerequisites

Create a multi-node kind cluster for this lab:

```bash
cd starter/
kind create cluster --config=kind-scheduling-cluster.yaml --name=scheduling
kubectl config use-context kind-scheduling
```

Set up node labels for scheduling tests:

```bash
./setup-labels.sh
kubectl get nodes --show-labels
```

Starter assets for this lab are in [`starter/`](./starter/):

- `kind-scheduling-cluster.yaml`
- `setup-labels.sh`
- `nodeaffinity-required.yaml`
- `nodeaffinity-preferred.yaml`
- `pod-antiaffinity.yaml`
- `topology-spread.yaml`

---

## Part 1: Node Selector (Simplest Scheduling)

Start with the most basic form of node targeting:

```bash
kubectl label nodes scheduling-worker environment=production
kubectl label nodes scheduling-worker2 environment=staging
kubectl label nodes scheduling-worker3 environment=development
```

Deploy with nodeSelector:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: prod-app
  template:
    metadata:
      labels:
        app: prod-app
    spec:
      nodeSelector:
        environment: production
      containers:
      - name: nginx
        image: nginx:1.20
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
EOF
```

Observe the scheduling:

```bash
kubectl get pods -o wide
```

Expected: All `prod-app` pods are on the `production` node.

Try scaling beyond node capacity:

```bash
kubectl scale deployment prod-app --replicas=6
kubectl get pods -o wide
```

Some pods will be Pending if the production node is resource-constrained.

---

## Part 2: Node Affinity - Required vs Preferred

**Required affinity** (hard constraint):

```bash
kubectl apply -f starter/nodeaffinity-required.yaml
kubectl get pods -l app=affinity-required -o wide
```

Check the YAML to see `requiredDuringSchedulingIgnoredDuringExecution`.

**Preferred affinity** (soft constraint):

```bash
kubectl apply -f starter/nodeaffinity-preferred.yaml
kubectl get pods -l app=affinity-preferred -o wide
```

Break the required affinity by removing the target label:

```bash
kubectl label nodes scheduling-worker environment-
kubectl scale deployment affinity-required --replicas=3
kubectl get pods -l app=affinity-required
```

Expected: New pods stay Pending because required affinity can't be satisfied.

Restore the label:

```bash
kubectl label nodes scheduling-worker environment=production
kubectl get pods -l app=affinity-required -o wide
```

Check scheduling events:

```bash
kubectl describe pod -l app=affinity-required | grep -A5 -B5 Events
```

---

## Part 2.5: Taints and Tolerations

`setup-labels.sh` pre-taints one node so you start with a realistic scheduler constraint:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

Apply (or re-apply) a hard taint on one worker:

```bash
kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule --overwrite
```

Deploy a pod pinned to the tainted node without any toleration:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: no-toleration
spec:
  nodeSelector:
    kubernetes.io/hostname: scheduling-worker2
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Observe scheduling:

```bash
kubectl get pods -o wide
kubectl describe pod no-toleration | grep -A8 Events
```

Expected: Pod stays `Pending` because it does not tolerate `workload=gpu:NoSchedule`.

Deploy with a matching toleration:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: with-toleration
spec:
  nodeSelector:
    kubernetes.io/hostname: scheduling-worker2
  tolerations:
  - key: "workload"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Verify it can schedule on the tainted node:

```bash
kubectl get pods -o wide
```

Now tolerate any value for the key using `Exists`:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: with-exists-operator
spec:
  nodeSelector:
    kubernetes.io/hostname: scheduling-worker2
  tolerations:
  - key: "workload"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Verify:

```bash
kubectl get pods -o wide
```

Quick taint effect drill:

```bash
# PreferNoSchedule: scheduler tries to avoid but may still place pods there
kubectl taint nodes scheduling-worker3 workload=batch:PreferNoSchedule --overwrite

# NoExecute: existing pods without tolerations get evicted
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: noexecute-demo
spec:
  nodeSelector:
    kubernetes.io/hostname: scheduling-worker
  containers:
  - name: nginx
    image: nginx:1.20
EOF
kubectl get pod noexecute-demo -o wide
kubectl taint nodes scheduling-worker maintenance=true:NoExecute --overwrite
kubectl get pod noexecute-demo -w
```

Press `Ctrl+C` after you see eviction/termination events.

Expected:
- `NoSchedule`: blocks new scheduling without matching toleration
- `PreferNoSchedule`: soft preference to avoid node
- `NoExecute`: evicts existing non-tolerating pods

Remove taints when done:

```bash
kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule-
kubectl taint nodes scheduling-worker3 workload=batch:PreferNoSchedule-
kubectl taint nodes scheduling-worker maintenance=true:NoExecute-
```

---

## Part 3: Pod Anti-Affinity for Distribution

Deploy a service that should spread across nodes:

```bash
kubectl apply -f starter/pod-antiaffinity.yaml
kubectl get pods -l app=distributed-service -o wide
```

Check the anti-affinity rules in the YAML:

```yaml
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app
        operator: In
        values:
        - distributed-service
    topologyKey: kubernetes.io/hostname
```

Scale beyond the number of nodes:

```bash
kubectl scale deployment distributed-service --replicas=5
kubectl get pods -l app=distributed-service -o wide
```

Expected: Only 3-4 pods Running (one per node), remaining pods Pending due to anti-affinity.

Inspect the Pending pod:

```bash
kubectl describe pod -l app=distributed-service | grep -A10 Events
```

Look for "didn't match pod anti-affinity rules" in the events.

---

## Part 4: Topology Spread Constraints

Deploy with topology spread to balance distribution:

```bash
kubectl apply -f starter/topology-spread.yaml
kubectl get pods -l app=spread-demo -o wide
```

Check the distribution:

```bash
kubectl get pods -l app=spread-demo -o wide | awk '{print $7}' | sort | uniq -c
```

Scale up and observe the spreading behavior:

```bash
kubectl scale deployment spread-demo --replicas=9
kubectl get pods -l app=spread-demo -o wide | awk '{print $7}' | sort | uniq -c
```

The `maxSkew: 1` setting tries to keep node counts within 1 of each other.

Demonstrate `whenUnsatisfiable: DoNotSchedule` vs `ScheduleAnyway`:

```bash
kubectl scale deployment spread-demo --replicas=15
kubectl get pods -l app=spread-demo
```

Some pods may be Pending if the spread constraint cannot be satisfied.

---

## Part 5: Combined Scheduling Patterns

Create a realistic production scenario combining multiple constraints:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-tier
spec:
  replicas: 4
  selector:
    matchLabels:
      app: web-tier
  template:
    metadata:
      labels:
        app: web-tier
        tier: frontend
    spec:
      # Only schedule on compute nodes
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: node-role
              operator: In
              values: ["compute"]
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
            - key: environment
              operator: In
              values: ["production"]

      # Spread across nodes for HA
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web-tier

      containers:
      - name: nginx
        image: nginx:1.20
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
```

Label nodes appropriately:

```bash
kubectl label nodes scheduling-worker node-role=compute
kubectl label nodes scheduling-worker2 node-role=compute
kubectl label nodes scheduling-worker3 node-role=storage
```

Observe the scheduling:

```bash
kubectl get pods -l app=web-tier -o wide
```

Expected: Pods scheduled only on `compute` nodes, spread evenly.

---

## Part 6: Troubleshooting Scheduling Failures

Intentionally create an impossible scheduling scenario:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: impossible-pod
spec:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: impossible-label
          operator: In
          values: ["does-not-exist"]
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Diagnose the scheduling failure:

```bash
kubectl get pod impossible-pod
kubectl describe pod impossible-pod
```

Check scheduler logs (in kind, the scheduler runs as a pod):

```bash
kubectl logs -n kube-system -l component=kube-scheduler --tail=20
```

Fix by either:
1. Adding the required label to a node
2. Modifying the affinity rule

```bash
kubectl label nodes scheduling-worker impossible-label=does-not-exist
kubectl get pod impossible-pod -o wide
```

---

## Validation Checklist

You are done when:

- nodeSelector restricts pods to labeled nodes
- Required nodeAffinity prevents scheduling when labels are missing
- Taints prevent scheduling without matching tolerations
- `NoExecute` evicts running pods that do not tolerate the taint
- You can add and remove taints with `kubectl taint`
- podAntiAffinity spreads replicas across different nodes
- topologySpreadConstraints balance pod distribution with maxSkew
- You can diagnose and fix scheduling failures using `kubectl describe`

---

## Cleanup

```bash
kind delete cluster --name=scheduling
kubectl config use-context kind-lab
```

---

## Reinforcement Scenarios

- `jerry-pod-wont-spread`
- `jerry-affinity-mismatch`
- `jerry-pod-unschedulable-taint`
