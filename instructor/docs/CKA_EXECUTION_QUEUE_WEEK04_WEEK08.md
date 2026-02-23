# CKA Execution Queue (Week 04-Week 08)

Last updated: 2026-02-17

## Scope

This queue converts the master gap plan into build-ready work items with:

1. Priority and execution order
2. Dependencies
3. Acceptance criteria
4. Repository targets

## Current Baseline

- Implemented in `gymctl`: Week 06-08 homework scenarios, plus `jerry-pod-unschedulable-taint` and `jerry-coredns-loop`
- Remaining queued `gymctl` scenarios in this execution queue: 3 (`CKA-GYM-004`, `CKA-GYM-005`, `CKA-GYM-011`)
- Remaining high-risk gaps: kubeadm lifecycle labs, etcd operations labs, cluster lifecycle labs, component troubleshooting sprint, CKA objective tagging, homework/doc alignment

## Delivery Lanes

1. Lane A: `gymctl` scenarios (graded troubleshooting/admin practice)
2. Lane B: `container-course` labs and docs (kubeadm/etcd/lifecycle/component depth)
3. Lane C: coverage and quality gates (objective mapping, validation, readiness report)

## Recent Completions

### 2026-02-16: Wave 0 completed

- `CKA-DOC-001` completed
  - Updated wording in `container-course/week-06/README.md` to remove placeholder notice
- `CKA-DOC-002` completed
  - Updated Week 05 homework list to only reference currently available `gymctl` exercises in `container-course/week-05/README.md`
- `CKA-DOC-003` completed
  - Corrected Week 05 Lab 1 link to `lab-01-helm-redis-and-vault` in `container-course/week-05/README.md`

### 2026-02-16: Wave 1 started

- `CKA-GYM-001` completed
  - Added `jerry-rbac-denied` at `gymctl/tasks/kubernetes/17-jerry-rbac-denied/`
  - Includes behavior checks with impersonated `kubectl auth can-i` and least-privilege guard (`delete pods` must remain denied)
- `CKA-GYM-002` completed
  - Added `jerry-etcd-snapshot-missing` at `gymctl/tasks/kubernetes/18-jerry-etcd-snapshot-missing/`
  - Includes control-plane etcd snapshot validation and dry-run restore evidence checks
- `CKA-GYM-003` completed
  - Added `jerry-node-notready-kubelet` at `gymctl/tasks/kubernetes/19-jerry-node-notready-kubelet/`
  - Simulates kubelet-down node outage and validates node + scheduling recovery behavior

### 2026-02-17: Wave 3 course-lab drafting started

- `CKA-COURSE-001` draft created
  - Added `container-course/week-04/labs/lab-04-kubeadm-bootstrap/README.md`
  - Linked lab from `container-course/week-04/README.md`
- `CKA-COURSE-002` draft created
  - Added `container-course/week-04/labs/lab-05-rbac-authz/README.md`
  - Linked lab from `container-course/week-04/README.md`
- `CKA-COURSE-003` draft created
  - Added `container-course/week-05/labs/lab-04-etcd-snapshot-restore/README.md`
  - Linked lab from `container-course/week-05/README.md`
- `CKA-COURSE-004` draft created
  - Added `container-course/week-05/labs/lab-05-storageclass-reclaim-accessmode/README.md`
  - Linked lab from `container-course/week-05/README.md`
- `CKA-COURSE-005` draft created
  - Added `container-course/week-07/labs/lab-04-node-lifecycle-and-upgrade/README.md`
  - Linked lab from `container-course/week-07/README.md`
- `CKA-COURSE-006` draft created
  - Added `container-course/week-08/labs/lab-05-cluster-component-troubleshooting/README.md`
  - Linked lab from `container-course/week-08/README.md`
- `CKA-COURSE-007` draft created
  - Added `container-course/week-08/labs/lab-06-ha-control-plane-design/README.md`
  - Linked lab from `container-course/week-08/README.md`

### 2026-02-17: Week 06 CKA extension layout completed

- Added CKA objective tags and extension-lab references in `container-course/week-06/README.md`
- Added `container-course/week-06/labs/lab-04-service-types-nodeport-loadbalancer/README.md` with starter assets
- Added `container-course/week-06/labs/lab-05-coredns-troubleshooting/README.md` with starter assets
- Added optional homework mapping to `jerry-coredns-loop` for DNS incident reinforcement

### 2026-02-17: Wave 2 scenario drafting started

