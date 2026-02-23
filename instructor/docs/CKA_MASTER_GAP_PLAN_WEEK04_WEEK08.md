# CKA Coverage Gap Plan (Week 04-Week 08)

Last updated: 2026-02-15

## Purpose

Create a single master plan that shows:

1. What is already covered in `container-course`, `talos-gitops`, and `gymctl`
2. What is missing for full CKA-aligned coverage
3. What to add from Week 04 through Week 08, with emphasis on `kubeadm`, `etcd`, and troubleshooting depth

## Scope Scanned

- `container-course` (weeks, labs, challenges, homework references)
- `talos-gitops` (bootstrap scripts, docs, RBAC, platform manifests)
- `gymctl` (existing Kubernetes exercises and scenario engine)

## CKA Target Baseline (Official)

Based on Linux Foundation CKA program changes (effective from February 18, 2025):

- Cluster Architecture, Installation and Configuration: 25%
- Workloads and Scheduling: 15%
- Services and Networking: 20%
- Storage: 10%
- Troubleshooting: 30%

This document maps against the competency list published in that update.

## Current State Summary

## `container-course`

- Strong coverage for app-level Kubernetes basics in Week 04-08: Deployments, Services, ConfigMaps/Secrets, StatefulSets/PVC, Ingress/Gateway API, NetworkPolicy, GitOps
- Good tooling exposure: `kubectl`, Helm, Kustomize, ArgoCD
- Troubleshooting exists, but mostly workload-level (pod/service/config/probe) rather than cluster-level (control plane, nodes, component failures)
- Mentions `kubeadm`/etcd concepts in lecture materials, but no hands-on kubeadm cluster lifecycle or etcd backup/restore labs

## `talos-gitops`

- Strong for platform GitOps operations, RBAC patterns, Gateway API, and shared cluster operations
- Good as a "real platform" reference for students after fundamentals
- Not suitable as the primary vehicle for CKA kubeadm objectives (Talos abstracts away kubeadm-style control plane management)

## `gymctl`

- Current Kubernetes track is small and Week 04-focused:
  - `jerry-forgot-resources`
  - `jerry-broken-service`
  - `jerry-missing-configmap`
  - `jerry-probe-failures`
  - `jerry-wrong-namespace`
- Week 06-08 homework exercises listed in `container-course` README files are not implemented in `gymctl` yet
- Existing troubleshooting is useful but not enough for CKA troubleshooting weighting (30%)

## Critical Gaps (High Priority)

1. No hands-on `kubeadm` cluster create/join/upgrade/reset flow
2. No etcd operational practice (snapshot, restore, failure recovery)
3. No HA control plane implementation exercise
4. Limited cluster lifecycle operations (upgrade strategy, node maintenance)
5. Limited troubleshooting at cluster/component level (`kubelet`, scheduler, CoreDNS, API server symptoms)
6. Missing Week 06-08 gym scenarios that are already referenced in course homework
7. Storage depth gap: reclaim policy, access modes, volume mode, dynamic provisioning tradeoffs
8. Services gap: Service type behavior (NodePort/LoadBalancer) is taught conceptually but lacks strong graded practice
9. Homework naming mismatch exists in Week 04 docs vs current `gymctl` exercise names

## CKA Objective Coverage Matrix

Legend:

- `Strong`: already taught with meaningful hands-on
- `Partial`: taught conceptually or lightly practiced
- `Missing`: not currently taught in practical form

