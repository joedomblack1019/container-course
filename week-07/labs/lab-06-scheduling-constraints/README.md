![Lab 06 Scheduling Constraints Deep Dive](../../../assets/generated/week-07-lab-06/hero.png)
![Lab 06 affinity taint toleration workflow](../../../assets/generated/week-07-lab-06/flow.gif)

---

# Lab 6: Scheduling Constraints Deep Dive

**Time:** 55 minutes
**Objective:** Control pod placement using taints/tolerations, nodeAffinity, podAntiAffinity, and topologySpreadConstraints — and diagnose pods that are stuck Pending because the constraints cannot be satisfied.

---

## The Story

Your cluster has four worker nodes. Three are general-purpose compute. One has a GPU card and is reserved for ML inference jobs. The platform team labelled that node and walked away. A week later, Jerry deploys his new inference service — except he forgets the toleration. The pod lands on a general-purpose node, maxes out CPU, and takes down two unrelated services.

Meanwhile, someone else deployed a critical API without any spread constraints. Both replicas landed on the same node. The node goes down. The API goes down. Half the team finds out via a customer escalation.

Neither of these required a cluster bug. They required knowing how to tell the scheduler what you actually want.

This lab covers every scheduling control surface you will encounter on the CKA and in production: node selectors for simple label matching, nodeAffinity for expressive hard and soft rules, taints and tolerations for node-driven access control, podAntiAffinity for separation guarantees, and topologySpreadConstraints for balanced distribution.

---

## CKA Objectives Mapped

- Configure pod admission and scheduling (node affinity, node selector)
- Use taints and tolerations to control scheduling
- Troubleshoot application failures caused by scheduling constraints
- Understand `Pending` pod diagnosis via `kubectl describe`

---

## Background: How the Scheduler Places Pods

### The scheduling pipeline

When you create a pod, the scheduler runs it through two phases before assigning it to a node:

**Filtering** removes nodes that cannot host the pod — insufficient CPU, memory, missing labels, active taints the pod does not tolerate, etc. Any node that fails a filter is excluded entirely.

**Scoring** ranks the remaining eligible nodes. The scheduler applies weighted scoring rules (resource balance, affinity preferences, topology spread) and picks the highest-scoring node.

If filtering removes all nodes, the pod stays `Pending`. The scheduler logs a reason, and `kubectl describe pod` surfaces it in the Events section. That is your diagnostic entry point.

```
New Pod
  │
  ▼
┌─────────────────────────────────────────┐
│              FILTERING                  │
│  - Enough CPU/memory?                   │
│  - Required nodeAffinity satisfied?     │
│  - Toleration for node taints?          │
│  - No conflicting podAntiAffinity?      │
│  - topologySpreadConstraints feasible?  │
└──────────────┬──────────────────────────┘
               │ eligible nodes remain
               ▼
┌─────────────────────────────────────────┐
│               SCORING                   │
│  - Preferred nodeAffinity weight        │
│  - Resource balance                     │
│  - Spread preferences                   │
└──────────────┬──────────────────────────┘
               │ highest-scoring node wins
               ▼
            Assigned
```

### Two control surfaces

Kubernetes gives you two distinct ways to influence scheduling, and they solve different problems:

**Node-driven: taints and tolerations.** The node declares restrictions. Pods must carry a matching toleration to be allowed. This is the right tool for dedicated capacity (GPU nodes, bare-metal nodes, licensed software nodes) and for lifecycle signals like maintenance (`kubectl drain` uses `NoExecute` taints to evict workloads before a node goes offline).

**Pod-driven: affinity rules.** The workload declares where it wants to run relative to node labels or other pods. This is the right tool for encoding topology intent — "I need to run near a specific hardware tier" or "my replicas must never share a node."

### Taint effects

| Effect | Blocks new scheduling? | Evicts existing pods? |
|---|---|---|
| `NoSchedule` | Yes (hard) | No |
| `PreferNoSchedule` | Soft (scheduler avoids but can break) | No |
| `NoExecute` | Yes (hard) | Yes — pods without matching toleration are evicted |

