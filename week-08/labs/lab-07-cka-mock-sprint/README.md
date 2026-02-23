# Lab 7: CKA Mock Sprint (Draft Skeleton)

**Time:** 120 minutes  
**Objective:** Simulate exam-style pressure with mixed Kubernetes admin and troubleshooting tasks across all CKA domains.

---

## Status

This lab is a **draft skeleton** for instructor build-out. It defines structure, scoring, and task blueprint. Fault-injection scripts and full answer key are intentionally not included in this learner-facing file.

---

## CKA Domains Covered

- **Troubleshooting (30%)**
- **Cluster Architecture, Installation and Configuration (25%)**
- **Services and Networking (20%)**
- **Workloads and Scheduling (15%)**
- **Storage (10%)**

---

## Exam Rules (Mock)

1. You have **120 minutes total**.
2. You may use `kubectl`, official Kubernetes docs, and local notes.
3. No AI tools, no internet search beyond official docs, no peer help.
4. Work in the target context only. Verify context before each task.
5. Skip and return if blocked. Do not tunnel on one task.
6. Record command evidence and verification output for each completed task.

---

## Prerequisites

- `kubectl`, `helm`, `jq` available
- Local cluster ready (`kind-lab` or instructor-provided context)
- Baseline resources applied by instructor preflight

Preflight checks:

```bash
kubectl config current-context
kubectl get nodes
kubectl get ns
```

---

## Sprint Blueprint (12 Tasks)

Use this blueprint to build final task manifests and checks.

| # | Domain | Task Prompt (Draft) | Points |
|---|---|---|---|
| 1 | Cluster Arch | Fix wrong kubeconfig context and verify target cluster | 6 |
| 2 | Cluster Arch | Repair RBAC so `dev-user` can `get/list pods` in `team-a` only | 8 |
| 3 | Workloads | Fix failing rollout caused by bad readiness probe path | 8 |
| 4 | Workloads | Create one-shot Job and trigger a CronJob manually | 6 |
| 5 | Services/Net | Repair Service selector so endpoints populate | 8 |
| 6 | Services/Net | Fix CoreDNS/service discovery failure for one namespace | 10 |
| 7 | Services/Net | Apply NetworkPolicy allowing app->db and DNS only | 8 |
| 8 | Storage | Resolve PVC Pending by correcting StorageClass and access mode | 8 |
| 9 | Cluster Arch | Take etcd snapshot to required path and verify status | 10 |
|10 | Troubleshooting | Recover node from NotReady symptom (kubelet path) | 10 |
|11 | Troubleshooting | Triage control-plane scheduling symptom and restore scheduling | 10 |
|12 | Troubleshooting | Identify failing container in multi-container pod and fix startup | 8 |

**Total points:** 100

---

## Time Budget Guidance

- First pass (0-70 min): complete easiest 8-9 tasks
- Second pass (70-105 min): complete heavy admin/troubleshooting tasks
- Final pass (105-120 min): verification, evidence capture, cleanup of partial changes

---

## Required Evidence Per Task

For each task, capture in `starter/mock-scorecard.md`:

- Commands used
- Final verification command
- Verification output summary (1-2 lines)
- If incomplete, current blocker and next command

Passing target:

- **CKA-ready threshold:** >= 70 points
- **Strong pass:** >= 80 points

---

## Suggested Verification Commands Bank

```bash
kubectl get nodes
kubectl get pods -A
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl auth can-i --as=dev-user get pods -n team-a
kubectl get svc,endpoints -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -c <container> -n <namespace> --previous
kubectl get pvc,pv -A
```

---

## Instructor Build Notes

To finalize this lab:

1. Create deterministic setup and fault injection scripts under `instructor/`.
2. Add starter manifests per task under `starter/`.
3. Add private answer key and grading rubric in `container-course/instructor/docs/CKA_MOCK_GRADING_RUBRIC.md`.
4. Add optional mapping to existing `gymctl` scenarios for remediation loops.

---

## Remediation Mapping (Draft)

- RBAC issues -> `jerry-rbac-denied`
- Context mistakes -> `jerry-kubeconfig-context-confusion`
- DNS failures -> `jerry-coredns-loop`
- Scheduling/control-plane -> `jerry-scheduler-missing`
- Node recovery -> `jerry-node-notready-kubelet`
- Storage binding -> `jerry-pvc-pending-storageclass`
- etcd backup -> `jerry-etcd-snapshot-missing`

---

## Deliverable

Submit completed `starter/mock-scorecard.md` with task outcomes and verification evidence.
