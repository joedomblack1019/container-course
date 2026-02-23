---
theme: default
title: Week 08 Lab 06 - HA Control Plane Design and Simulation
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 06 · HA Control Plane Design and Simulation"
---

# HA Control Plane Design and Simulation
## Lab 06

- Build 3-control-plane kind topology with 2 workers
- Inspect etcd membership and quorum requirements
- Simulate one control-plane failure and validate continuity
- Recover failed node and document HA incident runbook

---
layout: win95
windowTitle: "Quorum Math"
windowIcon: "🧮"
statusText: "Week 08 · Lab 06 · etcd majority requirements"
---

## Tolerated Failures by Member Count

| etcd members | Quorum | Tolerated failures |
|---|---|---|
| 3 | 2 | 1 |
| 5 | 3 | 2 |

> Writes require quorum; without it, control-plane state changes become unsafe/unavailable.

---
layout: win95-terminal
termTitle: "Command Prompt — create HA simulation cluster"
---

<Win95Terminal
  title="Command Prompt — cluster bring-up"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' > /tmp/kind-ha.yaml' },
    { type: 'input', text: 'kind: Cluster  # name ha, 3 control-plane + 2 worker nodes' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kind create cluster --name ha --config /tmp/kind-ha.yaml' },
    { type: 'input', text: 'kubectl config use-context kind-ha' },
    { type: 'input', text: 'kubectl get nodes -o wide' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — inspect control plane and etcd"
---

<Win95Terminal
  title="Command Prompt — quorum inspection"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n kube-system get pods -o wide | grep -E \'etcd|kube-apiserver|kube-controller-manager|kube-scheduler\'' },
    { type: 'input', text: 'for pod in $(kubectl -n kube-system get pods -l component=etcd -o name); do echo &quot;=== $pod ===&quot;; kubectl -n kube-system exec &quot;${pod#pod/}&quot; -- sh -c \'ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list | head -5\'; done' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — simulate failure and recover"
---

<Win95Terminal
  title="Command Prompt — failure drill"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker ps --format \'{{.Names}}\' | grep \'^ha-\'' },
    { type: 'input', text: 'docker stop ha-control-plane2' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl create namespace ha-lab' },
    { type: 'input', text: 'kubectl -n ha-lab create deployment smoke --image=nginx:1.27 --replicas=2' },
    { type: 'input', text: 'kubectl -n ha-lab rollout status deploy/smoke' },
    { type: 'input', text: 'docker start ha-control-plane2' },
    { type: 'input', text: 'kubectl get nodes -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — stabilization checks and cleanup"
---

<Win95Terminal
  title="Command Prompt — closeout"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n kube-system get pods -o wide | grep control-plane2' },
    { type: 'input', text: 'kubectl config use-context kind-lab || true' },
    { type: 'input', text: 'kind delete cluster --name ha' },
    { type: 'input', text: 'rm -f /tmp/kind-ha.yaml' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 06 — Key Commands"
windowIcon: "📋"
statusText: "Week 08 · Lab 06 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind create cluster --name ha --config /tmp/kind-ha.yaml` | Create HA simulation cluster |
| `kubectl config use-context kind-ha` | Switch kubeconfig context |
| `kubectl -n kube-system get pods -o wide | grep -E 'etcd|kube-apiserver|kube-controller-manager|kube-scheduler'` | Inspect control-plane pods |
| `ETCDCTL_API=3 etcdctl ... member list` | Check etcd membership/quorum evidence |
| `docker stop ha-control-plane2` | Simulate control-plane node failure |
| `kubectl -n ha-lab create deployment smoke --image=nginx:1.27 --replicas=2` | Verify continuity under single-node failure |
| `docker start ha-control-plane2` | Recover failed control-plane node |
| `kubectl get nodes -w` | Watch node return to Ready |
| `kind delete cluster --name ha` | Cleanup HA cluster |