`NoExecute` is what Kubernetes uses internally when a node becomes `NotReady`. The node controller adds a `node.kubernetes.io/not-ready:NoExecute` taint, which evicts pods that do not tolerate it — which is most pods, by design.

### Affinity modes

`requiredDuringSchedulingIgnoredDuringExecution` is a hard gate. The pod stays `Pending` forever if no node satisfies it. `IgnoredDuringExecution` means that if a node's labels change after the pod is already running, the pod is not evicted — the constraint was only enforced at scheduling time.

`preferredDuringSchedulingIgnoredDuringExecution` adds a weighted preference. If a preferred node is available, the scheduler favors it. If not, the pod still lands somewhere — it does not block.

### Anti-affinity vs topology spread

`podAntiAffinity` with `required` says "never co-locate these pods on the same topology key." That is a hard constraint and can deadlock scheduling if the cluster is too small — if you have 3 nodes and 4 replicas with strict anti-affinity, the 4th pod is permanently Pending.

`topologySpreadConstraints` targets a maximum **imbalance** (maxSkew) rather than a strict separation. It is usually a better fit for HA because it keeps scheduling progressing while still controlling concentration.

**When to use which:**

- `nodeSelector` — simple label match, no soft behavior needed
- `nodeAffinity` — expressive operators (`In`, `NotIn`, `Exists`), hard/soft behavior
- Taints + tolerations — node declares who is allowed (dedicated nodes, maintenance)
- `podAntiAffinity` — strict separation is more important than utilization
- `topologySpreadConstraints` — balanced distribution is the primary goal

**Further reading:**
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)

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

`nodeSelector` is the bluntest tool in the box — exact label match, hard constraint, no soft fallback. Use it when you need simple targeting and nothing else.

```bash
kubectl label nodes scheduling-worker environment=production
kubectl label nodes scheduling-worker2 environment=staging
kubectl label nodes scheduling-worker3 environment=development
```

Deploy with `nodeSelector`:

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

kubectl get pods -o wide
```

Scale beyond what one node can absorb:

```bash
kubectl scale deployment prod-app --replicas=6
kubectl get pods -o wide
```

Notice: some pods will be `Pending`. They are not stuck because of a bug — they are stuck because the only eligible node (`scheduling-worker`) is at capacity (the cluster config sets `max-pods: 6` on this node, and ~2 system pods are already running there) and there are no other nodes that match the selector. Check the events to confirm:

```bash
kubectl describe pod -l app=prod-app | grep -A5 Events
```

The event reason will be `Insufficient pods` / `Too many pods` — the scheduler filtered out `scheduling-worker` because it is full, and no other node carries the `environment=production` label.

Operator mindset: if a pod is `Pending`, treat it as scheduler feedback and read Events first; do not patch manifests until you see the failed predicate.

---

## Part 2: Node Affinity — Required vs Preferred

`nodeAffinity` gives you expressive matching operators and the ability to distinguish between hard requirements and weighted preferences.

**Required affinity** (hard gate — pod stays Pending if unsatisfied):

```bash
kubectl apply -f starter/nodeaffinity-required.yaml
kubectl get pods -l app=affinity-required -o wide
```

Open the YAML and find `requiredDuringSchedulingIgnoredDuringExecution`. That is the hard mode selector.

**Preferred affinity** (soft — pod lands somewhere even if the preference is unavailable):

```bash
kubectl apply -f starter/nodeaffinity-preferred.yaml
kubectl get pods -l app=affinity-preferred -o wide
```

Now break the required affinity by removing the label the required rule depends on:

```bash
kubectl label nodes scheduling-worker environment-
kubectl scale deployment affinity-required --replicas=3
kubectl get pods -l app=affinity-required
```

Notice: new pods are `Pending`. The hard gate cannot be satisfied — there is no node with `environment=production` anymore. The preferred-only pods are still running because their constraint was never a gate.

```bash
kubectl describe pod -l app=affinity-required | grep -A8 Events
```

Restore the label and watch the Pending pods schedule:

```bash
kubectl label nodes scheduling-worker environment=production
kubectl get pods -l app=affinity-required -o wide -w
```

Operator mindset: if label lifecycle is not tightly managed, use preferred affinity; reserve required affinity for truly non-negotiable placement rules.

---

## Part 2.5: Taints and Tolerations

Taints are the node's side of the conversation. The node declares "only pods that explicitly tolerate me are welcome here." This is how you reserve nodes for specific workloads without relying on pods correctly setting affinity rules.

Check the current taints (the setup script pre-taints one node):

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

Apply a hard taint on `scheduling-worker2` to simulate a GPU-reserved node:

```bash
kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule --overwrite
```

Deploy a pod targeting that node without any toleration:

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

kubectl get pods -o wide
kubectl describe pod no-toleration | grep -A8 Events
```