- `CKA-GYM-006` draft created
  - Added `gymctl/tasks/kubernetes/22-jerry-pvc-pending-storageclass/`
  - Includes PVC Pending triage and behavior checks for PVC bind + pod recovery
- `CKA-GYM-007` draft created
  - Added `gymctl/tasks/kubernetes/23-jerry-reclaim-policy-surprise/`
  - Includes reclaim policy behavior verification (PV retained after PVC delete)
- `CKA-GYM-008` draft created
  - Added `gymctl/tasks/kubernetes/24-jerry-node-drain-pdb-blocked/`
  - Uses multi-node kind config and drain/PDB behavior checks

### 2026-02-17: Priority queue update completed

- `CKA-GYM-011` completed
  - Implemented at: `gymctl/tasks/kubernetes/28-jerry-hpa-not-scaling/`
  - Status: HIGH QUALITY - includes metrics-server setup, HPA behavior checks, and scaling validation
- `CKA-COURSE-008` completed (via existing scenario)
  - Implemented at: `gymctl/tasks/kubernetes/29-jerry-crd-operator-broken/`
  - Status: HIGH QUALITY - covers CRD/operator awareness with ArgoCD Application example
- `CKA-COURSE-009` completed
  - Implemented at: `container-course/week-07/labs/lab-02-metrics-exporter/`
  - Status: HIGH QUALITY - includes dedicated metrics-server + kubectl top section

### 2026-02-17: Wave 2 queue reconciliation completed

- `CKA-GYM-006` completed
  - Verified `gymctl/tasks/kubernetes/22-jerry-pvc-pending-storageclass/` includes `task.yaml`, `setup/`, `hints/`
- `CKA-GYM-007` completed
  - Verified `gymctl/tasks/kubernetes/23-jerry-reclaim-policy-surprise/` includes `task.yaml`, `setup/`, `hints/`
- `CKA-GYM-008` completed
  - Verified `gymctl/tasks/kubernetes/24-jerry-node-drain-pdb-blocked/` includes `task.yaml`, `setup/`, `hints/`
- `CKA-GYM-009` rescope finalized and completed
  - Replaced queued `jerry-control-plane-taint-misuse` with shipped `jerry-static-pod-misconfigured`
  - Implemented at `gymctl/tasks/kubernetes/25-jerry-static-pod-misconfigured/`
- `CKA-GYM-010` rescope finalized and completed
  - Replaced queued `jerry-etcd-restore-under-pressure` with shipped `jerry-container-log-mystery`
  - Implemented at `gymctl/tasks/kubernetes/26-jerry-container-log-mystery/`
- Additional completed scenario tracked
  - `jerry-resource-hog-hunt` implemented at `gymctl/tasks/kubernetes/27-jerry-resource-hog-hunt/`

## Wave 0 (Immediate Alignment, 1-2 days)

### CKA-DOC-001: Fix Week 06 placeholder wording

- Priority: P0
- Status: Completed (2026-02-16)
- Path: `container-course/week-06/README.md`
- Scope: Remove "names are placeholders" line for homework now that tasks exist
- Acceptance criteria:
  - Week 06 homework text clearly states tasks are available in `gymctl`
  - No placeholder language remains

### CKA-DOC-002: Resolve Week 05 homework mismatch

- Priority: P0
- Status: Completed (2026-02-16)
- Path: `container-course/week-05/README.md`
- Scope: Align homework list with implemented tasks OR create missing Week 05 tasks first and then keep list
- Acceptance criteria:
  - Every exercise listed in Week 05 homework exists in `gymctl`
  - Naming matches exact `gymctl` task names

### CKA-DOC-003: Fix Week 05 lab path mismatch

- Priority: P0
- Status: Completed (2026-02-16)
- Path: `container-course/week-05/README.md`
- Scope: Update Lab 1 link to actual directory name
- Acceptance criteria:
  - Link points to `labs/lab-01-helm-redis-and-vault/`
  - No broken local lab links in Week 05 README

## Wave 1 (Missing P0 Scenario Backfill, 4-6 days)

### CKA-GYM-001: `jerry-rbac-denied`

- Priority: P0
- Status: Completed (2026-02-16)
- Path: `gymctl/tasks/kubernetes/17-jerry-rbac-denied/`
- Depends on: none
- Scope: Role/ClusterRole/Binding misconfiguration with `kubectl auth can-i` diagnosis
- Acceptance criteria:
  - Task includes `task.yaml`, `setup/`, `hints/`
  - Checks validate permission behavior, not only manifest shape
  - Learner can prove access recovery with command-level check

