---
theme: default
title: Week 07 Lab 06 - Scheduling Constraints Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 06 · Scheduling Constraints"
---

# Scheduling Constraints Deep Dive
## Lab 06

- Control placement with nodeSelector and nodeAffinity
- Enforce node admission with taints and tolerations
- Spread replicas with anti-affinity and topology constraints
- Diagnose impossible scheduling and recover quickly

---
layout: win95
windowTitle: "Constraint Types"
windowIcon: "🧭"
statusText: "Week 07 · Lab 06 · Scheduler controls"
---

## Control Surfaces

| Type | Driven by | Typical use |
|---|---|---|
| Taints/tolerations | node policy | reserve special nodes / maintenance |
| Node affinity | pod intent | require or prefer labeled nodes |
| Pod anti-affinity | pod-to-pod rules | avoid co-location for HA |
| Topology spread | distribution goal | keep replicas balanced per domain |

---
layout: win95-terminal
termTitle: "Command Prompt — cluster setup and nodeSelector"
---

<Win95Terminal
  title="Command Prompt — baseline scheduling"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd starter/' },
    { type: 'input', text: 'kind create cluster --config=kind-scheduling-cluster.yaml --name=scheduling' },
    { type: 'input', text: 'kubectl config use-context kind-scheduling' },
    { type: 'input', text: './setup-labels.sh' },
    { type: 'input', text: 'kubectl get nodes --show-labels' },
    { type: 'input', text: 'kubectl label nodes scheduling-worker environment=production' },
    { type: 'input', text: 'kubectl label nodes scheduling-worker2 environment=staging' },
    { type: 'input', text: 'kubectl label nodes scheduling-worker3 environment=development' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — affinity required vs preferred"
---

<Win95Terminal
  title="Command Prompt — affinity behavior"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f starter/nodeaffinity-required.yaml' },
    { type: 'input', text: 'kubectl apply -f starter/nodeaffinity-preferred.yaml' },
    { type: 'input', text: 'kubectl get pods -l app=affinity-required -o wide' },
    { type: 'input', text: 'kubectl label nodes scheduling-worker environment-' },
    { type: 'input', text: 'kubectl scale deployment affinity-required --replicas=3' },
    { type: 'input', text: 'kubectl get pods -l app=affinity-required' },
    { type: 'input', text: 'kubectl label nodes scheduling-worker environment=production' },
    { type: 'input', text: 'kubectl describe pod -l app=affinity-required | grep -A5 -B5 Events' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — taints and tolerations"
---

<Win95Terminal
  title="Command Prompt — taint effects"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints' },
    { type: 'input', text: 'kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule --overwrite' },
    { type: 'input', text: 'kubectl apply -f - <<\'EOF\'  # pod no-toleration pinned to scheduling-worker2' },
    { type: 'input', text: 'kubectl describe pod no-toleration | grep -A8 Events' },
    { type: 'input', text: 'kubectl apply -f - <<\'EOF\'  # pod with-toleration' },
    { type: 'input', text: 'kubectl apply -f - <<\'EOF\'  # pod with-exists-operator' },
    { type: 'input', text: 'kubectl taint nodes scheduling-worker maintenance=true:NoExecute --overwrite' },
    { type: 'input', text: 'kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule-; kubectl taint nodes scheduling-worker maintenance=true:NoExecute-' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — anti-affinity, spread, and failure triage"
---

<Win95Terminal
  title="Command Prompt — distribution controls"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f starter/pod-antiaffinity.yaml' },
    { type: 'input', text: 'kubectl scale deployment distributed-service --replicas=5' },
    { type: 'input', text: 'kubectl describe pod -l app=distributed-service | grep -A10 Events' },
    { type: 'input', text: 'kubectl apply -f starter/topology-spread.yaml' },
    { type: 'input', text: 'kubectl get pods -l app=spread-demo -o wide | awk \'{print $7}\' | sort | uniq -c' },
    { type: 'input', text: 'kubectl apply -f - <<\'EOF\'  # impossible-pod with required impossible-label' },
    { type: 'input', text: 'kubectl describe pod impossible-pod' },
    { type: 'input', text: 'kubectl label nodes scheduling-worker impossible-label=does-not-exist' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — final cleanup"
---

<Win95Terminal
  title="Command Prompt — cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind delete cluster --name=scheduling' },
    { type: 'input', text: 'kubectl config use-context kind-lab' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 06 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 06 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind create cluster --config=kind-scheduling-cluster.yaml --name=scheduling` | Create multi-node scheduling lab cluster |
| `./setup-labels.sh` | Seed node labels/taints for exercises |
| `kubectl apply -f starter/nodeaffinity-required.yaml` | Deploy hard-affinity workload |
| `kubectl apply -f starter/nodeaffinity-preferred.yaml` | Deploy soft-affinity workload |
| `kubectl taint nodes scheduling-worker2 workload=gpu:NoSchedule --overwrite` | Add hard scheduling taint |
| `kubectl describe pod no-toleration` | Verify taint-based scheduling failure |
| `kubectl apply -f starter/pod-antiaffinity.yaml` | Enforce one-per-node style distribution |
| `kubectl apply -f starter/topology-spread.yaml` | Apply topology spread constraints |
| `kubectl describe pod impossible-pod` | Diagnose unschedulable pod |
| `kubectl label nodes scheduling-worker impossible-label=does-not-exist` | Satisfy impossible affinity rule |
| `kind delete cluster --name=scheduling` | Cleanup scheduling cluster |