Notice: the pod is `Pending` even though it has an explicit `nodeSelector` pointing at `scheduling-worker2`. The taint blocks it regardless. This is exactly the scenario from the story — Jerry's inference pod landing on the wrong node is prevented when the GPU node is properly tainted, but only if he is also required to add the toleration.

Now deploy with a matching toleration:

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

kubectl get pods -o wide
```

Try the `Exists` operator (tolerate any value for the key):

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

kubectl get pods -o wide
```

Now observe `NoExecute` — which evicts running pods:

```bash
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

Press `Ctrl+C` after the pod terminates.

Notice: `NoExecute` did what `NoSchedule` does not — it evicted a pod that was already running. This is how `kubectl drain` works under the hood: it adds a `NoExecute` taint to the node, which causes Kubernetes to evict all pods that lack a matching toleration, clearing the node before maintenance.

Remove all taints before continuing:

```bash
kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule-
kubectl taint nodes scheduling-worker maintenance=true:NoExecute-
```

Ordering rule: taints protect nodes from workloads that do not belong there, but they only prevent placement when applied before scheduling.

---

## Part 3: Pod Anti-Affinity for Separation

Hard pod anti-affinity enforces a strict "no two of these pods on the same node" rule. It is the right tool when availability requires physical separation — for example, you cannot afford to lose two replicas of a service to a single node failure.

```bash
kubectl apply -f starter/pod-antiaffinity.yaml
kubectl get pods -l app=distributed-service -o wide
```

Check the anti-affinity rule in the YAML. The `topologyKey: kubernetes.io/hostname` means "treat each unique hostname as a distinct topology zone — at most one pod per zone."

Scale beyond the number of nodes:

```bash
kubectl scale deployment distributed-service --replicas=5
kubectl get pods -l app=distributed-service -o wide
```

Notice: you have 3-4 nodes but you asked for 5 replicas. The 4th or 5th pod is `Pending` — there are no eligible nodes left because every node already has one copy of this pod, and hard anti-affinity forbids a second.

```bash
kubectl describe pod -l app=distributed-service | grep -A10 Events
```

Look for "didn't match pod anti-affinity rules" in the events. This is the deadlock risk with hard anti-affinity — if you need more replicas than you have nodes, scaling is permanently blocked.

Capacity rule: plan hard anti-affinity with replica ceilings. If replicas can exceed eligible nodes, prefer topology spread to avoid deadlock.

---

## Part 4: Topology Spread Constraints

`topologySpreadConstraints` distributes pods across topology zones (nodes, availability zones, regions) within a defined skew tolerance. It is usually a better fit than hard anti-affinity for HA because it keeps scaling progressing rather than deadlocking.

```bash
kubectl apply -f starter/topology-spread.yaml
kubectl get pods -l app=spread-demo -o wide
```

Check the distribution across nodes:

```bash
kubectl get pods -l app=spread-demo -o wide | awk '{print $7}' | sort | uniq -c
```

Scale up and watch the spread behavior:

```bash
kubectl scale deployment spread-demo --replicas=9
kubectl get pods -l app=spread-demo -o wide | awk '{print $7}' | sort | uniq -c
```

Notice: with `maxSkew: 1`, the scheduler tries to keep node pod counts within 1 of each other. With 3 nodes and 9 pods, you should see 3-3-3. With 9 pods and 4 nodes, you will see a 3-2-2-2 or 3-3-2-1 distribution depending on existing placement.

Push replicas high enough that the spread constraint cannot be satisfied:

```bash
kubectl scale deployment spread-demo --replicas=15
kubectl get pods -l app=spread-demo
```

Notice: `whenUnsatisfiable: DoNotSchedule` means any pod that cannot be placed without violating `maxSkew` stays `Pending` rather than landing somewhere that breaks the spread. This is preferable to silently concentrating pods — you want to know when your cluster needs more capacity.

Capacity signal: topology spread with `DoNotSchedule` exposes real capacity limits. If pods are Pending, confirm intent, then add capacity or adjust SLOs deliberately.

---

## Part 5: Combined Scheduling (Production Pattern)

Real production workloads often combine multiple constraints. This is what the web tier of a properly architected system looks like:

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
      # Hard: only run on compute nodes
      # Soft: prefer production-labelled compute nodes
      affinity:
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
      # Balance replicas evenly across compute nodes
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

Label the nodes to match the affinity rules:

```bash
kubectl label nodes scheduling-worker node-role=compute
kubectl label nodes scheduling-worker2 node-role=compute
kubectl label nodes scheduling-worker3 node-role=storage
```

```bash
kubectl get pods -l app=web-tier -o wide
```

Notice: all pods land on `scheduling-worker` and `scheduling-worker2` (the compute nodes), and they are balanced across those two nodes. `scheduling-worker3` is excluded by the required affinity even though it has available capacity. This is the correct behavior — compute workloads should not spill onto storage nodes.

Operating model: scheduling constraints are a contract between platform labels and application affinity rules; both must stay aligned.

---

## Part 6: Troubleshooting Scheduling Failures

The diagnostic workflow for a `Pending` pod is always the same: `kubectl describe pod`, read the Events section, find the scheduling failure reason, trace it back to the constraint or resource that is blocking placement.

Create an impossible scheduling scenario:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: impossible-pod
spec:
  affinity:
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

Diagnose it:

```bash
kubectl get pod impossible-pod
kubectl describe pod impossible-pod
kubectl logs -n kube-system -l component=kube-scheduler --tail=20
```

Notice: the Events section in `describe` will show "0/4 nodes are available: 4 node(s) didn't match Pod's node affinity/selector." That tells you the filter that blocked it. The scheduler logs show the same information at a lower level. On the CKA you will primarily use `kubectl describe` — the scheduler logs are a deeper fallback.

Fix it by adding the required label to a node:

```bash
kubectl label nodes scheduling-worker impossible-label=does-not-exist
kubectl get pod impossible-pod -o wide -w
```

Operator mindset: if a pod is unschedulable, start with the Events block before changing labels, taints, or affinity; the scheduler already names the blocking rule.

---

## Verification Checklist

You are done when:

- `nodeSelector` restricts pods to labelled nodes and leaves others Pending
- Required `nodeAffinity` leaves pods Pending when no node matches
- Preferred `nodeAffinity` still places pods when the preference is unavailable
- `NoSchedule` taint blocks new scheduling without a matching toleration
- `NoExecute` taint evicts running pods that do not tolerate it
- You can add and remove taints with `kubectl taint`
- Hard `podAntiAffinity` puts pods Pending when no eligible node remains
- `topologySpreadConstraints` distributes pods with a defined maxSkew
- You can diagnose any Pending pod using `kubectl describe` and read the scheduler's reason

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