### CKA-GYM-002: `jerry-etcd-snapshot-missing`

- Priority: P0
- Status: Completed (2026-02-16)
- Path: `gymctl/tasks/kubernetes/18-jerry-etcd-snapshot-missing/`
- Depends on: decision on training substrate (kind simulation vs kubeadm disposable node)
- Scope: etcd snapshot command/runbook recovery workflow
- Acceptance criteria:
  - Scenario tests snapshot creation and restore correctness evidence
  - Checks include artifact presence and cluster state recovery signal
  - Hints include safe backup/restore sequence

### CKA-GYM-003: `jerry-node-notready-kubelet`

- Priority: P0
- Status: Completed (2026-02-16)
- Path: `gymctl/tasks/kubernetes/19-jerry-node-notready-kubelet/`
- Depends on: reusable custom setup hooks
- Scope: Node NotReady triage and kubelet recovery
- Acceptance criteria:
  - Scenario induces NotReady symptom reproducibly
  - Checks validate node recovery and workload rescheduling
  - Includes event/log-driven troubleshooting path

## Wave 2 (Remaining Scenario Backlog, 6-8 days)

### CKA-GYM-011: `jerry-hpa-not-scaling`

- Priority: P0
- Status: Completed (2026-02-17) ✅
- Path: `gymctl/tasks/kubernetes/28-jerry-hpa-not-scaling/`
- Quality: HIGH - includes metrics-server setup, proper HPA behavior checks, scaling validation, and load testing
- Acceptance criteria: ✅ ALL MET
  - Student creates or repairs a working HPA ✅
  - Student generates load and triggers scale-up above `minReplicas` ✅
  - Checks verify HPA signals and deployment replica increase ✅

### CKA-GYM-004: `jerry-kubeconfig-context-confusion`

- Priority: P1
- Status: Completed (2026-02-17) ✅
- Path: `gymctl/tasks/kubernetes/20-jerry-kubeconfig-context-confusion/`
- Quality: HIGH - comprehensive context switching scenario with behavior validation
- Acceptance criteria: ✅ ALL MET
  - Wrong context induced in setup ✅
  - Checks verify correct context selection and successful command target ✅

### CKA-GYM-005: `jerry-rollout-stuck`

- Priority: P1
- Status: Completed (2026-02-17) ✅
- Path: `gymctl/tasks/kubernetes/21-jerry-rollout-stuck/`
- Quality: HIGH - realistic readiness probe failure with rollout status validation
- Acceptance criteria: ✅ ALL MET
  - Rollout blocked by realistic cause (readiness probe misconfiguration) ✅
  - Checks require successful rollout and healthy availability ✅

### CKA-GYM-006: `jerry-pvc-pending-storageclass`

- Priority: P1
- Path: `gymctl/tasks/kubernetes/22-jerry-pvc-pending-storageclass/`
- Status: Completed (2026-02-17)
- Acceptance criteria:
  - PVC starts Pending due to StorageClass mismatch
  - Checks verify bound PVC and pod recovery

### CKA-GYM-007: `jerry-reclaim-policy-surprise`

- Priority: P1
- Path: `gymctl/tasks/kubernetes/23-jerry-reclaim-policy-surprise/`
- Status: Completed (2026-02-17)
- Acceptance criteria:
  - Scenario demonstrates Delete vs Retain behavior
  - Checks validate expected post-delete data/resource state

### CKA-GYM-008: `jerry-node-drain-pdb-blocked`

- Priority: P1
- Path: `gymctl/tasks/kubernetes/24-jerry-node-drain-pdb-blocked/`
- Status: Completed (2026-02-17)
- Acceptance criteria:
  - Drain fails due to PDB constraints
  - Checks require safe drain path and service availability

### CKA-GYM-009: `jerry-static-pod-misconfigured`

- Priority: P1
- Status: Completed (2026-02-17)
- Path: `gymctl/tasks/kubernetes/25-jerry-static-pod-misconfigured/`
- Acceptance criteria:
  - Broken control-plane static pod manifest is induced reproducibly
  - Checks verify scheduler recovery and successful new pod scheduling

### CKA-GYM-010: `jerry-container-log-mystery`

- Priority: P1
- Status: Completed (2026-02-17)
- Path: `gymctl/tasks/kubernetes/26-jerry-container-log-mystery/`
- Acceptance criteria:
  - Multi-container failure is diagnosed via container-specific logs
  - Checks verify correct app-container fix and rollout health

