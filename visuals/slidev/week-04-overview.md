---
theme: default
title: Week 04 - Kubernetes Architecture and First Deployment
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Week 04 · Kubernetes Architecture"
---

# Kubernetes Architecture
## Week 04

- Move from Docker Compose to Kubernetes control loops
- Deploy, scale, update, and debug workloads with `kubectl`
- Practice GitOps, kubeadm, RBAC, PSA, and extension interfaces

---
layout: win95
windowTitle: "Lab 01 — kind Cluster & Exploration"
windowIcon: "☸"
statusText: "Week 04 · Lab 01 · Local + shared cluster contexts"
---

## Lab 01 Focus

- Create `kind-lab` and inspect control-plane components
- Learn `kubectl get/describe/api-resources`
- Connect to shared `ziyotek-prod` context through `cloudflared`

---
layout: win95
windowTitle: "Lab 02 — Deploy, Scale, Update, Debug"
windowIcon: "🚀"
statusText: "Week 04 · Lab 02 · Deployment workflow"
---

## Lab 02 Focus

- Build `student-app:v4`, load into kind, apply Deployment + Service
- Scale to 3 replicas, observe self-healing and load balancing
- Perform rollout update/undo and debug `ImagePullBackOff` and `CrashLoopBackOff`

---
layout: win95
windowTitle: "Lab 03 — Deploy to Dev via GitOps"
windowIcon: "🔄"
statusText: "Week 04 · Lab 03 · PR-driven delivery"
---

## Lab 03 Focus

- Push image to GHCR and scaffold manifests with `kubectl create --dry-run`
- Add `kustomization.yaml` and register your student directory
- Submit PR and verify ArgoCD sync into `student-<username>-dev`

---
layout: win95
windowTitle: "Lab 04 — kubeadm Bootstrap Foundations"
windowIcon: "🛠"
statusText: "Week 04 · Lab 04 · Control-plane bootstrap"
---

## Lab 04 Focus

- Run preflight checks and initialize control plane with `kubeadm init`
- Install CNI, inspect `/etc/kubernetes/manifests` and PKI files
- Generate join command and practice reset/rebuild workflow

---
layout: win95
windowTitle: "Lab 04b — kubeadm Full Lifecycle (VirtualBox)"
windowIcon: "🖥"
statusText: "Week 04 · Lab 04b · Multi-node lifecycle"
---

## Lab 04b Focus

- Build 3-node VM cluster, install CNI, join workers
- Practice upgrade flow and optional HA control-plane steps
- Reset and clean up all cluster state safely

---
layout: win95
windowTitle: "Lab 05 — RBAC Authorization Deep Dive"
windowIcon: "🔐"
statusText: "Week 04 · Lab 05 · Least-privilege authz"
---

## Lab 05 Focus

- Create Role/ClusterRole and bindings for service accounts
- Validate permissions with `kubectl auth can-i --as=...`
- Diagnose namespace-scoping binding failures

---
layout: win95
windowTitle: "Lab 06 — Pod Security Admission"
windowIcon: "🔒"
statusText: "Week 04 · Lab 06 · Admission-time policy"
---

## Lab 06 Focus

- Enforce `restricted` with namespace PSA labels
- Fix pod specs with `securityContext` and writable `emptyDir` paths
- Compare enforce/audit/warn behaviors and version pinning

---
layout: win95
windowTitle: "Lab 07 — Extension Interfaces"
windowIcon: "🧩"
statusText: "Week 04 · Lab 07 · CRI/CNI/CSI boundaries"
---

## Lab 07 Focus

- Inspect runtime socket, CNI config, and storage classes
- Observe interface-specific failure patterns and triage commands
- Build a troubleshooting mental map for CRI vs CNI vs CSI