| Domain | CKA Objective | Current Coverage | Status | Gap Closure Needed |
|---|---|---|---|---|
| Cluster Arch/Install/Config | Manage RBAC | Week 04 auth/RBAC lecture and shared cluster model; `talos-gitops/student-infra/rbac` | Partial | Add dedicated RBAC lab with Role/ClusterRole/Bindings and `kubectl auth can-i` troubleshooting |
| Cluster Arch/Install/Config | Prepare infrastructure for cluster install | kind setup exists (`week-04/labs/lab-01-kind-cluster`) | Partial | Add kubeadm preflight infrastructure prep module (sysctl, cgroups, runtime, ports) |
| Cluster Arch/Install/Config | Create/manage clusters with kubeadm | Only mention in slides (`week-04/presentations/03-k8s-flavors.excalidraw`) | Missing | Add full kubeadm lab sequence (init, join, cert upload, reset) |
| Cluster Arch/Install/Config | Manage lifecycle of clusters | Minimal lifecycle in current content | Missing | Add upgrade and maintenance runbook labs (version skew, drain/uncordon, upgrade plan) |
| Cluster Arch/Install/Config | Configure HA control plane | No HA lab | Missing | Add 3-control-plane HA design and implementation walkthrough/lab |
| Cluster Arch/Install/Config | Use Helm/Kustomize for components | Strong across Week 05/07/08 | Strong | Keep and map explicitly to CKA objective in week outcomes |
| Cluster Arch/Install/Config | Understand CNI/CSI/CRI interfaces | CNI discussed; CSI/CRI minimal | Partial | Add module on runtime/CNI/CSI responsibilities with troubleshooting cases |
| Cluster Arch/Install/Config | Understand CRDs/operators | Operator mention only, light exposure | Partial | Add CRD/operator install + failure scenario lab |
| Workloads/Scheduling | Deployments, rolling update, rollback | Week 04 Lab 2 includes rollout/undo | Strong | Keep |
| Workloads/Scheduling | ConfigMaps/Secrets | Week 05 labs + gym scenario | Strong | Keep |
| Workloads/Scheduling | Scale applications | Week 04 deploy/scale | Strong | Keep |
| Workloads/Scheduling | Self-healing primitives | Deployments/probes covered | Partial | Add deeper controller behavior and failure simulations |
| Workloads/Scheduling | Resource limits and scheduling impact | Week 04 + `jerry-forgot-resources` | Strong | Add taints/tolerations/affinity for scheduler depth |
| Workloads/Scheduling | Manifest management/templating awareness | Kustomize/Helm/GitOps strong | Strong | Keep |
| Services/Networking | Pod connectivity | Week 06 + gym namespace/service exercises | Strong | Keep |
| Services/Networking | NetworkPolicies | Week 06 Lab 3 strong | Strong | Keep |
| Services/Networking | Service types + endpoints | Taught in Week 06; weak graded practice | Partial | Add graded NodePort/LoadBalancer troubleshooting labs |
| Services/Networking | Ingress controllers/resources | Week 06 Lab 1 strong | Strong | Keep |
| Services/Networking | CoreDNS | Conceptual mention; little dedicated debug | Partial | Add CoreDNS failure lab and DNS triage checklist |
| Storage | StorageClass + dynamic provisioning | Mentioned in labs, but light | Partial | Add explicit dynamic provisioning lab across StorageClasses |
| Storage | local/hostPath/CSI/network storage models | Mentioned but not compared deeply | Partial | Add storage backend comparison exercise and decision matrix |
| Storage | PV/PVC | Week 05 strong | Strong | Keep |
| Storage | volume mode/access mode/reclaim policy | Access mode touched; reclaim/volume mode weak | Partial | Add reclaim policy + Retain/Delete lab and restore workflow |
| Troubleshooting | Troubleshoot clusters and nodes | Mostly workload-level | Missing | Add node NotReady, kubelet down, disk pressure labs |
| Troubleshooting | Troubleshoot cluster components | Minimal component failure labs | Missing | Add scheduler/CoreDNS/API-server symptom-based scenarios |
| Troubleshooting | Monitor resource usage | Some metrics exposure in Week 07 | Partial | Add `kubectl top`, events, saturation diagnostics, SLO thresholds |
| Troubleshooting | Manage/evaluate container output streams | logs/describe/events already used | Strong | Keep and expand to multi-container and init-container logs |
| Troubleshooting | Troubleshoot services and networking | Week 06 and gym service exercises | Strong | Add deeper DNS + endpoint + CNI routing fault drills |

## Week 04-08 Expansion Plan

## Week 04 (Foundation + Admin Entry)

Add:

- Kubeadm foundations lecture: control plane certificates, kubeconfig locations, static pods
- Lab: kubeadm preflight + single control-plane bootstrap in disposable lab environment
- Lab: RBAC hands-on with least privilege and auth checks
- Gym additions:
  - `jerry-rbac-denied`
  - `jerry-kubeconfig-context-confusion`
  - `jerry-rollout-stuck`

Outputs:

- `container-course/week-04` new admin lab docs
- `gymctl/tasks/kubernetes/week-04-admin/*`

## Week 05 (State + etcd + Storage Depth)

Add:

- etcd architecture and operational safety module
- Lab: etcd snapshot and restore drill
- Lab: StorageClass, reclaim policy, and access mode comparison
- Gym additions:
  - `jerry-etcd-snapshot-missing`
  - `jerry-pvc-pending-storageclass`
  - `jerry-reclaim-policy-surprise`

Outputs:

- `container-course/week-05` new etcd/storage labs
- `gymctl/tasks/kubernetes/week-05-state/*`

## Week 06 (Networking + DNS + Service Types)

Add:

- Lab: Service type behavior (ClusterIP/NodePort/LoadBalancer) end-to-end
- Lab: CoreDNS troubleshooting (broken service discovery)
- Implement missing homework scenarios already referenced:
  - `jerry-nodeport-mystery`
  - `jerry-broken-ingress-host`
  - `jerry-networkpolicy-dns`
  - `jerry-gateway-route-detached`

Outputs:

- `container-course/week-06` reinforced troubleshooting labs
- `gymctl/tasks/kubernetes/week-06-network/*`

## Week 07 (Scheduling + Cluster Lifecycle + Upgrade Ops)

Add:

- Scheduler deep dive: taints, tolerations, affinity/anti-affinity, topology spread
- Lab: node maintenance (`cordon`, `drain`, `uncordon`) and disruption impact
- Lab: upgrade planning and version skew simulation
- Implement missing homework scenarios:
  - `jerry-kustomize-drift`
  - `jerry-exporter-missing-metrics`
  - `jerry-prometheus-target-down`
- Gym additions for CKA depth:
  - `jerry-pod-unschedulable-taint`
  - `jerry-node-drain-pdb-blocked`

Outputs:

- `container-course/week-07` admin scheduling/lifecycle module
- `gymctl/tasks/kubernetes/week-07-ops/*`

## Week 08 (CKA Troubleshooting Sprint + Mock)

Add:

- Component troubleshooting day (API server symptoms, scheduler queue, CoreDNS, kubelet)
- Lab: timed multi-issue incident response
- Implement missing homework scenarios:
  - `jerry-argo-out-of-sync`
  - `jerry-ci-pipeline-fix`
- Add CKA-focused final drills:
  - `jerry-node-notready-kubelet`
  - `jerry-coredns-loop`
  - `jerry-etcd-restore-under-pressure`
  - `jerry-control-plane-taint-misuse`

Outputs:

- `container-course/week-08` troubleshooting-intensive capstone
- `gymctl/tasks/kubernetes/week-08-cka/*`

## Gym Backlog (Prioritized)

P0 (must build first):

1. `jerry-nodeport-mystery`
2. `jerry-networkpolicy-dns`
3. `jerry-gateway-route-detached`
4. `jerry-kustomize-drift`
5. `jerry-prometheus-target-down`
6. `jerry-argo-out-of-sync`
7. `jerry-etcd-snapshot-missing`
8. `jerry-node-notready-kubelet`
9. `jerry-coredns-loop`
10. `jerry-rbac-denied`

P1 (second wave):

1. `jerry-pod-unschedulable-taint`
2. `jerry-node-drain-pdb-blocked`
3. `jerry-pvc-pending-storageclass`
4. `jerry-reclaim-policy-surprise`
5. `jerry-control-plane-taint-misuse`

## Talos-GitOps Integration Strategy

Use `talos-gitops` as:

- Real-world platform reference for RBAC, Gateway API, ArgoCD, and multi-namespace operations
- Shared production visibility environment for students

Do not use `talos-gitops` as the only CKA admin lab substrate for kubeadm objectives. For CKA coverage, add a dedicated kubeadm-focused disposable lab environment in course/gym workflows.

## Required Repository Changes

## `container-course`

- Add CKA objective tags to Week 04-08 learning outcomes
- Add missing admin content: kubeadm, etcd, lifecycle, component troubleshooting
- Align homework tables with actual gym exercises available

## `gymctl`

- Implement Week 06-08 scenarios already documented in course README files
- Add new CKA admin/troubleshooting tracks and metadata by week
- Add scenario checks that validate operator behavior, not only final YAML shape

## `talos-gitops`

- Add optional docs for "how this platform differs from kubeadm exam tasks"
- Add troubleshooting runbooks students can reference for shared-cluster incidents

## Definition of Done (Full CKA Coverage Standard)

The course reaches CKA-ready standard when all are true:

1. Every CKA competency in the Linux Foundation list maps to at least one graded lab or gym scenario
2. Troubleshooting objectives (30%) have equivalent practice weight in assignments
3. Week 06-08 homework references exactly match implemented `gymctl` scenarios
4. Students complete at least two timed mixed-failure drills by Week 08
5. A published coverage matrix shows objective -> lab/gym evidence paths

## Immediate Execution Order

1. Implement missing Week 06-08 `gymctl` scenarios already listed in course docs
2. Add Week 05 etcd backup/restore and Week 07 node lifecycle modules
3. Add Week 08 cluster/component troubleshooting sprint
4. Add kubeadm end-to-end lab sequence and HA control plane module
5. Publish final objective-level coverage matrix after implementation

## External References

- Linux Foundation forum post with updated CKA domains and competency list (effective 2025-02-18):
  - https://forum.linuxfoundation.org/discussion/866984/cka-program-changes-important-information
- Linux Foundation certification page:
  - https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/