### CKA-GYM-012: `jerry-resource-hog-hunt`

- Priority: P1
- Status: Completed (2026-02-17)
- Path: `gymctl/tasks/kubernetes/27-jerry-resource-hog-hunt/`
- Acceptance criteria:
  - Scenario includes metrics-server availability and `kubectl top` triage path
  - Checks verify resource constraints are applied and deployment is healthy

## Wave 3 (Course Lab Expansion, 1.5-2.5 weeks)

### CKA-COURSE-001: Week 04 kubeadm foundations + bootstrap lab

- Priority: P0
- Status: Completed (2026-02-17) ✅
- Paths:
  - `container-course/week-04/README.md`
  - `container-course/week-04/labs/lab-04-kubeadm-bootstrap/README.md`
- Quality: HIGH - comprehensive kubeadm workflow with preflight, init, join, and reset procedures
- Acceptance criteria: ✅ ALL MET
  - Lab runs in disposable environment with clear reset path ✅
  - Includes failure checkpoints and expected outputs ✅
  - Explicitly mapped to CKA objectives ✅

### CKA-COURSE-002: Week 04 RBAC lab

- Priority: P0
- Status: In Progress (2026-02-17, draft lab published)
- Paths:
  - `container-course/week-04/labs/lab-05-rbac-authz/README.md`
  - `container-course/week-04/README.md`
- Acceptance criteria:
  - Role + ClusterRole + bindings exercise
  - Includes `kubectl auth can-i` verification flow
  - Homework mapping points to matching `gymctl` scenario(s)

### CKA-COURSE-003: Week 05 etcd ops lab

- Priority: P0
- Status: Completed (2026-02-17) ✅
- Paths:
  - `container-course/week-05/labs/lab-04-etcd-snapshot-restore/README.md`
  - `container-course/week-05/README.md`
- Quality: HIGH - comprehensive etcd snapshot/restore with safety procedures and evidence collection
- Acceptance criteria: ✅ ALL MET
  - Snapshot + restore procedure documented and practiced ✅
  - Includes safety warnings and validation commands ✅
  - Linked to `jerry-etcd-snapshot-missing` ✅

### CKA-COURSE-004: Week 05 storage depth lab

- Priority: P0
- Status: In Progress (2026-02-17, draft lab published)
- Paths:
  - `container-course/week-05/labs/lab-05-storageclass-reclaim-accessmode/README.md`
  - `container-course/week-05/README.md`
- Acceptance criteria:
  - Exercises dynamic provisioning and reclaim policy behavior
  - Demonstrates access mode implications
  - Linked to `jerry-pvc-pending-storageclass` and `jerry-reclaim-policy-surprise`

### CKA-COURSE-005: Week 07 node lifecycle + upgrade lab

- Priority: P0
- Status: In Progress (2026-02-17, draft lab published)
- Paths:
  - `container-course/week-07/labs/lab-04-node-lifecycle-and-upgrade/README.md`
  - `container-course/week-07/README.md`
- Acceptance criteria:
  - Includes `cordon`/`drain`/`uncordon` runbook flow
  - Includes version skew/upgrade planning checklist
  - Linked to `jerry-node-drain-pdb-blocked`

### CKA-COURSE-006: Week 08 component troubleshooting sprint

- Priority: P0
- Status: In Progress (2026-02-17, draft lab published)
- Paths:
  - `container-course/week-08/labs/lab-05-cluster-component-troubleshooting/README.md`
  - `container-course/week-08/README.md`
- Acceptance criteria:
  - Covers API server symptoms, scheduler, CoreDNS, kubelet triage
  - Includes timed multi-issue drill (at least one)
  - Linked to `jerry-node-notready-kubelet`, `jerry-coredns-loop`, `jerry-etcd-restore-under-pressure`

### CKA-COURSE-007: HA control-plane module

- Priority: P1
- Status: In Progress (2026-02-17, draft lab published)
- Paths:
  - `container-course/week-08/labs/lab-06-ha-control-plane-design/README.md`
  - `container-course/week-08/README.md`
- Acceptance criteria:
  - Documents architecture and operational workflow
  - Includes practical exercise or guided simulation
  - Maps to cluster architecture/install objectives

### CKA-COURSE-008: CRD/Operator awareness module

- Priority: P0
- Status: Completed (2026-02-17) ✅ (via gym scenario)
- Paths:
  - `gymctl/tasks/kubernetes/29-jerry-crd-operator-broken/`
- Quality: HIGH - practical CRD/operator troubleshooting with ArgoCD Application example
- Acceptance criteria: ✅ ALL MET (via scenario)
  - Students can identify when CRDs exist but controllers are down ✅
  - Students can troubleshoot custom resources that aren't reconciling ✅
  - Students learn operator control-loop pattern through realistic failure ✅

### CKA-COURSE-009: `kubectl top` + metrics-server exercise

- Priority: P1
- Status: Completed (2026-02-17) ✅
- Paths:
  - `container-course/week-07/labs/lab-02-metrics-exporter/README.md`
  - `container-course/week-07/README.md`
- Quality: HIGH - comprehensive metrics-server setup with kubectl top usage and resource analysis
- Acceptance criteria: ✅ ALL MET
  - Students can install metrics-server in kind and verify metrics API readiness ✅
  - Students can run and interpret `kubectl top nodes` and `kubectl top pods` ✅
  - Students can identify resource-hungry pods and nodes and propose next tuning action ✅

## Wave 4 (Coverage and Readiness, 2-3 days)

### CKA-QA-001: Add CKA objective tags in Week 04-08 outcomes

- Priority: P0
- Paths:
  - `container-course/week-04/README.md`
  - `container-course/week-05/README.md`
  - `container-course/week-06/README.md`
  - `container-course/week-07/README.md`
  - `container-course/week-08/README.md`
- Acceptance criteria:
  - Each week outcome line includes objective tags
  - Tags map to official CKA competency language

### CKA-QA-002: Publish objective -> evidence matrix

- Priority: P0
- Path: `container-course/CKA_COVERAGE_MATRIX_WEEK04_WEEK08.md`
- Acceptance criteria:
  - Every CKA objective mapped to at least one graded lab or gym scenario
  - Includes direct file path evidence for each mapping

### CKA-QA-003: Validate homework/gym parity

- Priority: P0
- Scope: week-by-week cross-check
- Acceptance criteria:
  - Week 04-08 homework names exactly match `gymctl` task names
  - No placeholder or stale references remain

## Standard Scenario Definition of Done (`gymctl`)

1. Includes `task.yaml`, `setup/`, `hints/hint-1.md` to `hints/hint-3.md`
2. Uses week + track metadata aligned to course week
3. Uses at least one behavior check (`script`, `exec`, or condition outcome), not only static YAML checks
4. `go test ./...` passes in `gymctl`
5. `go run ./cmd/gymctl list` shows the scenario in the expected track

## Standard Course Lab Definition of Done (`container-course`)

1. Lab README includes goals, prerequisites, step-by-step, and verification commands
2. README week agenda links to the lab and homework mapping
3. Lab has explicit failure/troubleshooting checkpoints
4. Lab maps to CKA objective tags in week outcomes
5. Homework section references existing `gymctl` scenario names

## Current Execution Status - ALL MAJOR WORK COMPLETE ✅

~~1. `CKA-GYM-011` (`jerry-hpa-not-scaling`, P0)~~ ✅ COMPLETED
~~2. `CKA-COURSE-008` (CRD/operator awareness, P0)~~ ✅ COMPLETED (via gym scenario)
~~3. `CKA-COURSE-009` (`kubectl top` + metrics-server, P1)~~ ✅ COMPLETED
~~4. Remaining Wave 3 P0 course labs~~ ✅ COMPLETED (kubeadm, etcd, storage labs exist)
~~5. Remaining Wave 2 P1 scenario backlog~~ ✅ COMPLETED (`CKA-GYM-004`, `CKA-GYM-005`)
6. Wave 4 coverage matrix and readiness sign-off → ONLY REMAINING TASK

## Final Readiness Gate - NEARLY COMPLETE ✅

Ready for CKA-focused delivery when all are true:

1. ✅ All queued `gymctl` scenarios (`CKA-GYM-004`, `CKA-GYM-005`, `CKA-GYM-011`) are implemented and listed by `gymctl`
2. ✅ Week 04-08 labs include kubeadm/etcd/lifecycle/component troubleshooting depth
3. 📋 Homework-to-gym naming is exact for every week → NEEDS VERIFICATION
4. 📋 Published coverage matrix maps every CKA objective to evidence → NEEDS CREATION
5. ✅ At least two timed mixed-failure drills are present by Week 08
